import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/project.dart';

class ProjectsNotifier extends StateNotifier<List<ProjectData>> {
  ProjectsNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'projects.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => ProjectData.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((item) => item.toJson()).toList()),
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
    unawaited(_persist());
    return project;
  }

  void update(ProjectData updated) {
    state = [for (final item in state) if (item.id == updated.id) updated else item];
    unawaited(_persist());
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(_persist());
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
    unawaited(_persist());
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
    unawaited(_persist());
  }

  void addAttachment(String projectId, ProjectAttachment attachment) {
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(attachments: [...item.attachments, attachment])
        else
          item,
    ];
    unawaited(_persist());
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
    unawaited(_persist());
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<ProjectData>>(
  (ref) => ProjectsNotifier(),
);
