import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';

void main() {
  test('schema v6 contains migration and incremental-sync tables', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names, contains('entity_documents'));
    expect(names, contains('sync_changes'));
    expect(names, contains('sync_states'));
    expect(names, contains('sync_conflicts'));
    expect(names, contains('migration_journal'));

    await db.close();
  });
}
