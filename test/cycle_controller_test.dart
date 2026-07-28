import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/cycle/domain/cycle_log.dart';
import 'package:raha_life/features/cycle/presentation/cycle_controller.dart';

void main() {
  test('estimates next cycle from recorded intervals', () {
    final controller = CycleNotifier(persistenceEnabled: false);
    controller.add(startDate: DateTime(2026, 1, 1), flow: FlowIntensity.medium, painLevel: 2, mood: CycleMood.calm);
    controller.add(startDate: DateTime(2026, 1, 29), flow: FlowIntensity.medium, painLevel: 2, mood: CycleMood.calm);
    expect(controller.predictedNextStart, DateTime(2026, 2, 26));
  });
}
