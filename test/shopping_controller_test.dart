import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/shopping/presentation/shopping_controller.dart';

void main() {
  test('creates a shopping list and toggles an item', () {
    final controller = ShoppingNotifier(persistenceEnabled: false);
    controller.addList('Home', ['Milk', 'Bread']);
    expect(controller.state.single.items.length, 2);
    final item = controller.state.single.items.first;
    controller.toggleItem(controller.state.single.id, item.id);
    expect(controller.state.single.items.first.checked, isTrue);
  });
}
