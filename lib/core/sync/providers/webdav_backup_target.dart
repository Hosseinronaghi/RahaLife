import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'backup_target.dart';

class WebDavBackupTarget implements BackupTarget {
  WebDavBackupTarget({
    required this.profile,
    required this.credentials,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;

  @override
  SyncProviderKind get kind => profile.kind;

  @override
  Set<SyncProviderCapability> get capabilities => <SyncProviderCapability>{
    SyncProviderCapability.automaticBackup,
    SyncProviderCapability.files,
    SyncProviderCapability.selfHosted,
  };

  String get _baseUrl =>
      (profile.config['baseUrl'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');
  String get _remotePath => (profile.config['remotePath'] ?? 'RahaLife').trim();

  Map<String, String> get _headers {
    final token = credentials['token'];
    if (token != null && token.isNotEmpty) {
      return <String, String>{'Authorization': 'Bearer $token'};
    }
    final username =
        credentials['username'] ?? profile.config['username'] ?? '';
    final password = credentials['password'] ?? '';
    if (username.isEmpty && password.isEmpty) return const <String, String>{};
    return <String, String>{
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    };
  }

  String _urlFor(String fileName) {
    final segments = <String>[
      ..._remotePath.split('/').where((part) => part.trim().isNotEmpty),
      fileName,
    ];
    final encoded = segments.map(Uri.encodeComponent).join('/');
    return '$_baseUrl/$encoded';
  }

  String _directoryUrl() {
    final segments = _remotePath
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return segments.isEmpty ? _baseUrl : '$_baseUrl/$segments';
  }

  Future<void> _ensureDirectory() async {
    if (_baseUrl.isEmpty) throw const FormatException('WebDAV URL is empty.');
    final parts = _remotePath
        .split('/')
        .where((part) => part.trim().isNotEmpty);
    var current = _baseUrl;
    for (final part in parts) {
      current = '$current/${Uri.encodeComponent(part)}';
      final response = await _dio.request<Object?>(
        current,
        options: Options(
          method: 'MKCOL',
          headers: _headers,
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 400 && status != 405 && status != 409) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'WebDAV MKCOL failed with HTTP $status',
        );
      }
    }
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    try {
      await _ensureDirectory();
      final response = await _dio.request<Object?>(
        _directoryUrl(),
        options: Options(
          method: 'PROPFIND',
          headers: <String, String>{..._headers, 'Depth': '0'},
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      final success = status >= 200 && status < 400;
      return BackupTargetTestResult(
        success: success,
        message: success
            ? 'WebDAV connection is ready.'
            : 'WebDAV returned HTTP $status.',
      );
    } catch (error) {
      return BackupTargetTestResult(success: false, message: error.toString());
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    await _ensureDirectory();
    final response = await _dio.put<Object?>(
      _urlFor('latest.rahabackup'),
      data: object.bytes,
      options: Options(
        headers: <String, String>{
          ..._headers,
          Headers.contentTypeHeader: 'application/octet-stream',
        },
        contentType: 'application/octet-stream',
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'WebDAV upload failed with HTTP $status',
      );
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final response = await _dio.get<List<int>>(
      _urlFor('latest.rahabackup'),
      options: Options(
        headers: _headers,
        responseType: ResponseType.bytes,
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode == 404) return null;
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'WebDAV download failed with HTTP $status',
      );
    }
    return BackupObject(
      bytes: Uint8List.fromList(response.data!),
      fileName: 'latest.rahabackup',
      createdAtUtc: DateTime.now().toUtc(),
    );
  }
}
