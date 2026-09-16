import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/sync/backup/logical_drift_snapshot.dart';

void main() {
  test('restore never overwrites an equal local revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final localTime = DateTime.utc(2026, 8, 15, 10);
    await db
        .into(db.entityDocuments)
        .insert(
          EntityDocumentsCompanion.insert(
            id: 'n1',
            entityType: 'rich_note',
            payloadJson: jsonEncode(const <String, Object?>{
              'id': 'n1',
              'title': 'Local edit',
            }),
            version: const Value(3),
            deviceId: 'windows',
            createdAt: localTime,
            updatedAt: localTime,
          ),
        );

    final snapshot = LogicalDriftSnapshotService(database: db);
    final merged = await snapshot.mergeEntities(<Map<String, Object?>>[
      <String, Object?>{
        'id': 'n1',
        'entityType': 'rich_note',
        'payload': const <String, Object?>{'id': 'n1', 'title': 'Backup edit'},
        'version': 3,
        'deviceId': 'phone',
        'createdAtUtc': localTime.toIso8601String(),
        'updatedAtUtc': DateTime.utc(2026, 8, 15, 12).toIso8601String(),
      },
    ]);

    expect(merged, 0);
    final stored = await db.select(db.entityDocuments).getSingle();
    expect(jsonDecode(stored.payloadJson)['title'], 'Local edit');
    expect(await db.select(db.syncChanges).get(), isEmpty);

    await db.close();
  });

  test('restore preserves divergent higher revision as conflict', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final localTime = DateTime.utc(2026, 8, 15, 10);
    await db
        .into(db.entityDocuments)
        .insert(
          EntityDocumentsCompanion.insert(
            id: 'n1',
            entityType: 'rich_note',
            payloadJson: jsonEncode(const <String, Object?>{
              'id': 'n1',
              'title': 'Old local',
            }),
            version: const Value(2),
            deviceId: 'windows',
            createdAt: localTime,
            updatedAt: localTime,
          ),
        );

    final snapshot = LogicalDriftSnapshotService(database: db);
    final merged = await snapshot.mergeEntities(<Map<String, Object?>>[
      <String, Object?>{
        'id': 'n1',
        'entityType': 'rich_note',
        'payload': const <String, Object?>{'id': 'n1', 'title': 'New backup'},
        'version': 3,
        'deviceId': 'phone',
        'createdAtUtc': localTime.toIso8601String(),
        'updatedAtUtc': DateTime.utc(2026, 8, 15, 12).toIso8601String(),
      },
    ]);

    expect(merged, 0);
    final stored = await db.select(db.entityDocuments).getSingle();
    expect(stored.version, 2);
    expect(jsonDecode(stored.payloadJson)['title'], 'Old local');
    expect(await db.select(db.syncChanges).get(), isEmpty);
    expect(await db.select(db.syncConflicts).get(), hasLength(1));

    await db.close();
  });
}
