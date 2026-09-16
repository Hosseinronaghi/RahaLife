import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'backup_target.dart';

class CustomHttpBackupTarget implements BackupTarget {
  CustomHttpBackupTarget({
    required this.profile,
    required this.credentials,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;

  String get _baseUrl =>
      (profile.config['baseUrl'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get _headers {
    final token = credentials['token'] ?? '';
    return <String, String>{
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      'X-Raha-Client': 'Raha-Life/0.7.0',
    };
  }

  @override
  SyncProviderKind get kind => profile.kind;

  @override
  Set<SyncProviderCapability> get capabilities => <SyncProviderCapability>{
    SyncProviderCapability.automaticBackup,
    SyncProviderCapability.files,
    SyncProviderCapability.selfHosted,
    if (profile.kind == SyncProviderKind.rahaServer ||
        profile.kind == SyncProviderKind.customHttp)
      SyncProviderCapability.recordSync,
  };

  @override
  Future<BackupTargetTestResult> testConnection() async {
    if (_baseUrl.isEmpty) {
      return const BackupTargetTestResult(
        success: false,
        message: 'Server URL is empty.',
      );
    }
    try {
      final response = await _dio.get<Object?>(
        '$_baseUrl/health',
        options: Options(headers: _headers, validateStatus: (_) => true),
      );
      final status = response.statusCode ?? 0;
      return BackupTargetTestResult(
        success: status >= 200 && status < 300,
        message: status >= 200 && status < 300
            ? 'Server connection is ready.'
            : 'Server returned HTTP $status.',
      );
    } catch (error) {
      return BackupTargetTestResult(success: false, message: error.toString());
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    final response = await _dio.put<Object?>(
      '$_baseUrl/v1/backup/latest',
      data: object.bytes,
      options: Options(
        headers: <String, String>{
          ..._headers,
          'X-Raha-Backup-Name': object.fileName,
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
        message: 'Server upload failed with HTTP $status',
      );
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final response = await _dio.get<List<int>>(
      '$_baseUrl/v1/backup/latest',
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
        message: 'Server download failed with HTTP $status',
      );
    }
    return BackupObject(
      bytes: Uint8List.fromList(response.data!),
      fileName: 'latest.rahabackup',
      createdAtUtc: DateTime.now().toUtc(),
    );
  }
}
