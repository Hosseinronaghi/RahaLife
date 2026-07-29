import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/finance_models.dart';
import 'finance_controller.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  FinanceTransactionType? filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(financeProvider);
    final transactions = filter == null
        ? state.transactions
        : state.transactions.where((item) => item.type == filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(
            onPressed: () => _showAccountForm(context, ref),
            tooltip: l10n.addAccount,
            icon: const Icon(Icons.account_balance_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _Summary(state: state),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: filter == null,
                  onSelected: (_) => setState(() => filter = null),
                ),
                const SizedBox(width: 8),
                for (final type in FinanceTransactionType.values) ...[
                  ChoiceChip(
                    label: Text(_typeLabel(l10n, type)),
                    selected: filter == type,
                    onSelected: (_) => setState(() => filter = type),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text(l10n.noTransactions)),
            )
          else
            ...transactions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_typeIcon(item.type))),
                    title: Text(
                      item.isBill && item.billType != null
                          ? _billTypeLabel(l10n, item.billType!)
                          : _typeLabel(l10n, item.type),
                    ),
                    subtitle: Text(
                      [
                        if (item.category?.isNotEmpty ?? false)
                          _categoryLabel(l10n, item.category!),
                        compactDualDate(
                          item.dueDate ?? item.dateTime,
                          Localizations.localeOf(context),
                        ),
                        if (item.isBill)
                          item.paid ? l10n.paid : l10n.unpaid,
                      ].join(' • '),
                    ),
                    trailing: SizedBox(
                      width: item.isBill ? 148 : 112,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.isBill)
                            IconButton(
                              tooltip: item.paid ? l10n.markUnpaid : l10n.markPaid,
                              onPressed: () => ref
                                  .read(financeProvider.notifier)
                                  .toggleBillPaid(item.id),
                              icon: Icon(
                                item.paid
                                    ? Icons.check_circle_rounded
                                    : Icons.payments_outlined,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              localizeDigits(
                                item.amount.toStringAsFixed(0),
                                Localizations.localeOf(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onLongPress: () => ref
                        .read(financeProvider.notifier)
                        .deleteTransaction(item.id),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showFinanceForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});
  final FinanceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final unpaidBills = state.transactions
        .where((item) => item.isBill && !item.paid)
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.financialSummary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Amount(
                  label: l10n.balance,
                  value: state.balance,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _Amount(
                  label: l10n.income,
                  value: state.income,
                  icon: Icons.trending_up_rounded,
                ),
                _Amount(
                  label: l10n.expense,
                  value: state.expense,
                  icon: Icons.trending_down_rounded,
                ),
              ].map((widget) => SizedBox(width: 180, child: widget)).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              '${l10n.accounts}: ${localizeDigits(state.accounts.length.toString(), locale)} · ${l10n.unpaidBills}: ${localizeDigits(unpaidBills.toString(), locale)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(
                    localizeDigits(
                      value.toStringAsFixed(0),
                      Localizations.localeOf(context),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

String _typeLabel(AppLocalizations l10n, FinanceTransactionType type) =>
    switch (type) {
      FinanceTransactionType.income => l10n.income,
      FinanceTransactionType.expense => l10n.expense,
      FinanceTransactionType.transfer => l10n.transfer,
      FinanceTransactionType.debt => l10n.debt,
      FinanceTransactionType.receivable => l10n.receivable,
      FinanceTransactionType.saving => l10n.saving,
      FinanceTransactionType.bill => l10n.bill,
    };

IconData _typeIcon(FinanceTransactionType type) => switch (type) {
      FinanceTransactionType.income => Icons.south_west_rounded,
      FinanceTransactionType.expense => Icons.north_east_rounded,
      FinanceTransactionType.transfer => Icons.swap_horiz_rounded,
      FinanceTransactionType.debt => Icons.request_quote_rounded,
      FinanceTransactionType.receivable => Icons.payments_rounded,
      FinanceTransactionType.saving => Icons.savings_rounded,
      FinanceTransactionType.bill => Icons.receipt_long_rounded,
    };

Future<void> showFinanceForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  final billIdentifier = TextEditingController();
  final paymentIdentifier = TextEditingController();
  var type = FinanceTransactionType.expense;
  var accountId = ref.read(financeProvider).accounts.isEmpty
      ? ''
      : ref.read(financeProvider).accounts.first.id;
  var date = DateTime.now();
  var dueDate = DateTime.now().add(const Duration(days: 3));
  var category = defaultExpenseCategories.first;
  var billType = defaultBillTypes.first;
  var reminderEnabled = true;
  var reminderKind = ReminderKind.notification;
  var reminderRepeat = ReminderRepeat.monthly;
  var minutesBefore = 1440;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final accounts = ref.read(financeProvider).accounts;
        if (accountId.isEmpty && accounts.isNotEmpty) {
          accountId = accounts.first.id;
        }
        final isBill = type == FinanceTransactionType.bill;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.addFinance,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<FinanceTransactionType>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: l10n.transactionType),
                    items: FinanceTransactionType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_typeLabel(l10n, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.amount),
                    validator: (value) => double.tryParse(
                              toEnglishDigits(value ?? '').replaceAll(',', ''),
                            ) ==
                            null
                        ? l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: accountId.isEmpty ? null : accountId,
                    decoration: InputDecoration(labelText: l10n.account),
                    items: accounts
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => accountId = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (isBill) ...[
                    DropdownButtonFormField<String>(
                      initialValue: billType,
                      decoration: InputDecoration(labelText: l10n.billType),
                      items: defaultBillTypes
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_billTypeLabel(l10n, value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => billType = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: billIdentifier,
                      decoration:
                          InputDecoration(labelText: l10n.billIdentifier),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paymentIdentifier,
                      decoration:
                          InputDecoration(labelText: l10n.paymentIdentifier),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2120),
                              initialDate: dueDate,
                            );
                            if (selected != null) {
                              setState(
                                () => dueDate = DateTime(
                                  selected.year,
                                  selected.month,
                                  selected.day,
                                  dueDate.hour,
                                  dueDate.minute,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.event_busy_rounded),
                          label: Text(
                            '${l10n.dueDate}: ${compactDualDate(dueDate, Localizations.localeOf(context))}',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(dueDate),
                            );
                            if (selected != null) {
                              setState(
                                () => dueDate = DateTime(
                                  dueDate.year,
                                  dueDate.month,
                                  dueDate.day,
                                  selected.hour,
                                  selected.minute,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text(localizedTime(
                            dueDate,
                            Localizations.localeOf(context),
                          )),
                        ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.reminder),
                      value: reminderEnabled,
                      onChanged: (value) =>
                          setState(() => reminderEnabled = value),
                    ),
                    if (reminderEnabled) ...[
                      DropdownButtonFormField<ReminderKind>(
                        initialValue: reminderKind,
                        decoration:
                            InputDecoration(labelText: l10n.reminderMode),
                        items: [
                          DropdownMenuItem(
                            value: ReminderKind.notification,
                            child: Text(l10n.notificationMode),
                          ),
                          DropdownMenuItem(
                            value: ReminderKind.alarm,
                            child: Text(l10n.alarmMode),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => reminderKind = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: minutesBefore,
                        decoration:
                            InputDecoration(labelText: l10n.remindBefore),
                        items: const [60, 120, 1440, 2880, 10080]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value >= 1440
                                      ? l10n.daysBefore(value ~/ 1440)
                                      : l10n.hoursBefore(value ~/ 60),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => minutesBefore = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ReminderRepeat>(
                        initialValue: reminderRepeat,
                        decoration: InputDecoration(labelText: l10n.repeat),
                        items: ReminderRepeat.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_financeRepeatLabel(l10n, value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => reminderRepeat = value);
                          }
                        },
                      ),
                    ],
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: defaultExpenseCategories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_categoryLabel(l10n, value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => category = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: note,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l10n.notes),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2120),
                        initialDate: date,
                      );
                      if (selected != null) setState(() => date = selected);
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      compactDualDate(date, Localizations.localeOf(context)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: accounts.isEmpty
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final reminder = ReminderPlan(
                              enabled: isBill && reminderEnabled,
                              kind: reminderKind,
                              minutesBefore: minutesBefore,
                              repeat: isBill
                                  ? reminderRepeat
                                  : ReminderRepeat.none,
                            );
                            final transaction = ref
                                .read(financeProvider.notifier)
                                .addTransaction(
                                  type: type,
                                  amount: double.parse(
                                    toEnglishDigits(amount.text)
                                        .replaceAll(',', ''),
                                  ),
                                  dateTime: date,
                                  accountId: accountId,
                                  category: isBill ? 'bills' : category,
                                  note: note.text,
                                  dueDate: isBill ? dueDate : null,
                                  billType: isBill ? billType : null,
                                  billIdentifier:
                                      isBill ? billIdentifier.text : null,
                                  paymentIdentifier:
                                      isBill ? paymentIdentifier.text : null,
                                  reminder: reminder,
                                );
                            if (reminder.enabled && transaction.dueDate != null) {
                              await ReminderService.instance
                                  .requestPermissions();
                              await ReminderService.instance.schedule(
                                key: 'bill:${transaction.id}',
                                title:
                                    '${l10n.bill}: ${_billTypeLabel(l10n, billType)}',
                                body: l10n.billReminderBody,
                                eventDateTime: transaction.dueDate!,
                                plan: reminder,
                                payload: 'bill:${transaction.id}',
                              );
                            }
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  amount.dispose();
  note.dispose();
  billIdentifier.dispose();
  paymentIdentifier.dispose();
}

Future<void> _showAccountForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController();
  final balance = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.addAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.accountName),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: balance,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.openingBalance),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;
            ref.read(financeProvider.notifier).addAccount(
                  name.text,
                  openingBalance:
                      double.tryParse(toEnglishDigits(balance.text)) ?? 0,
                );
            Navigator.pop(dialogContext);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  name.dispose();
  balance.dispose();
}

String _categoryLabel(AppLocalizations l10n, String key) => switch (key) {
      'bills' => l10n.categoryBills,
      'rentHousing' => l10n.categoryRentHousing,
      'groceries' => l10n.categoryGroceries,
      'restaurantCafe' => l10n.categoryRestaurantCafe,
      'transportation' => l10n.categoryTransportation,
      'fuel' => l10n.categoryFuel,
      'healthcare' => l10n.categoryHealthcare,
      'medicine' => l10n.categoryMedicine,
      'dailyShopping' => l10n.categoryDailyShopping,
      'education' => l10n.categoryEducation,
      'entertainment' => l10n.categoryEntertainment,
      'travel' => l10n.categoryTravel,
      'clothing' => l10n.categoryClothing,
      'internetPhone' => l10n.categoryInternetPhone,
      'insurance' => l10n.categoryInsurance,
      'tax' => l10n.categoryTax,
      'loanInstallment' => l10n.categoryLoanInstallment,
      'subscriptions' => l10n.categorySubscriptions,
      'repairs' => l10n.categoryRepairs,
      'gift' => l10n.categoryGift,
      'family' => l10n.categoryFamily,
      'pets' => l10n.categoryPets,
      'charity' => l10n.categoryCharity,
      _ => l10n.other,
    };

String _billTypeLabel(AppLocalizations l10n, String key) => switch (key) {
      'electricity' => l10n.billElectricity,
      'water' => l10n.billWater,
      'gas' => l10n.billGas,
      'telephone' => l10n.billTelephone,
      'internet' => l10n.billInternet,
      'buildingCharge' => l10n.billBuildingCharge,
      'insurance' => l10n.categoryInsurance,
      'tax' => l10n.categoryTax,
      'loanInstallment' => l10n.categoryLoanInstallment,
      _ => l10n.other,
    };


String _financeRepeatLabel(
  AppLocalizations l10n,
  ReminderRepeat repeat,
) =>
    switch (repeat) {
      ReminderRepeat.none => l10n.repeatOnce,
      ReminderRepeat.daily => l10n.repeatDaily,
      ReminderRepeat.weekly => l10n.repeatWeekly,
      ReminderRepeat.monthly => l10n.repeatMonthly,
      ReminderRepeat.yearly => l10n.repeatYearly,
    };
