import '../date/local_date.dart';
import 'pay_period.dart';
import 'period_summary.dart';

/// "Busy week": plan payments piled up in a few days of one pay period.
/// An observation only, never a warning; not the same thing as a tight
/// period ([PeriodStatus.tight], left under the user's threshold).
///
/// The rule's fixed numbers, in one place (product decisions 1 and 2:
/// the user cannot change them).
abstract final class BusyWeekRule {
  /// Days in the sliding window.
  static const int windowDays = 7;

  /// At least this many plan payments in the window...
  static const int minPayments = 3;

  /// ...and at least this share of the period's plan payments, as
  /// numerator / denominator (one half), so no doubles are needed.
  static const int shareNumerator = 1;
  static const int shareDenominator = 2;
}

/// The busy week of one pay period: [first] and [last] are its first and
/// last payment days (the shown range, not the whole 7-day window).
class BusyWeek {
  const BusyWeek({
    required this.first,
    required this.last,
    required this.count,
    required this.totalMinor,
  });

  final LocalDate first;
  final LocalDate last;

  /// Plan payments in it.
  final int count;

  /// Their sum, paid or not.
  final int totalMinor;

  bool contains(LocalDate date) => date >= first && date <= last;

  @override
  bool operator ==(Object other) =>
      other is BusyWeek &&
      other.first == first &&
      other.last == last &&
      other.count == count &&
      other.totalMinor == totalMinor;

  @override
  int get hashCode => Object.hash(first, last, count, totalMinor);

  @override
  String toString() => 'BusyWeek($first..$last, $count, $totalMinor)';
}

/// The busy week of [period], or null.
///
/// [planPayments] are plan payments only (recurring payments never
/// count), each on its due date, paid or not; ones outside [period] are
/// ignored. A window is [BusyWeekRule.windowDays] days starting on any day
/// of the period and never crossing its end. It is busy when it holds at
/// least [BusyWeekRule.minPayments] payments and at least half of the
/// period's: both together. Of the busy windows, the one with the most
/// payments wins; on a tie, the earliest. At most one per period.
BusyWeek? busyWeekOf({
  required PayPeriod period,
  required Iterable<DatedAmount> planPayments,
}) {
  final inPeriod = [
    for (final p in planPayments)
      if (period.contains(p.date)) p,
  ]..sort((a, b) => a.date.compareTo(b.date));
  final total = inPeriod.length;
  if (total < BusyWeekRule.minPayments) return null;

  List<DatedAmount>? best;
  for (var start = period.start; start < period.end; start = start.addDays(1)) {
    var end = start.addDays(BusyWeekRule.windowDays);
    if (end > period.end) end = period.end;
    final window = [
      for (final p in inPeriod)
        if (p.date >= start && p.date < end) p,
    ];
    final n = window.length;
    final busy =
        n >= BusyWeekRule.minPayments &&
        n * BusyWeekRule.shareDenominator >=
            total * BusyWeekRule.shareNumerator;
    // Strictly more: an equal count later on never replaces the earlier.
    if (busy && (best == null || n > best.length)) best = window;
  }
  if (best == null) return null;
  return BusyWeek(
    first: best.first.date,
    last: best.last.date,
    count: best.length,
    totalMinor: best.fold(0, (sum, p) => sum + p.amountMinor),
  );
}
