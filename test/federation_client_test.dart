import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/federation/federation_client.dart';

class FakeAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool encrypted = false;
  Map<String?, Object> history = {};
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
    if (options.uri.path.endsWith('/messages')) {
      return ResponseBody.fromString(
        jsonEncode(history[options.queryParameters['from']]),
        200,
        headers: {'content-type': ['application/json']},
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
  test('Matrix history follows older cursors even after an empty page', () async {
    final adapter = FakeAdapter()..history = {
      null: {
        'chunk': [
          {'event_id': 'new', 'type': 'm.room.encrypted'},
          {'event_id': 'previous', 'type': 'm.room.message'},
        ],
        'end': 'first',
      },
      'first': {'chunk': [], 'end': 'next'},
      'next': {
        'chunk': [
          {'event_id': 'old', 'type': 'm.room.message'},
          {'event_id': 'join', 'type': 'm.room.member'},
        ],
      },
    };
    final client = FederationClient(
      'https://matrix.example',
      'secret',
      dio: Dio()..httpClientAdapter = adapter,
    );
    final latest = await client.matrixHistory('!room:matrix.example');
    expect(latest.events.map((item) => item['event_id']), ['previous', 'new']);
    final empty = await client.matrixHistory(
      '!room:matrix.example', from: latest.olderCursor,
    );
    expect(empty.events, isEmpty);
    expect(empty.olderCursor, 'next');
    final old = await client.matrixHistory(
      '!room:matrix.example', from: empty.olderCursor,
    );
    expect(old.events.single['event_id'], 'old');
    expect(old.olderCursor, isNull);
    expect(adapter.calls.map((e) => e.queryParameters['from']), [null, 'first', 'next']);
  });
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
