class Money {
  const Money({required this.minorUnits, required this.currencyCode});
  final int minorUnits;
  final String currencyCode;

  Money operator +(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError('Currency mismatch');
    }
    return Money(minorUnits: minorUnits + other.minorUnits, currencyCode: currencyCode);
  }
}
