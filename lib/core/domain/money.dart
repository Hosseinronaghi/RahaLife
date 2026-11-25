/// Money is stored and calculated in integer hundredths of the selected unit.
/// Legacy IRT/IRR values retain their existing scale; no silent currency conversion.
class Money {
  const Money({required this.minorUnits, required this.currencyCode});
  static const maxMinorUnits = 9007199254740991;
  final int minorUnits;
  final String currencyCode;

  factory Money.parse(String input, {String currencyCode = 'IRT'}) {
    var text = input.trim();
    const digits = '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < digits.length; i++) {
      text = text.replaceAll(digits[i], '${i % 10}');
    }
    text = text.replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.');
    final match = RegExp(
      r'^([+-]?)(\d+)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
    ).firstMatch(text);
    if (match == null || text.length > 100) {
      throw const FormatException('Invalid amount');
    }
    final exponent = int.tryParse(match.group(4) ?? '0');
    if (exponent == null || exponent.abs() > 100) {
      throw const FormatException('Invalid amount exponent');
    }
    final fraction = match.group(3) ?? '';
    var value = BigInt.parse('${match.group(2)}$fraction');
    final shift = exponent + 2 - fraction.length;
    if (shift >= 0) {
      value *= BigInt.from(10).pow(shift);
    } else {
      final divisor = BigInt.from(10).pow(-shift);
      final remainder = value.remainder(divisor);
      value = value ~/ divisor;
      if (remainder * BigInt.two >= divisor) value += BigInt.one;
    }
    if (match.group(1) == '-') value = -value;
    if (value.abs() > BigInt.from(maxMinorUnits)) {
      throw const FormatException('Amount exceeds exact integer range');
    }
    return Money(minorUnits: value.toInt(), currencyCode: currencyCode);
  }

  static int readMinor(Object? minor, Object? legacy) {
    if (minor != null) {
      final parsed = int.tryParse(minor.toString());
      if (parsed == null || parsed.abs() > maxMinorUnits) {
        throw const FormatException('Invalid minor units');
      }
      return parsed;
    }
    return Money.parse((legacy ?? 0).toString()).minorUnits;
  }

  String get decimal {
    final absolute = minorUnits.abs();
    return '${minorUnits < 0 ? '-' : ''}${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  Money operator +(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError('Currency mismatch');
    }
    final total = minorUnits + other.minorUnits;
    if (total.abs() > maxMinorUnits) {
      throw StateError('Money total exceeds exact integer range');
    }
    return Money(minorUnits: total, currencyCode: currencyCode);
  }
}
