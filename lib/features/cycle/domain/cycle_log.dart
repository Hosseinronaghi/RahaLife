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
  });

  factory CycleLog.fromJson(Map<String, Object?> json) => CycleLog(
        id: json['id']! as String,
        startDate: DateTime.parse(json['startDate']! as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate']! as String),
        flow: FlowIntensity.values.firstWhere((value) => value.name == json['flow'], orElse: () => FlowIntensity.medium),
        painLevel: json['painLevel'] as int? ?? 0,
        mood: CycleMood.values.firstWhere((value) => value.name == json['mood'], orElse: () => CycleMood.other),
        notes: json['notes'] as String?,
      );

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flow;
  final int painLevel;
  final CycleMood mood;
  final String? notes;

  Map<String, Object?> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'flow': flow.name,
        'painLevel': painLevel,
        'mood': mood.name,
        'notes': notes,
      };
}
