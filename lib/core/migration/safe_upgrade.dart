import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'safe_upgrade_platform.dart';

class SafeUpgradeCoordinator {
  SafeUpgradeCoordinator._();

  static const _snapshotMarker = 'migration.v0.7.preflight.complete';
  static const _recoveryPreferenceKey = 'migration.v0.7.legacy_recovery_json';

  static const legacyPrimaryKeys = <String>[
    'home.entries.v1',
    'shopping.lists.v2',
    'shopping.lists.v1',
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
  ];

  /// Captures the legacy payloads and the existing native SQLite file before
  /// v0.7 opens/migrates the database. The snapshot is intentionally kept after
  /// a successful migration so a damaged prerelease can still be recovered.
  static Future<void> prepare() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_snapshotMarker) == true) return;

    final recovery = <String, Object?>{};
    for (final key in legacyPrimaryKeys) {
      final value = prefs.get(key);
      if (value != null) recovery[key] = value;
    }
    await prefs.setString(_recoveryPreferenceKey, jsonEncode(recovery));
    await createNativeDatabaseSafetyCopy();
    await prefs.setBool(_snapshotMarker, true);
  }
}
