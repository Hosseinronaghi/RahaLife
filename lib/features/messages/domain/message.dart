enum MessageSyncStatus { pending, synced, failed }

class LocalMessage {
  const LocalMessage({
    required this.id,
    required this.personId,
    required this.body,
    required this.createdAt,
    this.outgoing = true,
    this.syncStatus = MessageSyncStatus.pending,
    this.sharedEntityType,
    this.sharedEntityId,
    this.attachmentName,
    this.attachmentPath,
    this.readAt,
  });

  factory LocalMessage.fromJson(Map<String, Object?> json) => LocalMessage(
        id: json['id']! as String,
        personId: json['personId']! as String,
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt']! as String),
        outgoing: json['outgoing'] as bool? ?? true,
        syncStatus: MessageSyncStatus.values.firstWhere(
          (value) => value.name == json['syncStatus'],
          orElse: () => MessageSyncStatus.pending,
        ),
        sharedEntityType: json['sharedEntityType'] as String?,
        sharedEntityId: json['sharedEntityId'] as String?,
        attachmentName: json['attachmentName'] as String?,
        attachmentPath: json['attachmentPath'] as String?,
        readAt: json['readAt'] == null
            ? null
            : DateTime.tryParse(json['readAt']! as String),
      );

  final String id;
  final String personId;
  final String body;
  final DateTime createdAt;
  final bool outgoing;
  final MessageSyncStatus syncStatus;
  final String? sharedEntityType;
  final String? sharedEntityId;
  final String? attachmentName;
  final String? attachmentPath;
  final DateTime? readAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'personId': personId,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'outgoing': outgoing,
        'syncStatus': syncStatus.name,
        'sharedEntityType': sharedEntityType,
        'sharedEntityId': sharedEntityId,
        'attachmentName': attachmentName,
        'attachmentPath': attachmentPath,
        'readAt': readAt?.toIso8601String(),
      };
}
