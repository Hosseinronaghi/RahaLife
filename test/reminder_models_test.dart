import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';
import 'package:raha_life/core/notifications/reminder_service.dart';

void main() {
  test('serializes an alarm reminder with recurrence', () {
    const reminder = ReminderPlan(
      enabled: true,
      kind: ReminderKind.alarm,
      minutesBefore: 30,
      repeat: ReminderRepeat.weekly,
    );

    final restored = ReminderPlan.fromJson(reminder.toJson());
    expect(restored.enabled, isTrue);
    expect(restored.kind, ReminderKind.alarm);
    expect(restored.minutesBefore, 30);
    expect(restored.repeat, ReminderRepeat.weekly);
  });

  test('creates stable positive notification ids', () {
    final first = ReminderService.instance.notificationId('shopping:list-1');
    final second = ReminderService.instance.notificationId('shopping:list-1');
    final different = ReminderService.instance.notificationId('bill:item-1');

    expect(first, second);
    expect(first, isNonNegative);
    expect(first, isNot(different));
  });
}
