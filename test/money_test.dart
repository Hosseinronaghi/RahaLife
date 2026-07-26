import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/domain/money.dart';

void main() {
  test('adds values with the same currency', () {
    const first = Money(minorUnits: 100, currencyCode: 'USD');
    const second = Money(minorUnits: 250, currencyCode: 'USD');
    expect((first + second).minorUnits, 350);
  });

  test('rejects currency mismatch', () {
    const first = Money(minorUnits: 100, currencyCode: 'USD');
    const second = Money(minorUnits: 250, currencyCode: 'IRR');
    expect(() => first + second, throwsArgumentError);
  });
}
