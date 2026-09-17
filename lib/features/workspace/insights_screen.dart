import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/locale_formatters.dart';
import '../../core/persistence/drift_entity_repository.dart';
import '../finance/presentation/finance_controller.dart';
import '../finance/domain/finance_models.dart';
import '../home/presentation/home_controller.dart';
import 'record_editor.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsState();
}

class _InsightsState extends ConsumerState<InsightsScreen> {
  int days = 30;
  String? account;
  @override
  Widget build(BuildContext c) {
    final finance = ref.watch(financeProvider);
    final start = DateTime.now().subtract(Duration(days: days));
    final rows = finance.transactions
        .where(
          (e) =>
              e.dateTime.isAfter(start) &&
              !e.dateTime.isAfter(DateTime.now()) &&
              (account == null || e.accountId == account),
        )
        .toList();
    final grouped = <String, int>{};
    for (final e in rows) {
      if (e.type == FinanceTransactionType.expense ||
          (e.type == FinanceTransactionType.bill && e.paid)) {
        grouped[e.category ?? 'other'] =
            (grouped[e.category ?? 'other'] ?? 0) + e.amountMinor;
      }
    }
    final max = grouped.values.fold<int>(1, (a, b) => a > b ? a : b);
    final habits = ref
        .watch(homeEntriesProvider)
        .where((e) => e.type.name == 'habit')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(c, 'گزارش و بودجه', 'Reports & budgets')),
        actions: [
          IconButton(
            tooltip: tr(c, 'اقساط', 'Installments'),
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => c.push('/installments'),
          ),
          IconButton(
            tooltip: tr(c, 'خروجی CSV', 'Export CSV'),
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              String cell(Object? v) {
                var s = v?.toString() ?? '';
                if (RegExp(r'^[=+@-]').hasMatch(s)) s = "'$s";
                return '"${s.replaceAll('"', '""')}"';
              }

              final csv =
                  '\ufeffdate,type,account,currency,amount,category,note\n${rows.map((e) => [e.dateTime.toIso8601String(), e.type.name, e.accountId, e.amount, e.category, e.note].map(cell).join(',')).join('\n')}';
              await FilePicker.saveFile(
                fileName: 'Raha-Report.csv',
                bytes: Uint8List.fromList(utf8.encode(csv)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 10,
            children: [
              for (final n in [7, 30, 90, 365])
                ChoiceChip(
                  label: Text(
                    '${localizedNumber(n, Localizations.localeOf(c))} ${tr(c, 'روز', 'days')}',
                  ),
                  selected: days == n,
                  onSelected: (_) => setState(() => days = n),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: account,
            decoration: InputDecoration(labelText: tr(c, 'حساب', 'Account')),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(tr(c, 'همهٔ حساب‌ها', 'All accounts')),
              ),
              for (final a in finance.accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} · ${a.currencyCode}'),
                ),
            ],
            onChanged: (v) => setState(() => account = v),
          ),
          const SizedBox(height: 24),
          if (account == null && finance.currencies.length > 1)
            Text(
              tr(
                c,
                'برای مقایسهٔ مبلغ‌ها یک حساب انتخاب کن؛ ارزهای متفاوت جمع نمی‌شوند.',
                'Choose an account to compare amounts; different currencies are not combined.',
              ),
            )
          else ...[
            Text(
              tr(c, 'هزینه بر پایهٔ دسته', 'Expenses by category'),
              style: Theme.of(c).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final e in grouped.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${e.key} · ${localizedNumber(e.value / 100, Localizations.localeOf(c))}',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: e.value / max,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 24),
          Text(
            tr(c, 'روزهای ثبت‌شدهٔ عادت‌ها', 'Habit check-ins'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          for (final habit in habits)
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: Text(habit.title),
              trailing: Text(
                localizedNumber(
                  habit.completedDates.length,
                  Localizations.localeOf(c),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            tr(c, 'بودجه و هدف', 'Budget & goals'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add_chart),
            label: Text(
              tr(
                c,
                'ثبت بودجه یا هدف پس‌انداز',
                'Add a budget or savings goal',
              ),
            ),
            onPressed: () async {
              await editRecord(c, ref, 'budget', {
                'id': const Uuid().v4(),
                'title': '',
                'amount': 0.0,
                'category': '',
                'currencyCode': 'IRT',
                'savingGoal': false,
                'savedAmount': 0.0,
                'startDate': DateTime.now().toIso8601String(),
                'dueDate': DateTime.now()
                    .add(const Duration(days: 30))
                    .toIso8601String(),
              });
              if (mounted) setState(() {});
            },
          ),
          FutureBuilder(
            future: DriftEntityRepository().loadAll('budget'),
            builder: (c, s) {
              return Column(
                children: [
                  for (final data in s.data ?? <Map<String, Object?>>[])
                    Builder(
                      builder: (c) {
                        final goal = data['savingGoal'] == true;
                        final limit = (data['amount'] as num?)?.toDouble() ?? 0;
                        final from =
                            DateTime.tryParse(
                              data['startDate']?.toString() ?? '',
                            ) ??
                            DateTime(2000);
                        final until =
                            DateTime.tryParse(
                              data['dueDate']?.toString() ?? '',
                            ) ??
                            DateTime(2200);
                        final currency =
                            data['currencyCode']?.toString() ?? 'IRT';
                        final category = data['category']?.toString() ?? '';
                        final spent =
                            finance.transactions
                                .where(
                                  (e) =>
                                      !e.dateTime.isBefore(from) &&
                                      !e.dateTime.isAfter(until) &&
                                      !e.dateTime.isAfter(DateTime.now()) &&
                                      (category.isEmpty ||
                                          e.category == category) &&
                                      finance.accounts.any(
                                        (a) =>
                                            a.id == e.accountId &&
                                            a.currencyCode == currency,
                                      ) &&
                                      (e.type ==
                                              FinanceTransactionType.expense ||
                                          ((e.type ==
                                                      FinanceTransactionType
                                                          .bill ||
                                                  e.type ==
                                                      FinanceTransactionType
                                                          .debt) &&
                                              e.paid)),
                                )
                                .fold<int>(0, (sum, e) => sum + e.amountMinor) /
                            100;
                        final current = goal
                            ? (data['savedAmount'] as num?)?.toDouble() ?? 0
                            : spent;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(data['title'].toString()),
                                  subtitle: Text(
                                    '${localizedNumber(current, Localizations.localeOf(c))} / ${localizedNumber(limit, Localizations.localeOf(c))} $currency',
                                  ),
                                  trailing: const Icon(Icons.edit_outlined),
                                  onTap: () async {
                                    await recordActions(c, ref, 'budget', data);
                                    if (mounted) setState(() {});
                                  },
                                ),
                                LinearProgressIndicator(
                                  value: limit <= 0
                                      ? 0
                                      : (current / limit)
                                            .clamp(0, 1)
                                            .toDouble(),
                                  color: !goal && current > limit
                                      ? Theme.of(c).colorScheme.error
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  goal
                                      ? tr(
                                          c,
                                          'پس‌انداز ثبت‌شده به‌صورت دستی',
                                          'Manually recorded savings',
                                        )
                                      : tr(
                                              c,
                                              'ماندهٔ بودجه: ',
                                              'Remaining budget: ',
                                            ) +
                                            localizedNumber(
                                              limit - current,
                                              Localizations.localeOf(c),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
