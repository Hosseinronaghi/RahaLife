import 'package:dio/dio.dart';

import '../sync_contract.dart';

class RahaHttpSyncTransport implements SyncTransport {
  RahaHttpSyncTransport({
    required String baseUrl,
    required String token,
    bool allowInsecureHttp = false,
    Dio? dio,
  }) : _baseUrl = _validatedBaseUrl(baseUrl, allowInsecureHttp),
       _token = token,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 45),
               sendTimeout: const Duration(seconds: 45),
             ),
           );

  final String _baseUrl;
  final String _token;
  final Dio _dio;

  static String _validatedBaseUrl(String raw, bool allowInsecureHttp) {
    final value = raw.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty || !uri.hasScheme) {
      throw const FormatException('A valid Raha Sync Server URL is required.');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https' || (scheme == 'http' && allowInsecureHttp)) {
      return value;
    }
    throw const FormatException(
      'HTTPS is required unless insecure HTTP is explicitly allowed.',
    );
  }

  Map<String, String> get _headers => <String, String>{
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
    'X-Raha-Client': 'Raha-Life/0.8.0',
  };

  bool _verified = false;
  Future<void> _verify() async {
    if (_verified) {
      return;
    }
    final result = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/health',
      options: Options(headers: _headers),
    );
    if ((result.data?['protocolVersion'] as num? ?? 0) < 3) {
      throw StateError(
        'Upgrade Raha Sync Server to protocol 3 before synchronizing.',
      );
    }
    _verified = true;
  }

  @override
  Future<SyncPullResult> pull({
    required String deviceId,
    String? cursor,
  }) async {
    await _verify();
    final response = await _dio.get<Object?>(
      '$_baseUrl/v1/sync/pull',
      queryParameters: {
        'deviceId': deviceId,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: Options(headers: _headers),
    );
    final data = response.data;
    if (data is! Map ||
        data['changes'] is! List ||
        data['nextCursor'] == null) {
      throw const FormatException('Incomplete sync response');
    }
    final raw = data['changes'] as List;
    if (raw.any((e) => e is! Map)) {
      throw const FormatException('Malformed sync page; cursor retained.');
    }
    return SyncPullResult(
      changes: raw
          .map(
            (e) => SyncEnvelope.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .toList(),
      nextCursor: data['nextCursor'].toString(),
      hasMore: data['hasMore'] == true,
    );
  }

  @override
  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  }) async {
    await _verify();
    final response = await _dio.post<Object?>(
      '$_baseUrl/v1/sync/push',
      data: {
        'deviceId': deviceId,
        'changes': changes.map((e) => e.toJson()).toList(),
      },
      options: Options(headers: _headers),
    );
    final data = response.data;
    if (data is! Map ||
        data['accepted'] is! List ||
        data['conflicts'] is! List) {
      throw const FormatException('Invalid sync push response');
    }
    final accepted = data['accepted'] as List, raw = data['conflicts'] as List;
    if (accepted.any((e) => e is! String) ||
        raw.any(
          (e) => e is! Map || e['local'] is! Map || e['remote'] is! Map,
        )) {
      throw const FormatException(
        'Malformed sync acknowledgement or conflict response',
      );
    }
    return SyncPushResult(
      accepted: accepted.cast<String>(),
      conflicts: raw
          .map(
            (e) => SyncConflict(
              local: SyncEnvelope.fromJson(
                Map<String, Object?>.from(e['local'] as Map),
              ),
              remote: SyncEnvelope.fromJson(
                Map<String, Object?>.from(e['remote'] as Map),
              ),
            ),
          )
          .toList(),
    );
  }
}
