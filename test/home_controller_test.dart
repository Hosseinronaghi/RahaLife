import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/home/domain/home_entry.dart';
import 'package:raha_life/features/home/presentation/home_controller.dart';

void main() {
  test('adds, toggles, searches, and deletes an entry', () {
    final controller = HomeEntriesNotifier(persistenceEnabled: false);
    final date = DateTime(2026, 7, 26, 10);

    controller.add(
      type: HomeEntryType.affair,
      title: 'Call the doctor',
      dateTime: date,
      details: 'Confirm the appointment',
    );

    expect(controller.state, hasLength(1));
    expect(controller.forDate(date), hasLength(1));
    expect(controller.search('doctor'), hasLength(1));

    final id = controller.state.single.id;
    controller.toggle(id);
    expect(controller.state.single.completed, isTrue);

    controller.delete(id);
    expect(controller.state, isEmpty);
  });

  test('birthday repeats by month and day', () {
    final entry = HomeEntry(
      id: 'birthday',
      type: HomeEntryType.birthday,
      title: 'Birthday',
      dateTime: DateTime(1990, 5, 10),
    );

    expect(entry.occursOn(DateTime(2026, 5, 10)), isTrue);
    expect(entry.occursOn(DateTime(2026, 5, 11)), isFalse);
  });
}
