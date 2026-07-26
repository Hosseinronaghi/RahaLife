import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAiCredentials {
  SecureAiCredentials([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveApiKey(String provider, String apiKey) =>
      _storage.write(key: 'ai_key_$provider', value: apiKey);

  Future<String?> readApiKey(String provider) =>
      _storage.read(key: 'ai_key_$provider');

  Future<void> deleteApiKey(String provider) =>
      _storage.delete(key: 'ai_key_$provider');
}
