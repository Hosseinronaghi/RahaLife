import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/medication_plan.dart';

class MedicationNotifier extends StateNotifier<List<MedicationPlan>> {
  MedicationNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'medication_plan';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.medications.v1',
        entityType: _entityType,
        preferenceKeys: const ['medications.v1'],
      );
      state = (await _repository.loadAll(
        _entityType,
      )).map(MedicationPlan.fromJson).toList(growable: false);
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

  MedicationPlan add({
    required String name,
    required MedicationForm form,
    required String dosage,
    required String time,
    String? genericName,
    String? brandName,
    String? therapeuticGroup,
    String? commonUse,
    String? reasonForUse,
    MedicationCourseType courseType = MedicationCourseType.continuous,
    DateTime? startDate,
    DateTime? endDate,
    int? courseDays,
    String? instructions,
    double? stock,
    ReminderPlan reminder = const ReminderPlan(
      enabled: true,
      repeat: ReminderRepeat.daily,
    ),
  }) {
    final plan = MedicationPlan(
      id: _uuid.v4(),
      name: name.trim(),
      form: form,
      dosage: dosage.trim(),
      time: time,
      genericName: genericName?.trim(),
      brandName: brandName?.trim(),
      therapeuticGroup: therapeuticGroup?.trim(),
      commonUse: commonUse?.trim(),
      reasonForUse: reasonForUse?.trim(),
      courseType: courseType,
      startDate: startDate,
      endDate: endDate,
      courseDays: courseDays,
      instructions: instructions?.trim(),
      stock: stock,
      reminder: reminder,
    );
    state = [...state, plan];
    WriteStatus.track(_persist());
    return plan;
  }

  MedicationPlan? toggleActive(String id) {
    MedicationPlan? updated;
    state = [
      for (final item in state)
        if (item.id == id)
          updated = item.copyWith(active: !item.active)
        else
          item,
    ];
    WriteStatus.track(_persist());
    if (updated != null && !updated.active) {
      unawaited(ReminderService.instance.cancel('medication:$id'));
    }
    return updated;
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    unawaited(ReminderService.instance.cancel('medication:$id'));
    WriteStatus.track(_persist());
  }
}

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, List<MedicationPlan>>(
      (ref) => MedicationNotifier(),
    );
