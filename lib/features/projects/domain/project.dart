class ProjectChecklistItem {
  const ProjectChecklistItem({
    required this.id,
    required this.title,
    this.done = false,
  });

  factory ProjectChecklistItem.fromJson(Map<String, Object?> json) =>
      ProjectChecklistItem(
        id: json['id']! as String,
        title: json['title']! as String,
        done: json['done'] as bool? ?? false,
      );

  final String id;
  final String title;
  final bool done;

  ProjectChecklistItem copyWith({bool? done}) => ProjectChecklistItem(
        id: id,
        title: title,
        done: done ?? this.done,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'done': done,
      };
}

class ProjectAttachment {
  const ProjectAttachment({
    required this.id,
    required this.name,
    required this.size,
    this.path,
  });

  factory ProjectAttachment.fromJson(Map<String, Object?> json) =>
      ProjectAttachment(
        id: json['id']! as String,
        name: json['name']! as String,
        size: (json['size'] as num?)?.toInt() ?? 0,
        path: json['path'] as String?,
      );

  final String id;
  final String name;
  final int size;
  final String? path;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'path': path,
      };
}

enum ProjectStatus { active, paused, done, archived }

class ProjectData {
  const ProjectData({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.status = ProjectStatus.active,
    this.progress = 0,
    this.startDate,
    this.dueDate,
    this.personIds = const [],
    this.checklist = const [],
    this.attachments = const [],
  });

  factory ProjectData.fromJson(Map<String, Object?> json) => ProjectData(
        id: json['id']! as String,
        title: json['title']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        description: json['description'] as String?,
        status: ProjectStatus.values.firstWhere(
          (item) => item.name == json['status'],
          orElse: () => ProjectStatus.active,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        startDate: json['startDate'] == null
            ? null
            : DateTime.parse(json['startDate']! as String),
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate']! as String),
        personIds: (json['personIds'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        checklist: (json['checklist'] as List<dynamic>? ?? const [])
            .map(
              (item) => ProjectChecklistItem.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(growable: false),
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map(
              (item) => ProjectAttachment.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );

  final String id;
  final String title;
  final String? description;
  final ProjectStatus status;
  final double progress;
  final DateTime? startDate;
  final DateTime? dueDate;
  final List<String> personIds;
  final List<ProjectChecklistItem> checklist;
  final List<ProjectAttachment> attachments;
  final DateTime createdAt;

  double get checklistProgress {
    if (checklist.isEmpty) return progress.clamp(0, 1);
    return checklist.where((item) => item.done).length / checklist.length;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'progress': progress,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'personIds': personIds,
        'checklist': checklist.map((item) => item.toJson()).toList(),
        'attachments': attachments.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  ProjectData copyWith({
    String? title,
    String? description,
    ProjectStatus? status,
    double? progress,
    DateTime? startDate,
    DateTime? dueDate,
    List<String>? personIds,
    List<ProjectChecklistItem>? checklist,
    List<ProjectAttachment>? attachments,
  }) =>
      ProjectData(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        personIds: personIds ?? this.personIds,
        checklist: checklist ?? this.checklist,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );
}
