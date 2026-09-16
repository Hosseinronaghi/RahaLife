import 'dart:convert';

enum ClockOrder { equal, before, after, concurrent }

Map<String, int> decodeClock(String raw, String device, int version) {
  final values = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  if (values.isEmpty) return {device: version};
  return values.map((key, value) => MapEntry(key, (value as num).toInt()));
}

ClockOrder compareClocks(Map<String, int> a, Map<String, int> b) {
  var less = false, greater = false;
  for (final key in {...a.keys, ...b.keys}) {
    less |= (a[key] ?? 0) < (b[key] ?? 0);
    greater |= (a[key] ?? 0) > (b[key] ?? 0);
  }
  if (less && greater) return ClockOrder.concurrent;
  if (less) return ClockOrder.before;
  if (greater) return ClockOrder.after;
  return ClockOrder.equal;
}

Map<String, int> joinClocks(Map<String, int> a, Map<String, int> b) => {
  for (final key in {...a.keys, ...b.keys})
    key: (a[key] ?? 0) > (b[key] ?? 0) ? a[key]! : b[key]!,
};
