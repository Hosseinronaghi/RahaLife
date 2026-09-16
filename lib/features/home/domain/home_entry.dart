import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/notifications/reminder_models.dart';

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
  shopping,
  bill,
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
    this.completedDates = const [],
    this.calendar = 'gregorian',
    this.subtype,
    this.personId,
    this.amount,
    this.location,
    this.address,
    this.linkedShoppingListId,
    this.projectId,
    this.reminder = const ReminderPlan(),
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
      completedDates: (json['completedDates'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      calendar: json['calendar']?.toString() ?? 'gregorian',
      subtype: json['subtype'] as String?,
      personId: json['personId'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      location: json['location'] as String?,
      address: json['address'] as String?,
      linkedShoppingListId: json['linkedShoppingListId'] as String?,
      projectId: json['projectId'] as String?,
      reminder: ReminderPlan.fromJson(
        json['reminder'] is Map
            ? Map<String, Object?>.from(json['reminder']! as Map)
            : null,
      ),
    );
  }

  final String id;
  final HomeEntryType type;
  final String title;
  final String? details;
  final DateTime dateTime;
  final bool completed;
  final List<String> completedDates;
  final String calendar;
  bool get recurring =>
      type == HomeEntryType.habit ||
      type == HomeEntryType.birthday ||
      reminder.repeat != ReminderRepeat.none;
  String dayKey(DateTime day) => '${day.year}-${day.month}-${day.day}';
  bool completedOn(DateTime day) =>
      recurring ? completedDates.contains(dayKey(day)) : completed;
  final String? subtype;
  final String? personId;
  final double? amount;
  final String? location;
  final String? address;
  final String? linkedShoppingListId;
  final String? projectId;
  final ReminderPlan reminder;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'details': details,
    'dateTime': dateTime.toIso8601String(),
    'completed': completed,
    'completedDates': completedDates,
    'calendar': calendar,
    'subtype': subtype,
    'personId': personId,
    'amount': amount,
    'location': location,
    'address': address,
    'linkedShoppingListId': linkedShoppingListId,
    'projectId': projectId,
    'reminder': reminder.toJson(),
  };

  HomeEntry copyWith({
    String? title,
    String? details,
    DateTime? dateTime,
    bool? completed,
    List<String>? completedDates,
    String? calendar,
    String? subtype,
    String? personId,
    double? amount,
    String? location,
    String? address,
    String? linkedShoppingListId,
    String? projectId,
    ReminderPlan? reminder,
  }) => HomeEntry(
    id: id,
    type: type,
    title: title ?? this.title,
    details: details ?? this.details,
    dateTime: dateTime ?? this.dateTime,
    completed: completed ?? this.completed,
    completedDates: completedDates ?? this.completedDates,
    calendar: calendar ?? this.calendar,
    subtype: subtype ?? this.subtype,
    personId: personId ?? this.personId,
    amount: amount ?? this.amount,
    location: location ?? this.location,
    address: address ?? this.address,
    linkedShoppingListId: linkedShoppingListId ?? this.linkedShoppingListId,
    projectId: projectId ?? this.projectId,
    reminder: reminder ?? this.reminder,
  );

  bool occursOn(DateTime date) {
    final start = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final target = DateTime(date.year, date.month, date.day);
    if (type != HomeEntryType.birthday && target.isBefore(start)) {
      return false;
    }
    final repeat = type == HomeEntryType.birthday
        ? ReminderRepeat.yearly
        : (type == HomeEntryType.habit && reminder.repeat == ReminderRepeat.none
              ? ReminderRepeat.daily
              : reminder.repeat);
    if (repeat == ReminderRepeat.daily) {
      return true;
    }
    if (repeat == ReminderRepeat.weekly) {
      return date.weekday == dateTime.weekday;
    }
    if (repeat == ReminderRepeat.monthly || repeat == ReminderRepeat.yearly) {
      if (calendar == 'jalali') {
        final a = Jalali.fromDateTime(dateTime), b = Jalali.fromDateTime(date);
        return a.day == b.day &&
            (repeat == ReminderRepeat.monthly || a.month == b.month);
      }
      return dateTime.day == date.day &&
          (repeat == ReminderRepeat.monthly || dateTime.month == date.month);
    }
    return target == start;
  }
}
