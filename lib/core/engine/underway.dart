import '../date/local_date.dart';
import 'plan_calculator.dart';
import 'plan_draft.dart';
import 'schedule.dart';
import 'split.dart';

/// How the payments of a plan that is already underway repeat. The dates
/// before the next payment are worked out backwards with the same rule the
/// plan would use going forward.
sealed class UnderwayPattern {
  const UnderwayPattern();
}

/// Payments every [interval] ([PaymentInterval.dateAt]): the same day each
/// month (the next payment's day, with the engine's month end rule: 31 Jan,
/// 28 Feb, 31 Mar) or every N days.
class IntervalPattern extends UnderwayPattern {
  const IntervalPattern(this.interval);
  final PaymentInterval interval;

  @override
  bool operator ==(Object other) =>
      other is IntervalPattern && other.interval == interval;

  @override
  int get hashCode => interval.hashCode;
}

/// Same day every month.
class MonthlyPattern extends IntervalPattern {
  const MonthlyPattern() : super(PaymentInterval.sameDay);
}

/// Pay in 4: every 14 days.
class PayIn4Pattern extends IntervalPattern {
  const PayIn4Pattern() : super(PaymentInterval.biweekly);
}

/// A credit card's due date each month, shifted off weekends if the card
/// says so.
class CardPattern extends UnderwayPattern {
  const CardPattern(this.terms);
  final CardTerms terms;
}

/// All [totalCount] payment dates of a plan whose payment number
/// `paidCount + 1` is due on [nextDate].
///
/// Built so that a plan set up going forward from the first date would
/// land on the same dates: monthly plans keep [nextDate]'s day of month
/// (clamped at month end, without drifting), day intervals step N days
/// (Pay in 4: 14), card plans use the card's due date of each month
/// ([CardTerms.dueInMonth] and [dueMonthOf], as for any card plan).
/// [nextDate] itself is kept as given.
List<LocalDate> underwayDates({
  required LocalDate nextDate,
  required int paidCount,
  required int totalCount,
  required UnderwayPattern pattern,
}) {
  if (totalCount < 1) throw const InvalidPlanInput('count');
  if (paidCount < 0 || paidCount >= totalCount) {
    throw const InvalidPlanInput('paidCount');
  }
  switch (pattern) {
    case IntervalPattern(:final interval):
      if (!interval.isValid) throw const InvalidPlanInput('interval');
      return [
        for (var i = 0; i < totalCount; i++)
          interval.dateAt(nextDate, i - paidCount),
      ];
    case CardPattern(:final terms):
      final base = dueMonthOf(nextDate, terms);
      return [
        for (var i = 0; i < totalCount; i++)
          i == paidCount
              ? nextDate
              : terms.dueInMonth(base.year, base.month + i - paidCount),
      ];
  }
}

/// The card's first due date after [today] (weekend shift applied): the
/// suggested "next payment date" for a card plan already underway.
LocalDate nextCardDueAfter(LocalDate today, CardTerms terms) {
  for (var k = 0; k < 3; k++) {
    final due = terms.dueInMonth(today.year, today.month + k);
    if (due > today) return due;
  }
  // Unreachable: a due date exists every month.
  return terms.dueInMonth(today.year, today.month + 3);
}

/// Builds the draft of a plan that is already underway: every payment from
/// the first one, the first [paidCount] paid before Kalan. Amounts are
/// split as for any new plan ([splitEvenly]: the leftover minor units go
/// to the first payment).
PlanDraft underwayPlan({
  required PlanKind kind,
  required int totalMinor,
  required int count,
  required int paidCount,
  required LocalDate nextDate,
  CardTerms? terms,
  bool isCashAdvance = false,
  PaymentInterval? interval,
}) {
  if (count < 1 || count > PlanCalculator.maxInstallments) {
    throw const InvalidPlanInput('count');
  }
  if (totalMinor < count) throw const InvalidPlanInput('total');
  if (paidCount < 1 || paidCount >= count) {
    throw const InvalidPlanInput('paidCount');
  }
  final planInterval = switch (kind) {
    PlanKind.monthly => interval ?? PaymentInterval.sameDay,
    PlanKind.payIn4 => interval ?? PaymentInterval.biweekly,
    _ => null,
  };
  final pattern = switch (kind) {
    PlanKind.monthly || PlanKind.payIn4 => IntervalPattern(planInterval!),
    PlanKind.card when terms != null => CardPattern(terms),
    _ => throw const InvalidPlanInput('kind'),
  };
  if (kind == PlanKind.payIn4 && count != 4) {
    throw const InvalidPlanInput('count');
  }
  final dates = underwayDates(
    nextDate: nextDate,
    paidCount: paidCount,
    totalCount: count,
    pattern: pattern,
  );
  final amounts = splitEvenly(totalMinor, count);
  return PlanDraft(
    kind: kind,
    installmentCount: count,
    isCashAdvance: kind == PlanKind.card && isCashAdvance,
    paidBeforeCount: paidCount,
    interval: planInterval,
    payments: [
      for (var i = 0; i < count; i++)
        DraftPayment(seq: i + 1, date: dates[i], amountMinor: amounts[i]),
    ],
  );
}

/// A manually entered plan whose first [paidCount] payments were paid
/// before Kalan. The entered dates stay as they are.
PlanDraft markPaidBefore(PlanDraft draft, int paidCount) {
  if (paidCount < 1 || paidCount >= draft.payments.length) {
    throw const InvalidPlanInput('paidCount');
  }
  return draft.withPaidBefore(paidCount);
}
