import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/domain/money.dart';
import 'package:raha_life/core/localization/locale_formatters.dart';
import 'package:raha_life/core/notifications/agenda.dart';
import 'package:raha_life/core/notifications/reminder_coordinator.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';
import 'package:raha_life/core/sync/sync_scope.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';

void main() {
  test('money accepts valid grouping without guessing decimal commas', () {
    expect(Money.parse('۱۲٬۳۴۵٫۵۰').minorUnits, 1234550);
    expect(Money.parse('1,234,567.05').minorUnits, 123456705);
    expect(Money.parse('0.575').minorUnits, 58);
    for (final input in ['1,25', '12٬34', '1,234٬567', '1.2,50']) {
      expect(() => Money.parse(input), throwsFormatException);
    }
  });

  test('currency totals and their display remain exact above JS safe int', () {
    const ledger = FinanceState(
      accounts: [
        FinanceAccount(id: 'a', name: 'Cash', openingBalanceMinor: 9007199254740991),
        FinanceAccount(id: 'b', name: 'Bank', openingBalanceMinor: 2),
      ],
      transactions: [],
    );
    final total = ledger.exactBalanceByCurrency['IRT']!;
    expect(total.toString(), '9007199254740993');
    expect(localizedMoneyMinor(total, const Locale('en')), '90,071,992,547,409.93');
  });

  test('legacy and previously opted-in connections withhold sensitive modules', () {
    expect(syncTypes({}), contains('rich_note'));
    expect(syncTypes({}), isNot(contains('cycle_log')));
    const old = {'modules': 'notes,health,finance'};
    expect(syncTypes(old), {'rich_note'});
    expect(syncScopeIdentity(old), 'notes');
    expect(
      syncTypes({...old, sensitiveSyncConsentKey: 'true'}),
      containsAll(['cycle_log', 'medication_dose', 'finance_transaction']),
    );
  });

  test('public notification title never contains the medication name', () {
    final item = AgendaItem(
      'dose:test', 'Synthetic drug name', DateTime(2026, 11, 27),
      '/medication', const ReminderPlan(), type: 'medication',
    );
    expect(publicReminderTitle(item, fa: false), 'Raha reminder');
    expect(publicReminderTitle(item, fa: true), 'یادآوری رها');
  });
}
