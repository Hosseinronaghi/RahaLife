import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/features/federation/federation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const alice = FederationAccount(
    network: 'matrix',
    server: 'https://a.test',
    identity: '@alice:a.test',
    token: 'secret-a',
  );
  const bob = FederationAccount(
    network: 'matrix',
    server: 'https://a.test',
    identity: '@bob:a.test',
    token: 'secret-b',
  );
  Map<String, dynamic> message(FederationAccount account, String id) => {
    'id': id,
    'mode': account.network,
    'server': account.server,
    'identity': account.identity,
    'room': '!room:a.test',
    'text': 'private text $id',
  };
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'multiple accounts remain separate; updating a token does not duplicate',
    () async {
      final store = FederationStore();
      await Future.wait([store.saveAccount(alice), store.saveAccount(bob)]);
      await store.saveAccount(
        const FederationAccount(
          network: 'matrix',
          server: 'https://a.test',
          identity: '@alice:a.test',
          token: 'new-token',
        ),
      );
      final accounts = await store.accounts();
      expect(accounts, hasLength(2));
      expect(accounts.firstWhere((a) => a.id == alice.id).token, 'new-token');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'legacy plaintext queue migrates without leaking another account',
    () async {
      SharedPreferences.setMockInitialValues({
        FederationStore.legacyQueueKey: jsonEncode([
          message(alice, '1'),
          message(bob, '2'),
        ]),
      });
      final store = FederationStore();
      expect((await store.queueFor(alice)).single['id'], '1');
      expect((await store.queueFor(bob)).single['id'], '2');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(FederationStore.legacyQueueKey), isFalse);
      final ciphertext = prefs.getString(FederationStore.queueKey)!;
      expect(ciphertext.contains('private text'), isFalse);
      expect(ciphertext.contains(alice.identity), isFalse);
    },
  );

  test(
    'parallel enqueue preserves both accounts and removal cannot cross accounts',
    () async {
      final store = FederationStore();
      await Future.wait([
        store.enqueue(alice, message(alice, '1')),
        FederationStore().enqueue(bob, message(bob, '2')),
      ]);
      await store.removeMessage(alice, '2');
      expect(await store.queueFor(bob), hasLength(1));
      await store.removeAccount(alice);
      expect(await store.queueFor(alice), isEmpty);
      expect(await store.queueFor(bob), hasLength(1));
    },
  );

  test('mismatched sender and duplicate transaction IDs are refused', () async {
    final store = FederationStore();
    await expectLater(
      store.enqueue(alice, message(bob, '1')),
      throwsStateError,
    );
    await store.enqueue(alice, message(alice, '1'));
    await expectLater(
      store.enqueue(alice, message(alice, '1')),
      throwsStateError,
    );
    expect(await store.queueFor(alice), hasLength(1));
  });

  test('missing encryption key cannot silently erase a saved queue', () async {
    final store = FederationStore();
    await store.enqueue(alice, message(alice, '1'));
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString(FederationStore.queueKey);
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(store.enqueue(bob, message(bob, '2')), throwsStateError);
    expect(prefs.getString(FederationStore.queueKey), before);
  });

  test(
    'tampered encrypted queue fails closed and preserves original bytes',
    () async {
      final store = FederationStore();
      await store.enqueue(alice, message(alice, '1'));
      final prefs = await SharedPreferences.getInstance();
      final value =
          jsonDecode(prefs.getString(FederationStore.queueKey)!) as Map;
      final mac = base64Decode(value['mac'] as String);
      mac[0] ^= 1;
      value['mac'] = base64Encode(mac);
      final corrupt = jsonEncode(value);
      await prefs.setString(FederationStore.queueKey, corrupt);
      await expectLater(store.queueFor(alice), throwsA(isA<Exception>()));
      expect(prefs.getString(FederationStore.queueKey), corrupt);
    },
  );
}
