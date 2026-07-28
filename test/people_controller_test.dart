import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/people/presentation/people_controller.dart';

void main() {
  test('adds and removes a person', () {
    final controller = PeopleNotifier(persistenceEnabled: false);
    controller.add(name: 'Sara', relationship: 'Friend');
    expect(controller.state.single.name, 'Sara');
    controller.delete(controller.state.single.id);
    expect(controller.state, isEmpty);
  });
}
