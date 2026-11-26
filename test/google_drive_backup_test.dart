import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/providers/backup_target.dart';
import 'package:raha_life/core/sync/providers/google_drive_backup_target.dart';
import 'package:raha_life/core/sync/providers/oauth_pkce.dart';

import 'cloud_oauth_test.dart' show CloudAdapter, json;

const _profile = SyncConnectionProfile(
  id: 'oauth-validation',
  name: 'Google Drive',
  kind: SyncProviderKind.googleDrive,
  purpose: SyncTargetPurpose.backup,
);
final _backup = BackupObject(
  bytes: Uint8List.fromList([2, 4, 6]),
  fileName: 'test.rahabackup',
  createdAtUtc: DateTime.utc(2026),
);

GoogleDriveBackupTarget _target(CloudAdapter adapter) => GoogleDriveBackupTarget(
  profile: _profile,
  credentials: {
    'accessToken': 'test-token',
    'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
  },
  dio: Dio()..httpClientAdapter = adapter,
);

void main() {
  test('Google requests app data only and exchanges a one-use PKCE verifier', () async {
    final redirect = Uri.parse('http://127.0.0.1:43829/callback');
    final attempt = OAuthPkceAttempt(redirectUri: redirect);
    final adapter = CloudAdapter((request, bytes) async {
      expect(request.uri.host, 'oauth2.googleapis.com');
      final form = Uri.splitQueryString(utf8.decode(bytes));
      expect(form['code_verifier'], attempt.verifier);
      expect(form.containsKey('client_secret'), isFalse);
      return json({'access_token': 'access', 'token_type': 'Bearer', 'expires_in': 3600});
    });
    final oauth = GoogleDriveOAuth(dio: Dio()..httpClientAdapter = adapter);
    final authorization = oauth.authorize(attempt, 'desktop-id');
    expect(authorization.queryParameters['scope'],
        'https://www.googleapis.com/auth/drive.appdata');
    expect(authorization.queryParameters['code_challenge_method'], 'S256');
    final credentials = await oauth.exchange(
      attempt: attempt, appId: 'desktop-id',
      callback: redirect.replace(queryParameters: {'code': 'code', 'state': attempt.state}),
    );
    expect(credentials['accessToken'], 'access');
  });

  test('Drive stores encrypted bytes as an app-data object and verifies downloads', () async {
    String? uploadedName;
    final adapter = CloudAdapter((request, bytes) async {
      expect(request.uri.host, 'www.googleapis.com');
      expect(request.followRedirects, isFalse);
      expect(request.headers['Authorization'], 'Bearer test-token');
      if (request.method == 'POST') {
        final metadata = jsonDecode(utf8.decode(bytes)) as Map;
        expect(metadata['parents'], ['appDataFolder']);
        uploadedName = metadata['name'] as String;
        return ResponseBody.fromString('', 200, headers: {
          'location': ['https://www.googleapis.com/upload/drive/v3/files?upload_id=example'],
        });
      }
      if (request.method == 'PUT') {
        expect(bytes, _backup.bytes);
        return json({'name': uploadedName, 'size': '3'});
      }
      if (request.uri.queryParameters['alt'] == 'media') {
        expect(request.uri.path, '/drive/v3/files/file_1');
        return ResponseBody.fromBytes([2, 4, 6], 200);
      }
      expect(request.uri.queryParameters['spaces'], 'appDataFolder');
      return json({
        'files': [{
          'name': uploadedName, 'size': '3', 'id': 'file_1', 'createdTime': '2026-01-01T00:00:00Z',
        }],
      });
    });
    final target = _target(adapter);
    await target.upload(_backup);
    final result = await target.downloadLatest();
    expect(result!.bytes, _backup.bytes);
    expect(result.fileName, uploadedName);
  });

  test('Drive rejects a resumable session on another host before sending bytes', () async {
    final adapter = CloudAdapter((request, _) async => ResponseBody.fromString('', 200, headers: {
      'location': ['https://example.test/upload/drive/v3/files?upload_id=example'],
    }));
    await expectLater(_target(adapter).upload(_backup), throwsStateError);
    expect(adapter.calls, hasLength(1));
  });
}
