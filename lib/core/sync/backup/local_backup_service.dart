import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../persistence/write_status.dart';
import '../../app_version.dart';
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
    Future<bool> Function(SharedPreferences, String, Object)? writePreference,
  }) : _writePreference = writePreference ?? _storePreference,
       _crypto = crypto ?? SyncCryptoService(),
       _logicalSnapshot = logicalSnapshot ?? LogicalDriftSnapshotService();

  static const _payloadVersion = 2;
  static const maxBackupBytes = 140 * 1024 * 1024;
  static const _restoreTable = 'backup_restore_journal';
  static const _portable = <String, String>{
    'settings.locale': 'string',
    'settings.theme': 'string',
    'settings.accent': 'string',
    'settings.textScale': 'number',
    'settings.hiddenSections': 'list',
    'settings.moduleOrder.v1': 'list',
    'settings.hiddenModules.v1': 'list',
    'theme.mode': 'string',
    'widgets.hideSensitive.v1': 'bool',
    'cycle.privacy.hideSensitive.v1': 'bool',
    'home.slots': 'list',
    'home.capacity': 'int',
  };
  static const _legacyRecords = <String>{
    'home.entries.v1',
    'people.v1',
    'notes.rich.v1',
    'projects.v1',
    'medications.v1',
    'cycle.logs.v1',
    'inbox.items.v1',
    'messages.local.v1',
    'sharing.grants.v1',
    'finance.accounts.v1',
    'finance.transactions.v2',
    'finance.transactions.v1',
    'shopping.lists.v1',
    'shopping.lists.v2',
  };

  Map<String, Object> _validatedPreferences(
    Object? raw, {
    required bool legacy,
  }) {
    if (raw == null) return {};
    if (raw is! Map) throw const FormatException('Invalid backup settings.');
    final result = <String, Object>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final kind =
          _portable[key] ??
          (legacy && _legacyRecords.contains(key) ? 'legacy' : null);
      if (kind == null) continue;
      final value = entry.value;
      final valid = switch (kind) {
        'string' || 'legacy' => value is String,
        'number' => value is num && value.isFinite,
        'bool' => value is bool,
        'int' => value is int,
        'list' => value is List && value.every((item) => item is String),
        _ => false,
      };
      if (!valid) {
        throw const FormatException('Unsupported backup setting value.');
      }
      if (kind == 'legacy') {
        final records = jsonDecode(value as String);
        if (records is! List ||
            records.any(
              (row) =>
                  row is! Map ||
                  row['id'] == null ||
                  row['id'].toString().isEmpty,
            )) {
          throw const FormatException('Invalid legacy backup records.');
        }
      }
      result[key] = kind == 'number'
          ? (value as num).toDouble()
          : value as Object;
    }
    return result;
  }

  /// The SQLite merge and preference journal commit together. Replaying the
  /// remaining preference writes is safe after kill, failure or restart.
  Future<int> resumePendingRestore() async {
    final row = await _logicalSnapshot.db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_restoreTable'",
        )
        .getSingleOrNull();
    if (row == null) return 0;
    final journal = await _logicalSnapshot.db
        .customSelect(
          'SELECT settings_json, legacy FROM $_restoreTable WHERE id=1',
        )
        .getSingleOrNull();
    if (journal == null) return 0;
    final legacy = journal.read<int>('legacy') == 1;
    final settings = _validatedPreferences(
      jsonDecode(journal.read<String>('settings_json')),
      legacy: legacy,
    );
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final ok = await _writePreference(prefs, entry.key, entry.value);
      if (!ok) {
        throw StateError(
          'Record restore committed. Settings recovery is pending; retry or restart.',
        );
      }
    }
    if (legacy) {
      await PrimaryDataMigrationCoordinator.migrateAll();
      await WriteStatus.flush();
    }
    await _logicalSnapshot.db.customStatement(
      'DELETE FROM $_restoreTable WHERE id=1',
    );
    return settings.length;
  }

  final Future<bool> Function(SharedPreferences, String, Object)
  _writePreference;
  static Future<bool> _storePreference(
    SharedPreferences prefs,
    String key,
    Object value,
  ) async {
    return switch (value) {
      String() => await prefs.setString(key, value),
      bool() => await prefs.setBool(key, value),
      int() => await prefs.setInt(key, value),
      double() => await prefs.setDouble(key, value),
      List() => await prefs.setStringList(key, value.cast<String>()),
      _ => false,
    };
  }

  final SyncCryptoService _crypto;
  final LogicalDriftSnapshotService _logicalSnapshot;

  Future<RahaBackupPackage> createEncryptedBackup() async {
    await WriteStatus.flush();
    final prefs = await SharedPreferences.getInstance();
    await resumePendingRestore();
    final snapshot = _validatedPreferences({
      for (final key in _portable.keys)
        if (prefs.containsKey(key)) key: prefs.get(key),
    }, legacy: false);
    final entities = await _logicalSnapshot.exportEntities();
    // Logical records are read from a consistent committed SQLite snapshot.
    // Copying a live SQLite file would miss WAL pages.
    const Uint8List? databaseBytes = null;
    final createdAt = DateTime.now().toUtc();
    final payload = <String, Object?>{
      'format': 'raha-life-backup',
      'payloadVersion': _payloadVersion,
      'appVersion': rahaAppVersion,
      'createdAtUtc': createdAt.toIso8601String(),
      'preferences': snapshot,
      'entities': entities,
      'database': databaseBytes == null ? null : base64Encode(databaseBytes),
    };
    final clearBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    if (clearBytes.length > (maxBackupBytes - 1024) * 3 ~/ 4) {
      throw StateError('Backup exceeds the supported size.');
    }
    final encrypted = await _crypto.encrypt(clearBytes);
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
    if (bytes.length > maxBackupBytes) {
      throw const FormatException('Backup exceeds the supported size.');
    }
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
    final settings = _validatedPreferences(
      decoded['preferences'],
      legacy: version == 1,
    );
    await WriteStatus.flush();
    await resumePendingRestore();
    final entityCount = await _logicalSnapshot.db.transaction(() async {
      await _logicalSnapshot.db.customStatement(
        'CREATE TABLE IF NOT EXISTS $_restoreTable (id INTEGER PRIMARY KEY, settings_json TEXT NOT NULL, legacy INTEGER NOT NULL)',
      );
      await _logicalSnapshot.db.customStatement(
        'INSERT INTO $_restoreTable (id, settings_json, legacy) VALUES (1, ?, ?)',
        [jsonEncode(settings), version == 1 ? 1 : 0],
      );
      return version >= 2
          ? await _logicalSnapshot.mergeEntities(decoded['entities'])
          : 0;
    });
    final applied = await resumePendingRestore();
    final createdAt =
        DateTime.tryParse(decoded['createdAtUtc']?.toString() ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    final databaseRaw = decoded['database'];
    return RahaBackupSummary(
      createdAtUtc: createdAt,
      preferenceCount: applied,
      includesDatabase:
          entityCount > 0 || (databaseRaw is String && databaseRaw.isNotEmpty),
      entityCount: entityCount,
    );
  }
}
