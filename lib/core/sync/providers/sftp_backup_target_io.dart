import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../backup/local_backup_service.dart';

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
    if (_remotePath.split('/').any((part) => part == '..') ||
        _remotePath.contains('\x00')) {
      throw const FormatException('Invalid backup directory.');
    }
    if (_host.isEmpty || _username.isEmpty) {
      throw const FormatException('SFTP host and username are required.');
    }
    final fingerprint = profile.config['hostFingerprint']?.trim();
    if (fingerprint == null ||
        !RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$').hasMatch(fingerprint)) {
      throw const FormatException(
        'Set the trusted SSH server SHA256 fingerprint before connecting.',
      );
    }
    final socket = await SSHSocket.connect(_host, _port);
    final client = SSHClient(
      socket,
      username: _username,
      onVerifyHostKey: (_, received) => utf8.decode(received) == fingerprint,
      onPasswordRequest: () => _password,
      handshakeTimeout: const Duration(seconds: 15),
      authTimeout: const Duration(seconds: 15),
    );
    // Authentication is awaited by each operation. Register a handler on the
    // independent transport-completion future before a handshake can fail.
    unawaited(_transportFinished(client));
    return client;
  }

  Future<void> _transportFinished(SSHClient client) async {
    try {
      await client.done;
    } catch (_) {
      // The awaiting SFTP/authentication operation reports the transport error.
    }
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
      } on SftpStatusError catch (error) {
        if (error.code != 2) rethrow;
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
      if (client != null) await _transportFinished(client);
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
    if (object.bytes.isEmpty ||
        object.bytes.length > LocalBackupService.maxBackupBytes) {
      throw const FormatException('Backup exceeds the supported size.');
    }
    final client = await _connect();
    try {
      await client.authenticated;
      final sftp = await client.sftp();
      await _ensureDirectory(sftp);
      final timestamp = DateTime.now()
          .toUtc()
          .microsecondsSinceEpoch
          .toString()
          .padLeft(20, '0');
      final name = 'backup-$timestamp-${const Uuid().v4()}.rahabackup';
      final temporary = _pathFor('.$name.part');
      try {
        await _writeObject(sftp, temporary, object.bytes);
        final uploaded = await sftp.open(temporary);
        try {
          if ((await uploaded.stat()).size != object.bytes.length ||
              await sha256
                      .bind(uploaded.read(length: object.bytes.length))
                      .first !=
                  sha256.convert(object.bytes)) {
            throw StateError('Uploaded backup did not pass verification.');
          }
        } finally {
          await uploaded.close();
        }
        await sftp.rename(temporary, _pathFor(name));
      } catch (_) {
        try {
          await sftp.remove(temporary);
        } catch (_) {
          /* A partial file is never selected. */
        }
        rethrow;
      }
    } finally {
      client.close();
      await _transportFinished(client);
    }
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final client = await _connect();
    try {
      await client.authenticated;
      final sftp = await client.sftp();
      List<String> versions;
      try {
        versions =
            (await sftp.listdir(_remotePath))
                .map((item) => item.filename)
                .where(
                  RegExp(
                    r'^backup-[0-9]{20}-[0-9a-f-]{36}\.rahabackup$',
                  ).hasMatch,
                )
                .toList()
              ..sort();
      } on SftpStatusError catch (error) {
        if (error.code == 2) return null;
        rethrow;
      }
      final name = versions.isEmpty ? 'latest.rahabackup' : versions.last;
      try {
        final file = await sftp.open(_pathFor(name));
        try {
          final size = (await file.stat()).size;
          if (size == null ||
              size < 1 ||
              size > LocalBackupService.maxBackupBytes) {
            throw const FormatException('Invalid or oversized remote backup.');
          }
          final bytes = await file.readBytes(length: size);
          if (bytes.length != size) {
            throw StateError('Incomplete remote backup.');
          }
          return BackupObject(
            bytes: bytes,
            fileName: name,
            createdAtUtc: DateTime.now().toUtc(),
          );
        } finally {
          await file.close();
        }
      } on SftpStatusError catch (error) {
        if (error.code == 2 && versions.isEmpty) return null;
        rethrow;
      }
    } finally {
      client.close();
      await _transportFinished(client);
    }
  }
}
