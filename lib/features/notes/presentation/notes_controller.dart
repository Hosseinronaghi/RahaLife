import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/rich_note.dart';

class NotesNotifier extends StateNotifier<List<RichNote>> {
  NotesNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'rich_note';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.notes.rich.v1',
        entityType: _entityType,
        preferenceKeys: const ['notes.rich.v1'],
      );
      state = (await _repository.loadAll(
        _entityType,
      )).map(RichNote.fromJson).toList(growable: false)..sort(_sortNotes);
    } catch (error) {
      WriteStatus.report(error);
    }
  }

  static int _sortNotes(RichNote a, RichNote b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    await _ready;
    await _repository.replaceAll(
      _entityType,
      state.map((item) => item.toJson()),
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
    WriteStatus.track(_persist());
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
    WriteStatus.track(_persist());
  }

  void archive(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(archived: true, updatedAt: DateTime.now().toUtc())
        else
          item,
    ];
    WriteStatus.track(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    WriteStatus.track(_persist());
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<RichNote>>(
  (ref) => NotesNotifier(),
);
