import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../l10n/generated/app_localizations.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final jalali = Jalali.fromDateTime(now);
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'fa'
        ? '${jalali.formatter.wN} ${jalali.day} ${jalali.formatter.mN} ${jalali.year}'
        : '${now.day}/${now.month}/${now.year}';

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          pinned: true,
          title: Text(l10n.today),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const _SummaryStrip(),
            const SizedBox(height: 24),
            _SectionCard(title: l10n.overdue, icon: Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.medications, icon: Icons.medication_outlined),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.appointments, icon: Icons.event_available_outlined),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.tasks, icon: Icons.task_alt_outlined),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.notes, icon: Icons.sticky_note_2_outlined),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.finance, icon: Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            _SectionCard(title: l10n.upNext, icon: Icons.next_plan_outlined),
            const SizedBox(height: 100),
          ]),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: const [
            _SummaryTile(icon: Icons.task_alt, value: '0', label: 'Tasks'),
            _SummaryTile(icon: Icons.medication, value: '0', label: 'Medicine'),
            _SummaryTile(icon: Icons.event, value: '0', label: 'Events'),
            _SummaryTile(icon: Icons.payments, value: '0', label: 'Cash flow'),
          ],
        ),
      );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsetsDirectional.only(end: 12),
        child: SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ]),
            ]),
          ),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Icon(icon), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 18),
            Text(AppLocalizations.of(context).noItemsToday, textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ]),
        ),
      );
}
