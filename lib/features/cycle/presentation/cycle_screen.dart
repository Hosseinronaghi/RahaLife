import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/widgets/reminder_editor.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/cycle_log.dart';
import 'cycle_controller.dart';

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final logs = ref.watch(cycleProvider);
    final hideSensitive = ref.watch(cyclePrivacyProvider);
    final predicted = ref.read(cycleProvider.notifier).predictedNextStart;
    final latest = logs.isEmpty ? null : logs.first;
    final now = DateTime.now();
    final cycleDay = latest == null
        ? null
        : now.difference(DateTime(latest.startDate.year, latest.startDate.month, latest.startDate.day)).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cycle),
        actions: [
          IconButton(
            tooltip: l10n.privacy,
            onPressed: () => _showPrivacy(context, ref, hideSensitive),
            icon: Icon(hideSensitive ? Icons.visibility_off_rounded : Icons.visibility_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  const Color(0xFFE11D48).withValues(alpha: 0.18),
                  const Color(0xFFA855F7).withValues(alpha: 0.10),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
              border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Color(0xFFE11D48), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.cycleToday, style: Theme.of(context).textTheme.titleLarge),
                          if (cycleDay != null && cycleDay > 0)
                            Text('${l10n.cycleDay} ${localizeDigits(cycleDay.toString(), locale)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (predicted != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.estimatedNextCycle, style: Theme.of(context).textTheme.labelLarge),
                              Text('${compactDualDate(predicted, locale)} • ${l10n.estimated}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(l10n.cyclePredictionHint),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(l10n.quickLog, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () => _showCycleForm(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.addCycleRecord),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(icon: Icons.water_drop_outlined, text: l10n.flowIntensity, onTap: () => _showCycleForm(context, ref)),
                      _QuickChip(icon: Icons.monitor_heart_outlined, text: l10n.painLevel, onTap: () => _showCycleForm(context, ref)),
                      _QuickChip(icon: Icons.mood_rounded, text: l10n.mood, onTap: () => _showCycleForm(context, ref)),
                      _QuickChip(icon: Icons.health_and_safety_outlined, text: l10n.symptoms, onTap: () => _showCycleForm(context, ref)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 46),
                    const SizedBox(height: 10),
                    Text(l10n.noCycleRecords),
                  ],
                ),
              ),
            )
          else ...[
            Text(l10n.cycleInsights, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final log in logs)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.12),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFFE11D48)),
                  ),
                  title: Text(compactDualDate(log.startDate, locale)),
                  subtitle: hideSensitive
                      ? Text(l10n.cyclePrivateHint, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : Text(
                          [
                            _flowLabel(l10n, log.flow),
                            '${l10n.painLevel}: ${localizeDigits(log.painLevel.toString(), locale)}',
                            _moodLabel(l10n, log.mood),
                            if (log.symptoms.isNotEmpty) log.symptoms.join('، '),
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    onPressed: () => ref.read(cycleProvider.notifier).delete(log.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(l10n.privacy),
              subtitle: Text(l10n.cyclePrivateHint),
              trailing: Switch.adaptive(
                value: hideSensitive,
                onChanged: (value) => ref.read(cyclePrivacyProvider.notifier).setHideSensitive(value),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showCycleForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(text),
        onPressed: onTap,
      );
}

Future<void> _showPrivacy(BuildContext context, WidgetRef ref, bool current) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.privacy, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.hideSensitiveWidgetData),
            subtitle: Text(l10n.cyclePrivateHint),
            value: current,
            onChanged: (value) {
              ref.read(cyclePrivacyProvider.notifier).setHideSensitive(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

String _flowLabel(AppLocalizations l10n, FlowIntensity flow) => switch (flow) {
      FlowIntensity.light => l10n.flowLight,
      FlowIntensity.medium => l10n.flowMedium,
      FlowIntensity.heavy => l10n.flowHeavy,
    };

String _moodLabel(AppLocalizations l10n, CycleMood mood) => switch (mood) {
      CycleMood.calm => l10n.moodCalm,
      CycleMood.sensitive => l10n.moodSensitive,
      CycleMood.low => l10n.moodLow,
      CycleMood.energetic => l10n.moodEnergetic,
      CycleMood.irritable => l10n.moodIrritable,
      CycleMood.other => l10n.other,
    };

Future<void> _showCycleForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  var start = DateTime.now();
  DateTime? end;
  var flow = FlowIntensity.medium;
  var pain = 0.0;
  var mood = CycleMood.calm;
  var reminder = const ReminderPlan();
  var reminderTime = const TimeOfDay(hour: 9, minute: 0);
  final notes = TextEditingController();
  final selectedSymptoms = <String>{};
  final symptomChoices = Localizations.localeOf(context).languageCode == 'fa'
      ? const ['سردرد', 'نفخ', 'خستگی', 'حساسیت سینه', 'کمردرد', 'تهوع']
      : const ['Headache', 'Bloating', 'Fatigue', 'Breast tenderness', 'Back pain', 'Nausea'];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final locale = Localizations.localeOf(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.addCycleRecord, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final value = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2120), initialDate: start);
                          if (value != null) setState(() => start = value);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('${l10n.startDate}: ${compactDualDate(start, locale)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final value = await showDatePicker(context: context, firstDate: start, lastDate: DateTime(2120), initialDate: end ?? start);
                          if (value != null) setState(() => end = value);
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(end == null ? l10n.endDateOptional : compactDualDate(end!, locale)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<FlowIntensity>(
                  initialValue: flow,
                  decoration: InputDecoration(labelText: l10n.flowIntensity),
                  items: FlowIntensity.values.map((value) => DropdownMenuItem(value: value, child: Text(_flowLabel(l10n, value)))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => flow = value);
                  },
                ),
                const SizedBox(height: 12),
                Text('${l10n.painLevel}: ${localizeDigits(pain.round().toString(), locale)}'),
                Slider(value: pain, max: 10, divisions: 10, onChanged: (value) => setState(() => pain = value)),
                DropdownButtonFormField<CycleMood>(
                  initialValue: mood,
                  decoration: InputDecoration(labelText: l10n.mood),
                  items: CycleMood.values.map((value) => DropdownMenuItem(value: value, child: Text(_moodLabel(l10n, value)))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => mood = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(l10n.symptoms, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final symptom in symptomChoices)
                      FilterChip(
                        selected: selectedSymptoms.contains(symptom),
                        label: Text(symptom),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            selectedSymptoms.add(symptom);
                          } else {
                            selectedSymptoms.remove(symptom);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: notes, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l10n.notes)),
                const SizedBox(height: 14),
                ReminderEditor(
                  plan: reminder,
                  allowedBeforeMinutes: const [0, 1440, 2880, 4320, 10080],
                  repeatOptions: const [ReminderRepeat.none],
                  onChanged: (value) => setState(() => reminder = value),
                ),
                if (reminder.enabled) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showTimePicker(context: context, initialTime: reminderTime);
                      if (selected != null) setState(() => reminderTime = selected);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(localizeDigits(reminderTime.format(context), locale)),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    final timeText = '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';
                    final log = ref.read(cycleProvider.notifier).add(
                          startDate: start,
                          endDate: end,
                          flow: flow,
                          painLevel: pain.round(),
                          mood: mood,
                          notes: notes.text,
                          symptoms: selectedSymptoms.toList(growable: false),
                          predictionReminder: reminder,
                          predictionReminderTime: timeText,
                        );
                    final predicted = ref.read(cycleProvider.notifier).predictedNextStart;
                    if (reminder.enabled && predicted != null) {
                      final eventDateTime = DateTime(predicted.year, predicted.month, predicted.day, reminderTime.hour, reminderTime.minute);
                      await ReminderService.instance.requestPermissions();
                      await ReminderService.instance.schedule(
                        key: 'cycle:${log.id}',
                        title: l10n.estimatedNextCycle,
                        body: l10n.cycleReminderBody,
                        eventDateTime: eventDateTime,
                        plan: reminder,
                        payload: 'cycle:${log.id}',
                      );
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  notes.dispose();
}
