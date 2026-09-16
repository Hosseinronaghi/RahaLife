import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';
import 'package:raha_life/core/sync/sync_contract.dart';

void main() {
  test('remote apply does not generate a new local upload delta', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final store = DriftSyncStore(providerId: 'provider-a', database: db);
    final remote = SyncEnvelope(
      changeId: 'remote-change-1',
      entityType: 'shopping_item',
      entityId: 'item-1',
      operation: SyncOperation.upsert,
      version: 4,
      updatedAtUtc: DateTime.utc(2026, 8, 15, 10),
      deviceId: 'phone',
      payload: const <String, Object?>{
        'id': 'item-1',
        'listId': 'list-1',
        'title': 'Milk',
      },
    );

    await store.applyRemote(remote);

    expect((await store.readCurrent('shopping_item', 'item-1'))?.version, 4);
    expect(await store.pendingCount(), 0);
    expect(await db.select(db.syncChanges).get(), isEmpty);

    await db.close();
  });
}
