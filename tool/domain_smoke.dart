// A smoke test against the production domain models.
// Run with: dart --enable-asserts tool/domain_smoke.dart
import 'dart:io';
import 'package:raha_life/core/sync/causal_clock.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';
import 'package:raha_life/features/medication/domain/medication_plan.dart';

void check(bool condition, String label) {
  if (!condition) throw StateError(label);
  stdout.writeln('PASS $label');
}

void main() {
  check(
    compareClocks({'A': 9}, {'A': 1, 'B': 1}) == ClockOrder.concurrent,
    'unequal counts preserve independent changes',
  );
  check(
    compareClocks({'A': 1}, {'A': 1, 'B': 1}) == ClockOrder.before,
    'causal descendant',
  );
  check(
    compareClocks({'A': 2, 'B': 3}, {'B': 3, 'A': 2}) == ClockOrder.equal,
    'clock key order',
  );
  final now = DateTime(2026, 9, 15);
  final medicine = MedicationPlan(
    id: 'm',
    name: 'Recorded medication',
    form: MedicationForm.tablet,
    dosage: 'as recorded',
    time: '09:00',
    startDate: DateTime(2026, 9, 20),
    courseType: MedicationCourseType.fixedDays,
    courseDays: 3,
  );
  check(
    medicine.nextDoseDateTime(now) == DateTime(2026, 9, 20, 9),
    'no medication dose before start',
  );
  check(
    medicine.calculatedEndDate == DateTime(2026, 9, 22),
    'three-day inclusive course',
  );
  check(
    !medicine.isCourseFinished(DateTime(2026, 9, 22, 9)),
    'last course day retained',
  );
  check(
    medicine.isCourseFinished(DateTime(2026, 9, 23)),
    'course stops after final day',
  );
  const accounts = [
    FinanceAccount(id: 'a', name: 'A', openingBalance: 100),
    FinanceAccount(id: 'b', name: 'B'),
  ];
  final transfer = FinanceTransaction(
    id: 't',
    type: FinanceTransactionType.transfer,
    amount: 20,
    dateTime: now,
    accountId: 'a',
    toAccountId: 'b',
  );
  final finance = FinanceState(accounts: accounts, transactions: [transfer]);
  check(finance.accountBalanceMinor('a') == 8000, 'transfer debits source');
  check(
    finance.accountBalanceMinor('b') == 2000,
    'transfer credits destination',
  );
  check(
    finance.balance == 100 && finance.income == 0 && finance.expense == 0,
    'transfer preserves total and cash flow',
  );
  final expense = FinanceState(
    accounts: accounts,
    transactions: [
      for (var i = 0; i < 10; i++)
        FinanceTransaction(
          id: 'e$i',
          type: FinanceTransactionType.expense,
          amount: 0.1,
          dateTime: now,
          accountId: 'a',
        ),
    ],
  );
  check(expense.expense == 1, 'sum minor units without decimal accumulation');
  final debt = FinanceTransaction(
    id: 'd',
    type: FinanceTransactionType.debt,
    amount: 30,
    dateTime: now,
    accountId: 'a',
  );
  check(
    FinanceState(accounts: accounts, transactions: [debt]).balance == 100,
    'unsettled debt does not move cash',
  );
  check(
    FinanceState(
          accounts: accounts,
          transactions: [debt.copyWith(paid: true)],
        ).balance ==
        70,
    'settled debt moves cash',
  );
  check(
    FinanceTransaction.fromJson(transfer.toJson()).toAccountId == 'b',
    'transfer round trip',
  );
}
