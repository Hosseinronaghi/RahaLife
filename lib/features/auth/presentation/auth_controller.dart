import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/local_account.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const AuthState(loading: true)) {
    unawaited(_load());
  }

  static const _profileKey = 'auth.local.profile.v1';
  static const _sessionKey = 'auth.local.session.v1';
  static const _hashKey = 'auth.local.password.hash.v1';
  static const _saltKey = 'auth.local.password.salt.v1';
  static const _uuid = Uuid();
  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    final hasSession = prefs.getBool(_sessionKey) ?? false;
    if (raw == null || !hasSession) {
      state = const AuthState();
      return;
    }
    try {
      state = AuthState(user: LocalAccount.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map)));
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> signUp({required String name, required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    if (password.length < 8) {
      state = state.copyWith(loading: false, errorCode: 'weakPassword');
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_profileKey) != null) {
      state = state.copyWith(loading: false, errorCode: 'accountExists');
      return false;
    }
    final salt = _randomSalt();
    final account = LocalAccount(id: _uuid.v4(), name: name.trim(), email: email.trim().toLowerCase());
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: _hash(password, salt));
    await prefs.setString(_profileKey, jsonEncode(account.toJson()));
    await prefs.setBool(_sessionKey, true);
    state = AuthState(user: account);
    return true;
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    final salt = await _storage.read(key: _saltKey);
    final storedHash = await _storage.read(key: _hashKey);
    if (raw == null || salt == null || storedHash == null) {
      state = state.copyWith(loading: false, errorCode: 'accountNotFound');
      return false;
    }
    final account = LocalAccount.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
    if (account.email != email.trim().toLowerCase() || _hash(password, salt) != storedHash) {
      state = state.copyWith(loading: false, errorCode: 'invalidCredentials');
      return false;
    }
    await prefs.setBool(_sessionKey, true);
    state = AuthState(user: account);
    return true;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    state = const AuthState();
  }

  static String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
