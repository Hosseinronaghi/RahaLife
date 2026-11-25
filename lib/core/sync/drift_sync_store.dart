import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'canonical_json.dart';
import 'causal_clock.dart';
import 'sync_contract.dart';

class DriftSyncStore implements SyncStore {
  DriftSyncStore({
    required this.providerId,
    this.entityTypes,
    AppDatabase? database,
  }) : db = database ?? appDatabase;

  final String providerId;
  final Set<String>? entityTypes;
  final AppDatabase db;
  static const _uuid = Uuid();

  @override
  Future<T> atomic<T>(Future<T> Function() action) => db.transaction(action);

  Expression<bool> get _pendingFilter =>
      db.syncChanges.uploaded.equals(false) &
      (entityTypes == null
          ? const Constant(true)
          : db.syncChanges.entityType.isIn(entityTypes!)) &
      const CustomExpression<bool>(
        'change_id NOT IN (SELECT change_id FROM sync_quarantine)',
      ) &
      const CustomExpression<bool>(
        'NOT EXISTS (SELECT 1 FROM sync_conflicts cf '
        'WHERE cf.resolved_at IS NULL '
        'AND cf.entity_type = sync_changes.entity_type '
        'AND cf.entity_id = sync_changes.entity_id)',
      );

  Future<int> quarantinedCount() async {
    final rows = await db
        .customSelect(
          'SELECT c.entity_type FROM sync_quarantine q JOIN sync_changes c ON c.change_id=q.change_id WHERE c.uploaded=0',
        )
        .get();
    return rows
        .where(
          (r) =>
              entityTypes == null ||
              entityTypes!.contains(r.read<String>('entity_type')),
        )
        .length;
  }

  Future<void> retryQuarantined() =>
      db.customStatement('DELETE FROM sync_quarantine');

  Future<int> pendingCount() async {
    final expression = db.syncChanges.sequence.count();
    final query = db.selectOnly(db.syncChanges)
      ..addColumns([expression])
      ..where(_pendingFilter);
    return (await query.map((row) => row.read(expression) ?? 0).getSingle());
  }

  Stream<int> watchPendingCount() {
    final filter = StringBuffer(
      'uploaded = 0 AND '
      'change_id NOT IN (SELECT change_id FROM sync_quarantine) AND '
      'NOT EXISTS (SELECT 1 FROM sync_conflicts cf WHERE cf.resolved_at IS NULL '
      'AND cf.entity_type = sync_changes.entity_type AND cf.entity_id = sync_changes.entity_id)',
    );
    final types = entityTypes?.toList();
    if (types != null && types.isEmpty) return Stream.value(0);
    if (types != null) {
      filter.write(
        ' AND entity_type IN (${List.filled(types.length, '?').join(',')})',
      );
    }
    return db
        .customSelect(
          'SELECT COUNT(*) AS pending FROM sync_changes WHERE $filter',
          readsFrom: {db.syncChanges, db.syncConflicts},
          variables: [
            for (final type in types ?? const <String>[])
              Variable.withString(type),
          ],
        )
        .watchSingle()
        .map((row) => row.read<int>('pending'))
        .distinct();
  }

  Future<int> unresolvedConflictCount() async {
    final expression = db.syncConflicts.id.count();
    final query = db.selectOnly(db.syncConflicts)
      ..addColumns([expression])
      ..where(db.syncConflicts.resolvedAt.isNull());
    return (await query.map((row) => row.read(expression) ?? 0).getSingle());
  }

  Stream<int> watchUnresolvedConflictCount() {
    final count = db.syncConflicts.id.count();
    return (db.selectOnly(db.syncConflicts)
          ..addColumns([count])
          ..where(db.syncConflicts.resolvedAt.isNull()))
        .watchSingle()
        .map((row) => row.read(count) ?? 0)
        .distinct();
  }

  Future<void> requeueAllChanges() async {
    await db.transaction(() async {
      // Seed the current complete state, including records originally pulled from another provider.
      final rows = await db.select(db.entityDocuments).get();
      for (final row in rows) {
        await db
            .into(db.syncChanges)
            .insert(
              SyncChangesCompanion.insert(
                changeId: _uuid.v4(),
                entityType: row.entityType,
                entityId: row.id,
                operation: row.deletedAt == null ? 'upsert' : 'delete',
                payloadJson: row.payloadJson,
                version: row.version,
                deviceId: row.deviceId,
                clockJson: Value(row.clockJson),
                occurredAt: row.updatedAt,
              ),
            );
      }
      await (db.delete(
        db.syncStates,
      )..where((r) => r.providerId.equals(providerId))).go();
    });
  }

  Future<int> pruneAcknowledgedHistory() =>
      (db.delete(db.syncChanges)..where(
            (r) =>
                r.uploaded.equals(true) &
                r.occurredAt.isSmallerThanValue(
                  DateTime.now().toUtc().subtract(const Duration(days: 90)),
                ),
          ))
          .go();

  @override
  Future<String?> readCursor() async {
    final row = await (db.select(
      db.syncStates,
    )..where((item) => item.providerId.equals(providerId))).getSingleOrNull();
    return row?.cursor;
  }

  @override
  Future<void> writeCursor(String? cursor) async {
    final now = DateTime.now().toUtc();
    final current = await (db.select(
      db.syncStates,
    )..where((item) => item.providerId.equals(providerId))).getSingleOrNull();
    await db
        .into(db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            providerId: providerId,
            cursor: Value(cursor),
            lastPullAt: Value(now),
            lastPushAt: Value(current?.lastPushAt),
            updatedAt: now,
          ),
        );
  }

  @override
  Future<List<SyncEnvelope>> pendingChanges() async {
    const batchLimit = 7 * 1024 * 1024;
    final bounded = <SyncChangeRow>[];
    var bytes = 0;
    // Scan past rejected rows; their original deltas remain durable for inspection.
    while (bounded.isEmpty) {
      final rows =
          await (db.select(db.syncChanges)
                ..where((row) => _pendingFilter)
                ..orderBy([(row) => OrderingTerm.asc(row.sequence)])
                ..limit(100))
              .get();
      if (rows.isEmpty) break;
      for (final row in rows) {
        final size = utf8.encode(row.payloadJson).length + 2048;
        if (size >= batchLimit) {
          await db.customStatement(
            'INSERT OR REPLACE INTO sync_quarantine(change_id,reason,bytes) VALUES(?,?,?)',
            [row.changeId, 'record_too_large', size],
          );
          // Notify watchers whose computed count depends on the side table.
          db.markTablesUpdated({db.syncChanges});
          continue;
        }
        if (bytes + size >= batchLimit) break;
        bounded.add(row);
        bytes += size;
      }
    }
    return bounded
        .map(
          (row) => SyncEnvelope(
            changeId: row.changeId,
            clock: decodeClock(row.clockJson, row.deviceId, row.version),
            entityType: row.entityType,
            entityId: row.entityId,
            operation: row.operation == 'delete'
                ? SyncOperation.delete
                : SyncOperation.upsert,
            version: row.version,
            updatedAtUtc: row.occurredAt.toUtc(),
            deviceId: row.deviceId,
            deletedAtUtc: row.operation == 'delete'
                ? row.occurredAt.toUtc()
                : null,
            payload: Map<String, Object?>.from(
              jsonDecode(row.payloadJson) as Map,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SyncEnvelope?> readCurrent(String entityType, String entityId) async {
    final row =
        await (db.select(db.entityDocuments)..where(
              (item) =>
                  item.entityType.equals(entityType) & item.id.equals(entityId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return SyncEnvelope(
      clock: decodeClock(row.clockJson, row.deviceId, row.version),
      entityType: row.entityType,
      entityId: row.id,
      operation: row.deletedAt == null
          ? SyncOperation.upsert
          : SyncOperation.delete,
      version: row.version,
      updatedAtUtc: row.updatedAt.toUtc(),
      deviceId: row.deviceId,
      deletedAtUtc: row.deletedAt?.toUtc(),
      payload: Map<String, Object?>.from(jsonDecode(row.payloadJson) as Map),
    );
  }

  @override
  Future<void> applyRemote(SyncEnvelope change) async {
    final existing =
        await (db.select(db.entityDocuments)..where(
              (row) =>
                  row.entityType.equals(change.entityType) &
                  row.id.equals(change.entityId),
            ))
            .getSingleOrNull();
    final now = change.updatedAtUtc.toUtc();
    await db
        .into(db.entityDocuments)
        .insertOnConflictUpdate(
          EntityDocumentsCompanion.insert(
            id: change.entityId,
            entityType: change.entityType,
            payloadJson: canonicalJson(change.payload),
            version: Value(change.version),
            clockJson: Value(jsonEncode(change.effectiveClock)),
            deviceId: change.deviceId,
            deletedAt: Value(change.deletedAtUtc),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> markUploaded(Iterable<String> changeIdsOrIdentities) async {
    final acknowledgements = changeIdsOrIdentities.toSet();
    if (acknowledgements.isEmpty) return;
    final ids = acknowledgements.toList(growable: false);
    for (var offset = 0; offset < ids.length; offset += 100) {
      await (db.update(db.syncChanges)..where(
            (row) =>
                row.uploaded.equals(false) &
                row.changeId.isIn(ids.skip(offset).take(100)) &
                (entityTypes == null
                    ? const Constant(true)
                    : row.entityType.isIn(entityTypes!)),
          ))
          .write(const SyncChangesCompanion(uploaded: Value(true)));
    }
    final now = DateTime.now().toUtc();
    final current = await (db.select(
      db.syncStates,
    )..where((row) => row.providerId.equals(providerId))).getSingleOrNull();
    await db
        .into(db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            providerId: providerId,
            cursor: Value(current?.cursor),
            lastPullAt: Value(current?.lastPullAt),
            lastPushAt: Value(now),
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> saveConflicts(List<SyncConflict> conflicts) async {
    if (conflicts.isEmpty) return;
    for (final conflict in conflicts) {
      final localJson = canonicalJson(conflict.local.toJson());
      final remoteJson = canonicalJson(conflict.remote.toJson());
      final duplicate =
          await (db.select(db.syncConflicts)..where(
                (row) =>
                    row.entityType.equals(conflict.local.entityType) &
                    row.entityId.equals(conflict.local.entityId) &
                    row.localJson.equals(localJson) &
                    row.remoteJson.equals(remoteJson) &
                    row.resolvedAt.isNull(),
              ))
              .getSingleOrNull();
      if (duplicate != null) continue;
      await db
          .into(db.syncConflicts)
          .insert(
            SyncConflictsCompanion.insert(
              id: _uuid.v4(),
              entityType: conflict.local.entityType,
              entityId: conflict.local.entityId,
              localJson: localJson,
              remoteJson: remoteJson,
              createdAt: DateTime.now().toUtc(),
            ),
          );
    }
  }
}
