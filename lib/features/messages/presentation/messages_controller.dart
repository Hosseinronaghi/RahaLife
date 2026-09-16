import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/message.dart';

class MessagesNotifier extends StateNotifier<List<LocalMessage>> {
  MessagesNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'message';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.messages.local.v1',
        entityType: _entityType,
        preferenceKeys: const ['messages.local.v1'],
      );
      state =
          (await _repository.loadAll(
              _entityType,
            )).map(LocalMessage.fromJson).toList(growable: false)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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

  void send({
    required String personId,
    required String body,
    String? entityType,
    String? entityId,
    String? attachmentName,
    String? attachmentPath,
  }) {
    if (body.trim().isEmpty && entityId == null && attachmentName == null) {
      return;
    }
    state = [
      ...state,
      LocalMessage(
        id: _uuid.v4(),
        personId: personId,
        body: body.trim(),
        createdAt: DateTime.now().toUtc(),
        sharedEntityType: entityType,
        sharedEntityId: entityId,
        attachmentName: attachmentName,
        attachmentPath: attachmentPath,
      ),
    ];
    WriteStatus.track(_persist());
  }
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<LocalMessage>>(
      (ref) => MessagesNotifier(),
    );
