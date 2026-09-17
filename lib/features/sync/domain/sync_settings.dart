import '../../../core/sync/providers/backup_target.dart';

enum PersonalSyncStrategy { localOnly, encryptedBackup, providerBased }

class SyncSettingsState {
  const SyncSettingsState({
    this.strategy = PersonalSyncStrategy.localOnly,
    this.connections = const <SyncConnectionProfile>[],
    this.autoBackup = false,
    this.autoSync = true,
    this.wifiOnly = true,
    this.lastBackupAt,
    this.lastSyncAt,
    this.pendingChanges = 0,
    this.conflicts = 0,
    this.deviceId = '',
    this.busyConnectionId,
    this.lastActionSucceeded,
    this.lastActionMessage,
  });

  final PersonalSyncStrategy strategy;
  final List<SyncConnectionProfile> connections;
  final bool autoBackup;
  final bool autoSync;
  final bool wifiOnly;
  final DateTime? lastBackupAt;
  final DateTime? lastSyncAt;
  final int pendingChanges;
  final int conflicts;
  final String deviceId;
  final String? busyConnectionId;
  final bool? lastActionSucceeded;
  final String? lastActionMessage;

  SyncConnectionProfile? connectionById(String id) {
    for (final connection in connections) {
      if (connection.id == id) return connection;
    }
    return null;
  }

  SyncConnectionProfile? get primaryConnection {
    for (final connection in connections) {
      if (connection.enabled && connection.isPrimary) return connection;
    }
    return null;
  }

  SyncSettingsState copyWith({
    PersonalSyncStrategy? strategy,
    List<SyncConnectionProfile>? connections,
    bool? autoBackup,
    bool? autoSync,
    bool? wifiOnly,
    DateTime? lastBackupAt,
    DateTime? lastSyncAt,
    int? pendingChanges,
    int? conflicts,
    String? deviceId,
    String? busyConnectionId,
    bool clearBusyConnection = false,
    bool? lastActionSucceeded,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return SyncSettingsState(
      strategy: strategy ?? this.strategy,
      connections: connections ?? this.connections,
      autoBackup: autoBackup ?? this.autoBackup,
      autoSync: autoSync ?? this.autoSync,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflicts: conflicts ?? this.conflicts,
      deviceId: deviceId ?? this.deviceId,
      busyConnectionId: clearBusyConnection
          ? null
          : busyConnectionId ?? this.busyConnectionId,
      lastActionSucceeded: clearActionMessage
          ? null
          : lastActionSucceeded ?? this.lastActionSucceeded,
      lastActionMessage: clearActionMessage
          ? null
          : lastActionMessage ?? this.lastActionMessage,
    );
  }
}
