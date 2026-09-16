import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'canonical_json.dart';
import 'causal_clock.dart';
import 'device_identity.dart';
import 'sync_contract.dart';

class SyncConflictRecord {
  const SyncConflictRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.local,
    required this.remote,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncEnvelope local;
  final SyncEnvelope remote;
  final DateTime createdAt;
}

enum SyncConflictResolution { keepLocal, useRemote }

/// Resolves the rare case where two devices edited the same revision of the
/// same entity independently. Resolution never deletes history silently:
/// obsolete queued deltas are marked as superseded and a local choice is
/// emitted as a fresh higher revision so every other device converges.
class SyncConflictRepository {
  SyncConflictRepository({AppDatabase? database})
    : db = database ?? appDatabase;

  final AppDatabase db;
  static const _uuid = Uuid();

  Future<List<SyncConflictRecord>> unresolved() async {
    final rows =
        await (db.select(db.syncConflicts)
              ..where((row) => row.resolvedAt.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
            .get();
    return rows.map(_decode).toList(growable: false);
  }

  Stream<List<SyncConflictRecord>> watchUnresolved() {
    final query = db.select(db.syncConflicts)
      ..where((row) => row.resolvedAt.isNull())
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.watch().map(
      (rows) => rows.map(_decode).toList(growable: false),
    );
  }

  Future<void> resolve(
    String conflictId,
    SyncConflictResolution resolution,
  ) async {
    final row = await (db.select(
      db.syncConflicts,
    )..where((item) => item.id.equals(conflictId))).getSingleOrNull();
    if (row == null || row.resolvedAt != null) return;

    final local = SyncEnvelope.fromJson(
      Map<String, Object?>.from(jsonDecode(row.localJson) as Map),
    );
    final remote = SyncEnvelope.fromJson(
      Map<String, Object?>.from(jsonDecode(row.remoteJson) as Map),
    );
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      // The conflicting queued revision must not be retried forever after the
      // user has made an explicit choice.
      final conflictedVersion = local.version > remote.version
          ? local.version
          : remote.version;
      final queued =
          await (db.select(db.syncChanges)..where(
                (change) =>
                    change.entityType.equals(row.entityType) &
                    change.entityId.equals(row.entityId) &
                    change.uploaded.equals(false),
              ))
              .get();
      final supersededSequences = queued
          .where((change) => change.version <= conflictedVersion)
          .map((change) => change.sequence)
          .toList(growable: false);
      if (supersededSequences.isNotEmpty) {
        await (db.update(db.syncChanges)
              ..where((change) => change.sequence.isIn(supersededSequences)))
            .write(const SyncChangesCompanion(uploaded: Value(true)));
      }

      final current = await _current(row.entityType, row.entityId);
      var resolutionLabel = resolution.name;
      if (current != null &&
          compareClocks(current.effectiveClock, local.effectiveClock) ==
              ClockOrder.after) {
        throw StateError(
          'The record changed after this conflict. Reload before resolving.',
        );
      }
      final chosen = resolution == SyncConflictResolution.useRemote
          ? remote
          : local;
      final deviceId = await DeviceIdentityService.getOrCreate();
      final clock = joinClocks(local.effectiveClock, remote.effectiveClock);
      clock[deviceId] = (clock[deviceId] ?? 0) + 1;
      final resolved = SyncEnvelope(
        changeId: _uuid.v4(),
        entityType: chosen.entityType,
        entityId: chosen.entityId,
        operation: chosen.operation,
        version:
            (local.version > remote.version ? local.version : remote.version) +
            1,
        updatedAtUtc: now,
        deviceId: deviceId,
        clock: clock,
        deletedAtUtc: chosen.operation == SyncOperation.delete ? now : null,
        payload: chosen.payload,
      );
      await _writeEntity(resolved);
      await db
          .into(db.syncChanges)
          .insert(
            SyncChangesCompanion.insert(
              changeId: resolved.changeId!,
              entityType: resolved.entityType,
              entityId: resolved.entityId,
              operation: resolved.operation.name,
              payloadJson: canonicalJson(resolved.payload),
              version: resolved.version,
              deviceId: deviceId,
              clockJson: Value(jsonEncode(clock)),
              occurredAt: now,
            ),
          );

      await (db.update(
        db.syncConflicts,
      )..where((item) => item.id.equals(conflictId))).write(
        SyncConflictsCompanion(
          resolvedAt: Value(now),
          resolution: Value(resolutionLabel),
        ),
      );
    });
  }

  Future<SyncEnvelope?> _current(String entityType, String entityId) async {
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

  Future<void> _writeEntity(SyncEnvelope value) async {
    final existing =
        await (db.select(db.entityDocuments)..where(
              (row) =>
                  row.entityType.equals(value.entityType) &
                  row.id.equals(value.entityId),
            ))
            .getSingleOrNull();
    await db
        .into(db.entityDocuments)
        .insertOnConflictUpdate(
          EntityDocumentsCompanion.insert(
            id: value.entityId,
            entityType: value.entityType,
            payloadJson: canonicalJson(value.payload),
            version: Value(value.version),
            clockJson: Value(jsonEncode(value.effectiveClock)),
            deviceId: value.deviceId,
            deletedAt: Value(value.deletedAtUtc),
            createdAt: existing?.createdAt ?? value.updatedAtUtc.toUtc(),
            updatedAt: value.updatedAtUtc.toUtc(),
          ),
        );
  }

  SyncConflictRecord _decode(SyncConflictRow row) => SyncConflictRecord(
    id: row.id,
    entityType: row.entityType,
    entityId: row.entityId,
    local: SyncEnvelope.fromJson(
      Map<String, Object?>.from(jsonDecode(row.localJson) as Map),
    ),
    remote: SyncEnvelope.fromJson(
      Map<String, Object?>.from(jsonDecode(row.remoteJson) as Map),
    ),
    createdAt: row.createdAt.toUtc(),
  );
}
