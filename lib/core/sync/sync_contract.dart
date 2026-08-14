enum SyncOperation { upsert, delete }

class SyncEnvelope {
  const SyncEnvelope({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.version,
    required this.updatedAtUtc,
    required this.deviceId,
    required this.payload,
    this.deletedAtUtc,
  });

  factory SyncEnvelope.fromJson(Map<String, Object?> json) => SyncEnvelope(
        entityType: json['entityType']! as String,
        entityId: json['entityId']! as String,
        operation: SyncOperation.values.firstWhere(
          (value) => value.name == json['operation'],
          orElse: () => SyncOperation.upsert,
        ),
        version: (json['version'] as num?)?.toInt() ?? 1,
        updatedAtUtc: DateTime.parse(json['updatedAtUtc']! as String).toUtc(),
        deviceId: json['deviceId']! as String,
        deletedAtUtc: json['deletedAtUtc'] == null
            ? null
            : DateTime.parse(json['deletedAtUtc']! as String).toUtc(),
        payload: json['payload'] is Map
            ? Map<String, Object?>.from(json['payload']! as Map)
            : const <String, Object?>{},
      );

  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final int version;
  final DateTime updatedAtUtc;
  final String deviceId;
  final DateTime? deletedAtUtc;
  final Map<String, Object?> payload;

  String get identity => '$entityType:$entityId';

  Map<String, Object?> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation.name,
        'version': version,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deletedAtUtc': deletedAtUtc?.toUtc().toIso8601String(),
        'payload': payload,
      };
}

class SyncConflict {
  const SyncConflict({required this.local, required this.remote});
  final SyncEnvelope local;
  final SyncEnvelope remote;
}

class SyncPullResult {
  const SyncPullResult({
    required this.changes,
    required this.nextCursor,
  });

  final List<SyncEnvelope> changes;
  final String? nextCursor;
}

class SyncPushResult {
  const SyncPushResult({
    this.accepted = const <String>[],
    this.conflicts = const <SyncConflict>[],
  });

  final List<String> accepted;
  final List<SyncConflict> conflicts;
}

class SyncResult {
  const SyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.conflicts,
  });

  final int uploaded;
  final int downloaded;
  final int conflicts;
}

/// Transport implemented by Raha Cloud. Drive/Dropbox/OneDrive are backup
/// providers and should not be used as a transactional collaboration transport.
abstract interface class SyncTransport {
  Future<SyncPullResult> pull({
    required String deviceId,
    String? cursor,
  });

  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  });
}

/// Local storage adapter. A Drift implementation will make the local database
/// the source of truth while preserving this transport-independent engine.
abstract interface class SyncStore {
  Future<String?> readCursor();
  Future<void> writeCursor(String? cursor);
  Future<List<SyncEnvelope>> pendingChanges();
  Future<SyncEnvelope?> readCurrent(String entityType, String entityId);
  Future<void> applyRemote(SyncEnvelope change);
  Future<void> markUploaded(Iterable<String> identities);
  Future<void> saveConflicts(List<SyncConflict> conflicts);
}

abstract interface class SyncService {
  Future<SyncResult> sync();
}

class RecordSyncEngine implements SyncService {
  const RecordSyncEngine({
    required this.deviceId,
    required this.store,
    required this.transport,
  });

  final String deviceId;
  final SyncStore store;
  final SyncTransport transport;

  @override
  Future<SyncResult> sync() async {
    var downloaded = 0;
    var uploaded = 0;
    final conflicts = <SyncConflict>[];

    // Pull first so stale local edits do not silently overwrite a newer remote
    // record. Independent records merge automatically because every entity has
    // its own UUID and version.
    final cursor = await store.readCursor();
    final pulled = await transport.pull(deviceId: deviceId, cursor: cursor);
    for (final remote in pulled.changes) {
      final local = await store.readCurrent(remote.entityType, remote.entityId);
      if (local == null || _remoteWins(local, remote)) {
        await store.applyRemote(remote);
        downloaded += 1;
      } else if (_isTrueConflict(local, remote)) {
        conflicts.add(SyncConflict(local: local, remote: remote));
      }
    }
    await store.writeCursor(pulled.nextCursor);

    final pending = await store.pendingChanges();
    if (pending.isNotEmpty) {
      final pushed = await transport.push(deviceId: deviceId, changes: pending);
      if (pushed.accepted.isNotEmpty) {
        await store.markUploaded(pushed.accepted);
        uploaded += pushed.accepted.length;
      }
      conflicts.addAll(pushed.conflicts);
    }

    if (conflicts.isNotEmpty) {
      await store.saveConflicts(conflicts);
    }

    return SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      conflicts: conflicts.length,
    );
  }

  bool _remoteWins(SyncEnvelope local, SyncEnvelope remote) {
    if (remote.version != local.version) return remote.version > local.version;
    return remote.updatedAtUtc.isAfter(local.updatedAtUtc) &&
        remote.deviceId == local.deviceId;
  }

  bool _isTrueConflict(SyncEnvelope local, SyncEnvelope remote) {
    if (local.identity != remote.identity) return false;
    if (local.deviceId == remote.deviceId) return false;
    if (local.version != remote.version) return false;
    return local.updatedAtUtc != remote.updatedAtUtc;
  }
}

abstract interface class BackupService {
  Future<String> createEncryptedBackup();
  Future<void> restoreEncryptedBackup(String path);
}

abstract interface class PersonalCloudBackupProvider {
  String get providerId;
  Future<bool> get isConnected;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> uploadBackup(String localEncryptedBackupPath);
  Future<String?> downloadLatestBackup();
}
