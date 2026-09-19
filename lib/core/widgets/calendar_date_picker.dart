import 'retained_popup.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../localization/locale_formatters.dart';

Future<DateTime?> showCalendarDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required String calendar,
}) async {
  if (calendar != 'jalali') {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
  final initial = Jalali.fromDateTime(initialDate);
  final year = TextEditingController(text: initial.year.toString()),
      month = TextEditingController(text: initial.month.toString()),
      day = TextEditingController(text: initial.day.toString());
  String? error;
  final fa = Localizations.localeOf(context).languageCode == 'fa';
  final result = await showRetainedDialog<DateTime>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(fa ? 'تاریخ شمسی' : 'Jalali date'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in [
                (year, fa ? 'سال' : 'Year'),
                (month, fa ? 'ماه' : 'Month'),
                (day, fa ? 'روز' : 'Day'),
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                    controller: field.$1,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: field.$2),
                  ),
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(c).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(fa ? 'لغو' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                final y = int.parse(toEnglishDigits(year.text)),
                    m = int.parse(toEnglishDigits(month.text)),
                    d = int.parse(toEnglishDigits(day.text));
                final date = Jalali(y, m, d).toDateTime();
                if (date.isBefore(
                      DateTime(firstDate.year, firstDate.month, firstDate.day),
                    ) ||
                    date.isAfter(
                      DateTime(lastDate.year, lastDate.month, lastDate.day),
                    )) {
                  throw const FormatException();
                }
                Navigator.pop(c, date);
              } catch (_) {
                set(
                  () => error = fa
                      ? 'تاریخ معتبر در بازهٔ مجاز وارد کنید.'
                      : 'Enter a valid date within range.',
                );
              }
            },
            child: Text(fa ? 'انتخاب' : 'Select'),
          ),
        ],
      ),
    ),
  );
  for (final c in [year, month, day]) {
    c.dispose();
  }
  return result;
}
