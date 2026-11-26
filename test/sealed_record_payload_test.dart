import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/sealed_record_payload.dart';
import 'package:raha_life/core/sync/sync_contract.dart';

SyncEnvelope _record() => SyncEnvelope(
  changeId: 'change-a',
  entityType: 'rich_note',
  entityId: 'example',
  operation: SyncOperation.upsert,
  version: 2,
  updatedAtUtc: DateTime.utc(2026),
  deviceId: 'device',
  clock: const {'device': 2},
  payload: const {'title': 'یادداشت محرمانه'},
);

void main() {
  test('sealed metadata can be transmitted without exposing note contents', () async {
    final key = await AesGcm.with256bits().newSecretKey();
    final codec = SealedRecordPayload(key, workspaceId: 'workspace-a', keyVersion: 1);
    final clear = _record();
    final a = await codec.seal(clear);
    final b = await codec.seal(clear);
    expect(a.payload.containsKey('title'), isFalse);
    expect(a.payload['nonce'], isNot(b.payload['nonce']));
    expect((await codec.open(a)).toJson(), clear.toJson());
  });

  test('another key, workspace, record or revision cannot open a payload', () async {
    final key = await AesGcm.with256bits().newSecretKey();
    final codec = SealedRecordPayload(key, workspaceId: 'workspace-a', keyVersion: 1);
    final sealed = await codec.seal(_record());
    final otherKey = await AesGcm.with256bits().newSecretKey();
    final differentKey = SealedRecordPayload(otherKey, workspaceId: 'workspace-a', keyVersion: 1);
    final differentSpace = SealedRecordPayload(key, workspaceId: 'workspace-b', keyVersion: 1);
    await expectLater(differentKey.open(sealed), throwsA(isA<SecretBoxAuthenticationError>()));
    await expectLater(differentSpace.open(sealed), throwsA(isA<SecretBoxAuthenticationError>()));
    for (final tamper in [
      {'entityId': 'different'},
      {'version': 3},
      {'clock': {'device': 3}},
      {'operation': 'delete'},
    ]) {
      final mutated = SyncEnvelope.fromJson({...sealed.toJson(), ...tamper});
      await expectLater(codec.open(mutated), throwsA(isA<SecretBoxAuthenticationError>()));
    }
    await expectLater(codec.open(_record()), throwsFormatException);
  });
}
