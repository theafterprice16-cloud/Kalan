import '../core/engine/engine.dart';
import 'db/app_database.dart';
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
    for (final pay in p.payments) _counting(pay, today),
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

/// [pay] on the day it counts in ([countingDate]), as of [today], dated
/// [dueDate] instead of its own date when given.
DatedAmount _counting(PaymentRow pay, LocalDate today, {LocalDate? dueDate}) =>
    DatedAmount(
      countingDate(
        dueDate: dueDate ?? pay.date,
        isPaid: pay.isPaid,
        paidOn: pay.paidOnDay == null
            ? null
            : LocalDate.fromEpochDay(pay.paidOnDay!),
        today: today,
      ),
      // Its amount plus its extra fee (21): the one place a fee joins a
      // period total.
      pay.spokenForMinor,
    );

/// "Change date" (20): the periods whose totals change when [plan]'s
/// payments take [newDates] (by payment number), on the home screen's
/// periods ([schedule]) and its counting rule. Only the plan's counting
/// payments differ before and after; everything else in a period total
/// (other plans, recurring payments) is the same on both sides, so the
/// change is exactly what the home screen shows after saving.
List<PeriodChange> dateChangePreview({
  required PlanWithPayments plan,
  required Map<int, LocalDate> newDates,
  required PaySchedule schedule,
  required LocalDate today,
}) => periodChanges(
  before: [for (final pay in plan.payments) _counting(pay, today)],
  after: [
    for (final pay in plan.payments)
      _counting(pay, today, dueDate: newDates[pay.seq]),
  ],
  schedule: schedule,
);
