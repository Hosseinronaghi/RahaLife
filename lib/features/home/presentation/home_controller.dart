import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/home_entry.dart';

class HomeEntriesNotifier extends StateNotifier<List<HomeEntry>> {
  HomeEntriesNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'home_entry';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.home.entries.v1',
        entityType: _entityType,
        preferenceKeys: const ['home.entries.v1'],
      );
      final restored =
          (await _repository.loadAll(
              _entityType,
            )).map(HomeEntry.fromJson).toList(growable: false)
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      state = restored;
    } catch (error) {
      WriteStatus.report(error);
      // A malformed legacy record must not prevent the app from opening.
    }
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    await _ready;
    await _repository.replaceAll(
      _entityType,
      state.map((item) => item.toJson()),
    );
  }

  HomeEntry add({
    required HomeEntryType type,
    required String title,
    required DateTime dateTime,
    String? details,
    String? subtype,
    String? personId,
    double? amount,
    String? location,
    String? address,
    String? linkedShoppingListId,
    String? projectId,
    String calendar = 'gregorian',
    ReminderPlan reminder = const ReminderPlan(),
  }) {
    final entry = HomeEntry(
      id: _uuid.v4(),
      type: type,
      title: title.trim(),
      details: details == null || details.trim().isEmpty
          ? null
          : details.trim(),
      dateTime: dateTime,
      subtype: subtype,
      personId: personId,
      amount: amount,
      location: location == null || location.trim().isEmpty
          ? null
          : location.trim(),
      address: address == null || address.trim().isEmpty
          ? null
          : address.trim(),
      linkedShoppingListId: linkedShoppingListId,
      projectId: projectId,
      calendar: calendar,
      reminder: reminder,
    );
    state = [...state, entry]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    WriteStatus.track(_persist());
    return entry;
  }

  void toggle(String id, {DateTime? date}) {
    final day = date ?? DateTime.now();
    state = [
      for (final item in state)
        if (item.id == id)
          item.recurring
              ? item.copyWith(
                  completedDates: item.completedOn(day)
                      ? item.completedDates
                            .where((d) => d != item.dayKey(day))
                            .toList()
                      : [...item.completedDates, item.dayKey(day)],
                )
              : item.copyWith(completed: !item.completed)
        else
          item,
    ];
    WriteStatus.track(_persist());
  }

  void update(HomeEntry entry) {
    state = [
      for (final item in state)
        if (item.id == entry.id) entry else item,
    ];
    WriteStatus.track(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(ReminderService.instance.cancel('home:$id'));
    WriteStatus.track(_persist());
  }

  List<HomeEntry> forDate(DateTime date) =>
      state.where((item) => item.occursOn(date)).toList(growable: false);

  List<HomeEntry> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return state
        .where(
          (item) =>
              item.title.toLowerCase().contains(normalized) ||
              (item.details?.toLowerCase().contains(normalized) ?? false),
        )
        .toList(growable: false);
  }
}

final homeEntriesProvider =
    StateNotifierProvider<HomeEntriesNotifier, List<HomeEntry>>(
      (ref) => HomeEntriesNotifier(),
    );
