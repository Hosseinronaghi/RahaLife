import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../finance/presentation/finance_controller.dart';
import '../../home/domain/home_entry.dart';
import '../../medication/presentation/medication_controller.dart';
import '../../people/presentation/people_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/presentation/home_entry_ui.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final entries = ref.watch(homeEntriesProvider);
    final completed = entries.where((item) => item.completed).length;
    final pending = entries.length - completed;
    final progress = entries.isEmpty ? 0.0 : completed / entries.length;
    final finance = ref.watch(financeProvider);
    final peopleCount = ref.watch(peopleProvider).length;
    final medicationCount = ref.watch(medicationProvider).length;
    final shoppingCount = ref.watch(shoppingProvider)
        .fold<int>(0, (sum, list) => sum + list.items.where((item) => !item.checked).length);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _MetricCard(
                icon: Icons.layers_rounded,
                label: l10n.totalItems,
                value: localizedNumber(entries.length, locale),
              ),
              _MetricCard(
                icon: Icons.check_circle_rounded,
                label: l10n.completedItems,
                value: localizedNumber(completed, locale),
              ),
              _MetricCard(
                icon: Icons.pending_actions_rounded,
                label: l10n.pendingItems,
                value: localizedNumber(pending, locale),
              ),
              _MetricCard(
                icon: Icons.payments_rounded,
                label: l10n.balance,
                value: localizedNumber(finance.balance, locale),
              ),
              _MetricCard(
                icon: Icons.people_alt_rounded,
                label: l10n.people,
                value: localizedNumber(peopleCount, locale),
              ),
              _MetricCard(
                icon: Icons.medication_rounded,
                label: l10n.medications,
                value: localizedNumber(medicationCount, locale),
              ),
              _MetricCard(
                icon: Icons.shopping_basket_rounded,
                label: l10n.shopping,
                value: localizedNumber(shoppingCount, locale),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.donut_large_rounded),
                      const SizedBox(width: 10),
                      Text(
                        l10n.progress,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${localizedNumber((progress * 100).round(), locale)}${locale.languageCode == 'fa' ? '٪' : '%'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: progress, minHeight: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.allFeatures,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  for (final type in homeSectionOrder) ...[
                    _TypeBar(
                      type: type,
                      count: entries.where((item) => item.type == type).length,
                      max: entries.isEmpty ? 1 : entries.length,
                    ),
                    if (type != homeSectionOrder.last)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      );
}

class _TypeBar extends StatelessWidget {
  const _TypeBar({required this.type, required this.count, required this.max});

  final HomeEntryType type;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final color = homeEntryTypeColor(type, Theme.of(context).colorScheme);
    return Row(
      children: [
        Icon(homeEntryTypeIcon(type), color: color, size: 21),
        const SizedBox(width: 10),
        SizedBox(width: 86, child: Text(homeEntryTypeLabel(l10n, type))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: count / max,
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(localizedNumber(count, locale)),
      ],
    );
  }
}
