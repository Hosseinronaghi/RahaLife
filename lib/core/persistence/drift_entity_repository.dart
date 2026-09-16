import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../sync/canonical_json.dart';
import '../sync/causal_clock.dart';
import '../sync/device_identity.dart';
import '../sync/drift_sync_store.dart';
import '../sync/sync_contract.dart';

class ConcurrentRecordEdit extends StateError {
  ConcurrentRecordEdit(super.message);
}

/// All record changes and outbox entries commit in the same Drift transaction.
class DriftEntityRepository {
  DriftEntityRepository({AppDatabase? database}) : db = database ?? appDatabase;
  final AppDatabase db;
  static const _uuid = Uuid();
  final Map<String, Map<String, Map<String, Object?>>> _observed = {};
  Map<String, Object?> _copy(Map<String, Object?> value) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
  Future<List<Map<String, Object?>>> loadAll(
    String type, {
    bool includeArchived = false,
  }) async {
    final rows =
        await (db.select(db.entityDocuments)
              ..where((r) => r.entityType.equals(type) & r.deletedAt.isNull())
              ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
            .get();
    final result = rows
        .map((r) => Map<String, Object?>.from(jsonDecode(r.payloadJson) as Map))
        .where((e) => includeArchived || e['archived'] != true)
        .toList();
    _observed[type] = {for (final e in result) e['id'].toString(): _copy(e)};
    return result;
  }

  Future<Map<String, Object?>?> loadOne(String type, String id) async {
    final row =
        await (db.select(db.entityDocuments)..where(
              (r) =>
                  r.entityType.equals(type) &
                  r.id.equals(id) &
                  r.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row == null
        ? null
        : Map<String, Object?>.from(jsonDecode(row.payloadJson) as Map);
  }

  Future<bool> containsIncludingDeleted(String type, String id) async =>
      await (db.select(db.entityDocuments)
            ..where((r) => r.entityType.equals(type) & r.id.equals(id)))
          .getSingleOrNull() !=
      null;
  Future<void> replaceAll(
    String type,
    Iterable<Map<String, Object?>> payloads,
  ) {
    final next = <String, Map<String, Object?>>{};
    for (final item in payloads) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty || next.containsKey(id)) {
        throw ArgumentError('Missing or duplicate stable identifier');
      }
      next[id] = _copy(item);
    }
    final previous = _observed[type] ?? <String, Map<String, Object?>>{};
    final edits = <String, Map<String, Object?>?>{};
    for (final id in {...previous.keys, ...next.keys}) {
      if (canonicalJson(previous[id]) != canonicalJson(next[id])) {
        edits[id] = next[id];
      }
    }
    _observed[type] = next;
    return db
        .transaction(() async {
          for (final edit in edits.entries) {
            await _writeOne(
              type,
              edit.key,
              edit.value,
              base: previous[edit.key],
            );
          }
        })
        .catchError((Object error) async {
          if (identical(_observed[type], next)) {
            _observed[type] = previous;
          }
          if (error is ConcurrentRecordEdit) {
            final store = DriftSyncStore(
              providerId: 'local-edit',
              database: db,
            );
            for (final edit in edits.entries) {
              final remote = await store.readCurrent(type, edit.key);
              if (remote == null) {
                continue;
              }
              await store.saveConflicts([
                SyncConflict(
                  local: SyncEnvelope(
                    entityType: type,
                    entityId: edit.key,
                    operation: edit.value == null
                        ? SyncOperation.delete
                        : SyncOperation.upsert,
                    version: remote.version,
                    updatedAtUtc: DateTime.now().toUtc(),
                    deviceId: await DeviceIdentityService.getOrCreate(),
                    payload: edit.value ?? previous[edit.key] ?? {},
                    clock: remote.effectiveClock,
                    deletedAtUtc: edit.value == null
                        ? DateTime.now().toUtc()
                        : null,
                  ),
                  remote: remote,
                ),
              ]);
            }
          }
          throw error;
        });
  }

  Future<void> upsert(String type, Map<String, Object?> value) {
    final id = value['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Missing stable identifier');
    }
    return db.transaction(() => _writeOne(type, id, _copy(value)));
  }

  Future<void> updateFromSnapshot(
    String type,
    Map<String, Object?> value,
    Map<String, Object?> base,
  ) => db.transaction(
    () => _writeOne(type, value['id'].toString(), value, base: base),
  );
  Future<void> delete(String type, String id) =>
      db.transaction(() => _writeOne(type, id, null));
  Future<void> deleteFromSnapshot(String type, Map<String, Object?> base) =>
      db.transaction(
        () => _writeOne(type, base['id'].toString(), null, base: base),
      );
  Future<void> _writeOne(
    String type,
    String id,
    Map<String, Object?>? value, {
    Map<String, Object?>? base,
  }) async {
    final current =
        await (db.select(db.entityDocuments)
              ..where((r) => r.entityType.equals(type) & r.id.equals(id)))
            .getSingleOrNull();
    if (value == null && (current == null || current.deletedAt != null)) {
      return;
    }
    if (type == 'finance_account' &&
        current != null &&
        current.deletedAt == null) {
      final old = jsonDecode(current.payloadJson) as Map;
      if (value == null ||
          (old['currencyCode'] ?? 'IRT') != (value['currencyCode'] ?? 'IRT')) {
        final rows =
            await (db.select(db.entityDocuments)..where(
                  (r) =>
                      r.entityType.equals('finance_transaction') &
                      r.deletedAt.isNull(),
                ))
                .get();
        if (rows.any((r) {
          final t = jsonDecode(r.payloadJson) as Map;
          return t['accountId'] == id || t['toAccountId'] == id;
        })) {
          throw StateError(
            'Archive accounts with transactions; their currency and history must be preserved.',
          );
        }
      }
    }
    var chosen = value;
    if (current != null && base != null) {
      final remote = Map<String, Object?>.from(
        jsonDecode(current.payloadJson) as Map,
      );
      if (value == null) {
        if (canonicalJson(base) != canonicalJson(remote)) {
          throw ConcurrentRecordEdit('Record changed. Reload before deleting.');
        }
      } else {
        if (current.deletedAt != null) {
          throw ConcurrentRecordEdit(
            'Record was deleted on another device. Restore it explicitly.',
          );
        }
        chosen = {...remote};
        for (final key in {...base.keys, ...value.keys}) {
          if (canonicalJson(base[key]) == canonicalJson(value[key])) {
            continue;
          }
          if (canonicalJson(remote[key]) != canonicalJson(base[key]) &&
              canonicalJson(remote[key]) != canonicalJson(value[key])) {
            throw ConcurrentRecordEdit(
              'Concurrent change in $type / $key. Reload before saving.',
            );
          }
          if (value.containsKey(key)) {
            chosen[key] = value[key];
          } else {
            chosen.remove(key);
          }
        }
      }
    }
    final encoded = chosen == null
        ? current!.payloadJson
        : canonicalJson(chosen);
    if (current != null &&
        current.deletedAt == null &&
        chosen != null &&
        current.payloadJson == encoded) {
      return;
    }
    final device = await DeviceIdentityService.getOrCreate();
    final clock = current == null
        ? <String, int>{}
        : decodeClock(current.clockJson, current.deviceId, current.version);
    clock[device] = (clock[device] ?? 0) + 1;
    final version = (current?.version ?? 0) + 1;
    final now = DateTime.now().toUtc();
    await db
        .into(db.entityDocuments)
        .insertOnConflictUpdate(
          EntityDocumentsCompanion.insert(
            id: id,
            entityType: type,
            payloadJson: encoded,
            version: Value(version),
            deviceId: device,
            clockJson: Value(jsonEncode(clock)),
            deletedAt: Value(chosen == null ? now : null),
            createdAt: current?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.syncChanges)
        .insert(
          SyncChangesCompanion.insert(
            changeId: _uuid.v4(),
            entityType: type,
            entityId: id,
            operation: chosen == null ? 'delete' : 'upsert',
            payloadJson: encoded,
            version: version,
            deviceId: device,
            clockJson: Value(jsonEncode(clock)),
            occurredAt: now,
          ),
        );
  }

  Future<int> migrateLegacyList({
    required String migrationKey,
    required String entityType,
    List<String> preferenceKeys = const [],
  }) async {
    final journal = await (db.select(
      db.migrationJournal,
    )..where((r) => r.key.equals(migrationKey))).getSingleOrNull();
    if (journal != null) {
      return 0;
    }
    final prefs = await SharedPreferences.getInstance();
    String? raw, usedKey;
    for (final key in preferenceKeys) {
      final candidate = prefs.getString(key);
      if (candidate != null && candidate.isNotEmpty) {
        raw = candidate;
        usedKey = key;
        break;
      }
    }
    if (raw == null) {
      await markMigrationComplete(
        key: migrationKey,
        source: 'shared_preferences:none',
      );
      return 0;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List ||
        decoded.any(
          (e) => e is! Map || e['id'] == null || e['id'].toString().isEmpty,
        )) {
      throw const FormatException(
        'Invalid legacy records; original data retained.',
      );
    }
    final payloads = decoded
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
    if (payloads.map((e) => e['id']).toSet().length != payloads.length) {
      throw const FormatException(
        'Duplicate legacy identifiers; original retained.',
      );
    }
    final checksum = _simpleChecksum(raw);
    await db.transaction(() async {
      for (final item in payloads) {
        if (!await containsIncludingDeleted(
          entityType,
          item['id'].toString(),
        )) {
          await _writeOne(entityType, item['id'].toString(), item);
        }
      }
      await db
          .into(db.migrationJournal)
          .insert(
            MigrationJournalCompanion.insert(
              key: migrationKey,
              source: 'shared_preferences:${usedKey ?? 'unknown'}',
              itemCount: Value(payloads.length),
              checksum: Value(checksum),
              migratedAt: DateTime.now().toUtc(),
            ),
          );
    });
    for (final key in preferenceKeys) {
      await prefs.remove(key);
    }
    return payloads.length;
  }

  Future<void> markMigrationComplete({
    required String key,
    required String source,
    int itemCount = 0,
  }) async {
    if (await (db.select(
          db.migrationJournal,
        )..where((r) => r.key.equals(key))).getSingleOrNull() !=
        null) {
      return;
    }
    await db
        .into(db.migrationJournal)
        .insert(
          MigrationJournalCompanion.insert(
            key: key,
            source: source,
            itemCount: Value(itemCount),
            migratedAt: DateTime.now().toUtc(),
          ),
        );
  }

  String _simpleChecksum(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
