import 'dart:collection';

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
    this.openingBalance = 0,
    this.currencyCode = 'IRT',
    this.kind = 'cash',
    this.bankName,
    this.accountNumber,
    this.archived = false,
  });

  factory FinanceAccount.fromJson(Map<String, Object?> json) => FinanceAccount(
    id: json['id']! as String,
    name: json['name']! as String,
    openingBalance: (json['openingBalanceMinor'] as num?)?.toDouble() != null
        ? (json['openingBalanceMinor'] as num).toDouble() / 100
        : (json['openingBalance'] as num?)?.toDouble() ?? 0,
    currencyCode: json['currencyCode']?.toString() ?? 'IRT',
    kind: json['kind']?.toString() ?? 'cash',
    bankName: json['bankName']?.toString(),
    accountNumber: json['accountNumber']?.toString(),
    archived: json['archived'] == true,
  );

  final String id;
  final String name;
  final double openingBalance;
  final String currencyCode, kind;
  final String? bankName, accountNumber;
  final bool archived;
  int get openingBalanceMinor => (openingBalance * 100).round();

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
    required this.amount,
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
  });

  factory FinanceTransaction.fromJson(Map<String, Object?> json) =>
      FinanceTransaction(
        id: json['id']! as String,
        type: FinanceTransactionType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => FinanceTransactionType.expense,
        ),
        amount: json['amountMinor'] is num
            ? (json['amountMinor'] as num).toDouble() / 100
            : (json['amount'] as num).toDouble(),
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
  final double amount;
  final DateTime dateTime;
  final String accountId;
  final String? toAccountId;
  int get amountMinor => (amount * 100).round();
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
        amount: amount,
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
  int _sum(bool Function(FinanceTransaction) include) =>
      transactions.where(include).fold<int>(0, (sum, e) => sum + e.amountMinor);
  double get income =>
      _sum(
        (e) =>
            e.type == FinanceTransactionType.income ||
            (e.type == FinanceTransactionType.receivable && e.paid),
      ) /
      100;
  double get expense =>
      _sum(
        (e) =>
            e.type == FinanceTransactionType.expense ||
            ((e.type == FinanceTransactionType.bill ||
                    e.type == FinanceTransactionType.debt) &&
                e.paid),
      ) /
      100;
  Set<String> get currencies => accounts.map((e) => e.currencyCode).toSet();
  int accountBalanceMinor(String id) {
    final account = accounts.where((e) => e.id == id).firstOrNull;
    var balance = account?.openingBalanceMinor ?? 0;
    for (final e in transactions) {
      if ((e.type == FinanceTransactionType.transfer ||
              e.type == FinanceTransactionType.saving) &&
          e.toAccountId != null) {
        if (e.accountId == id) {
          balance -= e.amountMinor;
        }
        if (e.toAccountId == id) {
          balance += e.amountMinor;
        }
      } else if (e.accountId == id) {
        if (e.type == FinanceTransactionType.income ||
            (e.type == FinanceTransactionType.receivable && e.paid)) {
          balance += e.amountMinor;
        }
        if (e.type == FinanceTransactionType.expense ||
            ((e.type == FinanceTransactionType.bill ||
                    e.type == FinanceTransactionType.debt) &&
                e.paid)) {
          balance -= e.amountMinor;
        }
      }
    }
    return balance;
  }

  Map<String, int> get balanceByCurrency => {
    for (final currency in currencies)
      currency: accounts
          .where((a) => a.currencyCode == currency)
          .fold<int>(0, (sum, a) => sum + accountBalanceMinor(a.id)),
  };
  double get balance => currencies.length > 1
      ? 0
      : balanceByCurrency.values.fold<int>(0, (a, b) => a + b) / 100;
}
