import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../persistence/write_status.dart';
import '../../migration/primary_data_migration.dart';
import 'logical_drift_snapshot.dart';
import 'sync_crypto_service.dart';

class RahaBackupSummary {
  const RahaBackupSummary({
    required this.createdAtUtc,
    required this.preferenceCount,
    required this.includesDatabase,
    this.entityCount = 0,
  });

  final DateTime createdAtUtc;
  final int preferenceCount;
  final bool includesDatabase;
  final int entityCount;
}

class RahaBackupPackage {
  const RahaBackupPackage({required this.bytes, required this.summary});

  final Uint8List bytes;
  final RahaBackupSummary summary;
}

class LocalBackupService {
  LocalBackupService({
    SyncCryptoService? crypto,
    LogicalDriftSnapshotService? logicalSnapshot,
  }) : _crypto = crypto ?? SyncCryptoService(),
       _logicalSnapshot = logicalSnapshot ?? LogicalDriftSnapshotService();

  static const _payloadVersion = 2;
  static const _excludedPreferenceKeys = <String>{
    'sync.device.v1',
    'collab.url',
    'collab.account',
    'auth.local.session.v1',
    'auth.local.profile.v1',
    'sync.connections.v2',
    'sync.active_record_provider.v1',
    'migration.v0.7.preflight.complete',
    'migration.v0.7.legacy_recovery_json',
  };

  final SyncCryptoService _crypto;
  final LogicalDriftSnapshotService _logicalSnapshot;

  Future<RahaBackupPackage> createEncryptedBackup() async {
    await WriteStatus.flush();
    final prefs = await SharedPreferences.getInstance();
    final snapshot = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (_excludedPreferenceKeys.contains(key)) continue;
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        snapshot[key] = value;
      }
    }

    final entities = await _logicalSnapshot.exportEntities();
    // Logical records are read from a consistent committed SQLite snapshot.
    // Copying a live SQLite file would miss WAL pages.
    const Uint8List? databaseBytes = null;
    final createdAt = DateTime.now().toUtc();
    final payload = <String, Object?>{
      'format': 'raha-life-backup',
      'payloadVersion': _payloadVersion,
      'appVersion': '0.8.0',
      'createdAtUtc': createdAt.toIso8601String(),
      'preferences': snapshot,
      'entities': entities,
      'database': databaseBytes == null ? null : base64Encode(databaseBytes),
    };
    final encrypted = await _crypto.encrypt(
      Uint8List.fromList(utf8.encode(jsonEncode(payload))),
    );
    return RahaBackupPackage(
      bytes: encrypted,
      summary: RahaBackupSummary(
        createdAtUtc: createdAt,
        preferenceCount: snapshot.length,
        includesDatabase: entities.isNotEmpty || databaseBytes != null,
        entityCount: entities.length,
      ),
    );
  }

  Future<RahaBackupSummary> restoreEncryptedBackup(Uint8List bytes) async {
    final clearBytes = await _crypto.decrypt(bytes);
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map || decoded['format'] != 'raha-life-backup') {
      throw const FormatException('Invalid Raha Life backup.');
    }
    final version = (decoded['payloadVersion'] as num?)?.toInt() ?? 0;
    if (version > _payloadVersion || version < 1) {
      throw const FormatException('Unsupported Raha Life backup version.');
    }

    if (version == 1 &&
        decoded['database'] is String &&
        (decoded['database'] as String).isNotEmpty) {
      throw const FormatException(
        'Legacy SQLite backup needs isolated recovery; no data was changed.',
      );
    }
    await WriteStatus.flush();
    // Validate and commit the record merge before touching preferences.
    var entityCount = 0;
    if (version >= 2) {
      entityCount = await _logicalSnapshot.mergeEntities(decoded['entities']);
    }
    final prefs = await SharedPreferences.getInstance();
    final currentDeviceId = prefs.getString('sync.device.v1');
    final map = decoded['preferences'];
    if (map is Map) {
      for (final entry in map.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (_excludedPreferenceKeys.contains(key)) continue;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List && value.every((item) => item is String)) {
          await prefs.setStringList(key, value.cast<String>());
        }
      }
    }
    if (currentDeviceId != null && currentDeviceId.isNotEmpty) {
      await prefs.setString('sync.device.v1', currentDeviceId);
    }

    if (version == 1) await PrimaryDataMigrationCoordinator.migrateAll();
    final createdAt =
        DateTime.tryParse(decoded['createdAtUtc']?.toString() ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    final databaseRaw = decoded['database'];
    return RahaBackupSummary(
      createdAtUtc: createdAt,
      preferenceCount: map is Map ? map.length : 0,
      includesDatabase:
          entityCount > 0 || (databaseRaw is String && databaseRaw.isNotEmpty),
      entityCount: entityCount,
    );
  }
}
