import '../../home/domain/birthday_occurrence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/entry_details_sheet.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/presentation/home_entry_ui.dart';
import '../../home/presentation/quick_add_sheet.dart';

class ModuleEntriesScreen extends ConsumerWidget {
  const ModuleEntriesScreen({required this.type, this.projectId, super.key});

  final HomeEntryType type;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items =
        ref
            .watch(effectiveHomeEntriesProvider)
            .where(
              (item) =>
                  item.type == type &&
                  (projectId == null || item.projectId == projectId),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final now = DateTime.now();
    if (type == HomeEntryType.birthday) {
      items.sort((a, b) {
        final group = birthdayGroup(a, now).compareTo(birthdayGroup(b, now));
        return group != 0
            ? group
            : (birthdayDaysAway(a, now) ?? 9999).compareTo(
                birthdayDaysAway(b, now) ?? 9999,
              );
      });
    }
    final color = homeEntryTypeColor(type, Theme.of(context).colorScheme);

    return Scaffold(
      appBar: AppBar(title: Text(homeEntryTypeLabel(l10n, type))),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        homeEntryTypeIcon(type),
                        color: color,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.noItemsToday,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () =>
                          showAddEntry(context, type, projectId: projectId),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(addHomeEntryLabel(l10n, type)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = items[index];
                final fa = Localizations.localeOf(context).languageCode == 'fa';
                final group = type == HomeEntryType.birthday
                    ? birthdayGroup(entry, now)
                    : 0;
                final showGroup =
                    type == HomeEntryType.birthday &&
                    (index == 0 ||
                        birthdayGroup(items[index - 1], now) != group);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showGroup)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          (fa
                              ? [
                                  'امروز',
                                  'فردا',
                                  '۷ روز آینده',
                                  'دیروز',
                                  'سایر تولدها',
                                ]
                              : [
                                  'Today',
                                  'Tomorrow',
                                  'Next 7 days',
                                  'Yesterday',
                                  'Other birthdays',
                                ])[group],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: entry.type == HomeEntryType.birthday
                            ? const Icon(Icons.cake_outlined)
                            : Checkbox(
                                value: entry.completedOn(DateTime.now()),
                                onChanged: (_) => ref
                                    .read(homeEntriesProvider.notifier)
                                    .toggle(entry.id),
                              ),
                        title: Text(
                          entry.title,
                          style: TextStyle(
                            decoration: entry.completedOn(DateTime.now())
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (homeEntrySubtypeLabel(l10n, entry) != null)
                              homeEntrySubtypeLabel(l10n, entry)!,
                            compactDualDate(
                              entry.dateTime,
                              Localizations.localeOf(context),
                            ),
                          ].join(' • '),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showEntryDetails(context, entry),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showAddEntry(context, type, projectId: projectId),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
