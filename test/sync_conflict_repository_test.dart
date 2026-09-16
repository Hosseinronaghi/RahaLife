import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/sync/sync_conflict_repository.dart';
import 'package:raha_life/core/sync/sync_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'keep local creates a newer revision and resolves old queued conflict',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sync.device.v1': 'windows',
      });
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = SyncEnvelope(
        changeId: 'local-change',
        entityType: 'rich_note',
        entityId: 'n1',
        operation: SyncOperation.upsert,
        version: 3,
        updatedAtUtc: DateTime.utc(2026, 8, 15, 10),
        deviceId: 'windows',
        payload: const <String, Object?>{'id': 'n1', 'title': 'Windows'},
      );
      final remote = SyncEnvelope(
        changeId: 'remote-change',
        entityType: 'rich_note',
        entityId: 'n1',
        operation: SyncOperation.upsert,
        version: 3,
        updatedAtUtc: DateTime.utc(2026, 8, 15, 11),
        deviceId: 'phone',
        payload: const <String, Object?>{'id': 'n1', 'title': 'Phone'},
      );

      await db
          .into(db.entityDocuments)
          .insert(
            EntityDocumentsCompanion.insert(
              id: 'n1',
              entityType: 'rich_note',
              payloadJson: jsonEncode(local.payload),
              version: const Value(3),
              deviceId: 'windows',
              createdAt: local.updatedAtUtc,
              updatedAt: local.updatedAtUtc,
            ),
          );
      await db
          .into(db.syncChanges)
          .insert(
            SyncChangesCompanion.insert(
              changeId: 'local-change',
              entityType: 'rich_note',
              entityId: 'n1',
              operation: 'upsert',
              payloadJson: jsonEncode(local.payload),
              version: 3,
              deviceId: 'windows',
              occurredAt: local.updatedAtUtc,
            ),
          );
      await db
          .into(db.syncConflicts)
          .insert(
            SyncConflictsCompanion.insert(
              id: 'conflict-1',
              entityType: 'rich_note',
              entityId: 'n1',
              localJson: jsonEncode(local.toJson()),
              remoteJson: jsonEncode(remote.toJson()),
              createdAt: DateTime.utc(2026, 8, 15, 12),
            ),
          );

      final repository = SyncConflictRepository(database: db);
      await repository.resolve('conflict-1', SyncConflictResolution.keepLocal);

      final document = await db.select(db.entityDocuments).getSingle();
      expect(document.version, 4);
      expect(document.deviceId, 'windows');
      expect(jsonDecode(document.payloadJson)['title'], 'Windows');

      final changes = await (db.select(
        db.syncChanges,
      )..orderBy([(row) => OrderingTerm.asc(row.sequence)])).get();
      expect(changes, hasLength(2));
      expect(changes.first.uploaded, isTrue);
      expect(changes.last.uploaded, isFalse);
      expect(changes.last.version, 4);

      final conflict = await db.select(db.syncConflicts).getSingle();
      expect(conflict.resolvedAt, isNotNull);
      expect(conflict.resolution, SyncConflictResolution.keepLocal.name);

      await db.close();
    },
  );
}
