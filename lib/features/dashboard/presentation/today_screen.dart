import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/settings/app_settings.dart';
import '../../../features/cycle/presentation/cycle_controller.dart';
import '../../../features/finance/domain/finance_models.dart';
import '../../../features/finance/presentation/finance_controller.dart';
import '../../../features/home/domain/home_entry.dart';
import '../../../features/home/presentation/entry_details_sheet.dart';
import '../../../features/home/presentation/home_controller.dart';
import '../../../features/home/presentation/home_entry_ui.dart';
import '../../../features/home/presentation/quick_add_sheet.dart';
import '../../../features/medication/presentation/medication_controller.dart';
import '../../../features/shopping/presentation/shopping_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final settings = ref.watch(appSettingsProvider);
    final allEntries = ref.watch(homeEntriesProvider);
    final now = DateTime.now();
    final entries = allEntries.where((item) => item.occursOn(now)).toList();
    final visibleEntries = entries
        .where((entry) => !settings.hiddenHomeSections.contains(entry.type))
        .toList(growable: false);
    final grouped = <HomeEntryType, List<HomeEntry>>{};
    for (final entry in visibleEntries) {
      grouped.putIfAbsent(entry.type, () => []).add(entry);
    }
    final shoppingLists = ref.watch(shoppingProvider);
    final uncheckedShopping = shoppingLists.fold<int>(
      0,
      (sum, list) => sum + list.items.where((item) => !item.checked).length,
    );
    final activeMedications = ref.watch(medicationProvider).where((item) => item.active).length;
    final financeState = ref.watch(financeProvider);
    final todayTransactions = financeState.transactions.where((item) =>
        item.dateTime.year == now.year &&
        item.dateTime.month == now.month &&
        item.dateTime.day == now.day).toList();
    final cycleLogs = ref.watch(cycleProvider);
    final predictedCycle = cycleLogs.isEmpty
        ? null
        : ref.read(cycleProvider.notifier).predictedNextStart;
    final cycleIsToday = predictedCycle != null &&
        predictedCycle.year == now.year &&
        predictedCycle.month == now.month &&
        predictedCycle.day == now.day;
    final hasSpecializedData = uncheckedShopping > 0 ||
        activeMedications > 0 ||
        todayTransactions.isNotEmpty ||
        cycleIsToday;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: const SizedBox.shrink(),
        actions: [
          IconButton.filledTonal(
            tooltip: l10n.search,
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: l10n.notifications,
            onPressed: () => _showNotifications(context),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
            sliver: SliverList.list(
              children: [
                _DateHeader(date: now, locale: locale),
                const SizedBox(height: 18),
                if (visibleEntries.isEmpty && !hasSpecializedData)
                  _EmptyTodayState(onAdd: () => showQuickAdd(context))
                else ...[
                  if (visibleEntries.isNotEmpty) ...[
                    _TodaySummary(entries: visibleEntries),
                    const SizedBox(height: 18),
                  ],
                  if (hasSpecializedData) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (uncheckedShopping > 0)
                          _ModuleSummaryCard(
                            icon: Icons.shopping_basket_rounded,
                            title: l10n.shopping,
                            value: '${localizedNumber(uncheckedShopping, locale)} ${l10n.items}',
                            onTap: () => context.push('/shopping'),
                          ),
                        if (activeMedications > 0)
                          _ModuleSummaryCard(
                            icon: Icons.medication_rounded,
                            title: l10n.medications,
                            value: localizedNumber(activeMedications, locale),
                            onTap: () => context.push('/medication'),
                          ),
                        if (todayTransactions.isNotEmpty)
                          _ModuleSummaryCard(
                            icon: Icons.account_balance_wallet_rounded,
                            title: l10n.finance,
                            value: localizedNumber(
                              todayTransactions.fold<double>(0, (sum, item) =>
                                sum + (item.type == FinanceTransactionType.expense || item.type == FinanceTransactionType.debt ? -item.amount : item.amount)),
                              locale,
                            ),
                            onTap: () => context.push('/finance'),
                          ),
                        if (cycleIsToday)
                          _ModuleSummaryCard(
                            icon: Icons.water_drop_rounded,
                            title: l10n.cycle,
                            value: l10n.estimatedNextCycle,
                            onTap: () => context.push('/cycle'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (visibleEntries.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 760;
                      final sections = [
                        for (final type in homeSectionOrder)
                          if (grouped[type]?.isNotEmpty ?? false)
                            _TodaySection(
                              type: type,
                              entries: grouped[type]!,
                            ),
                      ];
                      if (!twoColumns) {
                        return Column(
                          children: [
                            for (var index = 0;
                                index < sections.length;
                                index++) ...[
                              sections[index],
                              if (index < sections.length - 1)
                                const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 260,
                        ),
                        itemCount: sections.length,
                        itemBuilder: (_, index) => sections[index],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: l10n.addNewItem,
        onPressed: () => showQuickAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            icon: const Icon(Icons.notifications_none_rounded),
            title: Text(l10n.notifications),
            content: Text(l10n.noNotifications),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      );
}

class _ModuleSummaryCard extends StatelessWidget {
  const _ModuleSummaryCard({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ])),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ),
      );
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.locale});

  final DateTime date;
  final Locale locale;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryDateLabel(date, locale),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  secondaryDateLabel(date, locale),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 11,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      );
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer,
                    scheme.tertiaryContainer.withValues(alpha: 0.72),
                  ],
                ),
                borderRadius: BorderRadius.circular(34),
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 52,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noItemsToday,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyTodayHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addNewItem),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.entries});

  final List<HomeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final completed = entries.where((item) => item.completed).length;
    final pending = entries.length - completed;
    final financial = entries
        .where((item) => item.type == HomeEntryType.finance)
        .fold<double>(0, (sum, item) => sum + (item.amount ?? 0));
    final progress = entries.isEmpty ? 0.0 : completed / entries.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.todaySummary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryPill(
                  icon: Icons.layers_rounded,
                  label: l10n.totalItems,
                  value: localizedNumber(entries.length, locale),
                ),
                _SummaryPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: l10n.completedItems,
                  value: localizedNumber(completed, locale),
                ),
                _SummaryPill(
                  icon: Icons.pending_actions_rounded,
                  label: l10n.pendingItems,
                  value: localizedNumber(pending, locale),
                ),
                if (financial != 0)
                  _SummaryPill(
                    icon: Icons.payments_outlined,
                    label: l10n.financialTotal,
                    value: localizedNumber(financial, locale),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text('$label: '),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _TodaySection extends ConsumerWidget {
  const _TodaySection({required this.type, required this.entries});

  final HomeEntryType type;
  final List<HomeEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = homeEntryTypeColor(type, Theme.of(context).colorScheme);
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(homeEntryTypeIcon(type), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    homeEntryTypeLabel(l10n, type),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localizedNumber(
                      entries.length,
                      Localizations.localeOf(context),
                    ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => showEntryDetails(context, entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          Checkbox(
                            value: entry.completed,
                            onChanged: (_) => ref
                                .read(homeEntriesProvider.notifier)
                                .toggle(entry.id),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        decoration: entry.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: entry.completed
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (homeEntrySubtypeLabel(l10n, entry) != null)
                                      homeEntrySubtypeLabel(l10n, entry)!,
                                    localizedTime(entry.dateTime, Localizations.localeOf(context)),
                                    l10n.tapForDetails,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
