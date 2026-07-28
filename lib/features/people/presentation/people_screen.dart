import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/home_controller.dart';
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
          ? _EmptyPeople(onAdd: () => _showPersonForm(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final person = people[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(child: Text(person.name.characters.first)),
                    title: Text(person.name),
                    subtitle: Text([
                      if (person.relationship?.isNotEmpty ?? false) person.relationship!,
                      if (person.phone?.isNotEmpty ?? false) person.phone!,
                    ].join(' • ')),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          ref.read(peopleProvider.notifier).delete(person.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(person.name, style: Theme.of(context).textTheme.titleLarge),
                            if (person.relationship?.isNotEmpty ?? false) Text(person.relationship!),
                            if (person.phone?.isNotEmpty ?? false) Text(person.phone!),
                            if (person.email?.isNotEmpty ?? false) Text(person.email!),
                            if (person.birthDate != null) ...[
                              const SizedBox(height: 8),
                              Text('${l10n.birthdayDate}: ${compactDualDate(person.birthDate!, Localizations.localeOf(context))}'),
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
        onPressed: () => _showPersonForm(context, ref),
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
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(l10n.addPerson)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPersonForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final relationship = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final notes = TextEditingController();
  DateTime? birthDate;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.addPerson, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l10n.fullName), validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null),
                const SizedBox(height: 10),
                TextFormField(controller: relationship, decoration: InputDecoration(labelText: l10n.relationship)),
                const SizedBox(height: 10),
                TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l10n.phone)),
                const SizedBox(height: 10),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l10n.email)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(context: context, firstDate: DateTime(1920), lastDate: DateTime.now(), initialDate: birthDate ?? DateTime(1990));
                    if (selected != null) setState(() => birthDate = selected);
                  },
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(birthDate == null ? l10n.birthdayDate : compactDualDate(birthDate!, Localizations.localeOf(context))),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: notes, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l10n.notes)),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final personId = ref.read(peopleProvider.notifier).add(name: name.text, relationship: relationship.text, phone: phone.text, email: email.text, birthDate: birthDate, notes: notes.text);
                    if (birthDate != null) {
                      ref.read(homeEntriesProvider.notifier).add(
                            type: HomeEntryType.birthday,
                            title: name.text,
                            dateTime: birthDate!,
                            details: relationship.text,
                            personId: personId,
                          );
                    }
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
  name.dispose(); relationship.dispose(); phone.dispose(); email.dispose(); notes.dispose();
}
