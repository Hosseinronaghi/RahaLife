/// A user-entered outcome for one scheduled occurrence. No row means unknown,
/// never an inferred missed dose. Stable occurrence identity prevents duplicates.
enum DoseOutcome { taken, notTaken, postponed }

class MedicationDose {
  const MedicationDose({
    required this.id,
    required this.planId,
    required this.scheduledAt,
    required this.outcome,
    required this.recordedAt,
    this.takenAt,
    this.reason,
    this.remindAt,
  });
  final String id, planId;
  final DateTime scheduledAt, recordedAt;
  final DoseOutcome outcome;
  final DateTime? takenAt, remindAt;
  final String? reason;
  static String occurrenceId(String planId, DateTime scheduledAt) =>
      '$planId:${scheduledAt.toUtc().toIso8601String()}';
  factory MedicationDose.fromJson(Map<String, Object?> j) => MedicationDose(
    id: j['id']! as String,
    planId: j['planId']! as String,
    scheduledAt: DateTime.parse(j['scheduledAt']! as String),
    recordedAt: DateTime.parse(j['recordedAt']! as String),
    outcome: DoseOutcome.values.byName(j['outcome']! as String),
    takenAt: DateTime.tryParse(j['takenAt']?.toString() ?? ''),
    remindAt: DateTime.tryParse(j['remindAt']?.toString() ?? ''),
    reason: j['reason'] as String?,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'planId': planId,
    'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'outcome': outcome.name,
    'takenAt': takenAt?.toUtc().toIso8601String(),
    'reason': reason,
    'remindAt': remindAt?.toUtc().toIso8601String(),
  };
}
