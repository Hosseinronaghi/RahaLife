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

class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.name,
    required this.form,
    required this.dosage,
    required this.time,
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
  final MedicationForm form;
  final String dosage;
  final String time;
  final String? instructions;
  final double? stock;
  final bool active;
  final ReminderPlan reminder;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'form': form.name,
        'dosage': dosage,
        'time': time,
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
        form: form,
        dosage: dosage,
        time: time,
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
