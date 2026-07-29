import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../domain/cycle_log.dart';

class CycleNotifier extends StateNotifier<List<CycleLog>> {
  CycleNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'cycle.logs.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      state = (jsonDecode(raw) as List<dynamic>)
          .map((item) => CycleLog.fromJson(Map<String, Object?>.from(item as Map)))
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((item) => item.toJson()).toList()));
  }

  CycleLog add({
    required DateTime startDate,
    DateTime? endDate,
    required FlowIntensity flow,
    required int painLevel,
    required CycleMood mood,
    String? notes,
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
      predictionReminder: predictionReminder,
      predictionReminderTime: predictionReminderTime,
    );
    state = [...state, log]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    unawaited(_persist());
    return log;
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    unawaited(ReminderService.instance.cancel('cycle:$id'));
    unawaited(_persist());
  }

  DateTime? get predictedNextStart {
    if (state.isEmpty) return null;
    if (state.length == 1) return state.first.startDate.add(const Duration(days: 28));
    final sorted = [...state]..sort((a, b) => a.startDate.compareTo(b.startDate));
    var sum = 0;
    for (var index = 1; index < sorted.length; index++) {
      sum += sorted[index].startDate.difference(sorted[index - 1].startDate).inDays.abs();
    }
    final average = (sum / (sorted.length - 1)).round().clamp(21, 45).toInt();
    return sorted.last.startDate.add(Duration(days: average));
  }
}

final cycleProvider = StateNotifierProvider<CycleNotifier, List<CycleLog>>((ref) => CycleNotifier());
