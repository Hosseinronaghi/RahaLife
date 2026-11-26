import 'backup_target.dart';
import 'custom_http_backup_target.dart';
import 'dropbox_backup_target.dart';
import 'onedrive_backup_target.dart';
import 's3_backup_target.dart';
import 'sftp_backup_target.dart';
import 'transport_security.dart';
import 'webdav_backup_target.dart';

BackupTarget createBackupTarget({
  required SyncConnectionProfile profile,
  required Map<String, String> credentials,
}) {
  validateTransportSecurity(profile);
  return switch (profile.kind) {
    SyncProviderKind.dropbox => DropboxBackupTarget(
      profile: profile,
      credentials: credentials,
    ),
    SyncProviderKind.oneDrive => OneDriveBackupTarget(
      profile: profile,
      credentials: credentials,
    ),
    SyncProviderKind.webDav || SyncProviderKind.nextcloud => WebDavBackupTarget(
      profile: profile,
      credentials: credentials,
    ),
    SyncProviderKind.s3 => S3BackupTarget(
      profile: profile,
      credentials: credentials,
    ),
    SyncProviderKind.sftp => createSftpBackupTarget(
      profile: profile,
      credentials: credentials,
    ),
    SyncProviderKind.rahaServer || SyncProviderKind.customHttp =>
      CustomHttpBackupTarget(profile: profile, credentials: credentials),
    _ => throw UnsupportedError(
      '${profile.kind.name} does not expose an automatic backup target.',
    ),
  };
}

bool supportsAutomaticBackup(SyncProviderKind kind) => switch (kind) {
  SyncProviderKind.dropbox ||
  SyncProviderKind.oneDrive ||
  SyncProviderKind.webDav ||
  SyncProviderKind.nextcloud ||
  SyncProviderKind.s3 ||
  SyncProviderKind.sftp ||
  SyncProviderKind.rahaServer ||
  SyncProviderKind.customHttp => true,
  _ => false,
};

bool requiresPublishedOAuthApp(SyncProviderKind kind) => switch (kind) {
  SyncProviderKind.googleDrive ||
  SyncProviderKind.oneDrive ||
  SyncProviderKind.dropbox => true,
  _ => false,
};
