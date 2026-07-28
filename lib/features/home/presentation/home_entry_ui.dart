import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/home_entry.dart';

const homeSectionOrder = <HomeEntryType>[
  HomeEntryType.affair,
  HomeEntryType.appointment,
  HomeEntryType.shopping,
  HomeEntryType.medication,
  HomeEntryType.birthday,
  HomeEntryType.habit,
  HomeEntryType.note,
  HomeEntryType.finance,
];

String homeEntryTypeLabel(AppLocalizations l10n, HomeEntryType type) => switch (type) {
      HomeEntryType.affair => l10n.tasks,
      HomeEntryType.appointment => l10n.appointments,
      HomeEntryType.shopping => l10n.shopping,
      HomeEntryType.medication => l10n.medications,
      HomeEntryType.birthday => l10n.birthdays,
      HomeEntryType.habit => l10n.habits,
      HomeEntryType.note => l10n.notes,
      HomeEntryType.finance => l10n.finance,
    };

String addHomeEntryLabel(AppLocalizations l10n, HomeEntryType type) => switch (type) {
      HomeEntryType.affair => l10n.addTask,
      HomeEntryType.appointment => l10n.addAppointment,
      HomeEntryType.shopping => l10n.newShoppingList,
      HomeEntryType.medication => l10n.addMedicine,
      HomeEntryType.birthday => l10n.addBirthday,
      HomeEntryType.habit => l10n.addHabit,
      HomeEntryType.note => l10n.addNote,
      HomeEntryType.finance => l10n.addFinance,
    };

IconData homeEntryTypeIcon(HomeEntryType type) => switch (type) {
      HomeEntryType.affair => Icons.assignment_turned_in_rounded,
      HomeEntryType.appointment => Icons.people_alt_rounded,
      HomeEntryType.shopping => Icons.shopping_basket_rounded,
      HomeEntryType.medication => Icons.medication_rounded,
      HomeEntryType.birthday => Icons.cake_rounded,
      HomeEntryType.habit => Icons.auto_graph_rounded,
      HomeEntryType.note => Icons.sticky_note_2_rounded,
      HomeEntryType.finance => Icons.account_balance_wallet_rounded,
    };

Color homeEntryTypeColor(HomeEntryType type, ColorScheme scheme) => switch (type) {
      HomeEntryType.affair => scheme.primary,
      HomeEntryType.appointment => const Color(0xFF8B5CF6),
      HomeEntryType.shopping => const Color(0xFFEC4899),
      HomeEntryType.medication => const Color(0xFF0EA5E9),
      HomeEntryType.birthday => const Color(0xFFF97316),
      HomeEntryType.habit => const Color(0xFF6366F1),
      HomeEntryType.note => const Color(0xFFF59E0B),
      HomeEntryType.finance => const Color(0xFF10B981),
    };

String affairKindLabel(AppLocalizations l10n, AffairKind kind) => switch (kind) {
      AffairKind.personal => l10n.affairPersonal,
      AffairKind.work => l10n.affairWork,
      AffairKind.administrative => l10n.affairAdministrative,
      AffairKind.followUp => l10n.affairFollowUp,
      AffairKind.medical => l10n.affairMedical,
      AffairKind.laboratory => l10n.affairLaboratory,
      AffairKind.payment => l10n.affairPayment,
      AffairKind.study => l10n.affairStudy,
      AffairKind.custom => l10n.affairCustom,
    };

String appointmentKindLabel(AppLocalizations l10n, AppointmentKind kind) => switch (kind) {
      AppointmentKind.meeting => l10n.appointmentMeeting,
      AppointmentKind.cafe => l10n.appointmentCafe,
      AppointmentKind.gathering => l10n.appointmentGathering,
      AppointmentKind.inPerson => l10n.appointmentInPerson,
      AppointmentKind.phone => l10n.appointmentPhone,
      AppointmentKind.online => l10n.appointmentOnline,
      AppointmentKind.party => l10n.appointmentParty,
      AppointmentKind.custom => l10n.appointmentCustom,
    };


String? homeEntrySubtypeLabel(AppLocalizations l10n, HomeEntry entry) {
  final subtype = entry.subtype;
  if (subtype == null || subtype.isEmpty) return null;
  if (entry.type == HomeEntryType.affair) {
    final kind = AffairKind.values.firstWhere(
      (value) => value.name == subtype,
      orElse: () => AffairKind.custom,
    );
    return affairKindLabel(l10n, kind);
  }
  if (entry.type == HomeEntryType.appointment) {
    final kind = AppointmentKind.values.firstWhere(
      (value) => value.name == subtype,
      orElse: () => AppointmentKind.custom,
    );
    return appointmentKindLabel(l10n, kind);
  }
  return null;
}
