import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/widgets/reminder_editor.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/medication_catalog.dart';
import '../domain/medication_plan.dart';
import 'medication_controller.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final plans = ref.watch(medicationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medication),
        actions: [
          IconButton(
            tooltip: l10n.medicationCatalog,
            onPressed: () => _showCatalog(context, onSelected: (item) => showMedicationForm(context, ref, catalogItem: item)),
            icon: const Icon(Icons.manage_search_rounded),
          ),
        ],
      ),
      body: plans.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.medication_liquid_rounded, size: 48, color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.noMedications),
                    const SizedBox(height: 8),
                    Text(l10n.recordingOnly, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => showMedicationForm(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addMedicine),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plan = plans[index];
                final finished = plan.isCourseFinished();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(Icons.medication_rounded, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text('${_formLabel(l10n, plan.form)} • ${plan.dosage}'),
                                  if (plan.therapeuticGroup?.isNotEmpty ?? false)
                                    Text(plan.therapeuticGroup!, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Switch(
                              value: plan.active && !finished,
                              onChanged: finished
                                  ? null
                                  : (_) async {
                                      final updated = ref.read(medicationProvider.notifier).toggleActive(plan.id);
                                      if (updated != null && updated.active) {
                                        await _scheduleMedication(updated, l10n);
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
                              avatar: const Icon(Icons.schedule_rounded, size: 18),
                              label: Text(localizeDigits(plan.time, locale)),
                            ),
                            Chip(
                              avatar: const Icon(Icons.timelapse_rounded, size: 18),
                              label: Text(_courseLabel(l10n, plan, locale)),
                            ),
                            if (plan.stock != null)
                              Chip(
                                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                                label: Text('${l10n.stock}: ${localizeDigits(plan.stock!.toStringAsFixed(plan.stock! % 1 == 0 ? 0 : 1), locale)}'),
                              ),
                            if (finished)
                              Chip(
                                avatar: const Icon(Icons.flag_circle_rounded, size: 18),
                                label: Text(l10n.medicationFinished),
                              ),
                          ],
                        ),
                        if (plan.reasonForUse?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          Text('${l10n.reasonForUse}: ${plan.reasonForUse}'),
                        ],
                        if (plan.instructions?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 6),
                          Text(plan.instructions!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: plan.active && !finished
                                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.medicineTaken)))
                                    : null,
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.medicineTaken),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              onPressed: () => ref.read(medicationProvider.notifier).delete(plan.id),
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

String _courseTypeLabel(AppLocalizations l10n, MedicationCourseType type) => switch (type) {
      MedicationCourseType.continuous => l10n.courseContinuous,
      MedicationCourseType.fixedDate => l10n.courseFixed,
      MedicationCourseType.fixedDays => l10n.courseDays,
      MedicationCourseType.asNeeded => l10n.courseAsNeeded,
    };

String _courseLabel(AppLocalizations l10n, MedicationPlan plan, Locale locale) {
  final end = plan.calculatedEndDate;
  if (end != null) return '${_courseTypeLabel(l10n, plan.courseType)} • ${compactDualDate(end, locale)}';
  if (plan.courseDays != null) {
    return '${_courseTypeLabel(l10n, plan.courseType)} • ${localizeDigits(plan.courseDays.toString(), locale)}';
  }
  return _courseTypeLabel(l10n, plan.courseType);
}

Future<void> _scheduleMedication(MedicationPlan plan, AppLocalizations l10n) async {
  if (!plan.active || !plan.reminder.enabled || plan.isCourseFinished()) return;
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

Future<void> _showCatalog(
  BuildContext context, {
  required ValueChanged<MedicationCatalogItem> onSelected,
}) async {
  final l10n = AppLocalizations.of(context);
  final query = TextEditingController();
  var search = '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final lang = Localizations.localeOf(context).languageCode;
        final results = medicationStarterCatalog.where((item) {
          final haystack = '${item.genericName} ${item.groupFor(lang)} ${item.commonUseFor(lang)}'.toLowerCase();
          return haystack.contains(search.toLowerCase());
        }).toList();
        return FractionallySizedBox(
          heightFactor: 0.84,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Text(l10n.medicationCatalog, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.recordingOnly, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                TextField(
                  controller: query,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchMedicine,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = results[index];
                      return ListTile(
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(item.genericName),
                        subtitle: Text('${item.groupFor(lang)} • ${item.commonUseFor(lang)}'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onSelected(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  query.dispose();
}

Future<void> showMedicationForm(
  BuildContext context,
  WidgetRef ref, {
  MedicationCatalogItem? catalogItem,
}) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: catalogItem?.genericName ?? '');
  final brand = TextEditingController();
  final dosage = TextEditingController();
  final reason = TextEditingController();
  final instructions = TextEditingController();
  final stock = TextEditingController();
  final days = TextEditingController();
  var selectedCatalog = catalogItem;
  var form = selectedCatalog?.defaultForm ?? MedicationForm.tablet;
  var time = TimeOfDay.now();
  var courseType = MedicationCourseType.continuous;
  var startDate = DateTime.now();
  DateTime? endDate;
  var reminder = const ReminderPlan(enabled: true, repeat: ReminderRepeat.daily);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final locale = Localizations.localeOf(context);
        final lang = locale.languageCode;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l10n.addMedicine, style: Theme.of(context).textTheme.titleLarge)),
                      TextButton.icon(
                        onPressed: () async {
                          await _showCatalog(context, onSelected: (selected) {
                            name.text = selected.genericName;
                            setState(() {
                              selectedCatalog = selected;
                              form = selected.defaultForm;
                            });
                          });
                        },
                        icon: const Icon(Icons.search_rounded),
                        label: Text(l10n.selectFromCatalog),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: name,
                    autofocus: selectedCatalog == null,
                    decoration: InputDecoration(labelText: l10n.medicineName),
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: brand, decoration: InputDecoration(labelText: '${l10n.brandName} (${l10n.optional})')),
                  if (selectedCatalog != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('${catalogItem.groupFor(lang)} • ${catalogItem.commonUseFor(lang)}'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MedicationForm>(
                    initialValue: form,
                    decoration: InputDecoration(labelText: l10n.medicineForm),
                    items: MedicationForm.values.map((value) => DropdownMenuItem(value: value, child: Text(_formLabel(l10n, value)))).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => form = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dosage,
                    decoration: InputDecoration(labelText: l10n.dosage),
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: reason, decoration: InputDecoration(labelText: l10n.reasonForUse)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showTimePicker(context: context, initialTime: time);
                      if (selected != null) setState(() => time = selected);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(localizeDigits(time.format(context), locale)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MedicationCourseType>(
                    initialValue: courseType,
                    decoration: InputDecoration(labelText: l10n.courseType),
                    items: MedicationCourseType.values.map((value) => DropdownMenuItem(value: value, child: Text(_courseTypeLabel(l10n, value)))).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => courseType = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2120),
                        initialDate: startDate,
                      );
                      if (selected != null) setState(() => startDate = selected);
                    },
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text('${l10n.courseStart}: ${compactDualDate(startDate, locale)}'),
                  ),
                  if (courseType == MedicationCourseType.fixedDate) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: startDate,
                          lastDate: DateTime(2120),
                          initialDate: endDate ?? startDate,
                        );
                        if (selected != null) setState(() => endDate = selected);
                      },
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(endDate == null ? l10n.courseEnd : '${l10n.courseEnd}: ${compactDualDate(endDate!, locale)}'),
                    ),
                  ],
                  if (courseType == MedicationCourseType.fixedDays) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: days,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.courseLengthDays),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '${l10n.stock} (${l10n.optional})'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: instructions, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l10n.instructions)),
                  const SizedBox(height: 14),
                  ReminderEditor(
                    plan: reminder,
                    repeatOptions: const [ReminderRepeat.daily, ReminderRepeat.none],
                    allowedBeforeMinutes: const [0, 5, 10, 15, 30, 60],
                    onChanged: (value) => setState(() => reminder = value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final timeText = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      final plan = ref.read(medicationProvider.notifier).add(
                            name: name.text,
                            genericName: selectedCatalog?.genericName ?? name.text,
                            brandName: brand.text,
                            therapeuticGroup: selectedCatalog?.groupFor(lang),
                            commonUse: selectedCatalog?.commonUseFor(lang),
                            reasonForUse: reason.text,
                            form: form,
                            dosage: dosage.text,
                            time: timeText,
                            courseType: courseType,
                            startDate: startDate,
                            endDate: endDate,
                            courseDays: int.tryParse(toEnglishDigits(days.text)),
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
        );
      },
    ),
  );
  name.dispose();
  brand.dispose();
  dosage.dispose();
  reason.dispose();
  instructions.dispose();
  stock.dispose();
  days.dispose();
}
