import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/inbox_item.dart';

class InboxNotifier extends StateNotifier<List<InboxItem>> {
  InboxNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'inbox.items.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = (jsonDecode(raw) as List<dynamic>)
          .map((item) => InboxItem.fromJson(Map<String, Object?>.from(item as Map)))
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((item) => item.toJson()).toList()));
  }

  void add(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    state = [InboxItem(id: _uuid.v4(), text: value, createdAt: DateTime.now().toUtc()), ...state];
    unawaited(_persist());
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(_persist());
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, List<InboxItem>>(
  (ref) => InboxNotifier(),
);
