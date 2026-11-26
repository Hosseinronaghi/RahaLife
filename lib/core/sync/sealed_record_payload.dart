import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'canonical_json.dart';
import 'sync_contract.dart';

/// Versioned authenticated record encoding for a future private sync workspace.
/// This codec is deliberately not enabled on the legacy HTTP sync transport.
class SealedRecordPayload {
  SealedRecordPayload(this._key, {
    required this.workspaceId,
    required this.keyVersion,
  }) {
    if (workspaceId.isEmpty || keyVersion < 1) {
      throw ArgumentError('A private workspace and key version are required.');
    }
  }

  static const _format = 'raha-sync-aes256gcm-v1';
  static const _maxPlainBytes = 4 * 1024 * 1024;
  static const _maxEncodedChars = ((_maxPlainBytes + 2) ~/ 3) * 4;
  static const _fields = {'format', 'keyVersion', 'nonce', 'ciphertext', 'tag'};
  final String workspaceId;
  final int keyVersion;
  final SecretKey _key;
  final AesGcm _algorithm = AesGcm.with256bits();

  List<int> _metadata(SyncEnvelope change) {
    if (change.changeId == null || change.changeId!.isEmpty) {
      throw const FormatException('A durable sync change ID is required.');
    }
    return utf8.encode(canonicalJson({
      'format': _format,
      'workspaceId': workspaceId,
      'keyVersion': keyVersion,
      'change': change.toJson()..remove('payload'),
    }));
  }

  /// Persist the returned envelope before first transmission; retries must
  /// resend the saved ciphertext rather than seal the same change again.
  Future<SyncEnvelope> seal(SyncEnvelope clear) async {
    final metadata = _metadata(clear);
    final plaintext = utf8.encode(canonicalJson(clear.payload));
    if (plaintext.length > _maxPlainBytes) {
      throw const FormatException('Private sync record exceeds the size limit.');
    }
    final box = await _algorithm.encrypt(plaintext, secretKey: _key, aad: metadata);
    return _replacePayload(clear, {
      'format': _format,
      'keyVersion': keyVersion,
      'nonce': base64UrlEncode(box.nonce),
      'ciphertext': base64UrlEncode(box.cipherText),
      'tag': base64UrlEncode(box.mac.bytes),
    });
  }

  Future<SyncEnvelope> open(SyncEnvelope sealed) async {
    final fields = sealed.payload;
    if (fields.length != _fields.length ||
        !_fields.containsAll(fields.keys) ||
        fields['format'] != _format ||
        fields['keyVersion'] != keyVersion) {
      throw const FormatException('Invalid private sync envelope or key version.');
    }
    final metadata = _metadata(sealed);
    final nonce = _decode(fields['nonce'], 16);
    final tag = _decode(fields['tag'], 24);
    final ciphertext = _decode(fields['ciphertext'], _maxEncodedChars);
    if (nonce.length != 12 || tag.length != 16 || ciphertext.length > _maxPlainBytes) {
      throw const FormatException('Invalid private sync envelope size.');
    }
    final clear = await _algorithm.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
      secretKey: _key,
      aad: metadata,
    );
    final payload = jsonDecode(utf8.decode(clear));
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid private sync payload.');
    }
    return _replacePayload(sealed, payload);
  }

  List<int> _decode(Object? value, int limit) {
    if (value is! String || value.isEmpty || value.length > limit) {
      throw const FormatException('Invalid private sync envelope field.');
    }
    return base64Url.decode(value);
  }

  SyncEnvelope _replacePayload(SyncEnvelope change, Map<String, Object?> payload) =>
      SyncEnvelope.fromJson({...change.toJson(), 'payload': payload});
}
