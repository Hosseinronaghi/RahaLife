import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:raha_life/features/home/domain/home_entry.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';

void main() {
  test(
    'habit completion is specific to one day without requiring notifications',
    () {
      final habit = HomeEntry(
        id: 'h',
        type: HomeEntryType.habit,
        title: 'Read',
        dateTime: DateTime(2026, 9, 15),
        completedDates: ['2026-9-15'],
      );
      expect(habit.occursOn(DateTime(2026, 9, 16)), isTrue);
      expect(habit.completedOn(DateTime(2026, 9, 15)), isTrue);
      expect(habit.completedOn(DateTime(2026, 9, 16)), isFalse);
    },
  );
  test('weekly recurrence never creates events before its start', () {
    final entry = HomeEntry(
      id: 'w',
      type: HomeEntryType.affair,
      title: 'Weekly',
      dateTime: DateTime(2026, 9, 15),
      reminder: const ReminderPlan(repeat: ReminderRepeat.weekly),
    );
    expect(entry.occursOn(DateTime(2026, 9, 8)), isFalse);
    expect(entry.occursOn(DateTime(2026, 9, 22)), isTrue);
  });
  test('Solar Hijri birthdays follow the selected calendar across years', () {
    final entry = HomeEntry(
      id: 'b',
      type: HomeEntryType.birthday,
      title: 'Birthday',
      dateTime: Jalali(1403, 1, 1).toDateTime(),
      calendar: 'jalali',
    );
    expect(entry.occursOn(Jalali(1404, 1, 1).toDateTime()), isTrue);
    expect(entry.occursOn(Jalali(1404, 1, 2).toDateTime()), isFalse);
  });
  test('monthly day 31 does not overflow into a different month', () {
    final entry = HomeEntry(
      id: 'm',
      type: HomeEntryType.affair,
      title: 'Monthly',
      dateTime: DateTime(2026, 1, 31),
      reminder: const ReminderPlan(repeat: ReminderRepeat.monthly),
    );
    expect(entry.occursOn(DateTime(2026, 3, 3)), isFalse);
    expect(entry.occursOn(DateTime(2026, 3, 31)), isTrue);
  });
}
