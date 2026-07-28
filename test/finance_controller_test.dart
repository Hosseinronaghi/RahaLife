import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';
import 'package:raha_life/features/finance/presentation/finance_controller.dart';

void main() {
  test('calculates balance from accounts and transactions', () {
    final notifier = FinanceNotifier(persistenceEnabled: false);

    notifier.addAccount('Main', openingBalance: 1000);
    final accountId = notifier.state.accounts.single.id;
    notifier.addTransaction(
      type: FinanceTransactionType.income,
      amount: 500,
      dateTime: DateTime(2026, 7, 28),
      accountId: accountId,
    );
    notifier.addTransaction(
      type: FinanceTransactionType.expense,
      amount: 200,
      dateTime: DateTime(2026, 7, 28),
      accountId: accountId,
    );

    expect(notifier.state.income, 500);
    expect(notifier.state.expense, 200);
    expect(notifier.state.balance, 1300);
  });
}
