import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/settings/app_module.dart';
import '../../../core/settings/app_settings.dart';
import '../../../features/home/presentation/home_entry_ui.dart';
import '../../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _SettingsGroup(
            title: l10n.language,
            icon: Icons.translate_rounded,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'fa', label: Text(l10n.persian)),
                ButtonSegment(value: 'en', label: Text(l10n.english)),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (values) {
                notifier.setLocale(Locale(values.first));
              },
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.theme,
            icon: Icons.contrast_rounded,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    label: Text(l10n.systemTheme),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded),
                    label: Text(l10n.lightTheme),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded),
                    label: Text(l10n.darkTheme),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (values) {
                  notifier.setThemeMode(values.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.accentColor,
            icon: Icons.palette_outlined,
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final choice in AccentChoice.values)
                  _AccentButton(
                    choice: choice,
                    selected: settings.accentChoice == choice,
                    onTap: () => notifier.setAccent(choice),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.fontSize,
            icon: Icons.format_size_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(l10n.small),
                    Expanded(
                      child: Slider(
                        value: settings.textScale,
                        min: 0.9,
                        max: 1.2,
                        divisions: 3,
                        label: localizeDigits(
                          settings.textScale.toStringAsFixed(1),
                          Localizations.localeOf(context),
                        ),
                        onChanged: notifier.setTextScale,
                      ),
                    ),
                    Text(l10n.large),
                  ],
                ),
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.homeCustomization,
            icon: Icons.dashboard_customize_rounded,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final type in homeSectionOrder)
                  SwitchListTile.adaptive(
                    secondary: Icon(homeEntryTypeIcon(type)),
                    title: Text(homeEntryTypeLabel(l10n, type)),
                    subtitle: Text(
                      settings.hiddenHomeSections.contains(type)
                          ? l10n.hideSection
                          : l10n.showSection,
                    ),
                    value: !settings.hiddenHomeSections.contains(type),
                    onChanged: (visible) {
                      notifier.setSectionVisible(type, visible);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.customizeModuleOrder,
            icon: Icons.reorder_rounded,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Text(
                    l10n.dragToReorderModules,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: settings.moduleOrder.length,
                  onReorderItem: notifier.reorderModules,
                  itemBuilder: (context, index) {
                    final module = settings.moduleOrder[index];
                    final visible = !settings.hiddenModules.contains(module);
                    return SwitchListTile.adaptive(
                      key: ValueKey(module),
                      secondary: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_indicator_rounded),
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            appModuleIcon(module),
                            color: appModuleColor(module),
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(appModuleLabel(l10n, module))),
                        ],
                      ),
                      value: visible,
                      onChanged: (value) =>
                          notifier.setModuleVisible(module, value),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: OutlinedButton.icon(
                    onPressed: notifier.resetModuleLayout,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.restoreDefaultOrder),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: l10n.notificationsAndAlarms,
            icon: Icons.notifications_active_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.notificationsPermissionHint),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final granted = await ReminderService.instance
                            .requestPermissions();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? l10n.notificationPermissionGranted
                                  : l10n.notificationPermissionDenied,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(l10n.enableNotifications),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await ReminderService.instance.showTest(
                          title: l10n.testReminderTitle,
                          body: l10n.testReminderBody,
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded),
                      label: Text(l10n.testNotification),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await ReminderService.instance.showTest(
                          title: l10n.testAlarmTitle,
                          body: l10n.testAlarmBody,
                          alarm: true,
                        );
                      },
                      icon: const Icon(Icons.alarm_rounded),
                      label: Text(l10n.testAlarm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.icon,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: padding == EdgeInsets.zero
                    ? const EdgeInsets.fromLTRB(18, 18, 18, 8)
                    : EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final AccentChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: choice.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: choice.color.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
        ),
      );
}
