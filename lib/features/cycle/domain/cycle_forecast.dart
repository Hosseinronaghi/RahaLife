import 'cycle_log.dart';

/// Calendar-day arithmetic avoids DST changing interval counts.
int calendarDays(DateTime a, DateTime b) => DateTime.utc(
  a.year,
  a.month,
  a.day,
).difference(DateTime.utc(b.year, b.month, b.day)).inDays;

class CycleForecast {
  const CycleForecast(
    this.start,
    this.durationDays,
    this.intervalDays,
    this.samples,
    this.variationDays,
  );
  final DateTime start;
  final int durationDays, intervalDays, samples, variationDays;
  DateTime get end =>
      DateTime(start.year, start.month, start.day + durationDays - 1);
  bool overlaps(DateTime at) =>
      calendarDays(at, start) >= 0 && calendarDays(at, end) <= 0;
  static CycleForecast? fromLogs(Iterable<CycleLog> logs) {
    final sorted = logs.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (sorted.isEmpty) return null;
    final intervals = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final days = calendarDays(sorted[i].startDate, sorted[i - 1].startDate);
      if (days > 0) intervals.add(days);
    }
    final recent = intervals.reversed.take(6).toList()..sort();
    final interval = recent.isEmpty ? 28 : recent[recent.length ~/ 2];
    final durations =
        sorted
            .where((e) => e.endDate != null)
            .map((e) => calendarDays(e.endDate!, e.startDate) + 1)
            .where((d) => d > 0)
            .toList()
          ..sort();
    final duration = durations.isEmpty ? 5 : durations[durations.length ~/ 2];
    final last = sorted.last.startDate;
    return CycleForecast(
      DateTime(last.year, last.month, last.day + interval),
      duration,
      interval,
      recent.length,
      recent.isEmpty ? 0 : recent.last - recent.first,
    );
  }
}
