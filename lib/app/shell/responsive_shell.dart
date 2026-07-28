import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/quick_add_sheet.dart';
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
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: l10n.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month_outlined),
        selectedIcon: const Icon(Icons.calendar_month_rounded),
        label: l10n.calendar,
      ),
      NavigationDestination(
        icon: const Icon(Icons.grid_view_outlined),
        selectedIcon: const Icon(Icons.grid_view_rounded),
        label: l10n.lists,
      ),
      NavigationDestination(
        icon: const Icon(Icons.insights_outlined),
        selectedIcon: const Icon(Icons.insights_rounded),
        label: l10n.reports,
      ),
      NavigationDestination(
        icon: const Icon(Icons.more_horiz_rounded),
        selectedIcon: const Icon(Icons.more_rounded),
        label: l10n.more,
      ),
    ];

    void select(int value) => context.go(_paths[value]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        if (!desktop) {
          return Scaffold(
            extendBody: false,
            body: SafeArea(bottom: false, child: child),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1220,
                minExtendedWidth: 230,
                selectedIndex: index,
                onDestinationSelected: select,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 22),
                  child: constraints.maxWidth >= 1220
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BrandMark(onTap: () => context.go('/today')),
                            const SizedBox(width: 11),
                            Text(
                              l10n.appName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        )
                      : _BrandMark(onTap: () => context.go('/today')),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: constraints.maxWidth >= 1220
                      ? FilledButton.icon(
                          onPressed: () => showQuickAdd(context),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.add),
                        )
                      : FloatingActionButton.small(
                          onPressed: () => showQuickAdd(context),
                          child: const Icon(Icons.add_rounded),
                        ),
                ),
                destinations: destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                    )
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.eco_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
}
