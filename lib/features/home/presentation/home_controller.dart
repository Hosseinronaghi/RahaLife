import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/home_entry.dart';

class HomeEntriesNotifier extends StateNotifier<List<HomeEntry>> {
  HomeEntriesNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _uuid = Uuid();
  static const _storageKey = 'home.entries.v1';
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final restored = decoded
          .map(
            (item) => HomeEntry.fromJson(
              Map<String, Object?>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      state = restored;
    } catch (_) {
      // Keep the app usable if an old or damaged local payload cannot be read.
    }
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(state.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Persistence errors must not block local interaction.
    }
  }

  void add({
    required HomeEntryType type,
    required String title,
    required DateTime dateTime,
    String? details,
    double? amount,
  }) {
    final entry = HomeEntry(
      id: _uuid.v4(),
      type: type,
      title: title.trim(),
      details: details == null || details.trim().isEmpty
          ? null
          : details.trim(),
      dateTime: dateTime,
      amount: amount,
    );
    state = [...state, entry]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    unawaited(_persist());
  }

  void toggle(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(completed: !item.completed) else item,
    ];
    unawaited(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(_persist());
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
