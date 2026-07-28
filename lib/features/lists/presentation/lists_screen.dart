import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modules = <_ModuleItem>[
      _ModuleItem(Icons.assignment_turned_in_rounded, l10n.tasks, '/module/affair', const Color(0xFF22C55E)),
      _ModuleItem(Icons.people_alt_rounded, l10n.appointments, '/module/appointment', const Color(0xFF8B5CF6)),
      _ModuleItem(Icons.shopping_basket_rounded, l10n.shopping, '/shopping', const Color(0xFFEC4899)),
      _ModuleItem(Icons.medication_rounded, l10n.medications, '/medication', const Color(0xFF0EA5E9)),
      _ModuleItem(Icons.contacts_rounded, l10n.people, '/people', const Color(0xFF14B8A6)),
      _ModuleItem(Icons.cake_rounded, l10n.birthdays, '/module/birthday', const Color(0xFFF97316)),
      _ModuleItem(Icons.sticky_note_2_rounded, l10n.notes, '/module/note', const Color(0xFFF59E0B)),
      _ModuleItem(Icons.auto_graph_rounded, l10n.habits, '/module/habit', const Color(0xFF6366F1)),
      _ModuleItem(Icons.account_balance_wallet_rounded, l10n.finance, '/finance', const Color(0xFF10B981)),
      _ModuleItem(Icons.water_drop_rounded, l10n.cycle, '/cycle', const Color(0xFFE11D48)),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allFeatures)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 1100 ? 4 : MediaQuery.sizeOf(context).width >= 650 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.16,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return _ModuleCard(icon: module.icon, title: module.title, color: module.color, onTap: () => context.push(module.route));
        },
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem(this.icon, this.title, this.route, this.color);
  final IconData icon;
  final String title;
  final String route;
  final Color color;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.icon, required this.title, required this.color, required this.onTap});
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color)),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded, size: 19),
              ]),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
        ),
      );
}
