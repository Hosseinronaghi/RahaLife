import '../files/files_screen.dart';
import '../../core/widgets/retained_popup.dart';
import '../finance/presentation/finance_screen.dart';
import '../finance/domain/finance_models.dart';
import '../people/presentation/people_screen.dart';
import '../people/domain/person.dart';
import '../cycle/presentation/cycle_screen.dart';
import '../cycle/domain/cycle_log.dart';
import '../../core/widgets/reminder_editor.dart';
import '../../core/notifications/reminder_models.dart';
import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/persistence/drift_entity_repository.dart';
import '../../core/localization/locale_formatters.dart';
import '../sync/presentation/synced_feature_refresh.dart';

String tr(BuildContext c, String fa, String en) =>
    Localizations.localeOf(c).languageCode == 'fa' ? fa : en;
const labels = <String, List<String>>{
  'title': ['عنوان', 'Title'],
  'name': ['نام', 'Name'],
  'details': ['توضیحات', 'Details'],
  'description': ['توضیحات', 'Description'],
  'note': ['توضیح', 'Note'],
  'plainText': ['متن', 'Text'],
  'phone': ['تلفن', 'Phone'],
  'email': ['ایمیل', 'Email'],
  'relationship': ['نسبت', 'Relationship'],
  'location': ['مکان', 'Location'],
  'address': ['نشانی', 'Address'],
  'dosage': ['مقدار مصرف ثبت‌شده', 'Recorded dose'],
  'time': ['زمان', 'Time'],
  'instructions': ['یادداشت مصرف', 'Instructions'],
  'amount': ['مبلغ', 'Amount'],
  'savedAmount': ['پس‌انداز ثبت‌شده', 'Recorded savings'],
  'openingBalance': ['موجودی اولیه', 'Opening balance'],
  'category': ['دسته‌بندی', 'Category'],
  'url': ['نشانی اینترنتی', 'URL'],
  'folder': ['پوشه', 'Folder'],
  'occupation': ['شغل / فعالیت', 'Occupation'],
  'dateTime': ['تاریخ و زمان', 'Date and time'],
  'scheduledAt': ['زمان برنامه‌ریزی', 'Scheduled time'],
  'dueDate': ['سررسید', 'Due date'],
  'birthDate': ['تاریخ تولد', 'Birth date'],
  'startDate': ['تاریخ شروع', 'Start date'],
  'endDate': ['تاریخ پایان', 'End date'],
  'body': ['متن', 'Text'],
  'notes': ['یادداشت', 'Notes'],
  'currencyCode': ['واحد پول', 'Currency'],
  'bankName': ['نام بانک', 'Bank'],
  'accountNumber': ['شماره حساب', 'Account number'],
};
Future<void> editRecord(
  BuildContext context,
  WidgetRef ref,
  String type,
  Map<String, Object?> source,
) async {
  if (type == 'finance_transaction') {
    await showFinanceForm(
      context,
      ref,
      existing: FinanceTransaction.fromJson(source),
    );
    return;
  }
  if (type == 'finance_account') {
    await showAccountForm(
      context,
      ref,
      account: FinanceAccount.fromJson(source),
    );
    return;
  }
  if (type == 'person') {
    await showPersonForm(context, ref, person: Person.fromJson(source));
    return;
  }
  if (type == 'cycle_log') {
    await showCycleForm(context, ref, log: CycleLog.fromJson(source));
    return;
  }
  if (type == 'rich_note') {
    context.push('/notes/edit', extra: source['id']);
    return;
  }
  final data = Map<String, Object?>.from(jsonDecode(jsonEncode(source)) as Map);
  const dates = [
    'dateTime',
    'scheduledAt',
    'dueDate',
    'startDate',
    'endDate',
    'birthDate',
  ];
  const numbers = ['amount', 'openingBalance', 'savedAmount'];
  final fields = <String, TextEditingController>{
    for (final key in labels.keys)
      if (data.containsKey(key) && !dates.contains(key))
        key: TextEditingController(text: data[key]?.toString() ?? ''),
  };
  String? error;
  var busy = false;
  await showRetainedBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => StatefulBuilder(
      builder: (c, set) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.viewInsetsOf(c).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(c).height * .8,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(c, 'ویرایش اطلاعات', 'Edit details'),
                    style: Theme.of(c).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  for (final field in fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(
                        controller: field.value,
                        maxLines:
                            [
                              'details',
                              'description',
                              'note',
                              'instructions',
                              'body',
                              'notes',
                              'plainText',
                            ].contains(field.key)
                            ? 3
                            : 1,
                        decoration: InputDecoration(
                          labelText: tr(
                            c,
                            labels[field.key]![0],
                            labels[field.key]![1],
                          ),
                        ),
                      ),
                    ),
                  for (final key in dates)
                    if (data.containsKey(key))
                      ListTile(
                        title: Text(tr(c, labels[key]![0], labels[key]![1])),
                        subtitle: Text(
                          data[key]?.toString().split('T').first ?? '—',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: key == 'dateTime'
                              ? null
                              : () => set(() => data[key] = null),
                        ),
                        onTap: () async {
                          final current =
                              DateTime.tryParse(data[key]?.toString() ?? '') ??
                              DateTime.now();
                          final date = await showDatePicker(
                            context: c,
                            initialDate: current,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2200),
                          );
                          if (date == null || !c.mounted) {
                            return;
                          }
                          final time = await showTimePicker(
                            context: c,
                            initialTime: TimeOfDay.fromDateTime(current),
                          );
                          if (time != null && c.mounted) {
                            set(
                              () => data[key] = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              ).toIso8601String(),
                            );
                          }
                        },
                      ),
                  if (data['reminder'] is Map)
                    ReminderEditor(
                      plan: ReminderPlan.fromJson(
                        Map<String, Object?>.from(data['reminder'] as Map),
                      ),
                      onChanged: (v) =>
                          set(() => data['reminder'] = v.toJson()),
                    ),
                  if (type == 'home_entry')
                    DropdownButtonFormField<String>(
                      initialValue: data['calendar'] == 'jalali'
                          ? 'jalali'
                          : 'gregorian',
                      decoration: InputDecoration(
                        labelText: tr(
                          c,
                          'مبنای تکرار ماهانه و سالانه',
                          'Monthly and yearly calendar',
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'jalali',
                          child: Text(tr(c, 'شمسی', 'Solar Hijri')),
                        ),
                        DropdownMenuItem(
                          value: 'gregorian',
                          child: Text(tr(c, 'میلادی', 'Gregorian')),
                        ),
                      ],
                      onChanged: (v) => set(() => data['calendar'] = v),
                    ),
                  for (final key in ['paid', 'active', 'savingGoal'])
                    if (data[key] is bool)
                      SwitchListTile(
                        title: Text(
                          key == 'savingGoal'
                              ? tr(
                                  c,
                                  'هدف پس‌انداز (ثبت دستی)',
                                  'Savings goal (manual tracking)',
                                )
                              : key == 'paid'
                              ? tr(c, 'تسویه شده', 'Settled')
                              : tr(c, 'فعال', 'Active'),
                        ),
                        value: data[key] as bool,
                        onChanged: (v) => set(() => data[key] = v),
                      ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: Theme.of(c).colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: Icon(busy ? Icons.hourglass_top : Icons.check),
                    label: Text(tr(c, 'ذخیره', 'Save')),
                    onPressed: busy
                        ? null
                        : () async {
                            set(() => busy = true);
                            try {
                              for (final field in fields.entries) {
                                final raw = field.value.text.trim();
                                if (numbers.contains(field.key)) {
                                  if (raw.isEmpty &&
                                      source[field.key] == null) {
                                    data[field.key] = null;
                                    continue;
                                  }
                                  final value = double.tryParse(
                                    toEnglishDigits(raw),
                                  );
                                  if (value == null || !value.isFinite) {
                                    throw const FormatException(
                                      'Enter a finite number.',
                                    );
                                  }
                                  data[field.key] = value;
                                } else {
                                  data[field.key] = raw;
                                }
                              }
                              if ((data['title'] ??
                                      data['name'] ??
                                      data['body'] ??
                                      'valid')
                                  .toString()
                                  .trim()
                                  .isEmpty) {
                                throw const FormatException(
                                  'A name or title is required.',
                                );
                              }
                              if (data['amount'] is num) {
                                if ((data['amount'] as num) <= 0) {
                                  throw const FormatException(
                                    'Amount must be positive.',
                                  );
                                }
                                data['amountMinor'] =
                                    ((data['amount'] as num) * 100).round();
                              }
                              if (data['openingBalance'] is num) {
                                data['openingBalanceMinor'] =
                                    ((data['openingBalance'] as num) * 100)
                                        .round();
                              }
                              if (type == 'bookmark') {
                                final uri = Uri.tryParse(
                                  data['url'].toString(),
                                );
                                if (uri == null ||
                                    !['https', 'http'].contains(uri.scheme) ||
                                    uri.host.isEmpty) {
                                  throw const FormatException(
                                    'Enter a valid web URL.',
                                  );
                                }
                              }
                              await DriftEntityRepository().updateFromSnapshot(
                                type,
                                data,
                                source,
                              );
                              invalidateSyncedFeatureProviders(ref);
                              if (c.mounted) {
                                Navigator.pop(c);
                              }
                            } catch (e) {
                              if (c.mounted) {
                                set(() {
                                  busy = false;
                                  error = e.toString();
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  for (final field in fields.values) {
    field.dispose();
  }
}

Future<void> recordActions(
  BuildContext context,
  WidgetRef ref,
  String type,
  Map<String, Object?> data,
) async {
  final action = await showRetainedBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in [
          ('edit', Icons.edit_outlined, 'ویرایش', 'Edit'),
          (
            'files',
            Icons.attach_file,
            'فایل‌ها و صداها',
            'Files and recordings',
          ),
          ('copy', Icons.copy, 'ساخت کپی', 'Duplicate'),
          (
            'archive',
            Icons.archive_outlined,
            'بایگانی / خارج‌کردن',
            'Archive / unarchive',
          ),
          (
            'delete',
            Icons.delete_outline,
            'حذف و امکان بازگردانی',
            'Delete with undo',
          ),
        ])
          ListTile(
            leading: Icon(entry.$2),
            title: Text(tr(c, entry.$3, entry.$4)),
            onTap: () => Navigator.pop(c, entry.$1),
          ),
      ],
    ),
  );
  if (action == null || !context.mounted) {
    return;
  }
  if (action == 'files') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FilesScreen(entityType: type, entityId: data['id'].toString()),
      ),
    );
    return;
  }
  if (action == 'edit') {
    await editRecord(context, ref, type, data);
    return;
  }
  final repository = DriftEntityRepository();
  try {
    if (action == 'delete') {
      await repository.deleteFromSnapshot(type, data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'به حذف‌شده‌ها منتقل شد', 'Moved to trash'),
            ),
            action: SnackBarAction(
              label: tr(context, 'بازگردانی', 'Undo'),
              onPressed: () async {
                await repository.upsert(type, data);
                invalidateSyncedFeatureProviders(ref);
              },
            ),
          ),
        );
      }
    } else if (action == 'copy') {
      await repository.upsert(type, {
        ...data,
        'id': const Uuid().v4(),
        if (type == 'finance_account') 'openingBalance': 0,
        if (type == 'finance_account') 'openingBalanceMinor': 0,
      });
    } else {
      await repository.updateFromSnapshot(type, {
        ...data,
        'archived': data['archived'] != true,
      }, data);
    }
    invalidateSyncedFeatureProviders(ref);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
