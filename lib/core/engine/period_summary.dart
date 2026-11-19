import '../date/local_date.dart';
import 'pay_period.dart';

/// Anything with a date and an amount that is spoken for.
class DatedAmount {
  const DatedAmount(this.date, this.amountMinor);
  final LocalDate date;
  final int amountMinor;
}

enum PeriodStatus {
  /// No income entered: only "spoken for" is shown.
  noIncome,

  /// Left is at or above the threshold.
  comfortable,

  /// Left is below the user's threshold but not negative.
  tight,

  /// Spoken for exceeds income.
  negative,
}

class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.spokenForMinor,
    required this.itemCount,
    required this.status,
    this.incomeMinor,
  });

  final PayPeriod period;

  /// Every payment dated in the period, paid ones included, plus recurring
  /// payments.
  final int spokenForMinor;
  final int itemCount;
  final int? incomeMinor;
  final PeriodStatus status;

  /// Income minus spoken for; null when no income is set.
  int? get leftMinor =>
      incomeMinor == null ? null : incomeMinor! - spokenForMinor;

  /// How much spoken for exceeds income, as a positive amount; null when
  /// no income is set or nothing is short (left zero or above). Nonnull
  /// exactly when [status] is [PeriodStatus.negative].
  int? get shortMinor {
    final left = leftMinor;
    return left != null && left < 0 ? -left : null;
  }
}

/// Sums the items that fall in [period].
PeriodSummary summarizePeriod({
  required PayPeriod period,
  required Iterable<DatedAmount> items,
  int? incomeMinor,
  int? tightThresholdMinor,
}) {
  var spokenFor = 0;
  var count = 0;
  for (final item in items) {
    if (period.contains(item.date)) {
      spokenFor += item.amountMinor;
      count++;
    }
  }
  final PeriodStatus status;
  if (incomeMinor == null) {
    status = PeriodStatus.noIncome;
  } else {
    final left = incomeMinor - spokenFor;
    if (left < 0) {
      status = PeriodStatus.negative;
    } else if (tightThresholdMinor != null && left < tightThresholdMinor) {
      status = PeriodStatus.tight;
    } else {
      status = PeriodStatus.comfortable;
    }
  }
  return PeriodSummary(
    period: period,
    spokenForMinor: spokenFor,
    itemCount: count,
    incomeMinor: incomeMinor,
    status: status,
  );
}

/// An unpaid payment dated before the current period started.
bool isOverdue({
  required LocalDate date,
  required bool isPaid,
  required PayPeriod current,
}) => !isPaid && date < current.start;
