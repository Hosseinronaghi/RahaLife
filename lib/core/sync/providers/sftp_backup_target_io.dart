import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'backup_target.dart';

BackupTarget createSftpBackupTarget({
  required SyncConnectionProfile profile,
  required Map<String, String> credentials,
}) {
  return _SftpBackupTarget(profile: profile, credentials: credentials);
}

class _SftpBackupTarget implements BackupTarget {
  const _SftpBackupTarget({required this.profile, required this.credentials});

  final SyncConnectionProfile profile;
  final Map<String, String> credentials;

  String get _host => (profile.config['host'] ?? '').trim();
  int get _port => int.tryParse(profile.config['port'] ?? '') ?? 22;
  String get _username => (profile.config['username'] ?? '').trim();
  String get _password => credentials['password'] ?? '';
  String get _remotePath => (profile.config['remotePath'] ?? 'RahaLife').trim();

  @override
  SyncProviderKind get kind => SyncProviderKind.sftp;

  @override
  Set<SyncProviderCapability> get capabilities =>
      const <SyncProviderCapability>{
        SyncProviderCapability.automaticBackup,
        SyncProviderCapability.files,
        SyncProviderCapability.selfHosted,
      };

  Future<SSHClient> _connect() async {
    if (_host.isEmpty || _username.isEmpty) {
      throw const FormatException('SFTP host and username are required.');
    }
    final socket = await SSHSocket.connect(_host, _port);
    return SSHClient(
      socket,
      username: _username,
      onPasswordRequest: () => _password,
      handshakeTimeout: const Duration(seconds: 15),
      authTimeout: const Duration(seconds: 15),
    );
  }

  Future<void> _ensureDirectory(SftpClient sftp) async {
    final absolute = _remotePath.startsWith('/');
    final parts = _remotePath.split('/').where((part) => part.isNotEmpty);
    var current = absolute ? '' : '.';
    for (final part in parts) {
      current = current.isEmpty || current == '.'
          ? '${absolute ? '/' : ''}$part'
          : '$current/$part';
      try {
        await sftp.stat(current);
      } catch (_) {
        await sftp.mkdir(current);
      }
    }
  }

  String _pathFor(String fileName) {
    final base = _remotePath.replaceAll(RegExp(r'/+$'), '');
    return '$base/$fileName';
  }

  @override
  Future<BackupTargetTestResult> testConnection() async {
    SSHClient? client;
    try {
      client = await _connect();
      await client.authenticated;
      final sftp = await client.sftp();
      await _ensureDirectory(sftp);
      await sftp.listdir(_remotePath);
      return const BackupTargetTestResult(
        success: true,
        message: 'SFTP connection is ready.',
      );
    } catch (error) {
      return BackupTargetTestResult(success: false, message: error.toString());
    } finally {
      client?.close();
      if (client != null) await client.done;
    }
  }

  Future<void> _writeObject(
    SftpClient sftp,
    String path,
    Uint8List bytes,
  ) async {
    final file = await sftp.open(
      path,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );
    try {
      await file.writeBytes(bytes);
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> upload(BackupObject object) async {
    final client = await _connect();
    try {
      await client.authenticated;
      final sftp = await client.sftp();
      await _ensureDirectory(sftp);
      await _writeObject(sftp, _pathFor('latest.rahabackup'), object.bytes);
    } finally {
      client.close();
      await client.done;
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final client = await _connect();
    try {
      await client.authenticated;
      final sftp = await client.sftp();
      final path = _pathFor('latest.rahabackup');
      try {
        final file = await sftp.open(path);
        try {
          final bytes = await file.readBytes();
          return BackupObject(
            bytes: bytes,
            fileName: 'latest.rahabackup',
            createdAtUtc: DateTime.now().toUtc(),
          );
        } finally {
          await file.close();
        }
      } catch (_) {
        return null;
      }
    } finally {
      client.close();
      await client.done;
    }
  }
}
