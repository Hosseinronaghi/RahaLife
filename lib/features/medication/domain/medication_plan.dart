import '../../../core/notifications/reminder_models.dart';

enum MedicationForm {
  tablet,
  capsule,
  syrup,
  drops,
  injection,
  cream,
  inhaler,
  other,
}

enum MedicationCourseType { continuous, fixedDate, fixedDays, asNeeded }

class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.name,
    required this.form,
    required this.dosage,
    required this.time,
    this.genericName,
    this.brandName,
    this.therapeuticGroup,
    this.commonUse,
    this.reasonForUse,
    this.courseType = MedicationCourseType.continuous,
    this.startDate,
    this.endDate,
    this.courseDays,
    this.instructions,
    this.stock,
    this.active = true,
    this.reminder = const ReminderPlan(
      enabled: true,
      repeat: ReminderRepeat.daily,
    ),
  });

  factory MedicationPlan.fromJson(Map<String, Object?> json) => MedicationPlan(
        id: json['id']! as String,
        name: json['name']! as String,
        form: MedicationForm.values.firstWhere(
          (value) => value.name == json['form'],
          orElse: () => MedicationForm.tablet,
        ),
        dosage: json['dosage']! as String,
        time: json['time']! as String,
        genericName: json['genericName'] as String?,
        brandName: json['brandName'] as String?,
        therapeuticGroup: json['therapeuticGroup'] as String?,
        commonUse: json['commonUse'] as String?,
        reasonForUse: json['reasonForUse'] as String?,
        courseType: MedicationCourseType.values.firstWhere(
          (value) => value.name == json['courseType'],
          orElse: () => MedicationCourseType.continuous,
        ),
        startDate: json['startDate'] == null ? null : DateTime.tryParse(json['startDate']! as String),
        endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate']! as String),
        courseDays: (json['courseDays'] as num?)?.toInt(),
        instructions: json['instructions'] as String?,
        stock: (json['stock'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
        reminder: ReminderPlan.fromJson(
          json['reminder'] is Map
              ? Map<String, Object?>.from(json['reminder']! as Map)
              : null,
        ),
      );

  final String id;
  final String name;
  final String? genericName;
  final String? brandName;
  final MedicationForm form;
  final String dosage;
  final String time;
  final String? therapeuticGroup;
  final String? commonUse;
  final String? reasonForUse;
  final MedicationCourseType courseType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? courseDays;
  final String? instructions;
  final double? stock;
  final bool active;
  final ReminderPlan reminder;

  DateTime? get calculatedEndDate {
    if (endDate != null) return endDate;
    if (courseType == MedicationCourseType.fixedDays && startDate != null && courseDays != null) {
      return startDate!.add(Duration(days: courseDays!));
    }
    return null;
  }

  bool isCourseFinished([DateTime? now]) {
    final end = calculatedEndDate;
    if (end == null) return false;
    final current = now ?? DateTime.now();
    return current.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'genericName': genericName,
        'brandName': brandName,
        'form': form.name,
        'dosage': dosage,
        'time': time,
        'therapeuticGroup': therapeuticGroup,
        'commonUse': commonUse,
        'reasonForUse': reasonForUse,
        'courseType': courseType.name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'courseDays': courseDays,
        'instructions': instructions,
        'stock': stock,
        'active': active,
        'reminder': reminder.toJson(),
      };

  MedicationPlan copyWith({
    bool? active,
    double? stock,
    ReminderPlan? reminder,
  }) =>
      MedicationPlan(
        id: id,
        name: name,
        genericName: genericName,
        brandName: brandName,
        form: form,
        dosage: dosage,
        time: time,
        therapeuticGroup: therapeuticGroup,
        commonUse: commonUse,
        reasonForUse: reasonForUse,
        courseType: courseType,
        startDate: startDate,
        endDate: endDate,
        courseDays: courseDays,
        instructions: instructions,
        stock: stock ?? this.stock,
        active: active ?? this.active,
        reminder: reminder ?? this.reminder,
      );

  DateTime nextDoseDateTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var result = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (!result.isAfter(current)) result = result.add(const Duration(days: 1));
    return result;
  }
}
