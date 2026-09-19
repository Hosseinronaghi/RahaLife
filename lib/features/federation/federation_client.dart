import 'package:dio/dio.dart';

/// Tokens are bound to one explicit HTTPS origin; redirects never receive them.
class FederationClient {
  FederationClient(String server, String token, {Dio? dio})
    : base = validateServer(server),
      _token = token,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          );
  final String base, _token;
  final Dio _dio;
  static String validateServer(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException('HTTPS origin required');
    }
    return uri.origin;
  }

  Future<dynamic> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, String> headers = const {},
  }) async {
    final response = await _dio.request<dynamic>(
      '$base$path',
      data: data,
      queryParameters: query,
      options: Options(
        method: method,
        followRedirects: false,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          ...headers,
        },
      ),
    );
    return response.data;
  }

  Future<String> matrixIdentity() async =>
      (await request('GET', '/_matrix/client/v3/account/whoami'))['user_id']
          as String;
  Future<List<String>> matrixRooms() async => List<String>.from(
    (await request('GET', '/_matrix/client/v3/joined_rooms'))['joined_rooms']
        as List,
  );
  Future<bool> matrixEncrypted(String room) async {
    try {
      await request(
        'GET',
        '/_matrix/client/v3/rooms/${Uri.encodeComponent(room)}/state/m.room.encryption/',
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 &&
          e.response?.data is Map &&
          e.response?.data['errcode'] == 'M_NOT_FOUND') {
        return false;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> matrixMessages(String room) async {
    final response = await request(
      'GET',
      '/_matrix/client/v3/rooms/${Uri.encodeComponent(room)}/messages',
      query: {'dir': 'b', 'limit': 50},
    );
    return (response['chunk'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .reversed
        .toList();
  }

  Future<void> matrixSend(
    String room,
    String text,
    String transactionId,
  ) async {
    // Never leak plaintext into an encrypted room. E2EE requires the crypto SDK.
    if (await matrixEncrypted(room)) {
      throw StateError('encrypted_room_requires_crypto_client');
    }
    await request(
      'PUT',
      '/_matrix/client/v3/rooms/${Uri.encodeComponent(room)}/send/m.room.message/${Uri.encodeComponent(transactionId)}',
      data: {'msgtype': 'm.text', 'body': text},
    );
  }

  Future<String> matrixCreateRoom(String name, List<String> invite) async =>
      (await request(
            'POST',
            '/_matrix/client/v3/createRoom',
            data: {
              'name': name,
              'preset': 'private_chat',
              'visibility': 'private',
              'invite': invite,
            },
          ))['room_id']
          as String;
  Future<void> matrixJoin(String room) async {
    await request(
      'POST',
      '/_matrix/client/v3/join/${Uri.encodeComponent(room)}',
      data: {},
    );
  }

  Future<void> matrixInvite(String room, String user) async {
    await request(
      'POST',
      '/_matrix/client/v3/rooms/${Uri.encodeComponent(room)}/invite',
      data: {'user_id': user},
    );
  }

  Future<void> matrixLeave(String room) async {
    await request(
      'POST',
      '/_matrix/client/v3/rooms/${Uri.encodeComponent(room)}/leave',
      data: {},
    );
  }

  Future<Map<String, dynamic>> mastodonIdentity() async =>
      Map<String, dynamic>.from(
        await request('GET', '/api/v1/accounts/verify_credentials') as Map,
      );
  Future<List<Map<String, dynamic>>> mastodonTimeline() async =>
      (await request('GET', '/api/v1/timelines/home', query: {'limit': 20})
              as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Future<Map<String, dynamic>> mastodonPublish(
    String text,
    String visibility,
    String requestId,
  ) async {
    if (!['public', 'unlisted', 'private', 'direct'].contains(visibility)) {
      throw ArgumentError('Invalid visibility');
    }
    return Map<String, dynamic>.from(
      await request(
            'POST',
            '/api/v1/statuses',
            data: {'status': text, 'visibility': visibility},
            headers: {'Idempotency-Key': requestId},
          )
          as Map,
    );
  }

  Future<void> mastodonFavourite(String id) async {
    await request(
      'POST',
      '/api/v1/statuses/${Uri.encodeComponent(id)}/favourite',
    );
  }
}
