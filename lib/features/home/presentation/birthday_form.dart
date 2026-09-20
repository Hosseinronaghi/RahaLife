import '../../../core/sync/canonical_json.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/locale_formatters.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../../../core/widgets/calendar_date_picker.dart';
import '../../../core/widgets/reminder_editor.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../people/domain/person.dart';
import '../../people/presentation/people_controller.dart';
import '../../sync/presentation/synced_feature_refresh.dart';
import '../domain/home_entry.dart';

Future<void> showBirthdayForm(BuildContext c, {HomeEntry? entry}) =>
    showModalBottomSheet<void>(
      context: c,
      isScrollControlled: true,
      builder: (_) => BirthdayForm(entry: entry),
    );

class BirthdayForm extends ConsumerStatefulWidget {
  const BirthdayForm({this.entry, super.key});
  final HomeEntry? entry;
  @override
  ConsumerState<BirthdayForm> createState() => _BirthdayState();
}

class _BirthdayState extends ConsumerState<BirthdayForm> {
  final name = TextEditingController(),
      relation = TextEditingController(),
      notes = TextEditingController();
  final repository = DriftEntityRepository();
  DateTime date = DateTime.now();
  String calendar = 'jalali';
  String? personId;
  Person? selected;
  bool busy = false;
  bool loading = true;
  Map<String, Object?>? initialEntry;
  String? error;
  ReminderPlan reminder = const ReminderPlan();
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      name.text = e.title;
      date = e.dateTime;
      calendar = e.calendar;
      personId = e.personId;
      reminder = e.reminder;
    }
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      final e = widget.entry;
      initialEntry = e == null
          ? null
          : await repository.loadOne('home_entry', e.id);
      final person = personId == null
          ? null
          : await repository.loadOne('person', personId!);
      if (!mounted) return;
      selected = person == null ? null : Person.fromJson(person);
      notes.text = initialEntry?['details']?.toString() ?? '';
      relation.text =
          selected?.relationship ??
          initialEntry?['relationship']?.toString() ??
          '';
      setState(() => loading = false);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'خواندن اطلاعات ناموفق بود؛ فرم را دوباره باز کنید.',
            'Could not load data. Reopen the form.',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    relation.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> choosePerson(String? id) async {
    final p = ref.read(peopleProvider).where((p) => p.id == id).firstOrNull;
    if (p != null &&
        name.text.trim().isNotEmpty &&
        name.text.trim() != p.name) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            t('جایگزینی با مشخصات فرد؟', 'Use this person’s details?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(t('لغو', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(t('تأیید', 'Confirm')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      personId = p?.id;
      selected = p;
      if (p != null) {
        name.text = p.name;
        relation.text = p.relationship ?? '';
        if (p.birthDate != null) date = p.birthDate!;
        calendar = p.birthCalendar;
      }
    });
  }

  Future<void> save() async {
    if (busy || loading) return;
    if (name.text.trim().isEmpty) {
      setState(() => error = t('نام را وارد کنید.', 'Enter a name.'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repository.db.transaction(() async {
        final old = widget.entry == null
            ? null
            : await repository.loadOne('home_entry', widget.entry!.id);
        if (canonicalJson(old) != canonicalJson(initialEntry)) {
          throw StateError('Birthday changed; reopen');
        }
        if (personId != null) {
          final person = await repository.loadOne('person', personId!);
          if (person == null) throw StateError('Person unavailable');
          // A fresh record is used only to detect changes; never overwrite a stale selection.
          if (selected != null &&
              (person['name'] != selected!.name ||
                  person['birthDate'] !=
                      selected!.birthDate?.toIso8601String() ||
                  (person['relationship'] ?? '') !=
                      (selected!.relationship ?? '') ||
                  (person['birthCalendar'] ?? 'gregorian') !=
                      selected!.birthCalendar)) {
            throw StateError('Person changed; select again');
          }
          final changed =
              person['name'] != name.text.trim() ||
              person['birthDate'] != date.toIso8601String() ||
              person['birthCalendar'] != calendar ||
              (person['relationship'] ?? '') != relation.text.trim();
          if (changed) {
            // Confirmation is completed before transaction below; this guard prevents silent edits.
            if (!_confirmedPersonEdit) throw StateError('Confirm person edit');
            await repository.updateFromSnapshot('person', {
              ...person,
              'name': name.text.trim(),
              'birthDate': date.toIso8601String(),
              'birthCalendar': calendar,
              'relationship': relation.text.trim(),
            }, person);
          }
        }
        final all = await repository.loadAll('home_entry');
        final linked = personId == null
            ? null
            : all
                  .where(
                    (e) => e['type'] == 'birthday' && e['personId'] == personId,
                  )
                  .firstOrNull;
        final id =
            linked?['id']?.toString() ??
            old?['id']?.toString() ??
            const Uuid().v4();
        final value = {
          ...(linked ?? old ?? <String, Object?>{}),
          'id': id,
          'type': 'birthday',
          'title': name.text.trim(),
          'dateTime': date.toIso8601String(),
          'calendar': calendar,
          'personId': personId,
          'relationship': relation.text.trim(),
          'details': notes.text.trim(),
          'completed': false,
          'reminder': reminder.toJson(),
        };
        final base = linked ?? old;
        if (base == null) {
          await repository.upsert('home_entry', value);
        } else {
          await repository.updateFromSnapshot('home_entry', value, base);
        }
        if (old != null && old['id'] != id) {
          await repository.deleteFromSnapshot('home_entry', old);
        }
      });
      invalidateSyncedFeatureProviders(ref);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'ذخیره نشد؛ اطلاعات فرد را دوباره انتخاب و بررسی کنید.',
            'Not saved. Re-select the person and review their details.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
      _confirmedPersonEdit = false;
    }
  }

  bool _confirmedPersonEdit = false;
  Future<void> confirmSave() async {
    if (busy || loading) return;
    if (personId != null) {
      final p = ref
          .read(peopleProvider)
          .where((p) => p.id == personId)
          .firstOrNull;
      if (p == null) return;
      final changed =
          p.name != name.text.trim() ||
          p.birthDate != date ||
          p.birthCalendar != calendar ||
          (p.relationship ?? '') != relation.text.trim();
      if (changed) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              t('مشخصات فرد هم تغییر کند؟', 'Update the linked person too?'),
            ),
            content: Text(
              '${name.text}\n${compactDualDate(date, Localizations.localeOf(c))}\n${relation.text}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(t('لغو', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(t('تأیید تغییر', 'Confirm change')),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
      }
      selected ??= p;
      _confirmedPersonEdit = true;
    }
    await save();
  }

  @override
  Widget build(BuildContext c) {
    final people = ref.watch(peopleProvider);
    return SafeArea(
      child: AbsorbPointer(
        absorbing: loading || busy,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(c).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loading) const LinearProgressIndicator(),
              Text(
                t('ثبت تولد', 'Birthday'),
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: t('نام', 'Name')),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'jalali',
                    label: Text(t('شمسی', 'Jalali')),
                  ),
                  ButtonSegment(
                    value: 'gregorian',
                    label: Text(t('میلادی', 'Gregorian')),
                  ),
                ],
                selected: {calendar},
                onSelectionChanged: (v) => setState(() => calendar = v.first),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cake_outlined),
                label: Text(compactDualDate(date, Localizations.localeOf(c))),
                onPressed: () async {
                  final d = await showCalendarDatePicker(
                    c,
                    initialDate: date,
                    firstDate: DateTime(1800),
                    lastDate: DateTime.now(),
                    calendar: calendar,
                  );
                  if (d != null && mounted) setState(() => date = d);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relation,
                decoration: InputDecoration(
                  labelText: t('نسبت', 'Relationship'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(personId),
                initialValue: people.any((p) => p.id == personId)
                    ? personId
                    : '',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: t('فرد مرتبط', 'Related person'),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(t('بدون فرد مرتبط', 'No linked person')),
                  ),
                  for (final p in people)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: busy ? null : choosePerson,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: t('توضیحات', 'Notes')),
              ),
              const SizedBox(height: 16),
              ReminderEditor(
                plan: reminder,
                onChanged: (v) => setState(() => reminder = v),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(c).colorScheme.error),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : confirmSave,
                child: Text(t('ذخیره', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
