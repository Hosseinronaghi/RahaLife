import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'backup_target.dart';
import 'oauth_pkce.dart';
import 'provider_credentials.dart';

class GoogleDriveBackupTarget implements BackupTarget {
  GoogleDriveBackupTarget({
    required this.profile,
    required this.credentials,
    Dio? dio,
    ProviderCredentialsStore? store,
    GoogleDriveOAuth? oauth,
  }) : _dio = dio ?? Dio(BaseOptions(
         connectTimeout: const Duration(seconds: 15),
         receiveTimeout: const Duration(seconds: 90),
         sendTimeout: const Duration(seconds: 90),
       )),
       _store = store ?? ProviderCredentialsStore(),
       _oauth = oauth ?? GoogleDriveOAuth();

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;
  final ProviderCredentialsStore _store;
  final GoogleDriveOAuth _oauth;
  static final _refreshes = <String, Future<String>>{};
  static const _host = 'www.googleapis.com';
  static const _files = '/drive/v3/files';
  static const _upload = '/upload/drive/v3/files';
  static const _maxBytes = 140 * 1024 * 1024;

  @override
  SyncProviderKind get kind => SyncProviderKind.googleDrive;

  @override
  Set<SyncProviderCapability> get capabilities => {
    SyncProviderCapability.automaticBackup,
    SyncProviderCapability.files,
  };

  Future<String> _token() async {
    final current = _refreshes[profile.id];
    if (current != null) return current;
    final pending = _loadToken();
    _refreshes[profile.id] = pending;
    try {
      return await pending;
    } finally {
      if (identical(_refreshes[profile.id], pending)) {
        _refreshes.remove(profile.id);
      }
    }
  }

  Future<String> _loadToken() async {
    final temporary = profile.id == 'oauth-validation';
    final values = temporary ? credentials : await _store.read(profile.id);
    final expires = DateTime.tryParse(values['expiresAt'] ?? '');
    final token = values['accessToken'] ?? '';
    if (token.isNotEmpty &&
        expires != null &&
        expires.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return token;
    }
    final client = values['clientId'] ?? '';
    final refresh = values['refreshToken'] ?? '';
    if (temporary || client.isEmpty || refresh.isEmpty) {
      throw StateError('google_drive_reconnect_required');
    }
    final fresh = await _oauth.refresh(refreshToken: refresh, appId: client);
    if (!await _store.replaceIfUnchanged(
      profile.id,
      expected: values,
      replacement: {...values, ...fresh},
    )) {
      throw StateError('google_drive_credentials_changed');
    }
    return fresh['accessToken']!;
  }

  Future<Response<T>> _request<T>(
    String method,
    Uri uri, {
    Object? data,
    Map<String, Object> headers = const {},
    ResponseType? responseType,
  }) async {
    if (uri.scheme != 'https' || uri.host != _host ||
        uri.hasPort || uri.userInfo.isNotEmpty || uri.hasFragment ||
        (uri.path != _files && uri.path != _upload &&
            !uri.path.startsWith('$_files/'))) {
      throw StateError('google_drive_untrusted_destination');
    }
    try {
      return await _dio.requestUri<T>(
        uri, data: data,
        options: Options(
          method: method,
          headers: {...headers, 'Authorization': 'Bearer ${await _token()}'},
          followRedirects: false,
          responseType: responseType,
          validateStatus: (code) => code == 200 || code == 201,
        ),
      );
    } catch (_) {
      throw StateError('google_drive_request_failed');
    }
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    try {
      await _request<Map<String, dynamic>>(
        'GET', Uri.https(_host, _files, {
          'spaces': 'appDataFolder', 'pageSize': '1', 'fields': 'files(id)',
        }),
      );
      return const BackupTargetTestResult(
        success: true, message: 'Google Drive application storage is available.',
      );
    } catch (_) {
      return const BackupTargetTestResult(
        success: false, message: 'Reconnect Google Drive and check access.',
      );
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    final size = object.bytes.length;
    if (size == 0 || size > _maxBytes) throw StateError('google_drive_backup_size_limit');
    final stamp = object.createdAtUtc.millisecondsSinceEpoch;
    final name = 'raha-$stamp-${const Uuid().v4()}.rahabackup';
    final session = await _request<String>(
      'POST',
      Uri.https(_host, _upload, {'uploadType': 'resumable', 'fields': 'id,name,size'}),
      data: {
        'name': name,
        'parents': ['appDataFolder'],
        'mimeType': 'application/octet-stream',
      },
      headers: {
        'Content-Type': 'application/json',
        'X-Upload-Content-Type': 'application/octet-stream',
        'X-Upload-Content-Length': size,
      },
      responseType: ResponseType.plain,
    );
    final uri = Uri.tryParse(session.headers.value('location') ?? '');
    if (uri == null || uri.path != _upload ||
        (uri.queryParameters['upload_id']?.isEmpty ?? true)) {
      throw StateError('google_drive_invalid_upload_session');
    }
    final done = await _request<Map<String, dynamic>>(
      'PUT', uri,
      data: Stream.value(object.bytes),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': size,
        'Content-Range': 'bytes 0-${size - 1}/$size',
      },
    );
    final metadata = done.data;
    if (metadata?['name'] != name || int.tryParse('${metadata?['size']}') != size) {
      throw StateError('google_drive_incomplete_upload');
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    String? pageToken;
    final seen = <String>{};
    for (var page = 0; page < 100; page++) {
      final response = await _request<Map<String, dynamic>>(
        'GET', Uri.https(_host, _files, {
          'spaces': 'appDataFolder',
          'q': "trashed = false and name contains 'raha-'",
          'orderBy': 'createdTime desc',
          'pageSize': '100',
          'fields': 'nextPageToken,files(id,name,size,createdTime)',
          'pageToken': ?pageToken,
        }),
      );
      final entries = response.data?['files'];
      if (entries is! List) throw StateError('google_drive_invalid_file_list');
      for (final item in entries.whereType<Map<String, dynamic>>()) {
        final name = item['name'];
        if (name is String && name.startsWith('raha-') &&
            name.endsWith('.rahabackup')) {
          return _download(item, name);
        }
      }
      final cursor = response.data?['nextPageToken'];
      if (cursor == null) return null;
      if (cursor is! String || cursor.isEmpty || !seen.add(cursor)) {
        throw StateError('google_drive_invalid_pagination');
      }
      pageToken = cursor;
    }
    throw StateError('google_drive_pagination_limit');
  }

  Future<BackupObject> _download(Map<String, dynamic> item, String name) async {
    final id = item['id'];
    final size = int.tryParse('${item['size']}');
    final date = DateTime.tryParse('${item['createdTime']}');
    if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
        size == null || size <= 0 || size > _maxBytes || date == null) {
      throw StateError('google_drive_invalid_metadata');
    }
    final response = await _request<ResponseBody>(
      'GET', Uri.https(_host, '$_files/$id', {'alt': 'media'}),
      responseType: ResponseType.stream,
    );
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.data!.stream) {
      if (bytes.length + chunk.length > size) {
        throw StateError('google_drive_download_size_limit');
      }
      bytes.add(chunk);
    }
    if (bytes.length != size) throw StateError('google_drive_incomplete_download');
    return BackupObject(bytes: bytes.takeBytes(), fileName: name, createdAtUtc: date.toUtc());
  }
}
