import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/project.dart';

class ProjectsNotifier extends StateNotifier<List<ProjectData>> {
  ProjectsNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'project';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.projects.v1',
        entityType: _entityType,
        preferenceKeys: const ['projects.v1'],
      );
      state = (await _repository.loadAll(
        _entityType,
      )).map(ProjectData.fromJson).toList(growable: false);
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

  ProjectData add({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    List<String> personIds = const [],
  }) {
    final project = ProjectData(
      id: _uuid.v4(),
      title: title.trim(),
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      startDate: startDate,
      dueDate: dueDate,
      personIds: personIds,
      createdAt: DateTime.now().toUtc(),
    );
    state = [...state, project];
    WriteStatus.track(_persist());
    return project;
  }

  void update(ProjectData updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    WriteStatus.track(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    WriteStatus.track(_persist());
  }

  void addChecklist(String projectId, String title) {
    final text = title.trim();
    if (text.isEmpty) return;
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            checklist: [
              ...item.checklist,
              ProjectChecklistItem(id: _uuid.v4(), title: text),
            ],
          )
        else
          item,
    ];
    WriteStatus.track(_persist());
  }

  void toggleChecklist(String projectId, String checklistId) {
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            checklist: [
              for (final check in item.checklist)
                if (check.id == checklistId)
                  check.copyWith(done: !check.done)
                else
                  check,
            ],
          )
        else
          item,
    ];
    WriteStatus.track(_persist());
  }

  void addAttachment(String projectId, ProjectAttachment attachment) {
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(attachments: [...item.attachments, attachment])
        else
          item,
    ];
    WriteStatus.track(_persist());
  }

  void removeAttachment(String projectId, String attachmentId) {
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            attachments: item.attachments
                .where((attachment) => attachment.id != attachmentId)
                .toList(growable: false),
          )
        else
          item,
    ];
    WriteStatus.track(_persist());
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<ProjectData>>(
      (ref) => ProjectsNotifier(),
    );
