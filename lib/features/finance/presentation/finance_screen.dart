import '../../../core/widgets/retained_popup.dart';
import '../../workspace/record_editor.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/widgets/reminder_editor.dart';
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
            tooltip: tr(context, 'گزارش و بودجه', 'Reports and budgets'),
            icon: const Icon(Icons.insights),
            onPressed: () => context.push('/insights'),
          ),
          IconButton(
            tooltip: tr(context, 'ویرایش و بازیابی', 'Edit / restore'),
            icon: const Icon(Icons.edit_note),
            onPressed: () => context.push('/records'),
          ),
          IconButton(
            onPressed: () => showAccountForm(context, ref),
            tooltip: l10n.addAccount,
            icon: const Icon(Icons.account_balance_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (state.currencies.length <= 1) _Summary(state: state),
          for (final entry in state.balanceByCurrency.entries)
            ListTile(
              title: Text(financeCurrencyLabel(context, entry.key)),
              trailing: Text(
                localizeDigits(
                  (entry.value / 100).toStringAsFixed(2),
                  Localizations.localeOf(context),
                ),
              ),
            ),
          for (final account in state.accounts)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(
                  account.name == 'Cash'
                      ? tr(context, 'پول نقد', 'Cash')
                      : account.name,
                ),
                subtitle: Text(
                  '${financeCurrencyLabel(context, account.currencyCode)} · ${financeAccountKindLabel(context, account.kind)}${account.archived ? ' · ${tr(context, 'بایگانی', 'Archived')}' : ''}',
                ),
                trailing: Text(
                  localizeDigits(
                    (state.accountBalanceMinor(account.id) / 100)
                        .toStringAsFixed(2),
                    Localizations.localeOf(context),
                  ),
                ),
                onTap: () => showAccountForm(context, ref, account: account),
              ),
            ),
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
                          financeCategoryLabel(l10n, item.category!),
                        compactDualDate(
                          item.dueDate ?? item.dateTime,
                          Localizations.localeOf(context),
                        ),
                        if (item.isBill ||
                            item.type == FinanceTransactionType.debt ||
                            item.type == FinanceTransactionType.receivable)
                          item.paid ? l10n.paid : l10n.unpaid,
                      ].join(' • '),
                    ),
                    trailing: SizedBox(
                      width:
                          (item.isBill ||
                              item.type == FinanceTransactionType.debt ||
                              item.type == FinanceTransactionType.receivable)
                          ? 148
                          : 112,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.isBill ||
                              item.type == FinanceTransactionType.debt ||
                              item.type == FinanceTransactionType.receivable)
                            IconButton(
                              tooltip: item.paid
                                  ? l10n.markUnpaid
                                  : l10n.markPaid,
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
                    onLongPress: () => recordActions(
                      context,
                      ref,
                      'finance_transaction',
                      item.toJson(),
                    ),
                    onTap: () => showFinanceForm(context, ref, existing: item),
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
            for (final currency in state.currencies) ...[
              Text(
                financeCurrencyLabel(context, currency),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Builder(
                builder: (context) {
                  final selected = state.accounts
                      .where((a) => a.currencyCode == currency)
                      .toList();
                  final subset = FinanceState(
                    accounts: selected,
                    transactions: state.transactions
                        .where((t) => selected.any((a) => a.id == t.accountId))
                        .toList(),
                  );
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [
                              _Amount(
                                label: l10n.balance,
                                value: subset.balance,
                                icon: Icons.account_balance_wallet_rounded,
                              ),
                              _Amount(
                                label: l10n.income,
                                value: subset.income,
                                icon: Icons.trending_up_rounded,
                              ),
                              _Amount(
                                label: l10n.expense,
                                value: subset.expense,
                                icon: Icons.trending_down_rounded,
                              ),
                            ]
                            .map(
                              (widget) => SizedBox(width: 180, child: widget),
                            )
                            .toList(),
                  );
                },
              ),
            ],
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
  const _Amount({required this.label, required this.value, required this.icon});
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

Future<void> showFinanceForm(
  BuildContext context,
  WidgetRef ref, {
  String? projectId,
  FinanceTransaction? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(text: existing?.amount.toString() ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  final billIdentifier = TextEditingController(
    text: existing?.billIdentifier ?? '',
  );
  final paymentIdentifier = TextEditingController(
    text: existing?.paymentIdentifier ?? '',
  );
  var type = existing?.type ?? FinanceTransactionType.expense;
  final available = ref
      .read(financeProvider)
      .accounts
      .where(
        (a) =>
            !a.archived ||
            a.id == existing?.accountId ||
            a.id == existing?.toAccountId,
      )
      .toList();
  var accountId =
      existing?.accountId ?? (available.isEmpty ? '' : available.first.id);
  String? toAccountId = existing?.toAccountId;
  var date = existing?.dateTime ?? DateTime.now();
  var dueDate =
      existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));
  var category = existing?.category ?? defaultExpenseCategories.first;
  var billType = existing?.billType ?? defaultBillTypes.first;
  var reminder =
      existing?.reminder ??
      const ReminderPlan(
        enabled: true,
        kind: ReminderKind.notification,
        minutesBefore: 1440,
        repeat: ReminderRepeat.monthly,
      );

  await showRetainedBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final accounts = ref
            .read(financeProvider)
            .accounts
            .where(
              (a) =>
                  !a.archived ||
                  a.id == existing?.accountId ||
                  a.id == existing?.toAccountId,
            )
            .toList();
        if (accountId.isEmpty && accounts.isNotEmpty) {
          accountId = accounts.first.id;
        }
        final isBill = type == FinanceTransactionType.bill;
        final hasDueDate =
            isBill ||
            type == FinanceTransactionType.debt ||
            type == FinanceTransactionType.receivable;
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
                    decoration: InputDecoration(
                      labelText: l10n.transactionType,
                    ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l10n.amount),
                    validator: (value) {
                      final parsed = double.tryParse(
                        toEnglishDigits(value ?? '')
                            .replaceAll(',', '')
                            .replaceAll('٬', '')
                            .replaceAll('٫', '.'),
                      );
                      return parsed == null ||
                              !parsed.isFinite ||
                              parsed <= 0 ||
                              parsed > 90071992547409
                          ? tr(
                              context,
                              'مبلغ مثبت و معتبر وارد کنید.',
                              'Enter a valid positive amount.',
                            )
                          : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: accounts.any((a) => a.id == accountId)
                        ? accountId
                        : null,
                    isExpanded: true,
                    validator: (v) => v == null ? l10n.requiredField : null,
                    decoration: InputDecoration(labelText: l10n.account),
                    items: accounts
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.name == 'Cash'
                                  ? tr(context, 'پول نقد', 'Cash')
                                  : item.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          accountId = value;
                          toAccountId = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  if (type == FinanceTransactionType.transfer ||
                      type == FinanceTransactionType.saving)
                    DropdownButtonFormField<String>(
                      key: ValueKey(accountId),
                      initialValue: toAccountId,
                      decoration: InputDecoration(
                        labelText: tr(
                          context,
                          'حساب مقصد',
                          'Destination account',
                        ),
                      ),
                      items: accounts
                          .where(
                            (a) =>
                                a.id != accountId &&
                                a.currencyCode ==
                                    accounts
                                        .firstWhere((x) => x.id == accountId)
                                        .currencyCode,
                          )
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => toAccountId = v),
                      validator: (v) => v == null
                          ? tr(
                              context,
                              'حساب مقصد را انتخاب کن',
                              'Choose a destination',
                            )
                          : null,
                    ),
                  if (isBill) ...[
                    DropdownButtonFormField<String>(
                      initialValue: billType,
                      decoration: InputDecoration(labelText: l10n.billType),
                      items: {billType, ...defaultBillTypes}
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
                      decoration: InputDecoration(
                        labelText: l10n.billIdentifier,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paymentIdentifier,
                      decoration: InputDecoration(
                        labelText: l10n.paymentIdentifier,
                      ),
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
                          label: Text(
                            localizedTime(
                              dueDate,
                              Localizations.localeOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ReminderEditor(
                      plan: reminder,
                      allowedBeforeMinutes: const [60, 120, 1440, 2880, 10080],
                      onChanged: (value) => setState(() => reminder = value),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: {category, ...defaultExpenseCategories}
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(financeCategoryLabel(l10n, value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => category = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (hasDueDate && !isBill) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        '${l10n.dueDate}: ${compactDualDate(dueDate, Localizations.localeOf(context))}',
                      ),
                      onPressed: () async {
                        final value = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2200),
                        );
                        if (value != null) setState(() => dueDate = value);
                      },
                    ),
                    ReminderEditor(
                      plan: reminder,
                      onChanged: (v) => setState(() => reminder = v),
                    ),
                    const SizedBox(height: 20),
                  ],
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
                            final activeReminder = hasDueDate
                                ? reminder
                                : const ReminderPlan();
                            try {
                              final transaction = ref
                                  .read(financeProvider.notifier)
                                  .addTransaction(
                                    id: existing?.id,
                                    paid: existing?.paid ?? false,
                                    type: type,
                                    amount: double.parse(
                                      toEnglishDigits(amount.text)
                                          .replaceAll(',', '')
                                          .replaceAll('٬', '')
                                          .replaceAll('٫', '.'),
                                    ),
                                    dateTime: date,
                                    accountId: accountId,
                                    toAccountId: toAccountId,
                                    category: isBill ? 'bills' : category,
                                    note: note.text,
                                    dueDate: hasDueDate ? dueDate : null,
                                    billType: isBill ? billType : null,
                                    billIdentifier: isBill
                                        ? billIdentifier.text
                                        : null,
                                    paymentIdentifier: isBill
                                        ? paymentIdentifier.text
                                        : null,
                                    reminder: activeReminder,
                                    projectId: projectId ?? existing?.projectId,
                                  );
                              if (activeReminder.enabled &&
                                  transaction.dueDate != null) {
                                await ReminderService.instance
                                    .requestPermissions();
                                // Persisted data is reconciled by ReminderCoordinator.
                              }
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            } catch (_) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr(
                                        sheetContext,
                                        'حساب و مبلغ را بررسی کنید؛ حساب مقصد باید متفاوت و هم‌ارز باشد.',
                                        'Check amount and accounts. Destination must differ and use the same currency.',
                                      ),
                                    ),
                                  ),
                                );
                              }
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

String financeCurrencyLabel(BuildContext context, String value) =>
    switch (value) {
      'IRT' => tr(context, 'تومان', 'Toman'),
      'IRR' => tr(context, 'ریال', 'Rial'),
      'USD' => tr(context, 'دلار آمریکا', 'US dollar'),
      'EUR' => tr(context, 'یورو', 'Euro'),
      _ => value,
    };
String financeAccountKindLabel(BuildContext context, String value) =>
    switch (value) {
      'cash' => tr(context, 'پول نقد', 'Cash'),
      'bank' => tr(context, 'حساب بانکی', 'Bank'),
      'saving' => tr(context, 'پس‌انداز', 'Savings'),
      'wallet' => tr(context, 'کیف پول', 'Wallet'),
      _ => tr(context, 'سایر', 'Other'),
    };
Future<void> showAccountForm(
  BuildContext context,
  WidgetRef ref, {
  FinanceAccount? account,
}) async {
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController(
    text: account?.name == 'Cash'
        ? tr(context, 'پول نقد', 'Cash')
        : account?.name ?? '',
  );
  final balance = TextEditingController(
    text: (account?.openingBalance ?? 0).toString(),
  );
  final bank = TextEditingController(text: account?.bankName ?? '');
  final number = TextEditingController(text: account?.accountNumber ?? '');
  var currency = account?.currencyCode ?? 'IRT';
  var kind = account?.kind ?? 'cash';
  var archived = account?.archived ?? false;
  String? error;
  await showRetainedDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(account == null ? l10n.addAccount : l10n.edit),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.accountName),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr(context, 'نوع حساب', 'Account type'),
                  ),
                  items: {kind, 'cash', 'bank', 'saving', 'wallet'}
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(financeAccountKindLabel(context, v)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => kind = v!),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr(context, 'واحد پول', 'Currency'),
                  ),
                  items: {currency, 'IRT', 'IRR', 'USD', 'EUR'}
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(financeCurrencyLabel(context, v)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => currency = v!),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: balance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.openingBalance),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: bank,
                  decoration: InputDecoration(
                    labelText: tr(context, 'نام بانک', 'Bank name'),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: number,
                  decoration: InputDecoration(
                    labelText: tr(context, 'شماره حساب', 'Account number'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context, 'بایگانی حساب', 'Archive account')),
                  value: archived,
                  onChanged: (v) => setState(() => archived = v),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final opening = double.tryParse(
                toEnglishDigits(balance.text)
                    .replaceAll(',', '')
                    .replaceAll('٬', '')
                    .replaceAll('٫', '.')
                    .replaceAll('٬', '')
                    .replaceAll('٫', '.'),
              );
              if (name.text.trim().isEmpty ||
                  opening == null ||
                  !opening.isFinite) {
                setState(
                  () => error = tr(
                    context,
                    'نام و مبلغ معتبر وارد کنید.',
                    'Enter a name and valid amount.',
                  ),
                );
                return;
              }
              try {
                ref
                    .read(financeProvider.notifier)
                    .addAccount(
                      name.text,
                      id: account?.id,
                      openingBalance: opening,
                      currencyCode: currency,
                      kind: kind,
                      bankName: bank.text,
                      accountNumber: number.text,
                      archived: archived,
                    );
                Navigator.pop(dialogContext);
              } catch (_) {
                setState(
                  () => error = tr(
                    context,
                    'واحد پول حساب دارای تراکنش قابل تغییر نیست.',
                    'Currency of an account with transactions cannot change.',
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
  for (final c in [name, balance, bank, number]) {
    c.dispose();
  }
}

String financeCategoryLabel(AppLocalizations l10n, String key) => switch (key) {
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
