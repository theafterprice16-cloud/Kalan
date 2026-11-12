import '../date/local_date.dart';

enum PayFrequency { monthly, biweekly, weekly }

/// The span between two paydays: `[start, end)`.
class PayPeriod {
  const PayPeriod(this.start, this.end);

  final LocalDate start;

  /// Exclusive: the next payday.
  final LocalDate end;

  bool contains(LocalDate date) => date >= start && date < end;

  /// Inclusive last day, for display.
  LocalDate get lastDay => end.addDays(-1);

  @override
  bool operator ==(Object other) =>
      other is PayPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PayPeriod($start..$end)';
}

/// When the user gets paid.
///
/// Monthly schedules use a day of month (1-31); in shorter months the
/// payday falls on the last day. Weekly and biweekly schedules step from a
/// known payday ([anchor]). A payday on a weekend is not moved.
class PaySchedule {
  const PaySchedule.monthly(int day)
    : frequency = PayFrequency.monthly,
      monthDay = day,
      anchor = null,
      assert(day >= 1 && day <= 31, 'day must be 1-31');

  const PaySchedule.biweekly(LocalDate this.anchor)
    : frequency = PayFrequency.biweekly,
      monthDay = null;

  const PaySchedule.weekly(LocalDate this.anchor)
    : frequency = PayFrequency.weekly,
      monthDay = null;

  final PayFrequency frequency;
  final int? monthDay;
  final LocalDate? anchor;

  LocalDate _payday(int year, int month) =>
      LocalDate.clamped(year, month, monthDay!);

  PayPeriod periodContaining(LocalDate date) {
    switch (frequency) {
      case PayFrequency.monthly:
        final thisMonth = _payday(date.year, date.month);
        if (date >= thisMonth) {
          return PayPeriod(thisMonth, _payday(date.year, date.month + 1));
        }
        return PayPeriod(_payday(date.year, date.month - 1), thisMonth);
      case PayFrequency.biweekly:
      case PayFrequency.weekly:
        final step = frequency == PayFrequency.weekly ? 7 : 14;
        final offset = anchor!.daysUntil(date);
        final k = (offset / step).floor();
        final start = anchor!.addDays(k * step);
        return PayPeriod(start, start.addDays(step));
    }
  }

  PayPeriod next(PayPeriod period) => periodContaining(period.end);

  /// [count] consecutive periods, starting with the one containing [date].
  List<PayPeriod> periodsFrom(LocalDate date, int count) {
    final periods = <PayPeriod>[];
    var current = periodContaining(date);
    for (var i = 0; i < count; i++) {
      periods.add(current);
      current = next(current);
    }
    return periods;
  }
}
