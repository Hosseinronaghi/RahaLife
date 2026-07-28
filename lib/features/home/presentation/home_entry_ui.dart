import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/home_entry.dart';

const homeSectionOrder = <HomeEntryType>[
  HomeEntryType.task,
  HomeEntryType.appointment,
  HomeEntryType.medication,
  HomeEntryType.birthday,
  HomeEntryType.habit,
  HomeEntryType.note,
  HomeEntryType.shopping,
  HomeEntryType.finance,
];

String homeEntryTypeLabel(AppLocalizations l10n, HomeEntryType type) =>
    switch (type) {
      HomeEntryType.task => l10n.tasks,
      HomeEntryType.medication => l10n.medications,
      HomeEntryType.appointment => l10n.appointments,
      HomeEntryType.note => l10n.notes,
      HomeEntryType.shopping => l10n.shopping,
      HomeEntryType.finance => l10n.finance,
      HomeEntryType.habit => l10n.habits,
      HomeEntryType.birthday => l10n.birthdays,
    };

String addHomeEntryLabel(AppLocalizations l10n, HomeEntryType type) =>
    switch (type) {
      HomeEntryType.task => l10n.addTask,
      HomeEntryType.medication => l10n.addMedicine,
      HomeEntryType.appointment => l10n.addAppointment,
      HomeEntryType.note => l10n.addNote,
      HomeEntryType.shopping => l10n.addShopping,
      HomeEntryType.finance => l10n.addFinance,
      HomeEntryType.habit => l10n.addHabit,
      HomeEntryType.birthday => l10n.addBirthday,
    };

IconData homeEntryTypeIcon(HomeEntryType type) => switch (type) {
      HomeEntryType.task => Icons.task_alt_rounded,
      HomeEntryType.medication => Icons.medication_rounded,
      HomeEntryType.appointment => Icons.event_available_rounded,
      HomeEntryType.note => Icons.sticky_note_2_rounded,
      HomeEntryType.shopping => Icons.shopping_bag_rounded,
      HomeEntryType.finance => Icons.account_balance_wallet_rounded,
      HomeEntryType.habit => Icons.auto_graph_rounded,
      HomeEntryType.birthday => Icons.cake_rounded,
    };

Color homeEntryTypeColor(HomeEntryType type, ColorScheme scheme) => switch (type) {
      HomeEntryType.task => scheme.primary,
      HomeEntryType.medication => const Color(0xFF0EA5E9),
      HomeEntryType.appointment => const Color(0xFF8B5CF6),
      HomeEntryType.note => const Color(0xFFF59E0B),
      HomeEntryType.shopping => const Color(0xFFEC4899),
      HomeEntryType.finance => const Color(0xFF10B981),
      HomeEntryType.habit => const Color(0xFF6366F1),
      HomeEntryType.birthday => const Color(0xFFF97316),
    };
