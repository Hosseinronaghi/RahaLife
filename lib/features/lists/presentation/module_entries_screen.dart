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
  const ModuleEntriesScreen({required this.type, super.key});

  final HomeEntryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref
        .watch(homeEntriesProvider)
        .where((item) => item.type == type)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
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
                      onPressed: () => showAddEntry(context, type),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Checkbox(
                      value: entry.completed,
                      onChanged: (_) => ref
                          .read(homeEntriesProvider.notifier)
                          .toggle(entry.id),
                    ),
                    title: Text(
                      entry.title,
                      style: TextStyle(
                        decoration:
                            entry.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      compactDualDate(
                        entry.dateTime,
                        Localizations.localeOf(context),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showEntryDetails(context, entry),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showAddEntry(context, type),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
