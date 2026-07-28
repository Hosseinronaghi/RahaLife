import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/medication_plan.dart';

class MedicationNotifier extends StateNotifier<List<MedicationPlan>> {
  MedicationNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'medications.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      state = (jsonDecode(raw) as List<dynamic>)
          .map((item) => MedicationPlan.fromJson(Map<String, Object?>.from(item as Map)))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((item) => item.toJson()).toList()));
  }

  void add({required String name, required MedicationForm form, required String dosage, required String time, String? instructions, double? stock}) {
    state = [...state, MedicationPlan(id: _uuid.v4(), name: name.trim(), form: form, dosage: dosage.trim(), time: time, instructions: instructions?.trim(), stock: stock)];
    unawaited(_persist());
  }

  void toggleActive(String id) {
    state = [for (final item in state) if (item.id == id) item.copyWith(active: !item.active) else item];
    unawaited(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    unawaited(_persist());
  }
}

final medicationProvider = StateNotifierProvider<MedicationNotifier, List<MedicationPlan>>((ref) => MedicationNotifier());
