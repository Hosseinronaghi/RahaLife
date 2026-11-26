import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProviderCredentialsStore {
  ProviderCredentialsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static final _writes = <String, Future<void>>{};

  Future<T> _serialize<T>(String id, Future<T> Function() operation) async {
    final pending = (_writes[id] ?? Future<void>.value()).then(
      (_) => operation(),
    );
    final barrier = pending.then<void>((_) {}, onError: (Object _) {});
    _writes[id] = barrier;
    try {
      return await pending;
    } finally {
      if (identical(_writes[id], barrier)) _writes.remove(id);
    }
  }

  String _key(String connectionId) => 'sync.connection.secret.$connectionId';

  Future<void> write(
    String connectionId,
    Map<String, String> credentials,
  ) => _serialize(connectionId, () => _write(connectionId, credentials));

  Future<void> _write(
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

  Future<bool> replaceIfUnchanged(
    String connectionId, {
    required Map<String, String> expected,
    required Map<String, String> replacement,
  }) => _serialize(connectionId, () async {
    final current = await read(connectionId);
    if (expected.length != current.length ||
        !expected.entries.every((entry) => current[entry.key] == entry.value)) {
      return false;
    }
    await _write(connectionId, replacement);
    return true;
  });

  Future<void> delete(String connectionId) => _serialize(
    connectionId, () => _storage.delete(key: _key(connectionId)),
  );
}
