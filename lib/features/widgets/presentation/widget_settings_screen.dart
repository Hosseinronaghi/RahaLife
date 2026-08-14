import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/home_controller.dart';
import '../../medication/presentation/medication_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';
import '../data/home_widget_bridge.dart';

final widgetPrivacyProvider = StateNotifierProvider<WidgetPrivacyNotifier, bool>(
  (ref) => WidgetPrivacyNotifier(),
);

class WidgetPrivacyNotifier extends StateNotifier<bool> {
  WidgetPrivacyNotifier() : super(false) {
    _load();
  }
  static const _key = 'widgets.hideSensitive.v1';
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setValue(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final widgetBridgeSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final hideSensitive = ref.watch(widgetPrivacyProvider);
    final entries = ref.watch(homeEntriesProvider);
    final medicationPlans = ref.watch(medicationProvider);
    final shoppingLists = ref.watch(shoppingProvider);
    final now = DateTime.now();
    final today = entries.where((item) => item.occursOn(now)).toList();
    final next = today.where((item) => !item.completed).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final affairs = today
        .where((item) => item.type == HomeEntryType.affair && !item.completed)
        .toList();
    final appointments = today
        .where((item) => item.type == HomeEntryType.appointment && !item.completed)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final birthdays = today
        .where((item) => item.type == HomeEntryType.birthday)
        .toList();
    final activeMedication = medicationPlans
        .where((item) => item.active && !item.isCourseFinished(now))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final activeShopping = shoppingLists.where((item) => !item.completed).toList();
    final remainingShoppingItems = activeShopping.fold<int>(
      0,
      (total, list) => total + list.items.where((item) => !item.checked).length,
    );

    Future<void> refreshWidgets() async {
      final countItems = '${localizeDigits(today.length, locale)} ${l10n.items}';
      final affairsSummary = affairs.isEmpty
          ? l10n.noItems
          : '${localizeDigits(affairs.length, locale)} ${l10n.items} • ${affairs.first.title}';
      final medicationSummary = activeMedication.isEmpty
          ? l10n.noMedications
          : '${activeMedication.first.name} • ${localizeDigits(activeMedication.first.time, locale)}';
      final appointmentSummary = appointments.isEmpty
          ? l10n.noItems
          : '${localizedTime(appointments.first.dateTime, locale)} • ${appointments.first.title}';
      final shoppingSummary = remainingShoppingItems == 0
          ? l10n.noShoppingItems
          : '${localizeDigits(remainingShoppingItems, locale)} ${l10n.items} • ${activeShopping.first.title}';
      final birthdaySummary = birthdays.isEmpty ? l10n.noItems : birthdays.first.title;

      await RahaHomeWidgetBridge.updateDashboard(
        RahaWidgetDashboardData(
          todayTitle: l10n.widgetTodaySummary,
          todaySummary: countItems,
          todayNextItem: next.isEmpty ? l10n.noItemsToday : next.first.title,
          affairsTitle: l10n.tasks,
          affairsSummary: affairsSummary,
          medicationTitle: l10n.medication,
          medicationSummary: medicationSummary,
          appointmentTitle: l10n.appointments,
          appointmentSummary: appointmentSummary,
          shoppingTitle: l10n.shopping,
          shoppingSummary: shoppingSummary,
          birthdayTitle: l10n.birthdays,
          birthdaySummary: birthdaySummary,
          quickAddTitle: l10n.quickAdd,
          quickAddLabel: l10n.quickAdd,
        ),
        hideSensitive: hideSensitive,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetCenter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.widgets_rounded, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.widgets,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.hideSensitiveWidgetData),
                    subtitle: Text(l10n.widgetPrivacy),
                    value: hideSensitive,
                    onChanged: (value) =>
                        ref.read(widgetPrivacyProvider.notifier).setValue(value),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: widgetBridgeSupported
                        ? () async {
                      await refreshWidgets();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.widgetUpdated)),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.refreshWidget),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(_platformTitle(l10n)),
              subtitle: Text(_platformBody(l10n)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tapWidgetToAdd),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _WidgetActionChip(
                        label: l10n.widgetTodaySummary,
                        icon: Icons.today_rounded,
                        androidName: RahaHomeWidgetBridge.androidToday,
                      ),
                      _WidgetActionChip(
                        label: l10n.tasks,
                        icon: Icons.task_alt_rounded,
                        androidName: RahaHomeWidgetBridge.androidAffairs,
                      ),
                      _WidgetActionChip(
                        label: l10n.medications,
                        icon: Icons.medication_rounded,
                        androidName: RahaHomeWidgetBridge.androidMedication,
                      ),
                      _WidgetActionChip(
                        label: l10n.appointments,
                        icon: Icons.people_alt_rounded,
                        androidName: RahaHomeWidgetBridge.androidAppointment,
                      ),
                      _WidgetActionChip(
                        label: l10n.shopping,
                        icon: Icons.shopping_basket_rounded,
                        androidName: RahaHomeWidgetBridge.androidShopping,
                      ),
                      _WidgetActionChip(
                        label: l10n.birthdays,
                        icon: Icons.cake_rounded,
                        androidName: RahaHomeWidgetBridge.androidBirthday,
                      ),
                      _WidgetActionChip(
                        label: l10n.quickAdd,
                        icon: Icons.add_circle_outline_rounded,
                        androidName: RahaHomeWidgetBridge.androidQuickAdd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _WidgetActionChip extends StatelessWidget {
  const _WidgetActionChip({
    required this.label,
    required this.icon,
    required this.androidName,
  });

  final String label;
  final IconData icon;
  final String androidName;

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final l10n = AppLocalizations.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onPressed: isAndroid
          ? () async {
              await RahaHomeWidgetBridge.requestPinAndroid(androidName);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.widgetPinRequested)),
              );
            }
          : null,
    );
  }
}

String _platformTitle(AppLocalizations l10n) {
  if (kIsWeb) return l10n.webPlatform;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => l10n.androidWidgetReady,
    TargetPlatform.iOS => l10n.iosWidgetNeedsTarget,
    TargetPlatform.windows => l10n.desktopQuickPanel,
    TargetPlatform.macOS => l10n.desktopQuickPanel,
    TargetPlatform.linux => l10n.desktopQuickPanel,
    TargetPlatform.fuchsia => l10n.widgetNotSupported,
  };
}

String _platformBody(AppLocalizations l10n) {
  if (kIsWeb) return l10n.widgetNotSupported;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => l10n.androidWidgetReady,
    TargetPlatform.iOS => l10n.iosWidgetNeedsTarget,
    TargetPlatform.windows => l10n.widgetNotSupported,
    TargetPlatform.macOS => l10n.widgetNotSupported,
    TargetPlatform.linux => l10n.widgetNotSupported,
    TargetPlatform.fuchsia => l10n.widgetNotSupported,
  };
}
