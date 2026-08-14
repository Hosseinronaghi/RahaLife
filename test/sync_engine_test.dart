import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/sync_contract.dart';

void main() {
  test('record sync downloads remote changes and uploads local queue', () async {
    final remote = SyncEnvelope(
      entityType: 'affair',
      entityId: 'remote-1',
      operation: SyncOperation.upsert,
      version: 1,
      updatedAtUtc: DateTime.utc(2026, 8, 10, 10),
      deviceId: 'phone',
      payload: const {'title': 'Remote'},
    );
    final local = SyncEnvelope(
      entityType: 'note',
      entityId: 'local-1',
      operation: SyncOperation.upsert,
      version: 1,
      updatedAtUtc: DateTime.utc(2026, 8, 10, 11),
      deviceId: 'windows',
      payload: const {'title': 'Local'},
    );
    final store = _MemoryStore(pending: [local]);
    final transport = _MemoryTransport(remoteChanges: [remote]);
    final engine = RecordSyncEngine(
      deviceId: 'windows',
      store: store,
      transport: transport,
    );

    final result = await engine.sync();

    expect(result.downloaded, 1);
    expect(result.uploaded, 1);
    expect(result.conflicts, 0);
    expect(store.current[remote.identity]?.payload['title'], 'Remote');
    expect(store.pending, isEmpty);
  });

  test('same-version edits from different devices are kept as conflict', () async {
    final local = SyncEnvelope(
      entityType: 'shoppingList',
      entityId: 'same',
      operation: SyncOperation.upsert,
      version: 3,
      updatedAtUtc: DateTime.utc(2026, 8, 10, 11),
      deviceId: 'windows',
      payload: const {'title': 'Windows edit'},
    );
    final remote = SyncEnvelope(
      entityType: 'shoppingList',
      entityId: 'same',
      operation: SyncOperation.upsert,
      version: 3,
      updatedAtUtc: DateTime.utc(2026, 8, 10, 12),
      deviceId: 'iphone',
      payload: const {'title': 'iPhone edit'},
    );
    final store = _MemoryStore(current: {local.identity: local});
    final transport = _MemoryTransport(remoteChanges: [remote]);

    final result = await RecordSyncEngine(
      deviceId: 'windows',
      store: store,
      transport: transport,
    ).sync();

    expect(result.conflicts, 1);
    expect(store.conflicts, hasLength(1));
    expect(store.current[local.identity]?.payload['title'], 'Windows edit');
  });
}

class _MemoryStore implements SyncStore {
  _MemoryStore({
    Map<String, SyncEnvelope>? current,
    List<SyncEnvelope>? pending,
  })  : current = current ?? <String, SyncEnvelope>{},
        pending = pending ?? <SyncEnvelope>[];

  final Map<String, SyncEnvelope> current;
  final List<SyncEnvelope> pending;
  final List<SyncConflict> conflicts = [];
  String? cursor;

  @override
  Future<void> applyRemote(SyncEnvelope change) async {
    current[change.identity] = change;
  }

  @override
  Future<void> markUploaded(Iterable<String> identities) async {
    final ids = identities.toSet();
    pending.removeWhere((change) => ids.contains(change.identity));
  }

  @override
  Future<List<SyncEnvelope>> pendingChanges() async => List.of(pending);

  @override
  Future<SyncEnvelope?> readCurrent(String entityType, String entityId) async =>
      current['$entityType:$entityId'];

  @override
  Future<String?> readCursor() async => cursor;

  @override
  Future<void> saveConflicts(List<SyncConflict> values) async {
    conflicts.addAll(values);
  }

  @override
  Future<void> writeCursor(String? value) async {
    cursor = value;
  }
}

class _MemoryTransport implements SyncTransport {
  _MemoryTransport({this.remoteChanges = const []});
  final List<SyncEnvelope> remoteChanges;

  @override
  Future<SyncPullResult> pull({
    required String deviceId,
    String? cursor,
  }) async =>
      SyncPullResult(changes: remoteChanges, nextCursor: 'cursor-1');

  @override
  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  }) async =>
      SyncPushResult(accepted: changes.map((item) => item.identity).toList());
}
