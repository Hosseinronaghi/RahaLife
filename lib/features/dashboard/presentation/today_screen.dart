import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/agenda.dart';
import '../../../core/localization/locale_formatters.dart';
import '../../../core/settings/app_module.dart';
import '../../../core/settings/app_settings.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/quick_add_sheet.dart';
import '../../workspace/record_editor.dart';
import '../../sync/presentation/sync_controller.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayState();
}

class _TodayState extends ConsumerState<TodayScreen> {
  int offset = 0, capacity = 6;
  List<String> slots = [
    'affairs',
    'projects',
    'notes',
    'shopping',
    'medication',
    'finance',
  ];
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
        ref.invalidate(agendaProvider);
      }
    });
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final stored = p.getInt('home.capacity') ?? 6;
        capacity = [4, 6, 8, 12, 16].contains(stored) ? stored : 6;
        slots = (p.getStringList('home.slots') ?? slots)
            .where((n) => AppModule.values.any((m) => m.name == n))
            .toSet()
            .toList();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> customize() async {
    var draftCapacity = capacity;
    final draftSlots = [...slots];
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          return SizedBox(
            height: MediaQuery.sizeOf(c).height * .8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    tr(c, 'خانهٔ من', 'My home'),
                    style: Theme.of(c).textTheme.headlineSmall,
                  ),
                ),
                ListTile(
                  title: Text(tr(c, 'تعداد میان‌برها', 'Shortcut capacity')),
                  trailing: DropdownButton<int>(
                    value: draftCapacity,
                    items: [4, 6, 8, 12, 16]
                        .map(
                          (n) => DropdownMenuItem(value: n, child: Text('$n')),
                        )
                        .toList(),
                    onChanged: (v) => set(() => draftCapacity = v!),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorderItem: (a, b) {
                      set(() {
                        final item = draftSlots.removeAt(a);
                        draftSlots.insert(b, item);
                      });
                    },
                    children: [
                      for (final name in draftSlots)
                        ListTile(
                          key: ValueKey(name),
                          leading: const Icon(Icons.drag_indicator),
                          title: Text(
                            appModuleLabel(
                              AppLocalizations.of(c),
                              AppModule.values.firstWhere(
                                (m) => m.name == name,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => set(() => draftSlots.remove(name)),
                          ),
                        ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final module in AppModule.values)
                      if (!draftSlots.contains(module.name))
                        ActionChip(
                          label: Text(
                            appModuleLabel(AppLocalizations.of(c), module),
                          ),
                          onPressed: () {
                            if (draftSlots.length >= draftCapacity) {
                              ScaffoldMessenger.of(c).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr(
                                      c,
                                      'ظرفیت را بیشتر کن یا یک میان‌بر را بردار',
                                      'Increase capacity or remove a shortcut',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            set(() => draftSlots.add(module.name));
                          },
                        ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('home.capacity', draftCapacity);
                      await p.setStringList('home.slots', draftSlots);
                      if (c.mounted) Navigator.pop(c, true);
                    },
                    child: Text(tr(c, 'ذخیرهٔ چیدمان', 'Save layout')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (mounted && saved == true) {
      setState(() {
        capacity = draftCapacity;
        slots = draftSlots;
      });
    }
  }

  @override
  Widget build(BuildContext c) {
    final scheme = Theme.of(c).colorScheme,
        l10n = AppLocalizations.of(c),
        locale = Localizations.localeOf(c);
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day + offset);
    final schedule = ref.watch(agendaProvider);
    final all = schedule.valueOrNull ?? <AgendaItem>[];
    final items = all
        .where(
          (e) =>
              e.at.year == date.year &&
              e.at.month == date.month &&
              e.at.day == date.day,
        )
        .toList();
    final done = items.where((e) => e.done).length;
    final sync = ref.watch(syncSettingsProvider);
    final settings = ref.watch(appSettingsProvider);
    final modules = slots
        .take(capacity)
        .map(
          (n) => AppModule.values.firstWhere(
            (m) => m.name == n,
            orElse: () => AppModule.notes,
          ),
        )
        .where((m) => !settings.hiddenModules.contains(m))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raha Life'),
        actions: [
          IconButton(
            tooltip: l10n.search,
            onPressed: () => c.push('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: tr(c, 'چیدمان خانه', 'Customize home'),
            onPressed: customize,
            icon: const Icon(Icons.dashboard_customize_outlined),
          ),
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => c.push('/agenda'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAdd(c),
        icon: const Icon(Icons.add),
        label: Text(l10n.quickAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.sizeOf(c).width < 550 ? 20 : 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.tertiaryContainer.withValues(alpha: .6),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryDateLabel(date, locale),
                  style: Theme.of(c).textTheme.labelLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  tr(c, 'برای امروزت جا باز کن.', 'Make room for your day.'),
                  style: Theme.of(c).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(
                    c,
                    'کارها، قرارها و چیزهایی که برایت مهم‌اند؛ یک‌جا.',
                    'Tasks, plans and the things that matter. All together.',
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric(
                      value: localizedNumber(items.length, locale),
                      label: tr(c, 'برنامهٔ روز', 'Planned'),
                    ),
                    _Metric(
                      value: localizedNumber(done, locale),
                      label: tr(c, 'انجام‌شده', 'Completed'),
                    ),
                    ActionChip(
                      avatar: Icon(
                        sync.conflicts > 0
                            ? Icons.sync_problem
                            : Icons.cloud_done_outlined,
                        size: 18,
                      ),
                      label: Text(
                        sync.conflicts > 0
                            ? tr(c, 'بررسی تعارض‌ها', 'Review conflicts')
                            : sync.pendingChanges > 0
                            ? tr(c, 'در انتظار همگام‌سازی', 'Waiting to sync')
                            : tr(c, 'مرکز همگام‌سازی', 'Sync center'),
                      ),
                      onPressed: () => c.push('/sync'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(c, 'فضاهای من', 'My spaces'),
                  style: Theme.of(c).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => c.push('/lists'),
                child: Text(tr(c, 'همهٔ بخش‌ها', 'All spaces')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (c, b) {
              final columns = b.maxWidth > 900
                  ? 6
                  : b.maxWidth > 550
                  ? 3
                  : 2;
              final width = (b.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final module in modules)
                    SizedBox(
                      width: width,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => c.push(appModuleRoute(module)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: b.maxWidth < 550
                                ? Row(
                                    children: [
                                      Icon(
                                        appModuleIcon(module),
                                        color: appModuleColor(module),
                                        size: 26,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          appModuleLabel(l10n, module),
                                          style: Theme.of(
                                            c,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        appModuleIcon(module),
                                        color: appModuleColor(module),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        appModuleLabel(l10n, module),
                                        style: Theme.of(c).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            tr(c, 'مسیر روز', 'Your day'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      selected: offset == i,
                      onSelected: (_) => setState(() => offset = i),
                      label: Text(
                        i == 0
                            ? tr(c, 'امروز', 'Today')
                            : primaryDateLabel(
                                DateTime(now.year, now.month, now.day + i),
                                locale,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (schedule.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (schedule.hasError)
            Text(schedule.error.toString())
          else if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 40,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        c,
                        'این روز هنوز برنامه‌ای ندارد',
                        'Nothing planned for this day',
                      ),
                    ),
                    TextButton(
                      onPressed: () => showQuickAdd(c),
                      child: Text(l10n.addNewItem),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.done ? Icons.check : Icons.schedule),
                  ),
                  title: Text(item.title),
                  subtitle: Text(localizedTime(item.at, locale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => c.push(item.route),
                ),
              ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in [
                (
                  '/records',
                  'مدیریت و بازگردانی',
                  'Edit & restore',
                  Icons.history,
                ),
                (
                  '/bookmarks',
                  'نشانک‌ها',
                  'Bookmarks',
                  Icons.bookmarks_outlined,
                ),
                (
                  '/connections',
                  'ارتباطات',
                  'Connections',
                  Icons.people_outline,
                ),
                (
                  '/assistant',
                  'دستیار',
                  'Assistant',
                  Icons.auto_awesome_outlined,
                ),
              ])
                ActionChip(
                  avatar: Icon(action.$4, size: 18),
                  label: Text(tr(c, action.$2, action.$3)),
                  onPressed: () => c.push(action.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(c).colorScheme.surface.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Theme.of(c).textTheme.titleLarge),
        const SizedBox(width: 10),
        Flexible(child: Text(label)),
      ],
    ),
  );
}
