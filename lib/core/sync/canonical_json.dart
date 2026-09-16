import 'dart:convert';

/// Deterministic JSON used for change detection and conflict comparison.
/// Map insertion order must never turn an unchanged record into a new delta.
String canonicalJson(Object? value) => jsonEncode(canonicalizeJson(value));

Object? canonicalizeJson(Object? value) {
  if (value is Map) {
    final entries =
        value.entries
            .map((entry) => MapEntry(entry.key.toString(), entry.value))
            .toList(growable: false)
          ..sort((left, right) => left.key.compareTo(right.key));
    return <String, Object?>{
      for (final entry in entries) entry.key: canonicalizeJson(entry.value),
    };
  }
  if (value is List) {
    return value.map(canonicalizeJson).toList(growable: false);
  }
  return value;
}
