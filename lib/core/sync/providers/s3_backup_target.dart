import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'backup_target.dart';

class S3BackupTarget implements BackupTarget {
  S3BackupTarget({required this.profile, required this.credentials, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              followRedirects: false,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
            ),
          );

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;
  final Dio _dio;

  String get _endpoint =>
      (profile.config['endpoint'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');
  String get _bucket => (profile.config['bucket'] ?? '').trim();
  String get _region => (profile.config['region'] ?? 'us-east-1').trim();
  String get _prefix => (profile.config['prefix'] ?? 'RahaLife').trim();
  bool get _pathStyle => profile.config['pathStyle'] != 'false';
  String get _accessKey => credentials['accessKey'] ?? '';
  String get _secretKey => credentials['secretKey'] ?? '';
  String get _sessionToken => credentials['sessionToken'] ?? '';

  @override
  SyncProviderKind get kind => SyncProviderKind.s3;

  @override
  Set<SyncProviderCapability> get capabilities =>
      const <SyncProviderCapability>{
        SyncProviderCapability.automaticBackup,
        SyncProviderCapability.files,
        SyncProviderCapability.selfHosted,
      };

  Uri _objectUri(String objectName) {
    final base = Uri.parse(_endpoint);
    final objectSegments = <String>[
      ..._prefix.split('/').where((part) => part.isNotEmpty),
      objectName,
    ];
    if (_pathStyle) {
      return base.replace(
        pathSegments: <String>[
          ...base.pathSegments.where((part) => part.isNotEmpty),
          _bucket,
          ...objectSegments,
        ],
      );
    }
    return base.replace(
      host: '$_bucket.${base.host}',
      pathSegments: <String>[
        ...base.pathSegments.where((part) => part.isNotEmpty),
        ...objectSegments,
      ],
    );
  }

  static String _hexDigest(Digest digest) => digest.toString();

  static List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  static String _awsEncode(String value) {
    const unreserved =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~';
    final buffer = StringBuffer();
    for (final byte in utf8.encode(value)) {
      final character = String.fromCharCode(byte);
      if (unreserved.contains(character)) {
        buffer.write(character);
      } else {
        buffer
          ..write('%')
          ..write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }
    return buffer.toString();
  }

  static String _canonicalPath(Uri uri) {
    final encoded = uri.pathSegments.map(_awsEncode).join('/');
    return encoded.isEmpty ? '/' : '/$encoded';
  }

  static String _amzDate(DateTime now) {
    final utc = now.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _dateStamp(DateTime now) => _amzDate(now).substring(0, 8);

  Map<String, String> _signedHeaders({
    required String method,
    required Uri uri,
    required Uint8List body,
    required DateTime now,
  }) {
    if (_accessKey.isEmpty || _secretKey.isEmpty) {
      throw const FormatException('S3 access key and secret key are required.');
    }
    final payloadHash = _hexDigest(sha256.convert(body));
    final amzDate = _amzDate(now);
    final dateStamp = _dateStamp(now);
    final host = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;

    final headers = <String, String>{
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (_sessionToken.isNotEmpty) 'x-amz-security-token': _sessionToken,
    };
    final sortedKeys = headers.keys.toList()..sort();
    final canonicalHeaders =
        '${sortedKeys.map((key) => '$key:${headers[key]!.trim()}').join('\n')}\n';
    final signedHeaderNames = sortedKeys.join(';');
    final canonicalRequest = <String>[
      method,
      _canonicalPath(uri),
      uri.query,
      canonicalHeaders,
      signedHeaderNames,
      payloadHash,
    ].join('\n');
    final credentialScope = '$dateStamp/$_region/s3/aws4_request';
    final stringToSign = <String>[
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      _hexDigest(sha256.convert(utf8.encode(canonicalRequest))),
    ].join('\n');
    final dateKey = _hmac(utf8.encode('AWS4$_secretKey'), dateStamp);
    final regionKey = _hmac(dateKey, _region);
    final serviceKey = _hmac(regionKey, 's3');
    final signingKey = _hmac(serviceKey, 'aws4_request');
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    return <String, String>{
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (_sessionToken.isNotEmpty) 'x-amz-security-token': _sessionToken,
      'Authorization':
          'AWS4-HMAC-SHA256 Credential=$_accessKey/$credentialScope, SignedHeaders=$signedHeaderNames, Signature=$signature',
    };
  }

  Future<Response<List<int>>> _requestBytes({
    required String method,
    required String objectName,
    Uint8List? body,
  }) async {
    final uri = _objectUri(objectName);
    final payload = body ?? Uint8List(0);
    final headers = _signedHeaders(
      method: method,
      uri: uri,
      body: payload,
      now: DateTime.now().toUtc(),
    );
    return _dio.request<List<int>>(
      uri.toString(),
      data: body,
      options: Options(
        followRedirects: false,
        method: method,
        headers: headers,
        responseType: ResponseType.bytes,
        validateStatus: (_) => true,
      ),
    );
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    if (_endpoint.isEmpty || _bucket.isEmpty) {
      return const BackupTargetTestResult(
        success: false,
        message: 'S3 endpoint and bucket are required.',
      );
    }
    final probe = '.raha-probe-${const Uuid().v4()}';
    try {
      final put = await _requestBytes(
        method: 'PUT',
        objectName: probe,
        body: Uint8List(0),
      );
      final putStatus = put.statusCode ?? 0;
      if (putStatus < 200 || putStatus >= 300) {
        return BackupTargetTestResult(
          success: false,
          message: 'S3 upload probe returned HTTP $putStatus.',
        );
      }
      await _requestBytes(method: 'DELETE', objectName: probe);
      return const BackupTargetTestResult(
        success: true,
        message: 'S3-compatible storage is ready.',
      );
    } catch (_) {
      return const BackupTargetTestResult(
        success: false,
        message:
            'Connection failed. Check the address, credentials and network.',
      );
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    final response = await _requestBytes(
      method: 'PUT',
      objectName: 'latest.rahabackup',
      body: object.bytes,
    );
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('S3 upload failed with HTTP $status.');
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final response = await _requestBytes(
      method: 'GET',
      objectName: 'latest.rahabackup',
    );
    if (response.statusCode == 404) return null;
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300 || response.data == null) {
      throw StateError('S3 download failed with HTTP $status.');
    }
    return BackupObject(
      bytes: Uint8List.fromList(response.data!),
      fileName: 'latest.rahabackup',
      createdAtUtc: DateTime.now().toUtc(),
    );
  }
}
