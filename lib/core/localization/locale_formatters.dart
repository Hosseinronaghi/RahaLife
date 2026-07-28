import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

const _englishDigits = '0123456789';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

String toEnglishDigits(String value) {
  var result = value;
  for (var index = 0; index < _persianDigits.length; index++) {
    result = result.replaceAll(_persianDigits[index], _englishDigits[index]);
  }
  return result;
}

String localizeDigits(Object value, Locale locale) {
  final input = value.toString();
  if (locale.languageCode != 'fa') return input;
  var result = input;
  for (var index = 0; index < _englishDigits.length; index++) {
    result = result.replaceAll(_englishDigits[index], _persianDigits[index]);
  }
  return result;
}

String primaryDateLabel(DateTime date, Locale locale) {
  if (locale.languageCode == 'fa') {
    final jalali = Jalali.fromDateTime(date);
    final formatter = jalali.formatter;
    return localizeDigits(
      '${formatter.wN} ${formatter.d} ${formatter.mN} ${formatter.yyyy}',
      locale,
    );
  }
  return DateFormat('EEEE, MMMM d, y', 'en').format(date);
}

String secondaryDateLabel(DateTime date, Locale locale) {
  if (locale.languageCode == 'fa') {
    return localizeDigits(
      DateFormat('yyyy/MM/dd', 'en').format(date),
      locale,
    );
  }
  final jalali = Jalali.fromDateTime(date);
  final formatter = jalali.formatter;
  return '${formatter.wNFn} ${formatter.d} ${formatter.mNFn} ${formatter.yyyy}';
}

String compactDualDate(DateTime date, Locale locale) {
  if (locale.languageCode == 'fa') {
    final jalali = Jalali.fromDateTime(date).formatter;
    final gregorian = DateFormat('yyyy/MM/dd', 'en').format(date);
    return '${localizeDigits('${jalali.yyyy}/${jalali.mm}/${jalali.dd}', locale)} · ${localizeDigits(gregorian, locale)}';
  }
  final jalali = Jalali.fromDateTime(date).formatter;
  return '${DateFormat('yyyy/MM/dd', 'en').format(date)} · ${jalali.yyyy}/${jalali.mm}/${jalali.dd}';
}

String localizedTime(DateTime date, Locale locale) {
  final value = DateFormat('HH:mm', 'en').format(date);
  return localizeDigits(value, locale);
}

String localizedNumber(num value, Locale locale) =>
    localizeDigits(NumberFormat.decimalPattern('en').format(value), locale);
