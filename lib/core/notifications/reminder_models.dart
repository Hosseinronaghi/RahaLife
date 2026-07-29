enum ReminderKind { notification, alarm }

enum ReminderRepeat { none, daily, weekly, monthly, yearly }

class ReminderPlan {
  const ReminderPlan({
    this.enabled = false,
    this.kind = ReminderKind.notification,
    this.minutesBefore = 0,
    this.repeat = ReminderRepeat.none,
  });

  factory ReminderPlan.fromJson(Map<String, Object?>? json) {
    if (json == null) return const ReminderPlan();
    return ReminderPlan(
      enabled: json['enabled'] as bool? ?? false,
      kind: ReminderKind.values.firstWhere(
        (item) => item.name == json['kind'],
        orElse: () => ReminderKind.notification,
      ),
      minutesBefore: (json['minutesBefore'] as num?)?.toInt() ?? 0,
      repeat: ReminderRepeat.values.firstWhere(
        (item) => item.name == json['repeat'],
        orElse: () => ReminderRepeat.none,
      ),
    );
  }

  final bool enabled;
  final ReminderKind kind;
  final int minutesBefore;
  final ReminderRepeat repeat;

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'kind': kind.name,
        'minutesBefore': minutesBefore,
        'repeat': repeat.name,
      };

  ReminderPlan copyWith({
    bool? enabled,
    ReminderKind? kind,
    int? minutesBefore,
    ReminderRepeat? repeat,
  }) =>
      ReminderPlan(
        enabled: enabled ?? this.enabled,
        kind: kind ?? this.kind,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        repeat: repeat ?? this.repeat,
      );
}
