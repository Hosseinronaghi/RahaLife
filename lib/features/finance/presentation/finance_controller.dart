import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/finance_models.dart';

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier({this.persistenceEnabled = true}) : super(const FinanceState.empty()) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _accountsKey = 'finance.accounts.v1';
  static const _transactionsKey = 'finance.transactions.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final accountsRaw = prefs.getString(_accountsKey);
      final transactionsRaw = prefs.getString(_transactionsKey);
      var accounts = accountsRaw == null
          ? <FinanceAccount>[]
          : (jsonDecode(accountsRaw) as List<dynamic>).map((item) => FinanceAccount.fromJson(Map<String, Object?>.from(item as Map))).toList();
      if (accounts.isEmpty) accounts = [FinanceAccount(id: _uuid.v4(), name: 'Cash')];
      final transactions = transactionsRaw == null
          ? <FinanceTransaction>[]
          : (jsonDecode(transactionsRaw) as List<dynamic>).map((item) => FinanceTransaction.fromJson(Map<String, Object?>.from(item as Map))).toList();
      state = FinanceState(accounts: accounts, transactions: transactions..sort((a, b) => b.dateTime.compareTo(a.dateTime)));
      await _persist();
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(state.accounts.map((item) => item.toJson()).toList()));
    await prefs.setString(_transactionsKey, jsonEncode(state.transactions.map((item) => item.toJson()).toList()));
  }

  void addAccount(String name, {double openingBalance = 0}) {
    state = FinanceState(accounts: [...state.accounts, FinanceAccount(id: _uuid.v4(), name: name.trim(), openingBalance: openingBalance)], transactions: state.transactions);
    unawaited(_persist());
  }

  void addTransaction({required FinanceTransactionType type, required double amount, required DateTime dateTime, required String accountId, String? category, String? note}) {
    final transaction = FinanceTransaction(id: _uuid.v4(), type: type, amount: amount, dateTime: dateTime, accountId: accountId, category: category?.trim(), note: note?.trim());
    state = FinanceState(accounts: state.accounts, transactions: [...state.transactions, transaction]..sort((a, b) => b.dateTime.compareTo(a.dateTime)));
    unawaited(_persist());
  }

  void deleteTransaction(String id) {
    state = FinanceState(accounts: state.accounts, transactions: state.transactions.where((item) => item.id != id).toList());
    unawaited(_persist());
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) => FinanceNotifier());
