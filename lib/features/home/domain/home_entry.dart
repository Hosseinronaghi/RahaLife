enum HomeEntryType {
  affair,
  appointment,
  shopping,
  medication,
  finance,
  note,
  habit,
  birthday,
}

enum AffairKind {
  personal,
  work,
  administrative,
  followUp,
  medical,
  laboratory,
  payment,
  study,
  custom,
}

enum AppointmentKind {
  meeting,
  cafe,
  gathering,
  inPerson,
  phone,
  online,
  party,
  custom,
}

class HomeEntry {
  const HomeEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    this.details,
    this.completed = false,
    this.subtype,
    this.personId,
    this.amount,
  });

  factory HomeEntry.fromJson(Map<String, Object?> json) {
    final rawType = json['type'] as String? ?? 'affair';
    final type = rawType == 'task'
        ? HomeEntryType.affair
        : HomeEntryType.values.firstWhere(
            (value) => value.name == rawType,
            orElse: () => HomeEntryType.affair,
          );
    return HomeEntry(
      id: json['id']! as String,
      type: type,
      title: json['title']! as String,
      details: json['details'] as String?,
      dateTime: DateTime.parse(json['dateTime']! as String),
      completed: json['completed'] as bool? ?? false,
      subtype: json['subtype'] as String?,
      personId: json['personId'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  final String id;
  final HomeEntryType type;
  final String title;
  final String? details;
  final DateTime dateTime;
  final bool completed;
  final String? subtype;
  final String? personId;
  final double? amount;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'details': details,
        'dateTime': dateTime.toIso8601String(),
        'completed': completed,
        'subtype': subtype,
        'personId': personId,
        'amount': amount,
      };

  HomeEntry copyWith({
    String? title,
    String? details,
    DateTime? dateTime,
    bool? completed,
    String? subtype,
    String? personId,
    double? amount,
  }) =>
      HomeEntry(
        id: id,
        type: type,
        title: title ?? this.title,
        details: details ?? this.details,
        dateTime: dateTime ?? this.dateTime,
        completed: completed ?? this.completed,
        subtype: subtype ?? this.subtype,
        personId: personId ?? this.personId,
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
