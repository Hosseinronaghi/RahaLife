import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../localization/locale_formatters.dart';
import '../notifications/reminder_models.dart';

class ReminderEditor extends StatelessWidget {
  const ReminderEditor({
    super.key,
    required this.plan,
    required this.onChanged,
    this.allowedBeforeMinutes = const [0, 5, 10, 15, 30, 60, 120, 1440],
    this.repeatOptions = ReminderRepeat.values,
  });

  final ReminderPlan plan;
  final ValueChanged<ReminderPlan> onChanged;
  final List<int> allowedBeforeMinutes;
  final List<ReminderRepeat> repeatOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminder),
              subtitle: Text(l10n.reminderHint),
              secondary: Icon(
                plan.kind == ReminderKind.alarm
                    ? Icons.alarm_rounded
                    : Icons.notifications_active_outlined,
              ),
              value: plan.enabled,
              onChanged: (value) => onChanged(plan.copyWith(enabled: value)),
            ),
            if (plan.enabled) ...[
              const Divider(),
              SegmentedButton<ReminderKind>(
                segments: [
                  ButtonSegment(
                    value: ReminderKind.notification,
                    icon: const Icon(Icons.notifications_none_rounded),
                    label: Text(l10n.notificationMode),
                  ),
                  ButtonSegment(
                    value: ReminderKind.alarm,
                    icon: const Icon(Icons.alarm_rounded),
                    label: Text(l10n.alarmMode),
                  ),
                ],
                selected: {plan.kind},
                onSelectionChanged: (values) => onChanged(
                  plan.copyWith(kind: values.first),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: allowedBeforeMinutes.contains(plan.minutesBefore)
                    ? plan.minutesBefore
                    : allowedBeforeMinutes.first,
                decoration: InputDecoration(labelText: l10n.remindBefore),
                items: [
                  for (final minutes in allowedBeforeMinutes)
                    DropdownMenuItem(
                      value: minutes,
                      child: Text(
                        localizeDigits(
                          _beforeLabel(l10n, minutes),
                          locale,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(plan.copyWith(minutesBefore: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReminderRepeat>(
                initialValue: repeatOptions.contains(plan.repeat)
                    ? plan.repeat
                    : repeatOptions.first,
                decoration: InputDecoration(labelText: l10n.repeat),
                items: [
                  for (final repeat in repeatOptions)
                    DropdownMenuItem(
                      value: repeat,
                      child: Text(_repeatLabel(l10n, repeat)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(plan.copyWith(repeat: value));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _beforeLabel(AppLocalizations l10n, int minutes) {
  if (minutes == 0) return l10n.atEventTime;
  if (minutes == 1440) return l10n.oneDayBefore;
  if (minutes >= 60) return l10n.hoursBefore(minutes ~/ 60);
  return l10n.minutesBefore(minutes);
}

String _repeatLabel(AppLocalizations l10n, ReminderRepeat repeat) =>
    switch (repeat) {
      ReminderRepeat.none => l10n.repeatOnce,
      ReminderRepeat.daily => l10n.repeatDaily,
      ReminderRepeat.weekly => l10n.repeatWeekly,
      ReminderRepeat.monthly => l10n.repeatMonthly,
      ReminderRepeat.yearly => l10n.repeatYearly,
    };
