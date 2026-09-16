import 'backup_target.dart';
import 'sftp_backup_target_stub.dart'
    if (dart.library.io) 'sftp_backup_target_io.dart'
    as implementation;

BackupTarget createSftpBackupTarget({
  required SyncConnectionProfile profile,
  required Map<String, String> credentials,
}) {
  return implementation.createSftpBackupTarget(
    profile: profile,
    credentials: credentials,
  );
}
