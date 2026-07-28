import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/medication/domain/medication_plan.dart';
import 'package:raha_life/features/medication/presentation/medication_controller.dart';

void main() {
  test('adds and toggles a medication plan', () {
    final notifier = MedicationNotifier(persistenceEnabled: false);

    notifier.add(
      name: 'Vitamin D',
      form: MedicationForm.tablet,
      dosage: '1 tablet',
      time: '09:00',
      stock: 20,
    );

    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.active, isTrue);

    notifier.toggleActive(notifier.state.single.id);
    expect(notifier.state.single.active, isFalse);
  });
}
