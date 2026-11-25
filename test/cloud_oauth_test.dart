import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:raha_life/core/sync/providers/backup_target.dart';
import 'package:raha_life/core/sync/providers/dropbox_backup_target.dart';
import 'package:raha_life/core/sync/providers/oauth_pkce.dart';
import 'package:raha_life/core/sync/providers/provider_credentials.dart';

class CloudAdapter implements HttpClientAdapter {
  CloudAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions, Uint8List) respond;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final bytes = BytesBuilder();
    if (stream != null) {
      await for (final chunk in stream) {
        bytes.add(chunk);
      }
    }
    return respond(options, bytes.takeBytes());
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    'content-type': ['application/json'],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final redirect = Uri.parse('com.raha.life.oauth:/callback');
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('PKCE callbacks reject wrong origin/state/duplicates and replay', () {
    final attempt = OAuthPkceAttempt(redirectUri: redirect);
    for (final bad in [
      'evil:/callback?state=${attempt.state}&code=x',
      '$redirect?state=wrong&code=x',
      '$redirect?state=${attempt.state}&code=x&code=y',
      '$redirect?state=${attempt.state}&code=x#fragment',
      'com.raha.life.oauth:/elsewhere?state=${attempt.state}&code=x',
    ]) {
      expect(() => attempt.consume(Uri.parse(bad)), throwsStateError);
    }
    final good = redirect.replace(
      queryParameters: {'state': attempt.state, 'code': 'good'},
    );
    expect(attempt.consume(good), 'good');
    expect(() => attempt.consume(good), throwsStateError);
  });
  test('expired and denied authorization never supplies a code', () {
    final start = DateTime.utc(2026);
    final old = OAuthPkceAttempt(redirectUri: redirect, now: start);
    expect(
      () => old.consume(
        redirect.replace(queryParameters: {'state': old.state, 'code': 'x'}),
        now: start.add(const Duration(minutes: 11)),
      ),
      throwsStateError,
    );
    final denied = OAuthPkceAttempt(redirectUri: redirect);
    expect(
      () => denied.consume(
        redirect.replace(
          queryParameters: {
            'state': denied.state,
            'error': 'access_denied',
            'code': 'x',
          },
        ),
      ),
      throwsStateError,
    );
  });
  test(
    'authorization only exposes challenge; exchange sends verifier without a secret',
    () async {
      final attempt = OAuthPkceAttempt(redirectUri: redirect);
      final adapter = CloudAdapter((options, bytes) async {
        expect(options.uri.host, 'api.dropboxapi.com');
        expect(options.followRedirects, false);
        final form = Uri.splitQueryString(utf8.decode(bytes));
        expect(form['code_verifier'], attempt.verifier);
        expect(form.containsKey('client_secret'), false);
        return json({
          'access_token': 'access',
          'token_type': 'bearer',
          'expires_in': 14400,
          'refresh_token': 'refresh',
        });
      });
      final oauth = DropboxOAuth(dio: Dio()..httpClientAdapter = adapter);
      final uri = oauth.authorize(attempt, 'app');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.toString().contains(attempt.verifier), false);
      expect(uri.queryParameters['token_access_type'], 'offline');
      final token = await oauth.exchange(
        attempt: attempt,
        appId: 'app',
        callback: redirect.replace(
          queryParameters: {'state': attempt.state, 'code': 'one-time'},
        ),
      );
      expect(token['refreshToken'], 'refresh');
      await expectLater(
        oauth.exchange(
          attempt: attempt,
          appId: 'app',
          callback: redirect.replace(
            queryParameters: {'state': attempt.state, 'code': 'one-time'},
          ),
        ),
        throwsStateError,
      );
      expect(adapter.calls, hasLength(1));
    },
  );
  test('token endpoint failures do not expose authorization data', () async {
    final adapter = CloudAdapter(
      (options, bytes) async => json({'error': 'secret-token'}, 302),
    );
    final oauth = DropboxOAuth(dio: Dio()..httpClientAdapter = adapter);
    try {
      await oauth.refresh(refreshToken: 'private-refresh', appId: 'app');
      fail('redirect accepted');
    } catch (error) {
      expect(error.toString(), isNot(contains('private-refresh')));
      expect(error, isA<StateError>());
    }
    expect(adapter.calls, hasLength(1));
  });

  const profile = SyncConnectionProfile(
    id: 'cloud-test',
    name: 'Dropbox',
    kind: SyncProviderKind.dropbox,
    purpose: SyncTargetPurpose.backup,
  );
  Map<String, String> fresh() => {
    'accessToken': 'private-token',
    'expiresAt': DateTime.now()
        .toUtc()
        .add(const Duration(hours: 1))
        .toIso8601String(),
  };

  test(
    'backup restore paginates, pins a revision and downloads newest backup',
    () async {
      final adapter = CloudAdapter((options, bytes) async {
        expect(options.followRedirects, false);
        expect(options.headers['Authorization'], 'Bearer private-token');
        if (options.path.endsWith('/list_folder')) {
          return json({'entries': [], 'has_more': true, 'cursor': 'next'});
        }
        if (options.path.endsWith('/continue')) {
          return json({
            'entries': [
              {
                '.tag': 'file',
                'name': 'unrelated.txt',
                'server_modified': '2026-05-03T00:00:00Z',
              },
              {
                '.tag': 'file',
                'name': 'raha-new.rahabackup',
                'server_modified': '2026-05-02T00:00:00Z',
                'size': 3,
                'id': 'id:new',
                'rev': 'revision',
              },
              {
                '.tag': 'file',
                'name': 'raha-old.rahabackup',
                'server_modified': '2026-05-01T00:00:00Z',
                'size': 3,
                'id': 'id:old',
                'rev': 'old',
              },
            ],
            'has_more': false,
          });
        }
        expect(jsonDecode(options.headers['Dropbox-API-Arg'] as String), {
          'path': 'id:new',
          'rev': 'revision',
        });
        return ResponseBody.fromBytes([1, 2, 3], 200);
      });
      final target = DropboxBackupTarget(
        profile: profile,
        credentials: fresh(),
        dio: Dio()..httpClientAdapter = adapter,
      );
      final result = await target.downloadLatest();
      expect(result!.fileName, 'raha-new.rahabackup');
      expect(result.bytes, [1, 2, 3]);
      expect(adapter.calls, hasLength(3));
      expect(
        target.capabilities.contains(SyncProviderCapability.recordSync),
        false,
      );
    },
  );
  test(
    'two backups do not overwrite each other, payload is unchanged',
    () async {
      final paths = <String>[];
      final adapter = CloudAdapter((options, bytes) async {
        final args =
            jsonDecode(options.headers['Dropbox-API-Arg'] as String) as Map;
        paths.add(args['path'] as String);
        expect(args['mode'], 'add');
        expect(args['strict_conflict'], true);
        expect(bytes, [4, 5, 6]);
        return json({});
      });
      final target = DropboxBackupTarget(
        profile: profile,
        credentials: fresh(),
        dio: Dio()..httpClientAdapter = adapter,
      );
      final backup = BackupObject(
        bytes: Uint8List.fromList([4, 5, 6]),
        fileName: '../unsafe',
        createdAtUtc: DateTime.utc(2026),
      );
      await target.upload(backup);
      await target.upload(backup);
      expect(paths.toSet(), hasLength(2));
      expect(paths.any((p) => p.contains('..')), false);
    },
  );
  test(
    'parallel expired-token requests refresh once and persist rotated token',
    () async {
      final store = ProviderCredentialsStore();
      await store.write(profile.id, {
        'accessToken': 'expired',
        'refreshToken': 'old-refresh',
        'clientId': 'app',
        'expiresAt': '2020-01-01T00:00:00Z',
      });
      var refreshes = 0;
      final tokenAdapter = CloudAdapter((options, bytes) async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return json({
          'access_token': 'new-access',
          'refresh_token': 'rotated',
          'expires_in': 14400,
          'token_type': 'bearer',
        });
      });
      final apiAdapter = CloudAdapter((options, bytes) async {
        expect(options.headers['Authorization'], 'Bearer new-access');
        return json({'email': 'user@example.com'});
      });
      DropboxBackupTarget target() => DropboxBackupTarget(
        profile: profile,
        credentials: const {},
        store: store,
        oauth: DropboxOAuth(dio: Dio()..httpClientAdapter = tokenAdapter),
        dio: Dio()..httpClientAdapter = apiAdapter,
      );
      await Future.wait([target().accountEmail(), target().accountEmail()]);
      expect(refreshes, 1);
      expect((await store.read(profile.id))['refreshToken'], 'rotated');
    },
  );
  test('truncated remote backup is rejected before restore', () async {
    final adapter = CloudAdapter((options, bytes) async {
      if (options.path.endsWith('/list_folder')) {
        return json({
          'entries': [
            {
              '.tag': 'file',
              'name': 'raha-a.rahabackup',
              'server_modified': '2026-01-01T00:00:00Z',
              'size': 3,
              'id': 'id:a',
              'rev': 'a',
            },
          ],
          'has_more': false,
        });
      }
      return ResponseBody.fromBytes([1], 200);
    });
    final target = DropboxBackupTarget(
      profile: profile,
      credentials: fresh(),
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(target.downloadLatest(), throwsStateError);
  });
}
