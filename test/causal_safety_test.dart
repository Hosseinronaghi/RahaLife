import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';
import 'package:raha_life/core/sync/sync_contract.dart';
import 'package:raha_life/core/sync/causal_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'sync.device.v1': 'A'}));
  test('different edit counts do not imply causality', () {
    expect(compareClocks({'A': 2}, {'B': 3}), ClockOrder.concurrent);
    expect(compareClocks({'A': 2}, {'A': 2, 'B': 1}), ClockOrder.before);
  });
  test('stale controller does not delete a remotely added record', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftEntityRepository(database: db);
    await repo.upsert('person', {'id': 'one', 'name': 'Original'});
    await repo.loadAll('person');
    await DriftSyncStore(providerId: 'test', database: db).applyRemote(
      SyncEnvelope(
        entityType: 'person',
        entityId: 'remote',
        operation: SyncOperation.upsert,
        version: 1,
        updatedAtUtc: DateTime.now().toUtc(),
        deviceId: 'B',
        payload: {'id': 'remote', 'name': 'Remote'},
        clock: {'B': 1},
      ),
    );
    await repo.replaceAll('person', [
      {'id': 'one', 'name': 'Edited'},
    ]);
    expect(await repo.loadOne('person', 'remote'), isNotNull);
    await db.close();
  });
  test(
    'non-overlapping stale fields merge but overlapping edits fail',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final a = DriftEntityRepository(database: db),
          b = DriftEntityRepository(database: db);
      await a.upsert('person', {'id': 'p', 'name': 'A', 'phone': '1'});
      await a.loadAll('person');
      await b.upsert('person', {'id': 'p', 'name': 'A', 'phone': '2'});
      await a.replaceAll('person', [
        {'id': 'p', 'name': 'B', 'phone': '1'},
      ]);
      expect((await a.loadOne('person', 'p'))?['phone'], '2');
      await a.loadAll('person');
      await b.upsert('person', {'id': 'p', 'name': 'C', 'phone': '2'});
      await expectLater(
        a.replaceAll('person', [
          {'id': 'p', 'name': 'D', 'phone': '2'},
        ]),
        throwsStateError,
      );
      await db.close();
    },
  );
  test(
    'legacy import never overwrites current or deletes unrelated data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftEntityRepository(database: db);
      await repo.upsert('person', {'id': 'one', 'name': 'New'});
      await repo.upsert('person', {'id': 'two', 'name': 'Keep'});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'legacy',
        jsonEncode([
          {'id': 'one', 'name': 'Old'},
        ]),
      );
      await repo.migrateLegacyList(
        migrationKey: 'legacy-test',
        entityType: 'person',
        preferenceKeys: ['legacy'],
      );
      expect((await repo.loadOne('person', 'one'))?['name'], 'New');
      expect(await repo.loadOne('person', 'two'), isNotNull);
      await db.close();
    },
  );
  test('record identity cannot acknowledge untransmitted changes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DriftEntityRepository(database: db);
    final store = DriftSyncStore(providerId: 'test', database: db);
    await repo.upsert('person', {'id': 'one', 'name': 'A'});
    await store.markUploaded(['person:one']);
    expect(await store.pendingCount(), 1);
    await store.markUploaded([(await store.pendingChanges()).single.changeId!]);
    expect(await store.pendingCount(), 0);
    await db.close();
  });
  test('new provider seeds records received from another provider', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final store = DriftSyncStore(providerId: 'new', database: db);
    await store.applyRemote(
      SyncEnvelope(
        entityType: 'person',
        entityId: 'p',
        operation: SyncOperation.upsert,
        version: 1,
        updatedAtUtc: DateTime.now(),
        deviceId: 'B',
        payload: {'id': 'p', 'name': 'From B'},
        clock: {'B': 1},
      ),
    );
    await store.requeueAllChanges();
    expect(await store.pendingCount(), 1);
    await db.close();
  });
}
