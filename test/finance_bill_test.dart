import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';

void main() {
  test('unpaid bill is not counted as expense until marked paid', () {
    final dueDate = DateTime(2026, 8, 1, 9);
    final unpaid = FinanceTransaction(
      id: 'bill-1',
      type: FinanceTransactionType.bill,
      amount: 500,
      dateTime: DateTime(2026, 7, 28),
      accountId: 'cash',
      dueDate: dueDate,
      billType: 'electricity',
      reminder: const ReminderPlan(
        enabled: true,
        repeat: ReminderRepeat.monthly,
      ),
    );

    final unpaidState = FinanceState(
      accounts: const [FinanceAccount(id: 'cash', name: 'Cash')],
      transactions: [unpaid],
    );
    final paidState = FinanceState(
      accounts: unpaidState.accounts,
      transactions: [unpaid.copyWith(paid: true)],
    );

    expect(unpaidState.expense, 0);
    expect(paidState.expense, 500);
  });
}
