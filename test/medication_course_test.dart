import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/medication/domain/medication_plan.dart';

void main() {
  test('fixed-day medication course calculates an end date', () {
    final plan = MedicationPlan(
      id: 'm1',
      name: 'Example',
      form: MedicationForm.tablet,
      dosage: '1',
      time: '09:00',
      courseType: MedicationCourseType.fixedDays,
      startDate: DateTime(2026, 8, 1),
      courseDays: 10,
    );
    expect(plan.calculatedEndDate, DateTime(2026, 8, 11));
  });
}
