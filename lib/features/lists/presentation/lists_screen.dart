import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_module.dart';
import '../../../core/settings/app_settings.dart';
import '../../../l10n/generated/app_localizations.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final modules = settings.moduleOrder
        .where((module) => !settings.hiddenModules.contains(module))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allFeatures),
        actions: [
          IconButton(
            tooltip: l10n.customizeModuleOrder,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: modules.isEmpty
          ? Center(child: Text(l10n.noVisibleModules))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1100
                    ? 4
                    : MediaQuery.sizeOf(context).width >= 650
                        ? 3
                        : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.16,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return _ModuleCard(
                  icon: appModuleIcon(module),
                  title: appModuleLabel(l10n, module),
                  color: appModuleColor(module),
                  onTap: () => context.push(appModuleRoute(module)),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
                      width: 48,
                      height: 48,
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
              ],
            ),
          ),
        ),
      );
}
