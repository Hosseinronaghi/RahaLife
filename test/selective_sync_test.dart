import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'excluded pending rows cannot starve selected changes and remain unsent',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftEntityRepository(database: db);
      for (var i = 0; i < 110; i++) {
        await repo.upsert('cycle_log', {'id': 'h$i'});
      }
      await repo.upsert('rich_note', {'id': 'n', 'title': 'one'});
      final store = DriftSyncStore(
        providerId: 'selected',
        database: db,
        entityTypes: {'rich_note'},
      );
      final pending = await store.pendingChanges();
      expect(pending, hasLength(1));
      expect(pending.single.entityType, 'rich_note');
      await store.markUploaded(pending.map((e) => e.changeId!).toList());
      expect(await store.pendingChanges(), isEmpty);
      expect(await store.pendingCount(), 110);
      expect(
        await DriftSyncStore(
          providerId: 'empty',
          database: db,
          entityTypes: {},
        ).pendingChanges(),
        isEmpty,
      );
      await db.close();
    },
  );
}
