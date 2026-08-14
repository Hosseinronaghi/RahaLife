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
  });

  factory FinanceAccount.fromJson(Map<String, Object?> json) => FinanceAccount(
        id: json['id']! as String,
        name: json['name']! as String,
        openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      );

  final String id;
  final String name;
  final double openingBalance;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'openingBalance': openingBalance,
      };
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    required this.accountId,
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
        amount: (json['amount'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime']! as String),
        accountId: json['accountId']! as String,
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
        'dateTime': dateTime.toIso8601String(),
        'accountId': accountId,
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

  FinanceTransaction copyWith({bool? paid, String? projectId}) => FinanceTransaction(
        id: id,
        type: type,
        amount: amount,
        dateTime: dateTime,
        accountId: accountId,
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

  double get income => transactions
      .where(
        (item) =>
            item.type == FinanceTransactionType.income ||
            item.type == FinanceTransactionType.receivable,
      )
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get expense => transactions
      .where(
        (item) =>
            item.type == FinanceTransactionType.expense ||
            item.type == FinanceTransactionType.debt ||
            (item.type == FinanceTransactionType.bill && item.paid),
      )
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get balance =>
      accounts.fold<double>(0, (sum, item) => sum + item.openingBalance) +
      income -
      expense;
}
