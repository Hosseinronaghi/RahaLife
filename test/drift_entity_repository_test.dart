import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sync.device.v1': 'test-device',
    });
  });

  test('only real record changes create incremental sync deltas', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = DriftEntityRepository(database: db);

    await repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{
        'id': 'p1',
        'name': 'Sara',
        'meta': <String, Object?>{'z': 2, 'a': 1},
      },
    ]);
    expect(await db.select(db.syncChanges).get(), hasLength(1));

    // Key order is intentionally different. Canonical JSON must not create a
    // false update merely because map insertion order changed.
    await repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{
        'meta': <String, Object?>{'a': 1, 'z': 2},
        'name': 'Sara',
        'id': 'p1',
      },
    ]);
    expect(await db.select(db.syncChanges).get(), hasLength(1));

    await repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{'id': 'p1', 'name': 'Sara updated'},
    ]);
    final afterUpdate = await db.select(db.syncChanges).get();
    expect(afterUpdate, hasLength(2));
    expect(afterUpdate.last.version, 2);

    await repository.replaceAll('person', const <Map<String, Object?>>[]);
    final afterDelete = await db.select(db.syncChanges).get();
    expect(afterDelete, hasLength(3));
    expect(afterDelete.last.operation, 'delete');
    final document = await db.select(db.entityDocuments).getSingle();
    expect(document.deletedAt, isNotNull);

    await db.close();
  });

  test('rapid writes are serialized and the newest UI state wins', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = DriftEntityRepository(database: db);

    final first = repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{'id': 'p1', 'name': 'First'},
    ]);
    final second = repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{'id': 'p1', 'name': 'Second'},
    ]);
    final third = repository.replaceAll('person', const <Map<String, Object?>>[
      <String, Object?>{'id': 'p1', 'name': 'Newest'},
    ]);

    await Future.wait(<Future<void>>[first, second, third]);
    final stored = await repository.loadOne('person', 'p1');
    expect(stored?['name'], 'Newest');
    final changes = await db.select(db.syncChanges).get();
    expect(changes.map((row) => row.version).toList(), <int>[1, 2, 3]);

    await db.close();
  });

  test(
    'legacy SharedPreferences data moves to Drift once and is preserved',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sync.device.v1': 'migration-device',
        'legacy.people': '[{"id":"p1","name":"Sara"},{"id":"p2","name":"Ali"}]',
      });
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = DriftEntityRepository(database: db);

      final count = await repository.migrateLegacyList(
        migrationKey: 'test.people.migration',
        entityType: 'person',
        preferenceKeys: const <String>['legacy.people'],
      );

      expect(count, 2);
      expect(await repository.loadAll('person'), hasLength(2));
      expect(await db.select(db.syncChanges).get(), hasLength(2));
      expect(
        (await SharedPreferences.getInstance()).containsKey('legacy.people'),
        isFalse,
      );

      final secondRun = await repository.migrateLegacyList(
        migrationKey: 'test.people.migration',
        entityType: 'person',
        preferenceKeys: const <String>['legacy.people'],
      );
      expect(secondRun, 0);
      expect(await db.select(db.syncChanges).get(), hasLength(2));

      await db.close();
    },
  );
}
