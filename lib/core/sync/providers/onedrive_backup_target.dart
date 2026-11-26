import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'backup_target.dart';
import 'oauth_pkce.dart';
import 'provider_credentials.dart';

/// Stores encrypted, immutable backup files inside Microsoft's app folder.
class OneDriveBackupTarget implements BackupTarget {
  OneDriveBackupTarget({
    required this.profile,
    required this.credentials,
    Dio? dio,
    ProviderCredentialsStore? store,
    OneDriveOAuth? oauth,
  }) : _dio = dio ?? Dio(BaseOptions(
         connectTimeout: const Duration(seconds: 15),
         receiveTimeout: const Duration(seconds: 90),
         sendTimeout: const Duration(seconds: 90),
       )),
       _store = store ?? ProviderCredentialsStore(),
       _oauth = oauth ?? OneDriveOAuth();

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;
  final ProviderCredentialsStore _store;
  final OneDriveOAuth _oauth;
  static final Map<String, Future<String>> _refreshes = {};
  static const _maxBytes = 140 * 1024 * 1024;
  static const _root = '/v1.0/me/drive/special/approot';

  @override
  SyncProviderKind get kind => SyncProviderKind.oneDrive;

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
    // Validation runs before the profile is added to secure storage.
    final temporary = profile.id == 'oauth-validation';
    final values = temporary ? credentials : await _store.read(profile.id);
    final expires = DateTime.tryParse(values['expiresAt'] ?? '');
    final token = values['accessToken'] ?? '';
    if (token.isNotEmpty &&
        expires != null &&
        expires.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 2)))) {
      return token;
    }
    final client = values['clientId'] ?? '';
    final refresh = values['refreshToken'] ?? '';
    if (temporary || client.isEmpty || refresh.isEmpty) {
      throw StateError('onedrive_reconnect_required');
    }
    final fresh = await _oauth.refresh(refreshToken: refresh, appId: client);
    if (!await _store.replaceIfUnchanged(
      profile.id,
      expected: values,
      replacement: {...values, ...fresh},
    )) {
      throw StateError('onedrive_credentials_changed');
    }
    return fresh['accessToken']!;
  }

  static bool _graphUrl(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'graph.microsoft.com' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment &&
      uri.path.startsWith('/v1.0/');

  static bool _downloadUrl(Uri uri) =>
      uri.scheme == 'https' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment &&
      [
        '1drv.com',
        'sharepoint.com',
        'onedrive.com',
        'storage.live.com',
      ].any((domain) => uri.host == domain || uri.host.endsWith('.$domain'));

  Future<Map<String, dynamic>> _graph(
    Uri uri, {
    Uint8List? upload,
  }) async {
    if (!_graphUrl(uri)) throw StateError('onedrive_untrusted_graph_url');
    try {
      final response = await _dio.requestUri<Map<String, dynamic>>(
        uri,
        data: upload == null ? null : Stream.value(upload),
        options: Options(
          method: upload == null ? 'GET' : 'PUT',
          followRedirects: false,
          headers: {
            'Authorization': 'Bearer ${await _token()}',
            if (upload != null) 'Content-Length': upload.length,
          },
          contentType: upload == null ? null : 'application/octet-stream',
          validateStatus: (code) => code == 200 || code == 201,
        ),
      );
      return response.data!;
    } catch (_) {
      // Don't leak bearer headers or preauthenticated download URLs.
      throw StateError('onedrive_graph_request_failed');
    }
  }

  Future<String> _folderId() async {
    final result = await _graph(Uri.https('graph.microsoft.com', _root));
    final id = result['id'];
    if (result['folder'] is! Map || id is! String || id.isEmpty) {
      throw StateError('onedrive_app_folder_missing');
    }
    return id;
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    try {
      await _folderId();
      return const BackupTargetTestResult(
        success: true, message: 'OneDrive app folder is available.',
      );
    } catch (_) {
      return const BackupTargetTestResult(
        success: false, message: 'Reconnect OneDrive or check the app folder permission.',
      );
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    if (object.bytes.isEmpty || object.bytes.length > _maxBytes) {
      throw StateError('onedrive_backup_size_limit');
    }
    final folder = Uri.encodeComponent(await _folderId());
    final stamp = object.createdAtUtc.millisecondsSinceEpoch;
    final name = 'raha-$stamp-${const Uuid().v4()}.rahabackup';
    final result = await _graph(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$folder:/$name:/content'),
      upload: object.bytes,
    );
    if (result['name'] != name || result['size'] != object.bytes.length) {
      throw StateError('onedrive_incomplete_upload');
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final folder = Uri.encodeComponent(await _folderId());
    Uri? next = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$folder/children');
    Map<String, dynamic>? latest;
    DateTime? newest;
    final visited = <Uri>{};
    while (next != null) {
      if (visited.length >= 500 || !visited.add(next)) {
        throw StateError('onedrive_invalid_pagination');
      }
      final page = await _graph(next);
      final entries = page['value'];
      if (entries is! List) throw StateError('onedrive_invalid_list');
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final name = entry['name'];
        final modified = DateTime.tryParse('${entry['lastModifiedDateTime']}');
        if (entry['file'] is Map &&
            name is String && name.startsWith('raha-') &&
            name.endsWith('.rahabackup') && modified != null &&
            (newest == null || modified.isAfter(newest))) {
          newest = modified;
          latest = entry;
        }
      }
      final link = page['@odata.nextLink'];
      next = link == null ? null : Uri.parse(link as String);
    }
    if (latest == null) return null;
    final id = latest['id'];
    final revision = latest['eTag'];
    final size = latest['size'];
    if (id is! String || id.isEmpty || revision is! String || revision.isEmpty ||
        size is! int || size <= 0 || size > _maxBytes) {
      throw StateError('onedrive_invalid_file_metadata');
    }
    try {
      final path = '/v1.0/me/drive/items/${Uri.encodeComponent(id)}';
      final item = await _graph(
        Uri.parse('https://graph.microsoft.com$path').replace(queryParameters: {
          '\$select': 'id,size,eTag,@microsoft.graph.downloadUrl',
        }),
      );
      if (item['size'] != size || item['eTag'] != revision) {
        throw StateError('onedrive_backup_changed');
      }
      final uri = Uri.parse(item['@microsoft.graph.downloadUrl'] as String);
      if (!_downloadUrl(uri)) throw StateError('onedrive_download_host_untrusted');
      final response = await _dio.getUri<ResponseBody>(
        uri,
        options: Options(
          followRedirects: false,
          responseType: ResponseType.stream,
          headers: {'Authorization': null},
          validateStatus: (code) => code == 200,
        ),
      );
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.data!.stream) {
        if (bytes.length + chunk.length > size) {
          throw StateError('onedrive_download_size_limit');
        }
        bytes.add(chunk);
      }
      if (bytes.length != size) throw StateError('onedrive_incomplete_download');
      return BackupObject(
        bytes: bytes.takeBytes(),
        fileName: latest['name'] as String,
        createdAtUtc: newest!.toUtc(),
      );
    } catch (_) {
      throw StateError('onedrive_download_failed');
    }
  }
}
