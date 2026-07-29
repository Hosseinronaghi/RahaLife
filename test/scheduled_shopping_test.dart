import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';
import 'package:raha_life/features/shopping/presentation/shopping_controller.dart';

void main() {
  test('stores purchase time, location, reminder, and linked affair', () {
    final controller = ShoppingNotifier(persistenceEnabled: false);
    final scheduledAt = DateTime(2026, 7, 29, 18);
    final list = controller.addList(
      'Tomorrow shopping',
      ['Milk', 'Bread'],
      scheduledAt: scheduledAt,
      location: 'Local market',
      reminder: const ReminderPlan(
        enabled: true,
        minutesBefore: 30,
      ),
    );
    controller.linkAffair(list.id, 'affair-1');

    final stored = controller.state.single;
    expect(stored.scheduledAt, scheduledAt);
    expect(stored.location, 'Local market');
    expect(stored.reminder.enabled, isTrue);
    expect(stored.linkedAffairId, 'affair-1');
  });
}
