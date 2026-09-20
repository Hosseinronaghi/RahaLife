import 'home_entry.dart';

/// Calendar-day arithmetic avoids DST truncating a day into 23 hours.
int? birthdayDaysAway(HomeEntry entry, DateTime now) {
  for (var offset = 0; offset <= 1831; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    if (entry.occursOn(day)) return offset;
  }
  return null;
}

int birthdayGroup(HomeEntry e, DateTime now) {
  final days = birthdayDaysAway(e, now);
  if (days == 0) return 0;
  if (days == 1) return 1;
  if (days != null && days <= 7) return 2;
  if (e.occursOn(DateTime(now.year, now.month, now.day - 1))) return 3;
  return 4;
}
