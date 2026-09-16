import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({'sync.device.v1': 'device'}),
  );
  test('v6 to v7 preserves existing records and pending deltas', () async {
    final folder = await Directory.systemTemp.createTemp('raha-upgrade-test-');
    final file = File('${folder.path}/database.sqlite');
    final old = AppDatabase.forTesting(NativeDatabase(file));
    await DriftEntityRepository(
      database: old,
    ).upsert('person', {'id': 'p', 'name': 'Preserved'});
    await old.customStatement(
      'ALTER TABLE entity_documents DROP COLUMN clock_json',
    );
    await old.customStatement(
      'ALTER TABLE sync_changes DROP COLUMN clock_json',
    );
    await old.customStatement('PRAGMA user_version=6');
    await old.close();
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final row = await upgraded.select(upgraded.entityDocuments).getSingle();
      expect(row.id, 'p');
      expect(row.payloadJson, contains('Preserved'));
      expect(row.clockJson, '{}');
      expect(await upgraded.select(upgraded.syncChanges).get(), hasLength(1));
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 7);
    } finally {
      await upgraded.close();
      await folder.delete(recursive: true);
    }
  });
  test(
    'malformed legacy input keeps both original preferences and existing data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final repo = DriftEntityRepository(database: db);
        await repo.upsert('person', {'id': 'p', 'name': 'Keep'});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('malformed', '[{"name":"Missing ID"}]');
        await expectLater(
          repo.migrateLegacyList(
            migrationKey: 'bad',
            entityType: 'person',
            preferenceKeys: ['malformed'],
          ),
          throwsFormatException,
        );
        expect(prefs.getString('malformed'), isNotNull);
        expect((await repo.loadOne('person', 'p'))?['name'], 'Keep');
        expect(await db.select(db.migrationJournal).get(), isEmpty);
      } finally {
        await db.close();
      }
    },
  );
}
