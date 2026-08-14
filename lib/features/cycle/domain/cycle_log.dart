import '../../../core/notifications/reminder_models.dart';

enum FlowIntensity { light, medium, heavy }

enum CycleMood { calm, sensitive, low, energetic, irritable, other }

class CycleLog {
  const CycleLog({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.flow,
    required this.painLevel,
    required this.mood,
    this.notes,
    this.symptoms = const [],
    this.predictionReminder = const ReminderPlan(),
    this.predictionReminderTime = '09:00',
  });

  factory CycleLog.fromJson(Map<String, Object?> json) => CycleLog(
        id: json['id']! as String,
        startDate: DateTime.parse(json['startDate']! as String),
        endDate: json['endDate'] == null
            ? null
            : DateTime.parse(json['endDate']! as String),
        flow: FlowIntensity.values.firstWhere(
          (value) => value.name == json['flow'],
          orElse: () => FlowIntensity.medium,
        ),
        painLevel: json['painLevel'] as int? ?? 0,
        mood: CycleMood.values.firstWhere(
          (value) => value.name == json['mood'],
          orElse: () => CycleMood.other,
        ),
        notes: json['notes'] as String?,
        symptoms: (json['symptoms'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(growable: false),
        predictionReminder: ReminderPlan.fromJson(
          json['predictionReminder'] is Map
              ? Map<String, Object?>.from(json['predictionReminder']! as Map)
              : null,
        ),
        predictionReminderTime:
            json['predictionReminderTime'] as String? ?? '09:00',
      );

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flow;
  final int painLevel;
  final CycleMood mood;
  final String? notes;
  final List<String> symptoms;
  final ReminderPlan predictionReminder;
  final String predictionReminderTime;

  Map<String, Object?> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'flow': flow.name,
        'painLevel': painLevel,
        'mood': mood.name,
        'notes': notes,
        'symptoms': symptoms,
        'predictionReminder': predictionReminder.toJson(),
        'predictionReminderTime': predictionReminderTime,
      };
}
