enum SharePermission { view, check, edit }

enum ShareStatus { local, queued, synced, revoked }

class ShareGrant {
  const ShareGrant({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.personId,
    required this.createdAt,
    this.permission = SharePermission.view,
    this.status = ShareStatus.queued,
  });

  factory ShareGrant.fromJson(Map<String, Object?> json) => ShareGrant(
        id: json['id']! as String,
        entityType: json['entityType']! as String,
        entityId: json['entityId']! as String,
        personId: json['personId']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        permission: SharePermission.values.firstWhere(
          (value) => value.name == json['permission'],
          orElse: () => SharePermission.view,
        ),
        status: ShareStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ShareStatus.queued,
        ),
      );

  final String id;
  final String entityType;
  final String entityId;
  final String personId;
  final SharePermission permission;
  final ShareStatus status;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'personId': personId,
        'permission': permission.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
