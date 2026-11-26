import 'dart:convert';
import 'package:crypto/crypto.dart' as hashes;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncCryptoService {
  SyncCryptoService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _masterKeyStorageKey = 'sync.master_key.v1';
  static const _recoveryKeysStorageKey = 'sync.recovery_keys.v1';
  static Future<void> _keyOperations = Future<void>.value();
  static const _format = 'raha-backup-aesgcm-v1';

  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<T> _serializeKeys<T>(Future<T> Function() operation) {
    final next = _keyOperations.then((_) => operation());
    _keyOperations = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<SecretKey> getOrCreateMasterKey() =>
      _serializeKeys(_getOrCreateMasterKey);

  Future<SecretKey> _getOrCreateMasterKey() async {
    final existing = await _storage.read(key: _masterKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Url.decode(existing));
    }
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _storage.write(
      key: _masterKeyStorageKey,
      value: base64UrlEncode(bytes),
    );
    return key;
  }

  Future<String> exportRecoveryKey() async {
    final key = await getOrCreateMasterKey();
    final bytes = await key.extractBytes();
    return base64UrlEncode(bytes);
  }

  Future<List<String>> _recoveryKeys() async {
    final encoded = await _storage.read(key: _recoveryKeysStorageKey);
    return encoded == null
        ? []
        : (jsonDecode(encoded) as List).cast<String>().toList();
  }

  Future<void> importRecoveryKey(String encoded) => _serializeKeys(() async {
    final bytes = base64Url.decode(encoded.trim());
    if (bytes.length != 32) {
      throw const FormatException('Recovery key must contain 32 bytes.');
    }
    final key = base64UrlEncode(bytes);
    final active = await _storage.read(key: _masterKeyStorageKey);
    if (active == key) return;
    if (active == null || active.isEmpty) {
      await _storage.write(key: _masterKeyStorageKey, value: key);
      return;
    }
    final keys = await _recoveryKeys();
    if (keys.contains(key)) return;
    if (keys.length >= 12) throw StateError('Recovery key storage is full.');
    await _storage.write(
      key: _recoveryKeysStorageKey,
      value: jsonEncode([...keys, key]),
    );
  });

  String _keyId(List<int> bytes) => hashes.sha256.convert(bytes).toString();
  Future<Uint8List> encrypt(Uint8List clearBytes) async {
    final key = await getOrCreateMasterKey();
    final box = await _cipher.encrypt(clearBytes, secretKey: key);
    final envelope = <String, Object?>{
      'format': _format,
      'keyId': _keyId(await key.extractBytes()),
      'nonce': base64UrlEncode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Uint8List> decrypt(Uint8List encryptedBytes) async {
    final decoded = jsonDecode(utf8.decode(encryptedBytes));
    if (decoded is! Map || decoded['format'] != _format) {
      throw const FormatException('Unsupported Raha backup format.');
    }
    final box = SecretBox(
      base64Decode(decoded['cipherText']! as String),
      nonce: base64Url.decode(decoded['nonce']! as String),
      mac: Mac(base64Url.decode(decoded['mac']! as String)),
    );
    final keys = await _serializeKeys(() async {
      final active = await _storage.read(key: _masterKeyStorageKey);
      return [
        if (active != null && active.isNotEmpty) active,
        ...await _recoveryKeys(),
      ];
    });
    for (final key in keys) {
      final bytes = base64Url.decode(key);
      if (decoded['keyId'] != null && decoded['keyId'] != _keyId(bytes)) {
        continue;
      }
      try {
        final clear = await _cipher.decrypt(box, secretKey: SecretKey(bytes));
        return Uint8List.fromList(clear);
      } on SecretBoxAuthenticationError {
        // Older envelopes lack a key id. Try the next retained key.
      }
    }
    throw const FormatException(
      'Backup authentication failed. Check the recovery key and file.',
    );
  }
}
