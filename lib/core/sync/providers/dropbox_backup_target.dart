import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'backup_target.dart';
import 'oauth_pkce.dart';
import 'provider_credentials.dart';

/// The Dropbox application must be registered with App Folder access.
/// Uploads immutable encrypted backup files, never the active SQLite database.
class DropboxBackupTarget implements BackupTarget {
  DropboxBackupTarget({
    required this.profile,
    required this.credentials,
    Dio? dio,
    ProviderCredentialsStore? store,
    DropboxOAuth? oauth,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 90),
               sendTimeout: const Duration(seconds: 90),
             ),
           ),
       _store = store ?? ProviderCredentialsStore(),
       _oauth = oauth ?? DropboxOAuth();
  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;
  final ProviderCredentialsStore _store;
  final DropboxOAuth _oauth;
  static final Map<String, Future<String>> _refreshes = {};
  static const maxBytes =
      140 * 1024 * 1024; // Below Dropbox's single-upload limit.
  @override
  SyncProviderKind get kind => SyncProviderKind.dropbox;
  @override
  Set<SyncProviderCapability> get capabilities => {
    SyncProviderCapability.automaticBackup,
    SyncProviderCapability.files,
  };

  Future<String> _token() async {
    final current = _refreshes[profile.id];
    if (current != null) return current;
    final future = _loadToken();
    _refreshes[profile.id] = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshes[profile.id], future)) {
        _refreshes.remove(profile.id);
      }
    }
  }

  Future<String> _loadToken() async {
    // Always reload: another target may have rotated the refresh token.
    final saved = await _store.read(profile.id);
    final values = saved.isEmpty ? credentials : saved;
    final expires = DateTime.tryParse(values['expiresAt'] ?? '');
    final access = values['accessToken'] ?? '';
    if (access.isNotEmpty &&
        expires != null &&
        expires.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 2)),
        )) {
      return access;
    }
    final refresh = values['refreshToken'] ?? '';
    final client = values['clientId'] ?? '';
    if (refresh.isEmpty || client.isEmpty) {
      throw StateError('dropbox_reconnect_required');
    }
    final result = await _oauth.refresh(refreshToken: refresh, appId: client);
    // Do not resurrect an account removed while the refresh request was running.
    final latest = await _store.read(profile.id);
    if (saved.isNotEmpty && jsonEncode(latest) != jsonEncode(saved)) {
      throw StateError('dropbox_credentials_changed');
    }
    await _store.write(profile.id, {...values, ...result});
    return result['accessToken']!;
  }

  Future<Map<String, dynamic>> _rpc(String route, Object? body) async {
    try {
      final result = await _dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/2/$route',
        data: body == null ? 'null' : jsonEncode(body),
        options: Options(
          followRedirects: false,
          contentType: Headers.jsonContentType,
          headers: {'Authorization': 'Bearer ${await _token()}'},
          validateStatus: (s) => s == 200,
        ),
      );
      return result.data!;
    } catch (_) {
      throw StateError('dropbox_request_failed');
    }
  }

  Future<String> accountEmail() async {
    final account = await _rpc('users/get_current_account', null);
    return account['email'] as String? ?? '';
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    try {
      await accountEmail();
      return const BackupTargetTestResult(
        success: true,
        message: 'Dropbox connected.',
      );
    } catch (_) {
      return const BackupTargetTestResult(
        success: false,
        message: 'Dropbox connection failed. Reconnect or check your network.',
      );
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    if (object.bytes.isEmpty || object.bytes.length > maxBytes) {
      throw StateError('dropbox_backup_size_limit');
    }
    // UUID prevents two devices from overwriting each other's backups.
    final name =
        'raha-${object.createdAtUtc.toUtc().millisecondsSinceEpoch}-${const Uuid().v4()}.rahabackup';
    try {
      await _dio.post<Object?>(
        'https://content.dropboxapi.com/2/files/upload',
        data: Stream.value(object.bytes),
        options: Options(
          followRedirects: false,
          contentType: 'application/octet-stream',
          headers: {
            'Authorization': 'Bearer ${await _token()}',
            'Content-Length': object.bytes.length,
            'Dropbox-API-Arg': jsonEncode({
              'path': '/$name',
              'mode': 'add',
              'autorename': false,
              'mute': true,
              'strict_conflict': true,
            }),
          },
          validateStatus: (s) => s == 200,
        ),
      );
    } catch (_) {
      throw StateError('dropbox_upload_failed');
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    var page = await _rpc('files/list_folder', {
      'path': '',
      'recursive': false,
    });
    Map<String, dynamic>? latest;
    DateTime? newest;
    final cursors = <String>{};
    while (true) {
      for (final value in page['entries'] as List) {
        final entry = Map<String, dynamic>.from(value as Map);
        final name = entry['name'] as String? ?? '';
        final modified = DateTime.tryParse(
          entry['server_modified'] as String? ?? '',
        );
        if (entry['.tag'] == 'file' &&
            name.startsWith('raha-') &&
            name.endsWith('.rahabackup') &&
            modified != null &&
            (newest == null || modified.isAfter(newest))) {
          latest = entry;
          newest = modified;
        }
      }
      if (page['has_more'] != true) break;
      final cursor = page['cursor'] as String;
      if (!cursors.add(cursor)) throw StateError('dropbox_repeated_cursor');
      page = await _rpc('files/list_folder/continue', {'cursor': cursor});
    }
    if (latest == null) return null;
    final size = latest['size'] as num;
    if (size <= 0 || size > maxBytes) {
      throw StateError('dropbox_backup_size_limit');
    }
    try {
      final response = await _dio.post<ResponseBody>(
        'https://content.dropboxapi.com/2/files/download',
        options: Options(
          followRedirects: false,
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${await _token()}',
            'Dropbox-API-Arg': jsonEncode({
              'path': latest['id'],
              'rev': latest['rev'],
            }),
          },
          validateStatus: (s) => s == 200,
        ),
      );
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.data!.stream) {
        if (builder.length + chunk.length > maxBytes) {
          throw StateError('dropbox_backup_size_limit');
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.length != size) throw StateError('dropbox_incomplete_download');
      return BackupObject(
        bytes: bytes,
        fileName: latest['name'] as String,
        createdAtUtc: newest!.toUtc(),
      );
    } catch (_) {
      throw StateError('dropbox_download_failed');
    }
  }
}
