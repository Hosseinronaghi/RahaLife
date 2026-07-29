import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../people/domain/person.dart';
import '../../people/presentation/people_controller.dart';
import '../domain/home_entry.dart';
import 'home_controller.dart';
import 'home_entry_ui.dart';

Future<void> showEntryDetails(BuildContext context, HomeEntry entry) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntryDetailsSheet(entry: entry),
    );

class _EntryDetailsSheet extends ConsumerWidget {
  const _EntryDetailsSheet({required this.entry});

  final HomeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final typeColor = homeEntryTypeColor(entry.type, scheme);
    final people = ref.watch(peopleProvider);
    Person? relatedPerson;
    for (final person in people) {
      if (person.id == entry.personId) {
        relatedPerson = person;
        break;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(homeEntryTypeIcon(entry.type), color: typeColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeEntryTypeLabel(l10n, entry.type),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: typeColor,
                            ),
                      ),
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (homeEntrySubtypeLabel(l10n, entry) != null) ...[
              _InfoRow(
                icon: Icons.category_rounded,
                title: entry.type == HomeEntryType.affair
                    ? l10n.affairType
                    : l10n.appointmentType,
                value: homeEntrySubtypeLabel(l10n, entry)!,
              ),
              const SizedBox(height: 12),
            ],
            if (relatedPerson != null) ...[
              _InfoRow(
                icon: Icons.person_rounded,
                title: l10n.relatedPerson,
                value: relatedPerson.name,
              ),
              const SizedBox(height: 12),
            ],
            _InfoRow(
              icon: Icons.schedule_rounded,
              title: l10n.dateAndTime,
              value:
                  '${compactDualDate(entry.dateTime, locale)} · ${localizedTime(entry.dateTime, locale)}',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.subject_rounded,
              title: l10n.description,
              value: entry.details ?? l10n.noDescription,
            ),
            if (entry.location?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.location_on_outlined,
                title: l10n.location,
                value: [entry.location!, if (entry.address?.isNotEmpty ?? false) entry.address!].join(' · '),
              ),
            ],
            if (entry.reminder.enabled) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: entry.reminder.kind.name == 'alarm'
                    ? Icons.alarm_rounded
                    : Icons.notifications_active_outlined,
                title: l10n.reminder,
                value: entry.reminder.kind.name == 'alarm'
                    ? l10n.alarmMode
                    : l10n.notificationMode,
              ),
            ],
            if (entry.linkedShoppingListId != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/shopping/${entry.linkedShoppingListId}');
                },
                icon: const Icon(Icons.shopping_basket_outlined),
                label: Text(l10n.openLinkedShoppingList),
              ),
            ],
            if (entry.amount != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.payments_rounded,
                title: l10n.amount,
                value: localizedNumber(entry.amount!, locale),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(homeEntriesProvider.notifier).delete(entry.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.itemDeleted)),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.delete),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(homeEntriesProvider.notifier).toggle(entry.id);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      entry.completed
                          ? Icons.undo_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(
                      entry.completed ? l10n.markUndone : l10n.markDone,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      );
}
