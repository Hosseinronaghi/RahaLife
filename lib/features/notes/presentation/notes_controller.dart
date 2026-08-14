import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/rich_note.dart';

class NotesNotifier extends StateNotifier<List<RichNote>> {
  NotesNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'notes.rich.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => RichNote.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false)
        ..sort(_sortNotes);
    } catch (_) {}
  }

  static int _sortNotes(RichNote a, RichNote b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((item) => item.toJson()).toList()),
    );
  }

  RichNote save({
    String? id,
    required String title,
    required String deltaJson,
    required String plainText,
    List<String> tags = const [],
    String? projectId,
    String? personId,
    DateTime? scheduledAt,
  }) {
    final existing = id == null
        ? null
        : state.cast<RichNote?>().firstWhere(
              (item) => item?.id == id,
              orElse: () => null,
            );
    final note = RichNote(
      id: existing?.id ?? _uuid.v4(),
      title: title.trim(),
      deltaJson: deltaJson,
      plainText: plainText.trim(),
      tags: tags,
      pinned: existing?.pinned ?? false,
      archived: existing?.archived ?? false,
      projectId: projectId,
      personId: personId,
      scheduledAt: scheduledAt,
      updatedAt: DateTime.now().toUtc(),
    );
    state = [
      for (final item in state)
        if (item.id != note.id) item,
      note,
    ]..sort(_sortNotes);
    unawaited(_persist());
    return note;
  }

  void togglePinned(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(pinned: !item.pinned, updatedAt: DateTime.now().toUtc())
        else
          item,
    ]..sort(_sortNotes);
    unawaited(_persist());
  }

  void archive(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(archived: true, updatedAt: DateTime.now().toUtc())
        else
          item,
    ];
    unawaited(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(_persist());
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<RichNote>>(
  (ref) => NotesNotifier(),
);
