import 'dart:collection';

import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/finance_models.dart';

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const FinanceState.empty()) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _accountEntityType = 'finance_account';
  static const _transactionEntityType = 'finance_transaction';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.finance.accounts.v1',
        entityType: _accountEntityType,
        preferenceKeys: const ['finance.accounts.v1'],
      );
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.finance.transactions.v2',
        entityType: _transactionEntityType,
        preferenceKeys: const [
          'finance.transactions.v2',
          'finance.transactions.v1',
        ],
      );
      var accounts = (await _repository.loadAll(
        _accountEntityType,
        includeArchived: true,
      )).map(FinanceAccount.fromJson).toList();
      if (accounts.isEmpty) {
        accounts = [const FinanceAccount(id: 'default-cash', name: 'Cash')];
        await _repository.replaceAll(
          _accountEntityType,
          accounts.map((a) => a.toJson()),
        );
      }
      final transactions =
          (await _repository.loadAll(
              _transactionEntityType,
            )).map(FinanceTransaction.fromJson).toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      state = FinanceState(accounts: accounts, transactions: transactions);
    } catch (error) {
      WriteStatus.report(error);
    }
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    await _ready;
    await _repository.db.transaction(() async {
      await _repository.replaceAll(
        _accountEntityType,
        state.accounts.map((item) => item.toJson()),
      );
      await _repository.replaceAll(
        _transactionEntityType,
        state.transactions.map((item) => item.toJson()),
      );
    });
  }

  void addAccount(
    String name, {
    double openingBalance = 0,
    String? id,
    String currencyCode = 'IRT',
    String kind = 'cash',
    String? bankName,
    String? accountNumber,
    bool archived = false,
  }) {
    if (name.trim().isEmpty || !openingBalance.isFinite) {
      throw ArgumentError('Invalid account');
    }
    final existing = state.accounts.where((a) => a.id == id).firstOrNull;
    if (existing != null &&
        existing.currencyCode != currencyCode &&
        state.transactions.any(
          (t) => t.accountId == id || t.toAccountId == id,
        )) {
      throw ArgumentError('Currency cannot change after transactions.');
    }
    state = FinanceState(
      accounts: [
        ...state.accounts.where((a) => a.id != id),
        FinanceAccount(
          id: id ?? _uuid.v4(),
          currencyCode: currencyCode,
          kind: kind,
          bankName: bankName,
          accountNumber: accountNumber,
          archived: archived,
          name: name.trim(),
          openingBalance: openingBalance,
        ),
      ],
      transactions: state.transactions,
    );
    WriteStatus.track(_persist());
  }

  FinanceTransaction addTransaction({
    String? id,
    required FinanceTransactionType type,
    required double amount,
    required DateTime dateTime,
    required String accountId,
    String? toAccountId,
    String? category,
    String? note,
    DateTime? dueDate,
    String? billType,
    String? billIdentifier,
    String? paymentIdentifier,
    bool paid = false,
    ReminderPlan reminder = const ReminderPlan(),
    String? projectId,
  }) {
    if (!amount.isFinite || amount <= 0 || amount > 90071992547409) {
      throw ArgumentError('Amount must be positive.');
    }
    final previous = state.transactions.where((t) => t.id == id).firstOrNull;
    final account = state.accounts.where((a) => a.id == accountId).firstOrNull;
    if (account == null ||
        (account.archived && previous?.accountId != accountId)) {
      throw ArgumentError('Select an active account.');
    }
    if (type == FinanceTransactionType.transfer ||
        type == FinanceTransactionType.saving) {
      final target = state.accounts
          .where((a) => a.id == toAccountId)
          .firstOrNull;
      if (target == null ||
          (target.archived && previous?.toAccountId != toAccountId) ||
          target.id == accountId ||
          target.currencyCode != account.currencyCode) {
        throw ArgumentError('Select a different account in the same currency.');
      }
    }
    final transaction = FinanceTransaction(
      id: id ?? _uuid.v4(),
      type: type,
      amount: amount,
      dateTime: dateTime,
      accountId: accountId,
      toAccountId: toAccountId,
      category: category?.trim(),
      note: note?.trim(),
      dueDate: dueDate,
      billType: billType,
      billIdentifier: billIdentifier?.trim(),
      paymentIdentifier: paymentIdentifier?.trim(),
      paid: paid,
      reminder: reminder,
      projectId: projectId,
    );
    state = FinanceState(
      accounts: state.accounts,
      transactions: [
        ...state.transactions.where((t) => t.id != transaction.id),
        transaction,
      ]..sort((a, b) => b.dateTime.compareTo(a.dateTime)),
    );
    WriteStatus.track(_persist());
    return transaction;
  }

  void toggleBillPaid(String id) {
    state = FinanceState(
      accounts: state.accounts,
      transactions: [
        for (final item in state.transactions)
          if (item.id == id) item.copyWith(paid: !item.paid) else item,
      ],
    );
    unawaited(ReminderService.instance.cancel('bill:$id'));
    WriteStatus.track(_persist());
  }

  void deleteTransaction(String id) {
    state = FinanceState(
      accounts: state.accounts,
      transactions: state.transactions.where((item) => item.id != id).toList(),
    );
    unawaited(ReminderService.instance.cancel('bill:$id'));
    WriteStatus.track(_persist());
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>(
  (ref) => FinanceNotifier(),
);
