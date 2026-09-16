import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/inbox_item.dart';

class InboxNotifier extends StateNotifier<List<InboxItem>> {
  InboxNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'inbox_item';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.inbox.items.v1',
        entityType: _entityType,
        preferenceKeys: const ['inbox.items.v1'],
      );
      state =
          (await _repository.loadAll(
              _entityType,
            )).map(InboxItem.fromJson).toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  void add(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    state = [
      InboxItem(id: _uuid.v4(), text: value, createdAt: DateTime.now().toUtc()),
      ...state,
    ];
    WriteStatus.track(_persist());
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    WriteStatus.track(_persist());
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, List<InboxItem>>(
  (ref) => InboxNotifier(),
);
