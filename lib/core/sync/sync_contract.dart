import 'canonical_json.dart';
import 'causal_clock.dart';

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
    this.changeId,
    this.clock = const {},
    this.deletedAtUtc,
  });

  factory SyncEnvelope.fromJson(Map<String, Object?> json) {
    for (final key in ['entityType', 'entityId', 'deviceId']) {
      if (json[key] is! String || (json[key] as String).isEmpty) {
        throw FormatException('Invalid sync $key');
      }
    }
    if (!['upsert', 'delete'].contains(json['operation']) ||
        json['payload'] is! Map) {
      throw const FormatException('Invalid sync operation or payload');
    }
    if (json['clock'] is Map &&
        (json['clock'] as Map).values.any((v) => v is! int || v < 0)) {
      throw const FormatException('Invalid sync clock');
    }
    return SyncEnvelope(
      changeId: json['changeId']?.toString(),
      clock:
          (json['clock'] is Map
                  ? Map<String, dynamic>.from(json['clock'] as Map)
                  : <String, dynamic>{})
              .map((k, v) => MapEntry(k, (v as num).toInt())),
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
  }

  /// Stable id of one local change. It is optional for a synthesized current
  /// record but present for queued/pulled deltas. Servers use it to make push
  /// retries idempotent after timeouts.
  final String? changeId;
  final Map<String, int> clock;
  Map<String, int> get effectiveClock =>
      clock.isEmpty ? {deviceId: version} : clock;
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
    if (changeId != null && changeId!.isNotEmpty) 'changeId': changeId,
    'clock': effectiveClock,
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
    this.hasMore = false,
  });

  final List<SyncEnvelope> changes;
  final String? nextCursor;
  final bool hasMore;
}

class SyncPushResult {
  const SyncPushResult({
    this.accepted = const <String>[],
    this.conflicts = const <SyncConflict>[],
  });

  /// Exact change ids acknowledged by the server. Entity identities are rejected.
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

/// Record-level transport for a compatible self-hosted Raha Sync Server or
/// custom HTTPS API. File/cloud backup targets are intentionally kept separate
/// because they do not provide transactional record semantics by themselves.
abstract interface class SyncTransport {
  Future<SyncPullResult> pull({required String deviceId, String? cursor});

  Future<SyncPushResult> push({
    required String deviceId,
    required List<SyncEnvelope> changes,
  });
}

/// Local storage adapter. Drift is the source of truth. Local feature edits are
/// appended to a durable change log, then only those deltas are pushed.
abstract interface class SyncStore {
  Future<T> atomic<T>(Future<T> Function() action);
  Future<String?> readCursor();
  Future<void> writeCursor(String? cursor);
  Future<List<SyncEnvelope>> pendingChanges();
  Future<SyncEnvelope?> readCurrent(String entityType, String entityId);
  Future<void> applyRemote(SyncEnvelope change);
  Future<void> markUploaded(Iterable<String> changeIdsOrIdentities);
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
    var downloaded = 0, uploaded = 0, conflictCount = 0;
    var cursor = await store.readCursor();
    var pages = 0;
    while (true) {
      final pulled = await transport.pull(deviceId: deviceId, cursor: cursor);
      await store.atomic(() async {
        final conflicts = <SyncConflict>[];
        for (final remote in pulled.changes) {
          final local = await store.readCurrent(
            remote.entityType,
            remote.entityId,
          );
          final order = local == null
              ? ClockOrder.before
              : compareClocks(local.effectiveClock, remote.effectiveClock);
          if (local == null || order == ClockOrder.before) {
            await store.applyRemote(remote);
            downloaded++;
          } else if ((order == ClockOrder.concurrent ||
                  order == ClockOrder.equal) &&
              (canonicalJson(local.payload) != canonicalJson(remote.payload) ||
                  local.operation != remote.operation)) {
            conflicts.add(SyncConflict(local: local, remote: remote));
          }
        }
        await store.saveConflicts(conflicts);
        conflictCount += conflicts.length;
        await store.writeCursor(pulled.nextCursor);
      });
      if (pulled.hasMore && pulled.nextCursor == cursor) {
        throw StateError('Sync cursor did not advance');
      }
      cursor = pulled.nextCursor;
      pages++;
      if (!pulled.hasMore) {
        break;
      }
      if (pages >= 1000) {
        throw StateError(
          'Sync catch-up is incomplete; continue on the next run',
        );
      }
    }
    // Bounded uploads. Changes created during this run remain in the durable queue.
    for (var batch = 0; batch < 100; batch++) {
      final pending = await store.pendingChanges();
      if (pending.isEmpty) break;
      final pushed = await transport.push(deviceId: deviceId, changes: pending);
      final sent = pending.map((e) => e.changeId).whereType<String>().toSet();
      final accepted = pushed.accepted.where(sent.contains).toSet();
      await store.atomic(() async {
        await store.saveConflicts(pushed.conflicts);
        await store.markUploaded(accepted);
      });
      conflictCount += pushed.conflicts.length;
      uploaded += accepted.length;
      if (pushed.conflicts.isNotEmpty || accepted.isEmpty) break;
    }
    return SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      conflicts: conflictCount,
    );
  }
}
