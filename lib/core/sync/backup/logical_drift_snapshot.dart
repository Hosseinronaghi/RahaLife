import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../database/database_provider.dart';
import '../canonical_json.dart';
import '../causal_clock.dart';
import '../sync_contract.dart';
import '../drift_sync_store.dart';

class LogicalDriftSnapshotService {
  LogicalDriftSnapshotService({AppDatabase? database})
    : db = database ?? appDatabase;

  final AppDatabase db;
  static const _uuid = Uuid();

  Future<List<Map<String, Object?>>> exportEntities() async {
    final rows =
        await (db.select(db.entityDocuments)..orderBy([
              (row) => OrderingTerm.asc(row.entityType),
              (row) => OrderingTerm.asc(row.id),
            ]))
            .get();
    return rows
        .map(
          (row) => <String, Object?>{
            'id': row.id,
            'entityType': row.entityType,
            'payload': jsonDecode(row.payloadJson),
            'version': row.version,
            'clock': decodeClock(row.clockJson, row.deviceId, row.version),
            'deviceId': row.deviceId,
            'deletedAtUtc': row.deletedAt?.toUtc().toIso8601String(),
            'createdAtUtc': row.createdAt.toUtc().toIso8601String(),
            'updatedAtUtc': row.updatedAt.toUtc().toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  /// Non-destructive restore: a backup can fill a new device or recover older
  /// records without erasing newer local edits created after that backup.
  /// Imported rows are queued as baseline deltas so a later record sync can
  /// reconcile them with the selected provider.
  Future<int> mergeEntities(Object? rawEntities) async {
    if (rawEntities is! List || rawEntities.any((e) => e is! Map)) {
      throw const FormatException('Invalid backup record list.');
    }
    final seen = <String>{};
    var merged = 0;
    await db.transaction(() async {
      for (final raw in rawEntities) {
        final map = Map<String, Object?>.from(raw as Map);
        final id = map['id']?.toString() ?? '',
            type = map['entityType']?.toString() ?? '',
            device = map['deviceId']?.toString() ?? '';
        final version = (map['version'] as num?)?.toInt() ?? 1;
        final updated = _date(map['updatedAtUtc']),
            created = _date(map['createdAtUtc']),
            deleted = _nullableDate(map['deletedAtUtc']);
        if (id.isEmpty ||
            type.isEmpty ||
            device.isEmpty ||
            updated == null ||
            created == null ||
            map['payload'] is! Map ||
            !seen.add('$type:$id')) {
          throw const FormatException(
            'Invalid or duplicate backup record; restore rolled back.',
          );
        }
        final payload = Map<String, Object?>.from(map['payload'] as Map);
        if (payload['id'] != id) {
          throw const FormatException('Backup payload identifier mismatch');
        }
        final rawClock = map['clock'];
        if (rawClock is Map && rawClock.values.any((v) => v is! int || v < 0)) {
          throw const FormatException('Invalid backup clock');
        }
        final clock = rawClock is Map && rawClock.isNotEmpty
            ? Map<String, int>.from(rawClock)
            : <String, int>{device: version};
        final existing =
            await (db.select(db.entityDocuments)
                  ..where((r) => r.entityType.equals(type) & r.id.equals(id)))
                .getSingleOrNull();
        if (existing != null) {
          if (canonicalJson(payload) == existing.payloadJson &&
              (deleted != null) == (existing.deletedAt != null)) {
            continue;
          }
          final order = compareClocks(
            decodeClock(
              existing.clockJson,
              existing.deviceId,
              existing.version,
            ),
            clock,
          );
          if (order != ClockOrder.after) {
            final store = DriftSyncStore(providerId: 'restore', database: db);
            await store.saveConflicts([
              SyncConflict(
                local: (await store.readCurrent(type, id))!,
                remote: SyncEnvelope(
                  entityType: type,
                  entityId: id,
                  operation: deleted == null
                      ? SyncOperation.upsert
                      : SyncOperation.delete,
                  version: version,
                  updatedAtUtc: updated,
                  deviceId: device,
                  payload: payload,
                  clock: clock,
                  deletedAtUtc: deleted,
                ),
              ),
            ]);
          }
          continue;
        }
        final encoded = canonicalJson(payload);
        await db
            .into(db.entityDocuments)
            .insert(
              EntityDocumentsCompanion.insert(
                id: id,
                entityType: type,
                payloadJson: encoded,
                version: Value(version),
                clockJson: Value(jsonEncode(clock)),
                deviceId: device,
                deletedAt: Value(deleted),
                createdAt: created,
                updatedAt: updated,
              ),
            );
        await db
            .into(db.syncChanges)
            .insert(
              SyncChangesCompanion.insert(
                changeId: _uuid.v4(),
                entityType: type,
                entityId: id,
                operation: deleted == null ? 'upsert' : 'delete',
                payloadJson: encoded,
                version: version,
                clockJson: Value(jsonEncode(clock)),
                deviceId: device,
                occurredAt: updated,
              ),
            );
        merged++;
      }
    });
    return merged;
  }

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  DateTime? _nullableDate(Object? value) {
    if (value == null) return null;
    return _date(value);
  }
}
