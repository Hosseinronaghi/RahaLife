import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/notifications/reminder_coordinator.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/sync/backup/local_backup_service.dart';
import 'package:raha_life/core/sync/backup/logical_drift_snapshot.dart';
import 'package:raha_life/core/sync/backup/sync_crypto_service.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';
import 'package:raha_life/core/sync/sync_contract.dart';

class ConflictTransport implements SyncTransport {
  final sent = <String>[];
  @override
  Future<SyncPullResult> pull({
    required String deviceId,
    String? cursor,
  }) async => const SyncPullResult(changes: [], nextCursor: '1');
  @override
  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  }) async {
    sent.addAll(changes.map((x) => x.entityId));
    return SyncPushResult(
      accepted: changes
          .where((x) => x.entityId != 'conflicted')
          .map((x) => x.changeId!)
          .toList(),
      conflicts: [
        for (final x in changes.where((x) => x.entityId == 'conflicted'))
          SyncConflict(
            local: x,
            remote: SyncEnvelope(
              entityType: x.entityType,
              entityId: x.entityId,
              operation: x.operation,
              version: 1,
              updatedAtUtc: x.updatedAtUtc,
              deviceId: 'other',
              payload: const {'id': 'conflicted', 'title': 'Remote'},
            ),
          ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme.mode': 'dark',
      'sync.device.v1': 'local',
    });
    FlutterSecureStorage.setMockInitialValues({});
  });
  test(
    'a conflict blocks its own deltas while the next SQL batch is sent',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = DriftEntityRepository(database: db);
      await repository.upsert('rich_note', {
        'id': 'conflicted',
        'title': 'Local',
      });
      for (var i = 0; i < 100; i++) {
        await repository.upsert('rich_note', {
          'id': 'note-$i',
          'title': 'Local $i',
        });
      }
      final store = DriftSyncStore(providerId: 'server', database: db);
      final transport = ConflictTransport();
      final engine = RecordSyncEngine(
        deviceId: 'local',
        store: store,
        transport: transport,
      );
      final result = await engine.sync();
      expect(result.uploaded, 100);
      expect(result.conflicts, 1);
      expect(await store.pendingCount(), 0);
      expect(await store.unresolvedConflictCount(), 1);
      expect(
        (await db.select(db.syncChanges).get())
            .where((r) => !r.uploaded)
            .single
            .entityId,
        'conflicted',
      );
      await engine.sync();
      expect(transport.sent.where((id) => id == 'conflicted'), hasLength(1));
      expect(transport.sent.last, 'note-99');
    },
  );
  test(
    'settings write failure leaves a committed restore journal that resumes',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final snapshot = LogicalDriftSnapshotService(database: db);
      final crypto = SyncCryptoService();
      final service = LocalBackupService(
        crypto: crypto,
        logicalSnapshot: snapshot,
        writePreference: (_, _, _) async => false,
      );
      final bytes = await crypto.encrypt(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'format': 'raha-life-backup',
              'payloadVersion': 2,
              'entities': [
                {
                  'id': 'note-restore',
                  'entityType': 'rich_note',
                  'deviceId': 'remote',
                  'payload': {'id': 'note-restore'},
                  'createdAtUtc': '2026-10-10T00:00:00Z',
                  'updatedAtUtc': '2026-10-10T00:00:00Z',
                },
              ],
              'preferences': {
                'theme.mode': 'light',
                'collab.account.queued': 'private',
              },
            }),
          ),
        ),
      );
      await expectLater(
        service.restoreEncryptedBackup(bytes),
        throwsStateError,
      );
      expect(await snapshot.exportEntities(), hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme.mode'), 'dark');
      final recovered = LocalBackupService(
        crypto: crypto,
        logicalSnapshot: snapshot,
      );
      expect(await recovered.resumePendingRestore(), 1);
      expect(prefs.getString('theme.mode'), 'light');
      expect(prefs.containsKey('collab.account.queued'), isFalse);
      expect(await recovered.resumePendingRestore(), 0);
    },
  );
  test(
    'import adds recovery access without replacing the primary key',
    () async {
      final crypto = SyncCryptoService();
      final original = await crypto.exportRecoveryKey();
      final old = await crypto.encrypt(Uint8List.fromList([1, 2, 3]));
      final added = base64UrlEncode(List<int>.filled(32, 7));
      await crypto.importRecoveryKey(added);
      expect(await crypto.exportRecoveryKey(), original);
      expect(await crypto.decrypt(old), [1, 2, 3]);
      FlutterSecureStorage.setMockInitialValues({'sync.master_key.v1': added});
      final external = await crypto.encrypt(Uint8List.fromList([4, 5]));
      FlutterSecureStorage.setMockInitialValues({
        'sync.master_key.v1': original,
      });
      await crypto.importRecoveryKey(added);
      expect(await crypto.decrypt(external), [4, 5]);
    },
  );
  test(
    'failed alarm replacement preserves unrelated pending notifications',
    () async {
      final stored = <String, String?>{
        'same': 'same',
        'older': 'original',
        'removed': 'was-scheduled',
      };
      final cancelled = <String>[], attempted = <String>[];
      var succeeds = false;
      Future<void> run() => reconcileReminderSchedules(
        managed: stored,
        wanted: {'older': 'updated', 'same': 'same'},
        isPending: (_) => true,
        save: (_) async {},
        schedule: (key) async {
          attempted.add(key);
          return succeeds;
        },
        cancel: (key) async {
          cancelled.add(key);
        },
      );
      await run();
      expect(attempted, ['older']);
      expect(stored['older'], isNull);
      expect(cancelled, isEmpty);
      succeeds = true;
      await run();
      expect(stored, {'same': 'same', 'older': 'updated'});
      expect(cancelled, ['removed']);
    },
  );
}
