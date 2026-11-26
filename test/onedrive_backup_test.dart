import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/providers/backup_target.dart';
import 'package:raha_life/core/sync/providers/oauth_pkce.dart';
import 'package:raha_life/core/sync/providers/onedrive_backup_target.dart';
import 'package:raha_life/core/sync/providers/provider_credentials.dart';

import 'cloud_oauth_test.dart' show CloudAdapter, json;

const _profile = SyncConnectionProfile(
  id: 'microsoft-test',
  name: 'OneDrive',
  kind: SyncProviderKind.oneDrive,
  purpose: SyncTargetPurpose.backup,
);
const _appFolder = '/v1.0/me/drive/special/approot';
const _children = '/v1.0/me/drive/items/folder/children';

Map<String, String> _credentials() => {
  'accessToken': 'disposable-test-token',
  'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
};
Map<String, Object> _item(String id, String date) => {
  'id': id,
  'name': 'raha-$id.rahabackup',
  'file': <String, Object>{},
  'size': 3,
  'lastModifiedDateTime': date,
  'eTag': 'revision',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('Microsoft authorization uses PKCE and only app-folder access', () async {
    final redirect = Uri.parse('http://127.0.0.1:43829/callback');
    final attempt = OAuthPkceAttempt(redirectUri: redirect);
    final adapter = CloudAdapter((request, data) async {
      expect(request.uri.host, 'login.microsoftonline.com');
      expect(request.followRedirects, false);
      final form = Uri.splitQueryString(utf8.decode(data));
      expect(form['code_verifier'], attempt.verifier);
      expect(form['redirect_uri'], '$redirect');
      expect(form, isNot(contains('client_secret')));
      return json({
        'access_token': 'temporary-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
      });
    });
    final oauth = OneDriveOAuth(dio: Dio()..httpClientAdapter = adapter);
    final request = oauth.authorize(attempt, 'client');
    expect(request.host, 'login.microsoftonline.com');
    expect(request.queryParameters['code_challenge_method'], 'S256');
    expect(request.queryParameters['scope'],
        'offline_access https://graph.microsoft.com/Files.ReadWrite.AppFolder');
    expect(request.toString(), isNot(contains(attempt.verifier)));
    final result = await oauth.exchange(
      attempt: attempt,
      callback: redirect.replace(
        queryParameters: {'code': 'one-use', 'state': attempt.state},
      ),
      appId: 'client',
    );
    expect(result['accessToken'], 'temporary-token');
  });

  test('backup uploads unique objects and selects newest across pages', () async {
    final store = ProviderCredentialsStore();
    await store.write(_profile.id, _credentials());
    final names = <String>[];
    final adapter = CloudAdapter((request, body) async {
      expect(request.followRedirects, false);
      if (request.uri.host == 'tenant.sharepoint.com') {
        expect(request.headers['Authorization'], isNull);
        return ResponseBody.fromBytes([1, 2, 3], 200);
      }
      expect(request.uri.host, 'graph.microsoft.com');
      expect(request.headers['Authorization'], 'Bearer disposable-test-token');
      if (request.uri.path == _appFolder) return json({'id': 'folder', 'folder': {}});
      if (request.method == 'PUT') {
        expect(body, [1, 2, 3]);
        final name = request.uri.path.split('/')[6].replaceAll(':', '');
        expect(name, startsWith('raha-'));
        names.add(name);
        return json({'name': name, 'size': 3}, 201);
      }
      if (request.uri.path == _children) {
        return request.uri.hasQuery
            ? json({'value': [_item('new', '2026-09-02T12:00:00Z')]})
            : json({
                'value': [_item('old', '2026-09-01T12:00:00Z')],
                '@odata.nextLink': 'https://graph.microsoft.com$_children?next=1',
              });
      }
      expect(request.uri.path, '/v1.0/me/drive/items/new');
      return json({
        'eTag': 'revision',
        'size': 3,
        '@microsoft.graph.downloadUrl': 'https://tenant.sharepoint.com/file?temporary=1',
      });
    });
    final target = OneDriveBackupTarget(
      profile: _profile,
      credentials: const {},
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
    );
    expect((await target.testConnection()).success, isTrue);
    final backup = BackupObject(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'test.rahabackup',
      createdAtUtc: DateTime.utc(2026),
    );
    await target.upload(backup);
    await target.upload(backup);
    expect(names.toSet(), hasLength(2));
    final downloaded = await target.downloadLatest();
    expect(downloaded!.fileName, 'raha-new.rahabackup');
    expect(downloaded.bytes, [1, 2, 3]);
  });

  test('unexpected pagination hosts are rejected before a request', () async {
    final store = ProviderCredentialsStore();
    await store.write(_profile.id, _credentials());
    final adapter = CloudAdapter((request, _) async {
      expect(request.uri.host, 'graph.microsoft.com');
      return request.uri.path == _appFolder
          ? json({'id': 'folder', 'folder': {}})
          : json({'value': [], '@odata.nextLink': 'https://example.test/page'});
    });
    final target = OneDriveBackupTarget(
      profile: _profile,
      credentials: const {},
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(target.downloadLatest(), throwsStateError);
    expect(adapter.calls, hasLength(2));
  });

  test('removed cloud credentials cannot be restored by a pending refresh', () async {
    final store = ProviderCredentialsStore();
    final values = _credentials();
    await store.write(_profile.id, values);
    await store.delete(_profile.id);
    expect(await store.replaceIfUnchanged(
      _profile.id,
      expected: values,
      replacement: {...values, 'accessToken': 'rotated'},
    ), isFalse);
    expect(await store.read(_profile.id), isEmpty);
  });
}
