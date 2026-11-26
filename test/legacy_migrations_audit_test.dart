import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';

void main() {
  for (final oldVersion in [4, 5, 6, 7]) {
    test(
      'reconstructed v$oldVersion upgrades without losing legacy data or diverging columns',
      () async {
        final dir = await Directory.systemTemp.createTemp('raha-legacy-');
        final file = File('${dir.path}/db.sqlite');
        final old = AppDatabase.forTesting(NativeDatabase(file));
        await old
            .into(old.people)
            .insert(
              PeopleCompanion.insert(
                id: 'p',
                name: 'Preserved',
                createdAt: DateTime.utc(2025),
                updatedAt: DateTime.utc(2025),
              ),
            );
        if (oldVersion < 6) {
          await old.customStatement('DROP TABLE sync_quarantine');
          for (final table in [
            'entity_documents',
            'sync_changes',
            'sync_states',
            'sync_conflicts',
            'migration_journal',
            'sync_queue',
          ]) {
            await old.customStatement('DROP TABLE $table');
          }
          // Previously missed legacy metadata is repaired even on the direct v5 route.
          for (final table in ['projects', 'rich_notes']) {
            for (final column in ['version', 'device_id', 'deleted_at']) {
              await old.customStatement(
                'ALTER TABLE $table DROP COLUMN $column',
              );
            }
          }
        }
        if (oldVersion == 4) {
          for (final table in [
            'categories',
            'people',
            'user_profiles',
            'medications',
            'medication_schedules',
            'medication_logs',
            'appointments',
            'birthdays',
            'notes',
            'shopping_lists',
            'shopping_items',
            'accounts',
            'transactions',
            'habits',
            'habit_logs',
            'goals',
            'cycle_logs',
            'project_checklist',
            'project_attachments',
            'messages',
            'share_grants',
          ]) {
            for (final column in ['version', 'device_id', 'deleted_at']) {
              await old.customStatement(
                'ALTER TABLE $table DROP COLUMN $column',
              );
            }
          }
          await old.customStatement(
            'ALTER TABLE affairs DROP COLUMN device_id',
          );
        }
        if (oldVersion == 6) {
          await old.customStatement(
            'ALTER TABLE entity_documents DROP COLUMN clock_json',
          );
          await old.customStatement(
            'ALTER TABLE sync_changes DROP COLUMN clock_json',
          );
        }
        await old.customStatement('PRAGMA user_version=$oldVersion');
        await old.close();
        final upgraded = AppDatabase.forTesting(NativeDatabase(file));
        final fresh = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          expect(
            (await upgraded.select(upgraded.people).getSingle()).name,
            'Preserved',
          );
          for (final table in fresh.allTables) {
            final wanted = await fresh
                .customSelect('PRAGMA table_info("${table.actualTableName}")')
                .get();
            final got = await upgraded
                .customSelect('PRAGMA table_info("${table.actualTableName}")')
                .get();
            Map<String, List<Object?>> shape(List<dynamic> rows) => {
              for (final row in rows)
                row.read<String>('name'): [
                  row.read<String>('type'),
                  row.read<int>('notnull'),
                  row.data['dflt_value'],
                ],
            };
            expect(shape(got), shape(wanted), reason: table.actualTableName);
          }
          expect(
            (await upgraded.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version'),
            8,
          );
        } finally {
          await upgraded.close();
          await fresh.close();
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
