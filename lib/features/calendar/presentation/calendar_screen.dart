import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/entry_details_sheet.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/presentation/home_entry_ui.dart';
import '../../home/presentation/quick_add_sheet.dart';

enum _CalendarView { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _anchor = DateTime.now();
  DateTime _selected = DateTime.now();
  _CalendarView _view = _CalendarView.month;

  bool get _isPersian => Localizations.localeOf(context).languageCode == 'fa';

  void _move(int direction) {
    setState(() {
      switch (_view) {
        case _CalendarView.month:
          if (_isPersian) {
            final current = Jalali.fromDateTime(_anchor).withDay(1);
            _anchor = current.addMonths(direction).toDateTime();
          } else {
            _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
          }
          break;
        case _CalendarView.week:
          _anchor = _anchor.add(Duration(days: 7 * direction));
          break;
        case _CalendarView.day:
          _anchor = _anchor.add(Duration(days: direction));
          break;
      }
      _selected = _anchor;
    });
  }

  String _headerLabel(Locale locale) {
    if (_view == _CalendarView.day) return primaryDateLabel(_anchor, locale);
    if (_view == _CalendarView.week) {
      final start = _startOfWeek(_anchor);
      final end = start.add(const Duration(days: 6));
      return '${compactDualDate(start, locale)} — ${compactDualDate(end, locale)}';
    }
    if (_isPersian) {
      final value = Jalali.fromDateTime(_anchor).withDay(1).formatter;
      return localizeDigits('${value.mN} ${value.yyyy}', locale);
    }
    return DateFormat('MMMM y', 'en').format(_anchor);
  }

  DateTime _startOfWeek(DateTime date) {
    if (_isPersian) {
      final weekDay = Jalali.fromDateTime(date).weekDay;
      return DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: weekDay - 1));
    }
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final entries = ref.watch(homeEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendar)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_CalendarView>(
              showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _CalendarView.month,
                label: Text(l10n.calendarMonth),
                icon: const Icon(Icons.calendar_view_month_rounded),
              ),
              ButtonSegment(
                value: _CalendarView.week,
                label: Text(l10n.calendarWeek),
                icon: const Icon(Icons.view_week_rounded),
              ),
              ButtonSegment(
                value: _CalendarView.day,
                label: Text(l10n.calendarDay),
                icon: const Icon(Icons.view_day_rounded),
              ),
            ],
            selected: {_view},
              onSelectionChanged: (values) {
                setState(() => _view = values.first);
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: l10n.previousMonth,
                        onPressed: () => _move(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _headerLabel(locale),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_view == _CalendarView.month) ...[
                              const SizedBox(height: 3),
                              Text(
                                _isPersian
                                    ? localizeDigits(
                                        DateFormat('yyyy/MM', 'en').format(_anchor),
                                        locale,
                                      )
                                    : secondaryDateLabel(_anchor, locale),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: l10n.nextMonth,
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  switch (_view) {
                    _CalendarView.month => _MonthGrid(
                        anchor: _anchor,
                        selected: _selected,
                        isPersian: _isPersian,
                        entries: entries,
                        onSelected: (date) => setState(() => _selected = date),
                      ),
                    _CalendarView.week => _WeekStrip(
                        start: _startOfWeek(_anchor),
                        selected: _selected,
                        entries: entries,
                        onSelected: (date) => setState(() => _selected = date),
                      ),
                    _CalendarView.day => _DayHero(date: _anchor),
                  },
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SelectedDayAgenda(
            date: _view == _CalendarView.day ? _anchor : _selected,
            entries: entries,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showQuickAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.anchor,
    required this.selected,
    required this.isPersian,
    required this.entries,
    required this.onSelected,
  });

  final DateTime anchor;
  final DateTime selected;
  final bool isPersian;
  final List<HomeEntry> entries;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    late final int offset;
    late final int days;
    late final DateTime Function(int day) dateForDay;
    if (isPersian) {
      final first = Jalali.fromDateTime(anchor).withDay(1);
      offset = first.weekDay - 1;
      days = first.monthLength;
      dateForDay = (day) => Jalali(first.year, first.month, day).toDateTime();
    } else {
      final first = DateTime(anchor.year, anchor.month, 1);
      offset = first.weekday - 1;
      days = DateUtils.getDaysInMonth(anchor.year, anchor.month);
      dateForDay = (day) => DateTime(anchor.year, anchor.month, day);
    }
    final labels = isPersian
        ? const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
        : List.generate(
            7,
            (index) => DateFormat('E', 'en')
                .format(DateTime(2024, 1, 1 + index))
                .substring(0, 1),
          );
    final cellCount = ((offset + days + 6) ~/ 7) * 7;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Row(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.12,
              ),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > days) return const SizedBox.shrink();
            final date = dateForDay(day);
            final selectedDay = DateUtils.isSameDay(date, selected);
            final today = DateUtils.isSameDay(date, DateTime.now());
            final count = entries.where((item) => item.occursOn(date)).length;
            return InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => onSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: selectedDay
                      ? Theme.of(context).colorScheme.primary
                      : today
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      localizeDigits(day, locale),
                      style: TextStyle(
                        fontWeight: selectedDay || today
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: selectedDay
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        bottom: 5,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: selectedDay
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.entries,
    required this.onSelected,
  });

  final DateTime start;
  final DateTime selected;
  final List<HomeEntry> entries;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selected);
          final count = entries.where((item) => item.occursOn(date)).length;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    primaryDateLabel(date, locale).split(' ').first,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizeDigits(date.day, locale),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                  ),
                  if (count > 0)
                    Text(
                      localizeDigits(count, locale),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayHero extends StatelessWidget {
  const _DayHero({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            primaryDateLabel(date, locale),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Text(secondaryDateLabel(date, locale)),
        ],
      ),
    );
  }
}

class _SelectedDayAgenda extends StatelessWidget {
  const _SelectedDayAgenda({required this.date, required this.entries});

  final DateTime date;
  final List<HomeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final items = entries.where((item) => item.occursOn(date)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              primaryDateLabel(date, locale),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  l10n.noItemsToday,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    homeEntryTypeIcon(items[index].type),
                    color: homeEntryTypeColor(
                      items[index].type,
                      Theme.of(context).colorScheme,
                    ),
                  ),
                  title: Text(items[index].title),
                  subtitle: Text(
                    '${localizedTime(items[index].dateTime, locale)} · ${homeEntryTypeLabel(l10n, items[index].type)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showEntryDetails(context, items[index]),
                ),
                if (index < items.length - 1) const Divider(),
              ],
          ],
        ),
      ),
    );
  }
}
