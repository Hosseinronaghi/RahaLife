import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';
import 'package:raha_life/core/sync/providers/raha_http_sync_transport.dart';
import 'package:raha_life/core/sync/sync_conflict_repository.dart';
import 'package:raha_life/core/sync/sync_contract.dart';
import 'package:uuid/uuid.dart';

const _baseUrl = 'http://127.0.0.1:8090';
const _type = 'rich_note';

void main() {
  final registrationCode = Platform.environment['RAHA_SYNC_INTEGRATION_CODE'];
  test(
    'two clients recover a lost acknowledgement, resolve an offline conflict '
    'and synchronize a deletion over PHP/MySQL',
    () async {
      final api = Dio(BaseOptions(baseUrl: _baseUrl, followRedirects: false));
      addTearDown(() => api.close(force: true));
      final registered = await api.post<Map<String, dynamic>>(
        '/v1/account/register',
        data: {
          'username': 'dart_${const Uuid().v4().replaceAll('-', '').substring(0, 16)}',
          'password': 'disposable-local-test-password',
          'registrationCode': registrationCode!,
        },
      );
      final token = registered.data!['token'] as String;

      final first = _makeClient('phone', token);
      final second = _makeClient('desktop', token);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      expect(
        await first.transport.inner.destinationIdentity(),
        await second.transport.inner.destinationIdentity(),
      );
      await first.save('shared', 'Initial');
      final pending = await first.store.pendingChanges();
      expect(pending, hasLength(1));
      first.transport.dropNextAcknowledgement = true;
      await expectLater(first.engine.sync(), throwsA(isA<TimeoutException>()));
      expect(
        (await first.store.pendingChanges()).single.changeId,
        pending.single.changeId,
      );
      expect((await first.engine.sync()).uploaded, 1);
      expect(await first.store.pendingCount(), 0);
      final serverPage = await second.transport.inner.pull(deviceId: second.id);
      expect(
        serverPage.changes.where((change) => change.entityId == 'shared'),
        hasLength(1),
      );
      await second.engine.sync();
      expect(await second.title('shared'), 'Initial');

      await first.save('shared', 'Phone changed offline');
      await second.save('shared', 'Desktop changed offline');
      await second.save('unrelated', 'Send despite conflict');
      expect((await first.engine.sync()).uploaded, 1);
      final reconciliation = await second.engine.sync();
      expect(reconciliation.conflicts, 1);
      expect(reconciliation.uploaded, 1);
      expect(await second.title('shared'), 'Desktop changed offline');
      final conflict = (await second.conflicts.unresolved()).single;
      expect(conflict.remote.payload['title'], 'Phone changed offline');

      await second.conflicts.resolve(
        conflict.id,
        SyncConflictResolution.keepLocal,
      );
      expect((await second.engine.sync()).uploaded, 1);
      await first.engine.sync();
      expect(await first.title('shared'), 'Desktop changed offline');
      expect(await first.title('unrelated'), 'Send despite conflict');
      expect(await second.conflicts.unresolved(), isEmpty);

      await first.repository.delete(_type, 'shared');
      await first.engine.sync();
      await second.engine.sync();
      expect(await second.title('shared'), isNull);
      expect(
        (await second.store.readCurrent(_type, 'shared'))?.operation,
        SyncOperation.delete,
      );
      expect(await second.store.pendingCount(), 0);
    },
    skip: registrationCode == null || registrationCode.isEmpty
        ? 'Requires the disposable local PHP/MySQL service.'
        : false,
  );
}

_Client _makeClient(String id, String token) {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = DriftEntityRepository(
    database: database,
    deviceIdentity: () async => id,
  );
  final store = DriftSyncStore(providerId: 'local-test-server', database: database);
  final dio = Dio(BaseOptions(followRedirects: false));
  final transport = _InterruptOneResponse(
    RahaHttpSyncTransport(
      baseUrl: _baseUrl,
      token: token,
      allowInsecureHttp: true,
      dio: dio,
    ),
  );
  return _Client(
    id: id,
    repository: repository,
    store: store,
    transport: transport,
    conflicts: SyncConflictRepository(
      database: database,
      deviceIdentity: () async => id,
    ),
    dispose: () async {
      dio.close(force: true);
      await database.close();
    },
  );
}

class _Client {
  const _Client({
    required this.id,
    required this.repository,
    required this.store,
    required this.transport,
    required this.conflicts,
    required this.dispose,
  });

  final String id;
  final DriftEntityRepository repository;
  final DriftSyncStore store;
  final _InterruptOneResponse transport;
  final SyncConflictRepository conflicts;
  final Future<void> Function() dispose;

  RecordSyncEngine get engine =>
      RecordSyncEngine(deviceId: id, store: store, transport: transport);

  Future<void> save(String id, String title) =>
      repository.upsert(_type, {'id': id, 'title': title});

  Future<String?> title(String id) async =>
      (await repository.loadOne(_type, id))?['title'] as String?;
}

class _InterruptOneResponse implements SyncTransport {
  _InterruptOneResponse(this.inner);

  final RahaHttpSyncTransport inner;
  bool dropNextAcknowledgement = false;

  @override
  Future<SyncPullResult> pull({required String deviceId, String? cursor}) =>
      inner.pull(deviceId: deviceId, cursor: cursor);

  @override
  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  }) async {
    final result = await inner.push(deviceId: deviceId, changes: changes);
    if (dropNextAcknowledgement) {
      dropNextAcknowledgement = false;
      throw TimeoutException('Test interruption after the server committed');
    }
    return result;
  }
}
