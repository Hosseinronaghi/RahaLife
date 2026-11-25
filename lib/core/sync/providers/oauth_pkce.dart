import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// One short-lived authorization attempt. No verifier is written to disk.
class OAuthPkceAttempt {
  OAuthPkceAttempt({required this.redirectUri, DateTime? now})
    : createdAt = now ?? DateTime.now().toUtc(),
      state = _random(),
      verifier = _random();
  final Uri redirectUri;
  final DateTime createdAt;
  final String state, verifier;
  bool _consumed = false;
  static String _random() {
    final random = Random.secure();
    return base64UrlEncode(
      List.generate(32, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
  }

  String get challenge => base64UrlEncode(
    sha256.convert(ascii.encode(verifier)).bytes,
  ).replaceAll('=', '');

  String consume(Uri callback, {DateTime? now}) {
    if (_consumed) throw StateError('oauth_callback_already_consumed');
    final age = (now ?? DateTime.now().toUtc()).difference(createdAt);
    if (age.isNegative || age > const Duration(minutes: 10)) {
      _consumed = true;
      throw StateError('oauth_attempt_expired');
    }
    if (callback.scheme != redirectUri.scheme ||
        callback.host != redirectUri.host ||
        callback.port != redirectUri.port ||
        callback.path != redirectUri.path ||
        callback.userInfo.isNotEmpty ||
        callback.hasFragment ||
        callback.queryParametersAll.values.any(
          (values) => values.length != 1,
        ) ||
        callback.queryParameters['state'] != state) {
      throw StateError('oauth_callback_mismatch');
    }
    _consumed = true;
    if (callback.queryParameters.containsKey('error')) {
      throw StateError('oauth_authorization_denied');
    }
    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) throw StateError('oauth_code_missing');
    return code;
  }
}

/// Fixed provider endpoints; neither a callback nor a profile can redirect tokens.
class DropboxOAuth {
  DropboxOAuth({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          );
  final Dio _dio;
  static const clientId = String.fromEnvironment('RAHA_DROPBOX_CLIENT_ID');
  static const redirect = String.fromEnvironment('RAHA_DROPBOX_REDIRECT_URI');
  static bool get configured =>
      clientId.trim().isNotEmpty && redirect.isNotEmpty;

  Uri authorize(
    OAuthPkceAttempt attempt,
    String appId,
  ) => Uri.https('www.dropbox.com', '/oauth2/authorize', {
    'client_id': appId,
    'redirect_uri': attempt.redirectUri.toString(),
    'response_type': 'code',
    'state': attempt.state,
    'code_challenge': attempt.challenge,
    'code_challenge_method': 'S256',
    'token_access_type': 'offline',
    'scope':
        'account_info.read files.metadata.read files.content.read files.content.write',
  });

  Future<Map<String, String>> exchange({
    required OAuthPkceAttempt attempt,
    required Uri callback,
    required String appId,
  }) async => _token({
    'grant_type': 'authorization_code',
    'client_id': appId,
    'code': attempt.consume(callback),
    'code_verifier': attempt.verifier,
    'redirect_uri': attempt.redirectUri.toString(),
  });

  Future<Map<String, String>> refresh({
    required String refreshToken,
    required String appId,
  }) => _token({
    'grant_type': 'refresh_token',
    'client_id': appId,
    'refresh_token': refreshToken,
  });

  Future<Map<String, String>> _token(Map<String, String> form) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/oauth2/token',
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (s) => s == 200,
        ),
      );
      final data = response.data!;
      final token = data['access_token'];
      final type = data['token_type'];
      final seconds = data['expires_in'];
      if (token is! String ||
          token.isEmpty ||
          type is! String ||
          type.toLowerCase() != 'bearer' ||
          seconds is! num ||
          seconds <= 0) {
        throw StateError('oauth_invalid_token_response');
      }
      return {
        'accessToken': token,
        if (data['refresh_token'] is String)
          'refreshToken': data['refresh_token'] as String,
        'expiresAt': DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds.toInt()))
            .toIso8601String(),
        if (data['account_id'] is String)
          'accountId': data['account_id'] as String,
        'clientId': form['client_id']!,
      };
    } catch (_) {
      // DioException includes token request data. Never propagate it to logs/UI.
      throw StateError('oauth_token_exchange_failed');
    }
  }
}
