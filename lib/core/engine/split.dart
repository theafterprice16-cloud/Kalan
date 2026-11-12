/// Splits [total] minor units into [parts] payments.
///
/// Every payment gets `total ~/ parts`; the leftover minor units go to the
/// first payment, so the sum always equals [total].
List<int> splitEvenly(int total, int parts) {
  if (parts < 1) {
    throw ArgumentError.value(parts, 'parts', 'must be at least 1');
  }
  if (total < 0) {
    throw ArgumentError.value(total, 'total', 'must not be negative');
  }
  final base = total ~/ parts;
  final remainder = total - base * parts;
  return [for (var i = 0; i < parts; i++) i == 0 ? base + remainder : base];
}
