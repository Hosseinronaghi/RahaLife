enum FinanceTransactionType { income, expense, transfer, debt, receivable, saving }

class FinanceAccount {
  const FinanceAccount({required this.id, required this.name, this.openingBalance = 0});
  factory FinanceAccount.fromJson(Map<String, Object?> json) => FinanceAccount(
        id: json['id']! as String,
        name: json['name']! as String,
        openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      );
  final String id;
  final String name;
  final double openingBalance;
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'openingBalance': openingBalance};
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
  });
  factory FinanceTransaction.fromJson(Map<String, Object?> json) => FinanceTransaction(
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
      );
  final String id;
  final FinanceTransactionType type;
  final double amount;
  final DateTime dateTime;
  final String accountId;
  final String? category;
  final String? note;
  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'accountId': accountId,
        'category': category,
        'note': note,
      };
}

class FinanceState {
  const FinanceState({required this.accounts, required this.transactions});
  const FinanceState.empty() : accounts = const [], transactions = const [];
  final List<FinanceAccount> accounts;
  final List<FinanceTransaction> transactions;

  double get income => transactions.where((item) => item.type == FinanceTransactionType.income || item.type == FinanceTransactionType.receivable).fold<double>(0, (sum, item) => sum + item.amount);
  double get expense => transactions.where((item) => item.type == FinanceTransactionType.expense || item.type == FinanceTransactionType.debt).fold<double>(0, (sum, item) => sum + item.amount);
  double get balance => accounts.fold<double>(0, (sum, item) => sum + item.openingBalance) + income - expense;
}
