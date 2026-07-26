import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({required this.child, super.key});
  final Widget child;

  static const _paths = ['/today', '/calendar', '/lists', '/reports', '/more'];

  int _index(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final found = _paths.indexWhere(location.startsWith);
    return found < 0 ? 0 : found;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = _index(context);
    final destinations = [
      NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: l10n.today),
      NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l10n.calendar),
      NavigationDestination(icon: const Icon(Icons.checklist_outlined), selectedIcon: const Icon(Icons.checklist), label: l10n.lists),
      NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: l10n.reports),
      NavigationDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more), label: l10n.more),
    ];

    void select(int value) => context.go(_paths[value]);

    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      if (!desktop) {
        return Scaffold(
          body: SafeArea(child: child),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: select,
            destinations: destinations,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showQuickAdd(context),
            child: const Icon(Icons.add),
          ),
        );
      }

      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: constraints.maxWidth >= 1180,
              selectedIndex: index,
              onDestinationSelected: select,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FloatingActionButton.small(
                  onPressed: () => _showQuickAdd(context),
                  child: const Icon(Icons.add),
                ),
              ),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: SafeArea(child: child)),
          ],
        ),
      );
    });
  }

  Future<void> _showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => const _QuickAddSheet(),
      );
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(IconData, String)>[
      (Icons.task_alt, l10n.tasks),
      (Icons.medication_outlined, l10n.medications),
      (Icons.event_available, l10n.appointments),
      (Icons.note_add_outlined, l10n.notes),
      (Icons.shopping_cart_outlined, l10n.shopping),
      (Icons.payments_outlined, l10n.finance),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final item in items)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(item.$1),
                    const SizedBox(height: 8),
                    Text(item.$2, textAlign: TextAlign.center),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
