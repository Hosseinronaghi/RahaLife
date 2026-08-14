enum CloudSyncProvider { rahaCloud, googleDrive, dropbox, oneDrive, localBackup }

enum SyncMode { allDevices, backupOnly }

class SyncSettingsState {
  const SyncSettingsState({
    this.provider = CloudSyncProvider.rahaCloud,
    this.mode = SyncMode.allDevices,
    this.lastSyncAt,
    this.pendingChanges = 0,
    this.conflicts = 0,
    this.deviceId = '',
  });

  final CloudSyncProvider provider;
  final SyncMode mode;
  final DateTime? lastSyncAt;
  final int pendingChanges;
  final int conflicts;
  final String deviceId;

  SyncSettingsState copyWith({
    CloudSyncProvider? provider,
    SyncMode? mode,
    DateTime? lastSyncAt,
    int? pendingChanges,
    int? conflicts,
    String? deviceId,
  }) =>
      SyncSettingsState(
        provider: provider ?? this.provider,
        mode: mode ?? this.mode,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        pendingChanges: pendingChanges ?? this.pendingChanges,
        conflicts: conflicts ?? this.conflicts,
        deviceId: deviceId ?? this.deviceId,
      );
}
