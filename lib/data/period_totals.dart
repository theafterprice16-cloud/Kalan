import '../core/engine/engine.dart';
import 'models.dart';

/// The amounts "spoken for" as seen on [today], each on the day it counts
/// in: plan payments on their [countingDate] (past-due unpaid ones on
/// [today], payments paid before Kalan included, as paid), recurring
/// payments on each of their days in [period]. The one list behind every
/// period total: the home screen and the payday summary.
List<DatedAmount> spokenForItems({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required PayPeriod period,
  required LocalDate today,
}) => [
  for (final p in plans)
    for (final pay in p.payments)
      DatedAmount(
        countingDate(
          dueDate: pay.date,
          isPaid: pay.isPaid,
          paidOn: pay.paidOnDay == null
              ? null
              : LocalDate.fromEpochDay(pay.paidOnDay!),
          today: today,
        ),
        pay.amountMinor,
      ),
  for (final r in recurring)
    for (final date in r.occurrences(period.start, period.end))
      DatedAmount(date, r.item.amountMinor),
];

/// [period]'s summary as the home screen shows it on [today].
PeriodSummary periodSummaryOn({
  required Iterable<PlanWithPayments> plans,
  required Iterable<RecurringWithMarks> recurring,
  required PayPeriod period,
  required LocalDate today,
  int? incomeMinor,
  int? tightThresholdMinor,
}) => summarizePeriod(
  period: period,
  items: spokenForItems(
    plans: plans,
    recurring: recurring,
    period: period,
    today: today,
  ),
  incomeMinor: incomeMinor,
  tightThresholdMinor: tightThresholdMinor,
);
