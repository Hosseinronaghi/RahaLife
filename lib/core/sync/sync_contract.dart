class SyncResult {
  const SyncResult({required this.uploaded, required this.downloaded, required this.conflicts});
  final int uploaded;
  final int downloaded;
  final int conflicts;
}

abstract interface class SyncService {
  Future<SyncResult> sync();
}

abstract interface class BackupService {
  Future<String> createEncryptedBackup();
  Future<void> restoreEncryptedBackup(String path);
}
