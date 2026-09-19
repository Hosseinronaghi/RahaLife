import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/federation/federation_client.dart';

class FakeAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool encrypted = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    if (options.path.contains('/state/m.room.encryption/')) {
      return ResponseBody.fromString(
        jsonEncode(
          encrypted
              ? {'algorithm': 'm.megolm.v1.aes-sha2'}
              : {'errcode': 'M_NOT_FOUND'},
        ),
        encrypted ? 200 : 404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      '{"event_id":"event","id":"post"}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('rejects HTTP credentials and URL suffixes', () {
    for (final url in [
      'http://example.com',
      'https://u:p@example.com',
      'https://example.com/path',
      'https://example.com?token=x',
      'https://example.com#fragment',
    ]) {
      expect(() => FederationClient.validateServer(url), throwsFormatException);
    }
    expect(
      FederationClient.validateServer('https://example.com/'),
      'https://example.com',
    );
  });
  test('encrypted room never receives a plaintext message', () async {
    final adapter = FakeAdapter()..encrypted = true;
    final dio = Dio()..httpClientAdapter = adapter;
    final client = FederationClient(
      'https://matrix.example',
      'secret',
      dio: dio,
    );
    await expectLater(
      client.matrixSend('!room:matrix.example', 'private', 'tx'),
      throwsStateError,
    );
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.method, 'GET');
  });
  test(
    'plaintext send uses stable transaction ID and disables redirects',
    () async {
      final adapter = FakeAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final client = FederationClient(
        'https://matrix.example',
        'secret',
        dio: dio,
      );
      await client.matrixSend('!room:matrix.example', 'hello', 'retry-1');
      await client.matrixSend('!room:matrix.example', 'hello', 'retry-1');
      final sends = adapter.calls.where((e) => e.method == 'PUT').toList();
      expect(sends, hasLength(2));
      expect(sends[0].uri, sends[1].uri);
      expect(sends.first.followRedirects, false);
      expect(sends.first.headers['Authorization'], 'Bearer secret');
    },
  );
  test('Mastodon visibility and idempotency are explicit', () async {
    final adapter = FakeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final client = FederationClient(
      'https://social.example',
      'secret',
      dio: dio,
    );
    await client.mastodonPublish('hello', 'private', 'post-1');
    expect(adapter.calls.single.data, {
      'status': 'hello',
      'visibility': 'private',
    });
    expect(adapter.calls.single.headers['Idempotency-Key'], 'post-1');
    await expectLater(
      client.mastodonPublish('hello', 'unexpected', 'p'),
      throwsArgumentError,
    );
  });
}
