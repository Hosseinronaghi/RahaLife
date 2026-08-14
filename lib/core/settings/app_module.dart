import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

enum AppModule {
  projects,
  inbox,
  affairs,
  appointments,
  shopping,
  medication,
  cycle,
  people,
  birthdays,
  notes,
  habits,
  finance,
  messages,
}

const defaultAppModuleOrder = <AppModule>[
  AppModule.inbox,
  AppModule.projects,
  AppModule.affairs,
  AppModule.appointments,
  AppModule.shopping,
  AppModule.medication,
  AppModule.cycle,
  AppModule.people,
  AppModule.birthdays,
  AppModule.notes,
  AppModule.habits,
  AppModule.finance,
  AppModule.messages,
];

String appModuleLabel(AppLocalizations l10n, AppModule module) => switch (module) {
      AppModule.projects => l10n.projects,
      AppModule.inbox => l10n.inbox,
      AppModule.affairs => l10n.tasks,
      AppModule.appointments => l10n.appointments,
      AppModule.shopping => l10n.shopping,
      AppModule.medication => l10n.medications,
      AppModule.cycle => l10n.cycle,
      AppModule.people => l10n.people,
      AppModule.birthdays => l10n.birthdays,
      AppModule.notes => l10n.notes,
      AppModule.habits => l10n.habits,
      AppModule.finance => l10n.finance,
      AppModule.messages => l10n.messagesTitle,
    };

String appModuleRoute(AppModule module) => switch (module) {
      AppModule.projects => '/projects',
      AppModule.inbox => '/inbox',
      AppModule.affairs => '/module/affair',
      AppModule.appointments => '/module/appointment',
      AppModule.shopping => '/shopping',
      AppModule.medication => '/medication',
      AppModule.cycle => '/cycle',
      AppModule.people => '/people',
      AppModule.birthdays => '/module/birthday',
      AppModule.notes => '/notes',
      AppModule.habits => '/module/habit',
      AppModule.finance => '/finance',
      AppModule.messages => '/messages',
    };

IconData appModuleIcon(AppModule module) => switch (module) {
      AppModule.projects => Icons.workspaces_rounded,
      AppModule.inbox => Icons.inbox_rounded,
      AppModule.affairs => Icons.assignment_turned_in_rounded,
      AppModule.appointments => Icons.people_alt_rounded,
      AppModule.shopping => Icons.shopping_basket_rounded,
      AppModule.medication => Icons.medication_rounded,
      AppModule.cycle => Icons.water_drop_rounded,
      AppModule.people => Icons.contacts_rounded,
      AppModule.birthdays => Icons.cake_rounded,
      AppModule.notes => Icons.sticky_note_2_rounded,
      AppModule.habits => Icons.auto_graph_rounded,
      AppModule.finance => Icons.account_balance_wallet_rounded,
      AppModule.messages => Icons.forum_rounded,
    };

Color appModuleColor(AppModule module) => switch (module) {
      AppModule.projects => const Color(0xFF0F766E),
      AppModule.inbox => const Color(0xFF64748B),
      AppModule.affairs => const Color(0xFF22C55E),
      AppModule.appointments => const Color(0xFF8B5CF6),
      AppModule.shopping => const Color(0xFFEC4899),
      AppModule.medication => const Color(0xFF0EA5E9),
      AppModule.cycle => const Color(0xFFE11D48),
      AppModule.people => const Color(0xFF14B8A6),
      AppModule.birthdays => const Color(0xFFF97316),
      AppModule.notes => const Color(0xFFF59E0B),
      AppModule.habits => const Color(0xFF6366F1),
      AppModule.finance => const Color(0xFF10B981),
      AppModule.messages => const Color(0xFF7C3AED),
    };
