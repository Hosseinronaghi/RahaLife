class RichNote {
  const RichNote({
    required this.id,
    required this.title,
    required this.deltaJson,
    required this.plainText,
    required this.updatedAt,
    this.tags = const [],
    this.pinned = false,
    this.archived = false,
    this.projectId,
    this.personId,
    this.scheduledAt,
  });

  factory RichNote.fromJson(Map<String, Object?> json) => RichNote(
        id: json['id']! as String,
        title: json['title'] as String? ?? '',
        deltaJson: json['deltaJson'] as String? ??
            '[{"insert":"${(json['plainText'] as String? ?? '').replaceAll('"', '\\"')}\\n"}]',
        plainText: json['plainText'] as String? ?? '',
        updatedAt: DateTime.parse(json['updatedAt']! as String),
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        pinned: json['pinned'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        projectId: json['projectId'] as String?,
        personId: json['personId'] as String?,
        scheduledAt: json['scheduledAt'] == null
            ? null
            : DateTime.parse(json['scheduledAt']! as String),
      );

  final String id;
  final String title;
  final String deltaJson;
  final String plainText;
  final List<String> tags;
  final bool pinned;
  final bool archived;
  final String? projectId;
  final String? personId;
  final DateTime? scheduledAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'deltaJson': deltaJson,
        'plainText': plainText,
        'tags': tags,
        'pinned': pinned,
        'archived': archived,
        'projectId': projectId,
        'personId': personId,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  RichNote copyWith({
    String? title,
    String? deltaJson,
    String? plainText,
    List<String>? tags,
    bool? pinned,
    bool? archived,
    String? projectId,
    String? personId,
    DateTime? scheduledAt,
    DateTime? updatedAt,
  }) =>
      RichNote(
        id: id,
        title: title ?? this.title,
        deltaJson: deltaJson ?? this.deltaJson,
        plainText: plainText ?? this.plainText,
        tags: tags ?? this.tags,
        pinned: pinned ?? this.pinned,
        archived: archived ?? this.archived,
        projectId: projectId ?? this.projectId,
        personId: personId ?? this.personId,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
