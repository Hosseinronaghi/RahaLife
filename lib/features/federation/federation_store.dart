import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credentials never enter preferences, backups or the application sync store.
class FederationAccount {
  const FederationAccount({
    required this.network,
    required this.server,
    required this.identity,
    required this.token,
  });
  final String network, server, identity, token;
  String get id => sha256
      .convert(utf8.encode(jsonEncode([network, server, identity])))
      .toString();
  Map<String, dynamic> toJson() => {
    'network': network,
    'server': server,
    'identity': identity,
    'token': token,
  };
  factory FederationAccount.fromJson(Map<String, dynamic> value) =>
      FederationAccount(
        network: value['network'] as String,
        server: value['server'] as String,
        identity: value['identity'] as String,
        token: value['token'] as String,
      );
  bool owns(Map<String, dynamic> message) =>
      message['mode'] == network &&
      message['server'] == server &&
      message['identity'] == identity;
}

class FederationStore {
  FederationStore({FlutterSecureStorage? secure})
    : _secure = secure ?? const FlutterSecureStorage();
  final FlutterSecureStorage _secure;
  static const accountsKey = 'federation.accounts.v1';
  static const queueKey = 'federation.outbox.encrypted.v1';
  static const legacyQueueKey = 'federation.outbox';
  static const _encryptionKey = 'federation.outbox.key.v1';
  static Future<void> _tail = Future<void>.value();

  // Serializes read/modify/write across screens and store instances.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<FederationAccount>> _accounts() async {
    final value = await _secure.read(key: accountsKey);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .map(
          (e) =>
              FederationAccount.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<FederationAccount>> accounts() => _serial(_accounts);

  Future<void> saveAccount(FederationAccount account) => _serial(() async {
    final entries = await _accounts();
    entries.removeWhere((a) => a.id == account.id);
    entries.add(account);
    await _secure.write(
      key: accountsKey,
      value: jsonEncode(entries.map((a) => a.toJson()).toList()),
    );
    // Legacy credentials are removed only after the replacement is durable.
    await _secure.delete(key: 'federation.${account.network}');
  });

  Future<Map<String, dynamic>?> legacyCredentials(String network) async {
    final value = await _secure.read(key: 'federation.$network');
    return value == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<void> clearLegacyCredentials(String network) =>
      _serial(() => _secure.delete(key: 'federation.$network'));

  Future<SecretKey> _key({required bool create}) async {
    final value = await _secure.read(key: _encryptionKey);
    if (value != null) return SecretKey(base64Decode(value));
    if (!create) throw StateError('outbox_key_unavailable');
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _secure.write(key: _encryptionKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> items) async {
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(jsonEncode(items)),
      secretKey: await _key(create: true),
      aad: utf8.encode(queueKey),
    );
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      queueKey,
      jsonEncode({
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      }),
    );
    if (!ok) throw StateError('outbox_write_failed');
  }

  Future<List<Map<String, dynamic>>> _queue() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(queueKey);
    List<Map<String, dynamic>> items = [];
    if (stored != null) {
      final box = jsonDecode(stored) as Map;
      final bytes = await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(box['ciphertext'] as String),
          nonce: base64Decode(box['nonce'] as String),
          mac: Mac(base64Decode(box['mac'] as String)),
        ),
        secretKey: await _key(create: false),
        aad: utf8.encode(queueKey),
      );
      items = (jsonDecode(utf8.decode(bytes)) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    final legacy = prefs.getString(legacyQueueKey);
    if (legacy != null) {
      final ids = items.map((e) => e['id']).toSet();
      for (final item in jsonDecode(legacy) as List) {
        final message = Map<String, dynamic>.from(item as Map);
        if (ids.add(message['id'])) items.add(message);
      }
      await _writeQueue(items);
      if (!await prefs.remove(legacyQueueKey)) {
        throw StateError('legacy_outbox_cleanup_failed');
      }
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> queueFor(FederationAccount account) =>
      _serial(() async => (await _queue()).where(account.owns).toList());

  Future<void> enqueue(
    FederationAccount account,
    Map<String, dynamic> message,
  ) => _serial(() async {
    if (!account.owns(message) ||
        message['id'] is! String ||
        (message['id'] as String).isEmpty) {
      throw StateError('outbox_account_mismatch');
    }
    final items = await _queue();
    if (items.any((e) => e['id'] == message['id'])) {
      throw StateError('duplicate_outbox_id');
    }
    items.add(message);
    await _writeQueue(items);
  });

  Future<void> removeMessage(FederationAccount account, String id) =>
      _serial(() async {
        final items = await _queue();
        items.removeWhere((e) => account.owns(e) && e['id'] == id);
        await _writeQueue(items);
      });

  /// Local removal only: remote sessions must be revoked at the homeserver.
  Future<void> removeAccount(FederationAccount account) => _serial(() async {
    final items = await _queue();
    items.removeWhere(account.owns);
    await _writeQueue(items);
    final entries = await _accounts();
    entries.removeWhere((a) => a.id == account.id);
    await _secure.write(
      key: accountsKey,
      value: jsonEncode(entries.map((a) => a.toJson()).toList()),
    );
    await _secure.delete(key: 'federation.${account.network}');
  });
}
