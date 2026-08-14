import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../finance/presentation/finance_controller.dart';
import '../../home/presentation/entry_details_sheet.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/presentation/home_entry_ui.dart';
import '../../medication/presentation/medication_controller.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../people/presentation/people_controller.dart';
import '../../projects/presentation/projects_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';

enum _SearchKind { all, schedule, projects, notes, people, shopping, medication, finance }

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final controller = TextEditingController();
  _SearchKind filter = _SearchKind.all;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = controller.text.trim().toLowerCase();
    final results = <_SearchItem>[];

    if (query.isNotEmpty) {
      if (filter == _SearchKind.all || filter == _SearchKind.schedule) {
        for (final entry in ref.watch(homeEntriesProvider)) {
          if (entry.title.toLowerCase().contains(query) || (entry.details?.toLowerCase().contains(query) ?? false)) {
            results.add(_SearchItem(
              icon: homeEntryTypeIcon(entry.type),
              title: entry.title,
              subtitle: '${homeEntryTypeLabel(l10n, entry.type)} • ${compactDualDate(entry.dateTime, Localizations.localeOf(context))}',
              onTap: () => showEntryDetails(context, entry),
            ));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.projects) {
        for (final project in ref.watch(projectsProvider)) {
          final haystack = '${project.title} ${project.description ?? ''}'.toLowerCase();
          if (haystack.contains(query)) {
            results.add(_SearchItem(
              icon: Icons.workspaces_rounded,
              title: project.title,
              subtitle: l10n.projects,
              onTap: () => context.push('/projects/${project.id}'),
            ));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.notes) {
        for (final note in ref.watch(notesProvider)) {
          if (note.archived) continue;
          final haystack = '${note.title} ${note.plainText} ${note.tags.join(' ')}'.toLowerCase();
          if (haystack.contains(query)) {
            results.add(_SearchItem(
              icon: Icons.edit_note_rounded,
              title: note.title.isEmpty ? l10n.notes : note.title,
              subtitle: note.plainText,
              onTap: () => context.push('/notes/edit', extra: note.id),
            ));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.people) {
        for (final person in ref.watch(peopleProvider)) {
          final haystack = '${person.name} ${person.relationship ?? ''} ${person.phone ?? ''} ${person.email ?? ''} ${person.notes ?? ''}'.toLowerCase();
          if (haystack.contains(query)) {
            results.add(_SearchItem(icon: Icons.person_rounded, title: person.name, subtitle: person.relationship ?? l10n.people, onTap: () => context.push('/people')));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.shopping) {
        for (final list in ref.watch(shoppingProvider)) {
          final matches = list.title.toLowerCase().contains(query) || list.items.any((item) => item.title.toLowerCase().contains(query));
          if (matches) {
            results.add(_SearchItem(icon: Icons.shopping_basket_rounded, title: list.title, subtitle: '${list.checkedCount}/${list.items.length} ${l10n.items}', onTap: () => context.push('/shopping/${list.id}')));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.medication) {
        for (final medicine in ref.watch(medicationProvider)) {
          final haystack = '${medicine.name} ${medicine.dosage} ${medicine.instructions ?? ''}'.toLowerCase();
          if (haystack.contains(query)) {
            results.add(_SearchItem(icon: Icons.medication_rounded, title: medicine.name, subtitle: '${medicine.dosage} • ${medicine.time}', onTap: () => context.push('/medication')));
          }
        }
      }
      if (filter == _SearchKind.all || filter == _SearchKind.finance) {
        for (final transaction in ref.watch(financeProvider).transactions) {
          final haystack = '${transaction.category ?? ''} ${transaction.note ?? ''} ${transaction.amount}'.toLowerCase();
          if (haystack.contains(query)) {
            results.add(_SearchItem(icon: Icons.account_balance_wallet_rounded, title: transaction.category ?? l10n.finance, subtitle: localizeDigits(transaction.amount.toStringAsFixed(0), Localizations.localeOf(context)), onTap: () => context.push('/finance')));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.globalSearch)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.searchEverything,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { controller.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              for (final kind in _SearchKind.values) ...[
                ChoiceChip(label: Text(_kindLabel(l10n, kind)), selected: filter == kind, onSelected: (_) => setState(() => filter = kind)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: query.isEmpty
              ? _SearchMessage(icon: Icons.manage_search_rounded, message: l10n.searchHint)
              : results.isEmpty
                  ? _SearchMessage(icon: Icons.search_off_rounded, message: l10n.noSearchResults)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return Card(child: ListTile(leading: CircleAvatar(child: Icon(item.icon)), title: Text(item.title), subtitle: Text(item.subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: item.onTap));
                      },
                    ),
        ),
      ]),
    );
  }
}

String _kindLabel(AppLocalizations l10n, _SearchKind kind) => switch (kind) {
  _SearchKind.all => l10n.all,
  _SearchKind.schedule => l10n.calendar,
  _SearchKind.projects => l10n.projects,
  _SearchKind.notes => l10n.notes,
  _SearchKind.people => l10n.people,
  _SearchKind.shopping => l10n.shopping,
  _SearchKind.medication => l10n.medications,
  _SearchKind.finance => l10n.finance,
};

class _SearchItem {
  const _SearchItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)])));
}
