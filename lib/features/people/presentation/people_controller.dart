import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/person.dart';

class PeopleNotifier extends StateNotifier<List<Person>> {
  PeopleNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'people.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((item) => Person.fromJson(Map<String, Object?>.from(item as Map)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  String add({
    required String name,
    String? relationship,
    String? phone,
    String? email,
    DateTime? birthDate,
    String? notes,
  }) {
    final id = _uuid.v4();
    state = [
      ...state,
      Person(
        id: id,
        name: name.trim(),
        relationship: relationship?.trim(),
        phone: phone?.trim(),
        email: email?.trim(),
        birthDate: birthDate,
        notes: notes?.trim(),
      ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    unawaited(_persist());
    return id;
  }

  void delete(String id) {
    state = state.where((person) => person.id != id).toList();
    unawaited(_persist());
  }
}

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>(
  (ref) => PeopleNotifier(),
);
