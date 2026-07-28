enum HomeEntryType {
  task,
  medication,
  appointment,
  note,
  shopping,
  finance,
  habit,
  birthday,
}

class HomeEntry {
  const HomeEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    this.details,
    this.completed = false,
    this.amount,
  });

  factory HomeEntry.fromJson(Map<String, Object?> json) => HomeEntry(
        id: json['id']! as String,
        type: HomeEntryType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => HomeEntryType.task,
        ),
        title: json['title']! as String,
        details: json['details'] as String?,
        dateTime: DateTime.parse(json['dateTime']! as String),
        completed: json['completed'] as bool? ?? false,
        amount: (json['amount'] as num?)?.toDouble(),
      );

  final String id;
  final HomeEntryType type;
  final String title;
  final String? details;
  final DateTime dateTime;
  final bool completed;
  final double? amount;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'details': details,
        'dateTime': dateTime.toIso8601String(),
        'completed': completed,
        'amount': amount,
      };

  HomeEntry copyWith({
    String? title,
    String? details,
    DateTime? dateTime,
    bool? completed,
    double? amount,
  }) =>
      HomeEntry(
        id: id,
        type: type,
        title: title ?? this.title,
        details: details ?? this.details,
        dateTime: dateTime ?? this.dateTime,
        completed: completed ?? this.completed,
        amount: amount ?? this.amount,
      );

  bool occursOn(DateTime date) {
    if (type == HomeEntryType.birthday) {
      return date.month == dateTime.month && date.day == dateTime.day;
    }
    return date.year == dateTime.year &&
        date.month == dateTime.month &&
        date.day == dateTime.day;
  }
}
