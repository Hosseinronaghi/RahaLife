import '../../../core/sync/sync_scope.dart';
import 'dart:async';

import '../../../core/persistence/write_status.dart';

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/backup/local_backup_service.dart';
import '../../../core/sync/backup/sync_crypto_service.dart';
import '../../../core/sync/drift_sync_store.dart';
import '../../../core/sync/providers/backup_target.dart';
import '../../../core/sync/providers/backup_target_factory.dart';
import '../../../core/sync/providers/provider_credentials.dart';
import '../../../core/sync/providers/raha_http_sync_transport.dart';
import '../../../core/sync/sync_contract.dart';
import '../domain/sync_settings.dart';
import 'synced_feature_refresh.dart';

class SyncSettingsNotifier extends StateNotifier<SyncSettingsState> {
  SyncSettingsNotifier({
    bool boot = true,
    LocalBackupService? backupService,
    SyncCryptoService? cryptoService,
    ProviderCredentialsStore? credentialsStore,
    void Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged,
       _backupService = backupService ?? LocalBackupService(),
       _cryptoService = cryptoService ?? SyncCryptoService(),
       _credentialsStore = credentialsStore ?? ProviderCredentialsStore(),
       super(const SyncSettingsState()) {
    if (boot) unawaited(_load());
  }

  static const _strategyKey = 'sync.strategy.v2';
  static const _connectionsKey = 'sync.connections.v2';
  static const _autoBackupKey = 'sync.auto_backup.v2';
  static const _autoSyncKey = 'sync.auto_sync.v1';
  static const _wifiOnlyKey = 'sync.wifi_only.v2';
  static const _lastBackupKey = 'sync.last_backup.v2';
  static const _lastSyncKey = 'sync.last.v1';
  static const _deviceKey = 'sync.device.v1';
  static const _activeRecordProviderKey = 'sync.active_record_provider.v1';
  static const _uuid = Uuid();

  final LocalBackupService _backupService;
  final SyncCryptoService _cryptoService;
  final ProviderCredentialsStore _credentialsStore;
  final void Function()? _onDataChanged;
  StreamSubscription<int>? _pendingMetricSubscription;
  StreamSubscription<int>? _conflictMetricSubscription;
  Timer? _autoSyncDebounce;
  Timer? _poll;
  Future<void> _operationTail = Future<void>.value();
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = _operationTail.then((_) => action());
    _operationTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<SyncResult?>? _syncFlight;
  bool _disposed = false;
  String? _activeRecordProviderId;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceKey, deviceId);
    }
    final strategyName = prefs.getString(_strategyKey);
    final lastBackupRaw = prefs.getString(_lastBackupKey);
    final lastSyncRaw = prefs.getString(_lastSyncKey);
    final connectionsRaw = prefs.getString(_connectionsKey);
    _activeRecordProviderId = prefs.getString(_activeRecordProviderKey);
    var connections = <SyncConnectionProfile>[];
    if (connectionsRaw != null && connectionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(connectionsRaw);
        if (decoded is List) {
          connections = decoded
              .whereType<Map>()
              .map(
                (item) => SyncConnectionProfile.fromJson(
                  Map<String, Object?>.from(item),
                ),
              )
              .toList();
        }
      } catch (_) {
        connections = <SyncConnectionProfile>[];
      }
    }
    state = SyncSettingsState(
      strategy: PersonalSyncStrategy.values.firstWhere(
        (value) => value.name == strategyName,
        orElse: () => connections.isEmpty
            ? PersonalSyncStrategy.localOnly
            : PersonalSyncStrategy.providerBased,
      ),
      connections: connections,
      autoBackup: prefs.getBool(_autoBackupKey) ?? false,
      autoSync: prefs.getBool(_autoSyncKey) ?? true,
      wifiOnly: prefs.getBool(_wifiOnlyKey) ?? true,
      lastBackupAt: _parseDate(lastBackupRaw),
      lastSyncAt: _parseDate(lastSyncRaw),
      deviceId: deviceId,
    );
    await _refreshSyncMetrics();
    _startMetricWatch();
    _poll = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_disposed) unawaited(runAutoSyncIfEnabled());
    });
    unawaited(runAutoSyncIfEnabled());
    unawaited(runAutoBackupIfDue());
  }

  Future<void> _persistConnections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _connectionsKey,
      jsonEncode(state.connections.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> setStrategy(PersonalSyncStrategy strategy) async {
    state = state.copyWith(strategy: strategy);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_strategyKey, strategy.name);
  }

  Future<void> setAutoBackup(bool value) async {
    state = state.copyWith(autoBackup: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, value);
  }

  Future<void> setAutoSync(bool value) async {
    state = state.copyWith(autoSync: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, value);
    if (value) unawaited(runAutoSyncIfEnabled());
  }

  Future<void> setWifiOnly(bool value) async {
    state = state.copyWith(wifiOnly: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, value);
  }

  Future<String> addConnection({
    required String name,
    required SyncProviderKind kind,
    required SyncTargetPurpose purpose,
    required Map<String, String> config,
    required Map<String, String> credentials,
  }) async {
    final id = _uuid.v4();
    final firstPrimary = state.connections.every((item) => !item.isPrimary);
    final profile = SyncConnectionProfile(
      id: id,
      name: name.trim(),
      kind: kind,
      purpose: purpose,
      isPrimary: firstPrimary,
      config: config,
    );
    await _credentialsStore.write(id, credentials);
    state = state.copyWith(
      strategy: PersonalSyncStrategy.providerBased,
      connections: <SyncConnectionProfile>[...state.connections, profile],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _strategyKey,
      PersonalSyncStrategy.providerBased.name,
    );
    await _persistConnections();
    return id;
  }

  Future<void> updateConnection({
    required SyncConnectionProfile profile,
    Map<String, String>? credentials,
  }) async {
    final old = state.connectionById(profile.id);
    if (old?.config['baseUrl'] != profile.config['baseUrl'] ||
        old?.config['modules'] != profile.config['modules']) {
      _activeRecordProviderId = null;
    }
    if (credentials != null) {
      await _credentialsStore.write(profile.id, credentials);
    }
    state = state.copyWith(
      connections: <SyncConnectionProfile>[
        for (final item in state.connections)
          if (item.id == profile.id) profile else item,
      ],
    );
    await _persistConnections();
  }

  Future<void> removeConnection(String id) async {
    await _credentialsStore.delete(id);
    var remaining = state.connections.where((item) => item.id != id).toList();
    if (remaining.isNotEmpty && remaining.every((item) => !item.isPrimary)) {
      remaining = <SyncConnectionProfile>[
        remaining.first.copyWith(isPrimary: true),
        ...remaining.skip(1),
      ];
    }
    state = state.copyWith(connections: remaining);
    await _persistConnections();
  }

  Future<void> setConnectionEnabled(String id, bool enabled) async {
    state = state.copyWith(
      connections: <SyncConnectionProfile>[
        for (final item in state.connections)
          if (item.id == id) item.copyWith(enabled: enabled) else item,
      ],
    );
    await _persistConnections();
  }

  Future<void> setPrimaryConnection(String id) async {
    state = state.copyWith(
      connections: <SyncConnectionProfile>[
        for (final item in state.connections)
          item.copyWith(isPrimary: item.id == id),
      ],
    );
    await _persistConnections();
  }

  Future<BackupTargetTestResult> testConnection(String id) async {
    final profile = state.connectionById(id);
    if (profile == null) {
      return const BackupTargetTestResult(
        success: false,
        message: 'Connection not found.',
      );
    }
    state = state.copyWith(busyConnectionId: id, clearActionMessage: true);
    final credentials = await _credentialsStore.read(id);
    BackupTargetTestResult result;
    try {
      final target = createBackupTarget(
        profile: profile,
        credentials: credentials,
      );
      result = await target.testConnection();
    } catch (error) {
      result = BackupTargetTestResult(
        success: false,
        message: error.toString(),
      );
    }
    final testedAt = DateTime.now().toUtc();
    final updated = profile.copyWith(
      lastTestedAt: testedAt,
      lastSuccessAt: result.success ? testedAt : profile.lastSuccessAt,
      lastError: result.success ? null : result.message,
      clearLastError: result.success,
    );
    state = state.copyWith(
      connections: <SyncConnectionProfile>[
        for (final item in state.connections)
          if (item.id == id) updated else item,
      ],
      clearBusyConnection: true,
      lastActionSucceeded: result.success,
      lastActionMessage: result.message,
    );
    await _persistConnections();
    return result;
  }

  Future<bool> backupToConnection(String id) =>
      _exclusive(() => _backupToConnection(id));

  Future<bool> _backupToConnection(String id) async {
    final profile = state.connectionById(id);
    if (profile == null || !supportsAutomaticBackup(profile.kind)) return false;
    state = state.copyWith(busyConnectionId: id, clearActionMessage: true);
    try {
      final package = await _backupService.createEncryptedBackup();
      final credentials = await _credentialsStore.read(id);
      final target = createBackupTarget(
        profile: profile,
        credentials: credentials,
      );
      final createdAt = package.summary.createdAtUtc;
      await target.upload(
        BackupObject(
          bytes: package.bytes,
          fileName: _backupFileName(createdAt),
          createdAtUtc: createdAt,
        ),
      );
      final now = DateTime.now().toUtc();
      final updated = profile.copyWith(
        lastSuccessAt: now,
        clearLastError: true,
      );
      state = state.copyWith(
        connections: <SyncConnectionProfile>[
          for (final item in state.connections)
            if (item.id == id) updated else item,
        ],
        lastBackupAt: now,
        clearBusyConnection: true,
        lastActionSucceeded: true,
        lastActionMessage: 'backup_uploaded',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, now.toIso8601String());
      await _persistConnections();
      return true;
    } catch (error) {
      final updated = profile.copyWith(lastError: error.toString());
      state = state.copyWith(
        connections: <SyncConnectionProfile>[
          for (final item in state.connections)
            if (item.id == id) updated else item,
        ],
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      await _persistConnections();
      return false;
    }
  }

  bool _supportsRecordSync(SyncConnectionProfile profile) =>
      profile.kind == SyncProviderKind.rahaServer ||
      profile.kind == SyncProviderKind.customHttp;

  bool _purposeIncludesSync(SyncConnectionProfile profile) =>
      profile.purpose == SyncTargetPurpose.sync ||
      profile.purpose == SyncTargetPurpose.both;

  Future<void> _refreshSyncMetrics({String? providerId}) async {
    final store = DriftSyncStore(providerId: providerId ?? '__metrics__');
    final pending = await store.pendingCount();
    final conflicts = await store.unresolvedConflictCount();
    state = state.copyWith(pendingChanges: pending, conflicts: conflicts);
  }

  void _startMetricWatch() {
    final store = DriftSyncStore(providerId: '__metrics__');
    unawaited(_pendingMetricSubscription?.cancel());
    unawaited(_conflictMetricSubscription?.cancel());
    _pendingMetricSubscription = store.watchPendingCount().listen((pending) {
      if (_disposed) return;
      state = state.copyWith(pendingChanges: pending);
      if (pending > 0) _scheduleAutoSync();
    });
    _conflictMetricSubscription = store.watchUnresolvedConflictCount().listen((
      conflicts,
    ) {
      if (_disposed) return;
      state = state.copyWith(conflicts: conflicts);
    });
  }

  void _scheduleAutoSync() {
    _autoSyncDebounce?.cancel();
    if (!state.autoSync ||
        state.strategy != PersonalSyncStrategy.providerBased ||
        state.busyConnectionId != null) {
      return;
    }
    _autoSyncDebounce = Timer(const Duration(seconds: 2), () {
      if (_disposed || state.busyConnectionId != null) return;
      unawaited(runAutoSyncIfEnabled());
    });
  }

  Future<SyncResult?> syncConnection(String id) {
    if (_syncFlight != null) return _syncFlight!;
    final future = _exclusive(() => _syncConnection(id)).catchError((
      Object error,
    ) {
      if (!_disposed) {
        state = state.copyWith(
          lastActionSucceeded: false,
          lastActionMessage: error.toString(),
        );
      }
      return null;
    });
    _syncFlight = future;
    return future.whenComplete(() {
      _syncFlight = null;
    });
  }

  Future<SyncResult?> _syncConnection(String id) async {
    await WriteStatus.flush();
    final profile = state.connectionById(id);
    if (profile == null ||
        !profile.enabled ||
        !_supportsRecordSync(profile) ||
        !_purposeIncludesSync(profile)) {
      return null;
    }

    // Only one record-sync destination is active at a time. Backup targets can
    // still be unlimited. When the user deliberately switches the live sync
    // server, replay the durable change log; repeated changeIds are idempotent
    // on protocol-v2 servers, while changes the new provider has never seen are
    // seeded without replacing any remote database snapshot.
    final scopeId = '$id:${profile.config['modules'] ?? '*'}';
    if (_activeRecordProviderId != scopeId) {
      final switchStore = DriftSyncStore(providerId: scopeId);
      await switchStore.requeueAllChanges();
      _activeRecordProviderId = scopeId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeRecordProviderKey, scopeId);
    }

    state = state.copyWith(busyConnectionId: id, clearActionMessage: true);
    try {
      final credentials = await _credentialsStore.read(id);
      final baseUrl = profile.config['baseUrl'] ?? '';
      final token = credentials['token'] ?? '';
      final allowInsecureHttp =
          profile.config['allowInsecureHttp']?.toLowerCase() == 'true';
      final store = DriftSyncStore(
        providerId: scopeId,
        entityTypes: syncTypes(profile.config),
      );
      final transport = RahaHttpSyncTransport(
        baseUrl: baseUrl,
        entityTypes: syncTypes(profile.config),
        token: token,
        allowInsecureHttp: allowInsecureHttp,
      );
      final engine = RecordSyncEngine(
        deviceId: state.deviceId,
        store: store,
        transport: transport,
      );
      final result = await engine.sync();
      await store.pruneAcknowledgedHistory();
      final now = DateTime.now().toUtc();
      final updated = profile.copyWith(
        lastSuccessAt: now,
        clearLastError: true,
      );
      state = state.copyWith(
        connections: <SyncConnectionProfile>[
          for (final item in state.connections)
            if (item.id == id) updated else item,
        ],
        lastSyncAt: now,
        clearBusyConnection: true,
        lastActionSucceeded: true,
        lastActionMessage:
            'sync_complete:${result.uploaded}:${result.downloaded}:${result.conflicts}',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, now.toIso8601String());
      await _persistConnections();
      await _refreshSyncMetrics(providerId: id);
      if (result.downloaded > 0) _onDataChanged?.call();
      return result;
    } catch (error) {
      final updated = profile.copyWith(lastError: error.toString());
      state = state.copyWith(
        connections: <SyncConnectionProfile>[
          for (final item in state.connections)
            if (item.id == id) updated else item,
        ],
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      await _persistConnections();
      await _refreshSyncMetrics(providerId: id);
      return null;
    }
  }

  Future<bool> syncAllEnabled() async {
    final targets = state.connections
        .where(
          (item) =>
              item.enabled &&
              _supportsRecordSync(item) &&
              _purposeIncludesSync(item),
        )
        .toList(growable: false);
    if (targets.isEmpty) {
      await _refreshSyncMetrics();
      return false;
    }
    SyncConnectionProfile target = targets.first;
    for (final item in targets) {
      if (item.id == _activeRecordProviderId) {
        target = item;
        break;
      }
      if (item.isPrimary) target = item;
    }
    final result = await syncConnection(target.id);
    return result != null;
  }

  Future<bool> runAutoSyncIfEnabled() async {
    if (!state.autoSync ||
        state.strategy != PersonalSyncStrategy.providerBased) {
      return false;
    }
    if (state.wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final allowed =
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);
      if (!allowed) return false;
    }
    return syncAllEnabled();
  }

  Future<bool> runAutoBackupIfDue() async {
    if (!state.autoBackup ||
        state.strategy != PersonalSyncStrategy.providerBased) {
      return false;
    }
    final last = state.lastBackupAt;
    if (last != null &&
        DateTime.now().toUtc().difference(last) < const Duration(hours: 6)) {
      return false;
    }
    if (state.wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final allowed =
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);
      if (!allowed) return false;
    }
    return backupAllEnabled();
  }

  Future<bool> backupAllEnabled() async {
    final targets = state.connections
        .where(
          (item) =>
              item.enabled &&
              (item.purpose == SyncTargetPurpose.backup ||
                  item.purpose == SyncTargetPurpose.both) &&
              supportsAutomaticBackup(item.kind),
        )
        .toList();
    if (targets.isEmpty) return false;
    var anySuccess = false;
    for (final target in targets) {
      if (await backupToConnection(target.id)) anySuccess = true;
    }
    return anySuccess;
  }

  Future<bool> restoreLatestFromConnection(String id) =>
      _exclusive(() => _restoreLatestFromConnection(id));

  Future<bool> _restoreLatestFromConnection(String id) async {
    final profile = state.connectionById(id);
    if (profile == null || !supportsAutomaticBackup(profile.kind)) return false;
    state = state.copyWith(busyConnectionId: id, clearActionMessage: true);
    try {
      final credentials = await _credentialsStore.read(id);
      final target = createBackupTarget(
        profile: profile,
        credentials: credentials,
      );
      final object = await target.downloadLatest();
      if (object == null) {
        state = state.copyWith(
          clearBusyConnection: true,
          lastActionSucceeded: false,
          lastActionMessage: 'backup_not_found',
        );
        return false;
      }
      await _backupService.restoreEncryptedBackup(object.bytes);
      _onDataChanged?.call();
      await _refreshSyncMetrics(providerId: id);
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: true,
        lastActionMessage: 'backup_restored',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> exportEncryptedBackup() =>
      _exclusive(() => _exportEncryptedBackup());

  Future<bool> _exportEncryptedBackup() async {
    state = state.copyWith(
      busyConnectionId: 'manual-file',
      clearActionMessage: true,
    );
    try {
      final package = await _backupService.createEncryptedBackup();
      final fileName = _backupFileName(package.summary.createdAtUtc);
      final output = await FilePicker.saveFile(
        dialogTitle: 'Raha Life encrypted backup',
        fileName: fileName,
        bytes: package.bytes,
      );
      if (output == null) {
        state = state.copyWith(clearBusyConnection: true);
        return false;
      }
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        lastBackupAt: now,
        clearBusyConnection: true,
        lastActionSucceeded: true,
        lastActionMessage: 'backup_exported',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, now.toIso8601String());
      return true;
    } catch (error) {
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> shareEncryptedBackup() =>
      _exclusive(() => _shareEncryptedBackup());

  Future<bool> _shareEncryptedBackup() async {
    state = state.copyWith(
      busyConnectionId: 'manual-file',
      clearActionMessage: true,
    );
    try {
      final package = await _backupService.createEncryptedBackup();
      final fileName = _backupFileName(package.summary.createdAtUtc);
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Raha Life encrypted transfer',
          text: 'Raha Life encrypted backup / device transfer',
          files: <XFile>[
            XFile.fromData(package.bytes, mimeType: 'application/octet-stream'),
          ],
          fileNameOverrides: <String>[fileName],
          downloadFallbackEnabled: true,
        ),
      );
      final ok = result.status != ShareResultStatus.unavailable;
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: ok,
        lastActionMessage: ok ? 'backup_shared' : 'share_unavailable',
      );
      return ok;
    } catch (error) {
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> importEncryptedBackup() =>
      _exclusive(() => _importEncryptedBackup());

  Future<bool> _importEncryptedBackup() async {
    state = state.copyWith(
      busyConnectionId: 'manual-file',
      clearActionMessage: true,
    );
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['rahabackup'],
      );
      if (file == null) {
        state = state.copyWith(clearBusyConnection: true);
        return false;
      }
      final bytes = await file.readAsBytes();
      await _backupService.restoreEncryptedBackup(bytes);
      _onDataChanged?.call();
      await _refreshSyncMetrics();
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: true,
        lastActionMessage: 'backup_restored',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        clearBusyConnection: true,
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      return false;
    }
  }

  Future<String> exportRecoveryKey() => _cryptoService.exportRecoveryKey();

  Future<bool> importRecoveryKey(String value) async {
    try {
      await _cryptoService.importRecoveryKey(value);
      state = state.copyWith(
        lastActionSucceeded: true,
        lastActionMessage: 'recovery_key_imported',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        lastActionSucceeded: false,
        lastActionMessage: error.toString(),
      );
      return false;
    }
  }

  void clearActionMessage() {
    state = state.copyWith(clearActionMessage: true);
  }

  Future<void> refreshSyncMetrics() => _refreshSyncMetrics();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_pendingMetricSubscription?.cancel());
    unawaited(_conflictMetricSubscription?.cancel());
    _autoSyncDebounce?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

String _backupFileName(DateTime createdAtUtc) {
  final value = createdAtUtc.toUtc().toIso8601String().replaceAll(':', '-');
  return 'Raha-Life-Backup-$value.rahabackup';
}

final syncSettingsProvider =
    StateNotifierProvider<SyncSettingsNotifier, SyncSettingsState>(
      (ref) => SyncSettingsNotifier(
        onDataChanged: () => invalidateSyncedFeatureProviders(ref),
      ),
    );
