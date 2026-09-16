import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProviderCredentialsStore {
  ProviderCredentialsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String connectionId) => 'sync.connection.secret.$connectionId';

  Future<void> write(
    String connectionId,
    Map<String, String> credentials,
  ) async {
    await _storage.write(
      key: _key(connectionId),
      value: jsonEncode(credentials),
    );
  }

  Future<Map<String, String>> read(String connectionId) async {
    final raw = await _storage.read(key: _key(connectionId));
    if (raw == null || raw.isEmpty) return const <String, String>{};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<void> delete(String connectionId) =>
      _storage.delete(key: _key(connectionId));
}
