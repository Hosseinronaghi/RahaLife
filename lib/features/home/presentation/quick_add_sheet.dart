import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../medication/presentation/medication_screen.dart';
import '../../people/presentation/people_controller.dart';
import '../../shopping/presentation/shopping_screen.dart';
import '../domain/home_entry.dart';
import 'home_controller.dart';
import 'home_entry_ui.dart';

Future<void> showAddEntry(BuildContext context, HomeEntryType type) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddEntrySheet(type: type),
    );

Future<void> showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _QuickAddMenu(),
    );

class _QuickAddMenu extends ConsumerWidget {
  const _QuickAddMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 560 ? 4 : 2;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.quickAdd, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.75,
              ),
              itemCount: homeSectionOrder.length,
              itemBuilder: (context, index) {
                final type = homeSectionOrder[index];
                final color =
                    homeEntryTypeColor(type, Theme.of(context).colorScheme);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final navigatorContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    await Future<void>.delayed(Duration.zero);
                    if (!navigatorContext.mounted) return;
                    switch (type) {
                      case HomeEntryType.shopping:
                        await showShoppingListForm(navigatorContext, ref);
                        break;
                      case HomeEntryType.medication:
                        await showMedicationForm(navigatorContext, ref);
                        break;
                      case HomeEntryType.finance:
                        await showFinanceForm(navigatorContext, ref);
                        break;
                      default:
                        await showAddEntry(navigatorContext, type);
                        break;
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: color.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(homeEntryTypeIcon(type), color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              homeEntryTypeLabel(l10n, type),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEntrySheet extends ConsumerStatefulWidget {
  const _AddEntrySheet({required this.type});
  final HomeEntryType type;

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  AffairKind _affairKind = AffairKind.personal;
  AppointmentKind _appointmentKind = AppointmentKind.meeting;
  String? _personId;
  bool _reminderEnabled = false;
  ReminderKind _reminderKind = ReminderKind.notification;
  ReminderRepeat _reminderRepeat = ReminderRepeat.none;
  int _minutesBefore = 15;
  bool _saving = false;

  bool get _supportsLocation =>
      widget.type == HomeEntryType.affair ||
      widget.type == HomeEntryType.appointment;

  bool get _supportsReminder => widget.type != HomeEntryType.note;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1920),
      lastDate: DateTime(2120),
    );
    if (date == null) return;
    setState(
      () => _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(
      () => _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final subtype = widget.type == HomeEntryType.affair
        ? _affairKind.name
        : widget.type == HomeEntryType.appointment
            ? _appointmentKind.name
            : null;
    final reminder = ReminderPlan(
      enabled: _supportsReminder && _reminderEnabled,
      kind: _reminderKind,
      minutesBefore: _minutesBefore,
      repeat: _reminderRepeat,
    );
    final entry = ref.read(homeEntriesProvider.notifier).add(
          type: widget.type,
          title: _titleController.text,
          details: _detailsController.text,
          dateTime: _selectedDateTime,
          subtype: subtype,
          personId: _personId,
          location: _locationController.text,
          address: _addressController.text,
          reminder: reminder,
        );
    if (reminder.enabled) {
      await ReminderService.instance.requestPermissions();
      await ReminderService.instance.schedule(
        key: 'home:${entry.id}',
        title: entry.title,
        body: _locationController.text.trim().isEmpty
            ? l10n.reminderDue
            : '${l10n.location}: ${_locationController.text.trim()}',
        eventDateTime: entry.dateTime,
        plan: reminder,
        payload: 'home:${entry.id}',
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.itemAdded)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(homeEntryTypeIcon(widget.type)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      addHomeEntryLabel(l10n, widget.type),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.type == HomeEntryType.affair) ...[
                DropdownButtonFormField<AffairKind>(
                  initialValue: _affairKind,
                  decoration: InputDecoration(labelText: l10n.affairType),
                  items: AffairKind.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(affairKindLabel(l10n, value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _affairKind = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (widget.type == HomeEntryType.appointment) ...[
                DropdownButtonFormField<AppointmentKind>(
                  initialValue: _appointmentKind,
                  decoration: InputDecoration(labelText: l10n.appointmentType),
                  items: AppointmentKind.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(appointmentKindLabel(l10n, value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _appointmentKind = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (widget.type == HomeEntryType.affair ||
                  widget.type == HomeEntryType.appointment) ...[
                Builder(
                  builder: (context) {
                    final people = ref.watch(peopleProvider);
                    return DropdownButtonFormField<String>(
                      initialValue: _personId,
                      decoration: InputDecoration(labelText: l10n.relatedPerson),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(l10n.noRelatedPerson),
                        ),
                        ...people.map(
                          (person) => DropdownMenuItem<String>(
                            value: person.id,
                            child: Text(person.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => _personId =
                            value == null || value.isEmpty ? null : value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.title),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '${l10n.description} (${l10n.optional})',
                ),
              ),
              if (_supportsLocation) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: l10n.location,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '${l10n.address} (${l10n.optional})',
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(compactDualDate(_selectedDateTime, locale)),
                  ),
                  if (widget.type != HomeEntryType.birthday)
                    OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(localizedTime(_selectedDateTime, locale)),
                    ),
                ],
              ),
              if (_supportsReminder) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.reminder),
                          subtitle: Text(l10n.reminderHint),
                          secondary: const Icon(Icons.notifications_active_outlined),
                          value: _reminderEnabled,
                          onChanged: (value) =>
                              setState(() => _reminderEnabled = value),
                        ),
                        if (_reminderEnabled) ...[
                          const Divider(),
                          DropdownButtonFormField<ReminderKind>(
                            initialValue: _reminderKind,
                            decoration: InputDecoration(
                              labelText: l10n.reminderMode,
                            ),
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
                                setState(() => _reminderKind = value);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            initialValue: _minutesBefore,
                            decoration: InputDecoration(
                              labelText: l10n.remindBefore,
                            ),
                            items: const [0, 5, 10, 15, 30, 60, 120, 1440]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(_beforeLabel(l10n, value)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _minutesBefore = value);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<ReminderRepeat>(
                            initialValue: _reminderRepeat,
                            decoration: InputDecoration(
                              labelText: l10n.repeat,
                            ),
                            items: ReminderRepeat.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(_repeatLabel(l10n, value)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _reminderRepeat = value);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.save),
              ),
            ],
          ),
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
