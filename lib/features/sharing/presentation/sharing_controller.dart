import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/share_models.dart';

class SharingNotifier extends StateNotifier<List<ShareGrant>> {
  SharingNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'share_grant';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.sharing.grants.v1',
        entityType: _entityType,
        preferenceKeys: const ['sharing.grants.v1'],
      );
      state = (await _repository.loadAll(
        _entityType,
      )).map(ShareGrant.fromJson).toList(growable: false);
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

  void share({
    required String entityType,
    required String entityId,
    required Iterable<String> personIds,
    required SharePermission permission,
  }) {
    final withoutOld = state.where(
      (item) => !(item.entityType == entityType && item.entityId == entityId),
    );
    state = [
      ...withoutOld,
      for (final personId in personIds)
        ShareGrant(
          id: _uuid.v4(),
          entityType: entityType,
          entityId: entityId,
          personId: personId,
          permission: permission,
          createdAt: DateTime.now().toUtc(),
        ),
    ];
    WriteStatus.track(_persist());
  }

  void revoke(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    WriteStatus.track(_persist());
  }
}

final sharingProvider =
    StateNotifierProvider<SharingNotifier, List<ShareGrant>>(
      (ref) => SharingNotifier(),
    );
