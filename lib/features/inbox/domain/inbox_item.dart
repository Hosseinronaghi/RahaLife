class InboxItem {
  const InboxItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  factory InboxItem.fromJson(Map<String, Object?> json) => InboxItem(
        id: json['id']! as String,
        text: json['text']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}
