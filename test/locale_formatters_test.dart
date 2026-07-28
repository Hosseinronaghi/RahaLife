import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/localization/locale_formatters.dart';

void main() {
  test('converts English digits to Persian digits', () {
    expect(localizeDigits('1405/05/04', const Locale('fa')), '۱۴۰۵/۰۵/۰۴');
  });

  test('keeps English digits in English locale', () {
    expect(localizeDigits('2026/07/26', const Locale('en')), '2026/07/26');
  });

  test('converts Persian digits back to English for numeric input', () {
    expect(toEnglishDigits('۱۲۳۴۵'), '12345');
  });
}
