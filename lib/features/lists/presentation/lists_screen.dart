import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/home_entry_ui.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allFeatures)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
        ),
        itemCount: homeSectionOrder.length + 3,
        itemBuilder: (context, index) {
          if (index < homeSectionOrder.length) {
            final type = homeSectionOrder[index];
            final color = homeEntryTypeColor(
              type,
              Theme.of(context).colorScheme,
            );
            return _ModuleCard(
              icon: homeEntryTypeIcon(type),
              title: homeEntryTypeLabel(l10n, type),
              badge: l10n.available,
              color: color,
              onTap: () => context.push('/module/${type.name}'),
            );
          }
          final futureItems = [
            (Icons.flag_rounded, l10n.goals),
            (Icons.widgets_rounded, l10n.widgets),
            (Icons.forum_rounded, l10n.messages),
          ];
          final item = futureItems[index - homeSectionOrder.length];
          return _ModuleCard(
            icon: item.$1,
            title: item.$2,
            badge: l10n.comingSoon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onTap: () => context.push('/coming-soon', extra: item.$2),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_outward_rounded, size: 19),
                  ],
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 7),
                Text(
                  badge,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}
