import 'backup_target.dart';

BackupTarget createSftpBackupTarget({
  required SyncConnectionProfile profile,
  required Map<String, String> credentials,
}) {
  return _UnsupportedSftpBackupTarget(profile);
}

class _UnsupportedSftpBackupTarget implements BackupTarget {
  const _UnsupportedSftpBackupTarget(this.profile);

  final SyncConnectionProfile profile;

  @override
  SyncProviderKind get kind => SyncProviderKind.sftp;

  @override
  Set<SyncProviderCapability> get capabilities =>
      const <SyncProviderCapability>{
        SyncProviderCapability.automaticBackup,
        SyncProviderCapability.selfHosted,
      };

  @override
  Future<BackupObject?> downloadLatest() async => null;

  @override
  Future<BackupTargetTestResult> testConnection() async =>
      const BackupTargetTestResult(
        success: false,
        message: 'Direct SFTP is not available in a web browser.',
      );

  @override
  Future<void> upload(BackupObject object) async {
    throw UnsupportedError('Direct SFTP is not available on web.');
  }
}
