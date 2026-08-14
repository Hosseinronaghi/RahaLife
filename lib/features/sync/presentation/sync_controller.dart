import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/sync_settings.dart';

class SyncSettingsNotifier extends StateNotifier<SyncSettingsState> {
  SyncSettingsNotifier() : super(const SyncSettingsState()) {
    unawaited(_load());
  }

  static const _providerKey = 'sync.provider.v1';
  static const _modeKey = 'sync.mode.v1';
  static const _lastSyncKey = 'sync.last.v1';
  static const _deviceKey = 'sync.device.v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceKey, deviceId);
    }
    final providerName = prefs.getString(_providerKey);
    final modeName = prefs.getString(_modeKey);
    final lastRaw = prefs.getString(_lastSyncKey);
    state = SyncSettingsState(
      provider: CloudSyncProvider.values.firstWhere(
        (value) => value.name == providerName,
        orElse: () => CloudSyncProvider.rahaCloud,
      ),
      mode: SyncMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => SyncMode.allDevices,
      ),
      lastSyncAt: lastRaw == null ? null : DateTime.tryParse(lastRaw),
      deviceId: deviceId,
    );
  }

  Future<void> setProvider(CloudSyncProvider provider) async {
    state = state.copyWith(provider: provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
  }

  Future<void> setMode(SyncMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> markLocalCheckpoint() async {
    final now = DateTime.now().toUtc();
    state = state.copyWith(lastSyncAt: now, pendingChanges: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, now.toIso8601String());
  }

  void queueChange() {
    state = state.copyWith(pendingChanges: state.pendingChanges + 1);
  }
}

final syncSettingsProvider =
    StateNotifierProvider<SyncSettingsNotifier, SyncSettingsState>(
  (ref) => SyncSettingsNotifier(),
);
