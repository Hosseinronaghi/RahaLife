import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/cycle_log.dart';

class CycleNotifier extends StateNotifier<List<CycleLog>> {
  CycleNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'cycle_log';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.cycle.logs.v1',
        entityType: _entityType,
        preferenceKeys: const ['cycle.logs.v1'],
      );
      state =
          (await _repository.loadAll(
              _entityType,
            )).map(CycleLog.fromJson).toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));
    } catch (error) {
      WriteStatus.report(error);
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

  CycleLog add({
    required DateTime startDate,
    DateTime? endDate,
    required FlowIntensity flow,
    required int painLevel,
    required CycleMood mood,
    String? notes,
    List<String> symptoms = const [],
    ReminderPlan predictionReminder = const ReminderPlan(),
    String predictionReminderTime = '09:00',
  }) {
    final log = CycleLog(
      id: _uuid.v4(),
      startDate: startDate,
      endDate: endDate,
      flow: flow,
      painLevel: painLevel,
      mood: mood,
      notes: notes?.trim(),
      symptoms: symptoms,
      predictionReminder: predictionReminder,
      predictionReminderTime: predictionReminderTime,
    );
    state = [...state, log]..sort((a, b) => b.startDate.compareTo(a.startDate));
    WriteStatus.track(_persist());
    return log;
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    unawaited(ReminderService.instance.cancel('cycle:$id'));
    WriteStatus.track(_persist());
  }

  DateTime? get predictedNextStart {
    if (state.isEmpty) return null;
    if (state.length == 1) {
      return state.first.startDate.add(const Duration(days: 28));
    }
    final sorted = [...state]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    var sum = 0;
    for (var index = 1; index < sorted.length; index++) {
      sum += sorted[index].startDate
          .difference(sorted[index - 1].startDate)
          .inDays
          .abs();
    }
    final average = (sum / (sorted.length - 1)).round().clamp(21, 45).toInt();
    return sorted.last.startDate.add(Duration(days: average));
  }
}

final cycleProvider = StateNotifierProvider<CycleNotifier, List<CycleLog>>(
  (ref) => CycleNotifier(),
);

class CyclePrivacyNotifier extends StateNotifier<bool> {
  CyclePrivacyNotifier() : super(true) {
    unawaited(_loadPrivacy());
  }

  static const _privacyKey = 'cycle.privacy.hideSensitive.v1';

  Future<void> _loadPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_privacyKey) ?? true;
  }

  Future<void> setHideSensitive(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, value);
  }
}

final cyclePrivacyProvider = StateNotifierProvider<CyclePrivacyNotifier, bool>(
  (ref) => CyclePrivacyNotifier(),
);
