import '../../../core/widgets/retained_popup.dart';
import '../../../core/widgets/calendar_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/person.dart';

import 'people_controller.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.people)),
      body: people.isEmpty
          ? _EmptyPeople(onAdd: () => showPersonForm(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final person = people[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      child: Text(person.name.characters.first),
                    ),
                    title: Text(person.name),
                    subtitle: Text(
                      [
                        if (person.relationship?.isNotEmpty ?? false)
                          person.relationship!,
                        if (person.phone?.isNotEmpty ?? false) person.phone!,
                      ].join(' • '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showPersonForm(context, ref, person: person);
                        }
                        if (value == 'delete') {
                          ref.read(peopleProvider.notifier).delete(person.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                    onTap: () => showRetainedBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              person.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (person.relationship?.isNotEmpty ?? false)
                              Text(person.relationship!),
                            if (person.phone?.isNotEmpty ?? false)
                              Text(person.phone!),
                            if (person.email?.isNotEmpty ?? false)
                              Text(person.email!),
                            if (person.birthDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${l10n.birthdayDate}: ${compactDualDate(person.birthDate!, Localizations.localeOf(context))}',
                              ),
                            ],
                            if (person.notes?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 12),
                              Text(person.notes!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showPersonForm(context, ref),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}

class _EmptyPeople extends StatelessWidget {
  const _EmptyPeople({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_rounded, size: 72),
            const SizedBox(height: 16),
            Text(l10n.noPeople, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addPerson),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPersonForm(
  BuildContext context,
  WidgetRef ref, {
  Person? person,
}) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: person?.name ?? '');
  final relationship = TextEditingController(text: person?.relationship ?? '');
  final phone = TextEditingController(text: person?.phone ?? '');
  final email = TextEditingController(text: person?.email ?? '');
  final notes = TextEditingController(text: person?.notes ?? '');
  DateTime? birthDate = person?.birthDate;
  final fa = Localizations.localeOf(context).languageCode == 'fa';
  String birthCalendar = person?.birthCalendar ?? (fa ? 'jalali' : 'gregorian');
  const relationships = [
    'پدر',
    'مادر',
    'همسر',
    'فرزند',
    'خواهر',
    'برادر',
    'دوست',
    'همکار',
    'مدیر',
    'مشتری',
    'بستگان',
  ];
  const english = [
    'Father',
    'Mother',
    'Spouse',
    'Child',
    'Sister',
    'Brother',
    'Friend',
    'Colleague',
    'Manager',
    'Client',
    'Relative',
  ];
  await showRetainedBottomSheet<void>(
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
                  person == null ? l10n.addPerson : l10n.edit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.fullName),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: relationships.contains(relationship.text)
                      ? relationship.text
                      : 'other',
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.relationship),
                  items: [
                    for (var i = 0; i < relationships.length; i++)
                      DropdownMenuItem(
                        value: relationships[i],
                        child: Text(fa ? relationships[i] : english[i]),
                      ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(fa ? 'سایر / دلخواه' : 'Other / custom'),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => relationship.text = v == 'other' ? '' : v ?? '',
                  ),
                ),
                if (!relationships.contains(relationship.text)) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: relationship,
                    decoration: InputDecoration(
                      labelText: fa ? 'نسبت دلخواه' : 'Custom relationship',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phone),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.email),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showCalendarDatePicker(
                      context,
                      calendar: birthCalendar,
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                      initialDate: birthDate ?? DateTime(1990),
                    );
                    if (selected != null) setState(() => birthDate = selected);
                  },
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    birthDate == null
                        ? l10n.birthdayDate
                        : compactDualDate(
                            birthDate!,
                            Localizations.localeOf(context),
                          ),
                  ),
                ),
                if (birthDate != null)
                  TextButton(
                    onPressed: () => setState(() => birthDate = null),
                    child: Text(fa ? 'حذف تاریخ تولد' : 'Clear birthday'),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: birthCalendar,
                  decoration: InputDecoration(
                    labelText: fa
                        ? 'مبنای تکرار سالانهٔ تولد'
                        : 'Birthday calendar',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'jalali',
                      child: Text(fa ? 'شمسی' : 'Jalali'),
                    ),
                    DropdownMenuItem(
                      value: 'gregorian',
                      child: Text(fa ? 'میلادی' : 'Gregorian'),
                    ),
                  ],
                  onChanged: (v) => setState(() => birthCalendar = v!),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.notes),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    ref
                        .read(peopleProvider.notifier)
                        .add(
                          id: person?.id,
                          name: name.text,
                          relationship: relationship.text,
                          phone: phone.text,
                          email: email.text,
                          birthDate: birthDate,
                          birthCalendar: birthCalendar,
                          notes: notes.text,
                        );
                    Navigator.pop(sheetContext);
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
  relationship.dispose();
  phone.dispose();
  email.dispose();
  notes.dispose();
}
