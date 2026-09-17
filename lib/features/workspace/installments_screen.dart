import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/locale_formatters.dart';
import '../../core/persistence/drift_entity_repository.dart';
import '../finance/presentation/finance_controller.dart';
import '../sync/presentation/synced_feature_refresh.dart';
import 'record_editor.dart';

/// A schedule of unpaid bills; confirming never makes a bank payment.
class InstallmentsScreen extends ConsumerStatefulWidget {
  const InstallmentsScreen({super.key});
  @override
  ConsumerState<InstallmentsScreen> createState() => _InstallmentsState();
}

class _InstallmentsState extends ConsumerState<InstallmentsScreen> {
  final title = TextEditingController(), amount = TextEditingController();
  int count = 12;
  String? account;
  DateTime first = DateTime.now();
  bool busy = false;
  String? error;
  DateTime due(int i) {
    final last = DateTime(first.year, first.month + i + 1, 0).day;
    return DateTime(
      first.year,
      first.month + i,
      first.day > last ? last : first.day,
      9,
    );
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = double.tryParse(toEnglishDigits(amount.text.trim()));
      if (title.text.trim().isEmpty ||
          value == null ||
          !value.isFinite ||
          value <= 0 ||
          account == null) {
        throw StateError(
          tr(
            context,
            'عنوان، مبلغ مثبت و حساب را وارد کن',
            'Enter a title, positive amount and account',
          ),
        );
      }
      final repo = DriftEntityRepository();
      await repo.db.transaction(() async {
        for (var i = 0; i < count; i++) {
          await repo.upsert('finance_transaction', {
            'id': const Uuid().v4(),
            'type': 'bill',
            'amount': value,
            'amountMinor': (value * 100).round(),
            'dateTime': due(i).toIso8601String(),
            'dueDate': due(i).toIso8601String(),
            'accountId': account,
            'category': 'loanInstallment',
            'billType': 'loanInstallment',
            'note': '${title.text.trim()} · ${i + 1}/$count',
            'paid': false,
            'reminder': {'enabled': false, 'repeat': 'none'},
          });
        }
      });
      invalidateSyncedFeatureProviders(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    final accounts = ref
        .watch(financeProvider)
        .accounts
        .where((a) => !a.archived)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(c, 'برنامهٔ اقساط', 'Installment schedule')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            tr(
              c,
              'هر قسط به‌صورت یک قبض پرداخت‌نشده ثبت می‌شود. پرداخت بانکی انجام نمی‌شود.',
              'Each installment becomes an unpaid bill. This does not make a bank payment.',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: title,
            decoration: InputDecoration(labelText: tr(c, 'عنوان', 'Title')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr(c, 'مبلغ هر قسط', 'Amount per installment'),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: account,
            decoration: InputDecoration(labelText: tr(c, 'حساب', 'Account')),
            items: [
              for (final a in accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} · ${a.currencyCode}'),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => account = v),
          ),
          ListTile(
            title: Text(tr(c, 'تعداد اقساط ماهانه', 'Monthly installments')),
            trailing: DropdownButton<int>(
              value: count,
              items: [3, 6, 12, 18, 24, 36, 48, 60]
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(
                        localizedNumber(n, Localizations.localeOf(c)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy ? null : (v) => setState(() => count = v!),
            ),
          ),
          ListTile(
            title: Text(tr(c, 'اولین سررسید', 'First due date')),
            subtitle: Text(compactDualDate(first, Localizations.localeOf(c))),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: busy
                ? null
                : () async {
                    final d = await showDatePicker(
                      context: c,
                      initialDate: first,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && mounted) setState(() => first = d);
                  },
          ),
          const SizedBox(height: 20),
          Text(
            tr(c, 'پیش‌نمایش سررسیدها', 'Due dates preview'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          for (var i = 0; i < count; i++)
            ListTile(
              dense: true,
              title: Text(
                '${localizedNumber(i + 1, Localizations.localeOf(c))} · ${compactDualDate(due(i), Localizations.localeOf(c))}',
              ),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              tr(c, 'تأیید و ثبت همهٔ اقساط', 'Confirm installment schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
