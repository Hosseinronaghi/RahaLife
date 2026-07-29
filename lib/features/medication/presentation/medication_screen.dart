import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/medication_plan.dart';
import 'medication_controller.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plans = ref.watch(medicationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.medication)),
      body: plans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medication_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(l10n.noMedications),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showMedicationForm(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addMedicine),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.medication_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    '${_formLabel(l10n, plan.form)} • ${plan.dosage}',
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: plan.active,
                              onChanged: (_) async {
                                final updated = ref
                                    .read(medicationProvider.notifier)
                                    .toggleActive(plan.id);
                                if (updated?.active ?? false) {
                                  await _scheduleMedication(updated!, l10n);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                              ),
                              label: Text(
                                localizeDigits(
                                  plan.time,
                                  Localizations.localeOf(context),
                                ),
                              ),
                            ),
                            if (plan.reminder.enabled)
                              Chip(
                                avatar: Icon(
                                  plan.reminder.kind == ReminderKind.alarm
                                      ? Icons.alarm_rounded
                                      : Icons.notifications_none_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  plan.reminder.kind == ReminderKind.alarm
                                      ? l10n.alarmMode
                                      : l10n.notificationMode,
                                ),
                              ),
                            if (plan.stock != null)
                              Chip(
                                avatar: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '${l10n.stock}: ${localizeDigits(plan.stock!.toStringAsFixed(plan.stock! % 1 == 0 ? 0 : 1), Localizations.localeOf(context))}',
                                ),
                              ),
                          ],
                        ),
                        if (plan.instructions?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(plan.instructions!),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: plan.active
                                    ? () => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.medicineTaken),
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.medicineTaken),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(medicationProvider.notifier)
                                  .delete(plan.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showMedicationForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

String _formLabel(AppLocalizations l10n, MedicationForm form) => switch (form) {
      MedicationForm.tablet => l10n.tablet,
      MedicationForm.capsule => l10n.capsule,
      MedicationForm.syrup => l10n.syrup,
      MedicationForm.drops => l10n.drops,
      MedicationForm.injection => l10n.injection,
      MedicationForm.cream => l10n.cream,
      MedicationForm.inhaler => l10n.inhaler,
      MedicationForm.other => l10n.other,
    };

Future<void> _scheduleMedication(
  MedicationPlan plan,
  AppLocalizations l10n,
) async {
  if (!plan.active || !plan.reminder.enabled) return;
  await ReminderService.instance.requestPermissions();
  await ReminderService.instance.schedule(
    key: 'medication:${plan.id}',
    title: plan.name,
    body: '${plan.dosage} • ${l10n.medicationReminderBody}',
    eventDateTime: plan.nextDoseDateTime(),
    plan: plan.reminder,
    payload: 'medication:${plan.id}',
  );
}

Future<void> showMedicationForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final dosage = TextEditingController();
  final instructions = TextEditingController();
  final stock = TextEditingController();
  var form = MedicationForm.tablet;
  var time = TimeOfDay.now();
  var reminderEnabled = true;
  var reminderKind = ReminderKind.notification;
  var minutesBefore = 0;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.addMedicine,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.medicineName),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? l10n.requiredField
                          : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<MedicationForm>(
                  initialValue: form,
                  decoration: InputDecoration(labelText: l10n.medicineForm),
                  items: MedicationForm.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_formLabel(l10n, value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => form = value);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: dosage,
                  decoration: InputDecoration(labelText: l10n.dosage),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? l10n.requiredField
                          : null,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (selected != null) setState(() => time = selected);
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    localizeDigits(
                      time.format(context),
                      Localizations.localeOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${l10n.stock} (${l10n.optional})',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: instructions,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.instructions),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.reminder),
                  subtitle: Text(l10n.dailyMedicationReminder),
                  value: reminderEnabled,
                  onChanged: (value) =>
                      setState(() => reminderEnabled = value),
                ),
                if (reminderEnabled) ...[
                  DropdownButtonFormField<ReminderKind>(
                    initialValue: reminderKind,
                    decoration: InputDecoration(labelText: l10n.reminderMode),
                    items: [
                      DropdownMenuItem(
                        value: ReminderKind.notification,
                        child: Text(l10n.notificationMode),
                      ),
                      DropdownMenuItem(
                        value: ReminderKind.alarm,
                        child: Text(l10n.alarmMode),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => reminderKind = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: minutesBefore,
                    decoration: InputDecoration(labelText: l10n.remindBefore),
                    items: const [0, 5, 10, 15, 30, 60]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value == 0
                                  ? l10n.atEventTime
                                  : value == 60
                                      ? l10n.hoursBefore(1)
                                      : l10n.minutesBefore(value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => minutesBefore = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final timeText =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    final reminder = ReminderPlan(
                      enabled: reminderEnabled,
                      kind: reminderKind,
                      minutesBefore: minutesBefore,
                      repeat: ReminderRepeat.daily,
                    );
                    final plan = ref.read(medicationProvider.notifier).add(
                          name: name.text,
                          form: form,
                          dosage: dosage.text,
                          time: timeText,
                          instructions: instructions.text,
                          stock: double.tryParse(toEnglishDigits(stock.text)),
                          reminder: reminder,
                        );
                    await _scheduleMedication(plan, l10n);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  name.dispose();
  dosage.dispose();
  instructions.dispose();
  stock.dispose();
}
