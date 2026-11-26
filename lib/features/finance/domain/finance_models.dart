// Public parameter names remain stable for callers and stored-model compatibility.
// ignore_for_file: prefer_initializing_formals
import 'dart:collection';
import '../../../core/domain/money.dart';

import '../../../core/notifications/reminder_models.dart';

enum FinanceTransactionType {
  income,
  expense,
  transfer,
  debt,
  receivable,
  saving,
  bill,
}

const defaultExpenseCategories = <String>[
  'bills',
  'rentHousing',
  'groceries',
  'restaurantCafe',
  'transportation',
  'fuel',
  'healthcare',
  'medicine',
  'dailyShopping',
  'education',
  'entertainment',
  'travel',
  'clothing',
  'internetPhone',
  'insurance',
  'tax',
  'loanInstallment',
  'subscriptions',
  'repairs',
  'gift',
  'family',
  'pets',
  'charity',
  'other',
];

const defaultBillTypes = <String>[
  'electricity',
  'water',
  'gas',
  'telephone',
  'internet',
  'buildingCharge',
  'insurance',
  'tax',
  'loanInstallment',
  'other',
];

class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.name,
    double openingBalance = 0,
    int? openingBalanceMinor,
    this.currencyCode = 'IRT',
    this.kind = 'cash',
    this.bankName,
    this.accountNumber,
    this.archived = false,
  }) : _legacyOpeningBalance = openingBalance,
       _openingBalanceMinor = openingBalanceMinor;

  factory FinanceAccount.fromJson(Map<String, Object?> json) => FinanceAccount(
    id: json['id']! as String,
    name: json['name']! as String,
    openingBalanceMinor: Money.readMinor(
      json['openingBalanceMinor'],
      json['openingBalance'],
    ),
    currencyCode: json['currencyCode']?.toString() ?? 'IRT',
    kind: json['kind']?.toString() ?? 'cash',
    bankName: json['bankName']?.toString(),
    accountNumber: json['accountNumber']?.toString(),
    archived: json['archived'] == true,
  );

  final String id;
  final String name;
  final double _legacyOpeningBalance;
  final int? _openingBalanceMinor;
  double get openingBalance => openingBalanceMinor / 100;
  final String currencyCode, kind;
  final String? bankName, accountNumber;
  final bool archived;
  int get openingBalanceMinor =>
      _openingBalanceMinor ??
      Money.parse(_legacyOpeningBalance.toString()).minorUnits;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'openingBalance': openingBalance,
    'openingBalanceMinor': openingBalanceMinor,
    'currencyCode': currencyCode,
    'kind': kind,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'archived': archived,
  };
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    double amount = 0,
    int? amountMinor,
    required this.dateTime,
    required this.accountId,
    this.toAccountId,
    this.category,
    this.note,
    this.dueDate,
    this.billType,
    this.billIdentifier,
    this.paymentIdentifier,
    this.paid = false,
    this.reminder = const ReminderPlan(),
    this.projectId,
  }) : _legacyAmount = amount,
       _amountMinor = amountMinor;

  factory FinanceTransaction.fromJson(Map<String, Object?> json) =>
      FinanceTransaction(
        id: json['id']! as String,
        type: FinanceTransactionType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => FinanceTransactionType.expense,
        ),
        amountMinor: Money.readMinor(json['amountMinor'], json['amount']),
        dateTime: DateTime.parse(json['dateTime']! as String),
        accountId: json['accountId']! as String,
        toAccountId: json['toAccountId']?.toString(),
        category: json['category'] as String?,
        note: json['note'] as String?,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate']! as String),
        billType: json['billType'] as String?,
        billIdentifier: json['billIdentifier'] as String?,
        paymentIdentifier: json['paymentIdentifier'] as String?,
        paid: json['paid'] as bool? ?? false,
        projectId: json['projectId'] as String?,
        reminder: ReminderPlan.fromJson(
          json['reminder'] is Map
              ? Map<String, Object?>.from(json['reminder']! as Map)
              : null,
        ),
      );

  final String id;
  final FinanceTransactionType type;
  final double _legacyAmount;
  final int? _amountMinor;
  double get amount => amountMinor / 100;
  final DateTime dateTime;
  final String accountId;
  final String? toAccountId;
  int get amountMinor =>
      _amountMinor ?? Money.parse(_legacyAmount.toString()).minorUnits;
  final String? category;
  final String? note;
  final DateTime? dueDate;
  final String? billType;
  final String? billIdentifier;
  final String? paymentIdentifier;
  final bool paid;
  final ReminderPlan reminder;
  final String? projectId;

  bool get isBill => type == FinanceTransactionType.bill;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'amountMinor': amountMinor,
    'dateTime': dateTime.toIso8601String(),
    'accountId': accountId,
    'toAccountId': toAccountId,
    'category': category,
    'note': note,
    'dueDate': dueDate?.toIso8601String(),
    'billType': billType,
    'billIdentifier': billIdentifier,
    'paymentIdentifier': paymentIdentifier,
    'paid': paid,
    'reminder': reminder.toJson(),
    'projectId': projectId,
  };

  FinanceTransaction copyWith({bool? paid, String? projectId}) =>
      FinanceTransaction(
        id: id,
        type: type,
        amountMinor: amountMinor,
        dateTime: dateTime,
        accountId: accountId,
        toAccountId: toAccountId,
        category: category,
        note: note,
        dueDate: dueDate,
        billType: billType,
        billIdentifier: billIdentifier,
        paymentIdentifier: paymentIdentifier,
        paid: paid ?? this.paid,
        reminder: reminder,
        projectId: projectId ?? this.projectId,
      );
}

class FinanceState {
  const FinanceState({required this.accounts, required this.transactions});
  const FinanceState.empty() : accounts = const [], transactions = const [];
  final List<FinanceAccount> accounts;
  final List<FinanceTransaction> transactions;
  BigInt _sum(bool Function(FinanceTransaction) include) => transactions
      .where(include)
      .fold(BigInt.zero, (sum, e) => sum + BigInt.from(e.amountMinor));

  BigInt get incomeMinor => _sum(
    (e) => e.type == FinanceTransactionType.income ||
        (e.type == FinanceTransactionType.receivable && e.paid),
  );

  BigInt get expenseMinor => _sum(
    (e) => e.type == FinanceTransactionType.expense ||
        ((e.type == FinanceTransactionType.bill ||
                e.type == FinanceTransactionType.debt) &&
            e.paid),
  );

  double get income => incomeMinor.toDouble() / 100;
  double get expense => expenseMinor.toDouble() / 100;
  Set<String> get currencies => accounts.map((e) => e.currencyCode).toSet();

  BigInt exactAccountBalanceMinor(String id) {
    final account = accounts.where((e) => e.id == id).firstOrNull;
    var balance = BigInt.from(account?.openingBalanceMinor ?? 0);
    for (final e in transactions) {
      final amount = BigInt.from(e.amountMinor);
      if ((e.type == FinanceTransactionType.transfer ||
              e.type == FinanceTransactionType.saving) &&
          e.toAccountId != null) {
        if (e.accountId == id) balance -= amount;
        if (e.toAccountId == id) balance += amount;
      } else if (e.accountId == id) {
        if (e.type == FinanceTransactionType.income ||
            (e.type == FinanceTransactionType.receivable && e.paid)) {
          balance += amount;
        }
        if (e.type == FinanceTransactionType.expense ||
            ((e.type == FinanceTransactionType.bill ||
                    e.type == FinanceTransactionType.debt) &&
                e.paid)) {
          balance -= amount;
        }
      }
    }
    return balance;
  }

  Map<String, BigInt> get exactBalanceByCurrency => {
    for (final currency in currencies)
      currency: accounts
          .where((a) => a.currencyCode == currency)
          .fold(BigInt.zero, (sum, a) => sum + exactAccountBalanceMinor(a.id)),
  };

  int _checkedMinor(BigInt value) {
    if (value.abs() > BigInt.from(Money.maxMinorUnits)) {
      throw StateError('Use the exact balance for totals above the safe integer range');
    }
    return value.toInt();
  }

  int accountBalanceMinor(String id) => _checkedMinor(exactAccountBalanceMinor(id));
  Map<String, int> get balanceByCurrency =>
      exactBalanceByCurrency.map((key, value) => MapEntry(key, _checkedMinor(value)));
  double get balance => currencies.length > 1
      ? throw StateError('Select a currency before requesting a total balance')
      : exactBalanceByCurrency.values
                .fold(BigInt.zero, (sum, value) => sum + value)
                .toDouble() / 100;
}
