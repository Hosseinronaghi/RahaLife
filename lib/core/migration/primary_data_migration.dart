import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../persistence/drift_entity_repository.dart';
import '../persistence/write_status.dart';

/// Runs the v0.7 primary-domain migration before the UI and automatic sync are
/// started. Configuration/session preferences intentionally stay in
/// SharedPreferences; user-created domain records move into Drift.
class PrimaryDataMigrationCoordinator {
  PrimaryDataMigrationCoordinator._();

  static Future<void> migrateAll() async {
    final repository = DriftEntityRepository();
    for (final plan in _plans) {
      try {
        await repository.migrateLegacyList(
          migrationKey: plan.migrationKey,
          entityType: plan.entityType,
          preferenceKeys: plan.preferenceKeys,
        );
      } catch (error) {
        WriteStatus.report(error);
        // Keep the legacy payload untouched. SafeUpgradeCoordinator already
        // captured a recovery copy, and the feature can retry on next launch.
      }
    }
    await _migrateShopping(repository);
  }

  static Future<void> _migrateShopping(DriftEntityRepository repository) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString('shopping.lists.v2') ??
        prefs.getString('shopping.lists.v1');
    if (raw == null || raw.isEmpty) {
      await repository.markMigrationComplete(
        key: 'v0.7.shopping.v2',
        source: 'shared_preferences:none',
      );
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.any((e) => e is! Map)) {
        throw const FormatException(
          'Invalid shopping source; original retained.',
        );
      }
      final parents = <Map<String, Object?>>[],
          items = <Map<String, Object?>>[];
      for (final rawList in decoded) {
        final list = Map<String, Object?>.from(rawList as Map);
        final listId = list['id']?.toString();
        if (listId == null || listId.isEmpty) {
          throw const FormatException('Invalid shopping identifier');
        }
        final children = list.remove('items');
        parents.add(list);
        if (children != null && children is! List) {
          throw const FormatException('Invalid shopping children');
        }
        for (final rawItem in (children as List? ?? [])) {
          if (rawItem is! Map ||
              rawItem['id'] == null ||
              rawItem['id'].toString().isEmpty) {
            throw const FormatException('Invalid shopping item identifier');
          }
          items.add({...Map<String, Object?>.from(rawItem), 'listId': listId});
        }
      }
      if (parents.map((e) => e['id']).toSet().length != parents.length ||
          items.map((e) => e['id']).toSet().length != items.length) {
        throw const FormatException('Duplicate shopping identifiers');
      }
      await repository.db.transaction(() async {
        for (final parent in parents) {
          if (!await repository.containsIncludingDeleted(
            'shopping_list',
            parent['id'].toString(),
          )) {
            await repository.upsert('shopping_list', parent);
          }
        }
        for (final item in items) {
          if (!await repository.containsIncludingDeleted(
            'shopping_item',
            item['id'].toString(),
          )) {
            await repository.upsert('shopping_item', item);
          }
        }
        await repository.markMigrationComplete(
          key: 'v0.7.shopping.v2',
          source: 'shared_preferences:shopping.lists.v2/v1',
          itemCount: parents.length,
        );
      });
      await prefs.remove('shopping.lists.v2');
      await prefs.remove('shopping.lists.v1');
    } catch (error) {
      WriteStatus.report(error);
    }
  }

  static const _plans = <_LegacyListPlan>[
    _LegacyListPlan('v0.7.home.entries.v1', 'home_entry', ['home.entries.v1']),
    _LegacyListPlan('v0.7.people.v1', 'person', ['people.v1']),
    _LegacyListPlan('v0.7.notes.rich.v1', 'rich_note', ['notes.rich.v1']),
    _LegacyListPlan('v0.7.projects.v1', 'project', ['projects.v1']),
    _LegacyListPlan('v0.7.medications.v1', 'medication_plan', [
      'medications.v1',
    ]),
    _LegacyListPlan('v0.7.cycle.logs.v1', 'cycle_log', ['cycle.logs.v1']),
    _LegacyListPlan('v0.7.inbox.items.v1', 'inbox_item', ['inbox.items.v1']),
    _LegacyListPlan('v0.7.messages.local.v1', 'message', ['messages.local.v1']),
    _LegacyListPlan('v0.7.sharing.grants.v1', 'share_grant', [
      'sharing.grants.v1',
    ]),
    _LegacyListPlan('v0.7.finance.accounts.v1', 'finance_account', [
      'finance.accounts.v1',
    ]),
    _LegacyListPlan('v0.7.finance.transactions.v2', 'finance_transaction', [
      'finance.transactions.v2',
      'finance.transactions.v1',
    ]),
  ];
}

class _LegacyListPlan {
  const _LegacyListPlan(
    this.migrationKey,
    this.entityType,
    this.preferenceKeys,
  );

  final String migrationKey;
  final String entityType;
  final List<String> preferenceKeys;
}
