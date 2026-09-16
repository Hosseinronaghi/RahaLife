import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncCryptoService {
  SyncCryptoService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _masterKeyStorageKey = 'sync.master_key.v1';
  static const _format = 'raha-backup-aesgcm-v1';

  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<SecretKey> getOrCreateMasterKey() async {
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

  Future<void> importRecoveryKey(String encoded) async {
    final normalized = encoded.trim();
    final bytes = base64Url.decode(normalized);
    if (bytes.length != 32) {
      throw const FormatException('Recovery key must contain 32 bytes.');
    }
    await _storage.write(
      key: _masterKeyStorageKey,
      value: base64UrlEncode(bytes),
    );
  }

  Future<Uint8List> encrypt(Uint8List clearBytes) async {
    final key = await getOrCreateMasterKey();
    final box = await _cipher.encrypt(clearBytes, secretKey: key);
    final envelope = <String, Object?>{
      'format': _format,
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
    final key = await getOrCreateMasterKey();
    final clear = await _cipher.decrypt(box, secretKey: key);
    return Uint8List.fromList(clear);
  }
}
