import '../date/local_date.dart';
import 'pay_later.dart';
import 'pay_period.dart';
import 'period_summary.dart';
import 'plan_draft.dart';
import 'plan_status.dart';

/// "Change date" (20): the user records a date the provider moved. Kalan
/// only keeps the record; it never moves anything at the provider and
/// never suggests moving a payment. These rules are pure and tested on
/// their own; the engine itself is unchanged, so every screen reads the
/// new date as it reads any stored date.

/// A plan payment as the date change sees it.
class MovablePayment {
  const MovablePayment({
    required this.seq,
    required this.date,
    this.isPaid = false,
    this.originalDate,
  });

  final int seq;
  final LocalDate date;
  final bool isPaid;

  /// The date before the first change; null when never changed.
  final LocalDate? originalDate;
}

/// "Change date" is offered on an unpaid payment of an open plan. Not on
/// card installments (their dates follow the statement), plans on hold or
/// closed, or paid payments. Recurring payments are not plan payments.
bool canChangeDate({
  required PlanStatus status,
  required PlanKind kind,
  required bool isPaid,
}) => status == PlanStatus.open && kind != PlanKind.card && !isPaid;

/// Why a date change is not stored.
enum MoveRejection {
  /// The payment does not exist.
  notFound,

  /// Paid, on a card plan, or on a plan on hold or closed.
  notAllowed,

  /// The new date is the payment's own date.
  unchanged,

  /// The new date is before today.
  beforeToday,

  /// Moving the later payments too puts one of them before today.
  laterBeforeToday,
}

/// The one check for the screen and the save: null when payment [seq] of
/// a [status] / [kind] plan can move to [newDate] on [today].
MoveRejection? moveRejection(
  List<MovablePayment> payments, {
  required int seq,
  required LocalDate newDate,
  required bool shiftLater,
  required LocalDate today,
  required PlanStatus status,
  required PlanKind kind,
}) {
  final target = payments.where((p) => p.seq == seq).firstOrNull;
  if (target == null) return MoveRejection.notFound;
  if (!canChangeDate(status: status, kind: kind, isPaid: target.isPaid)) {
    return MoveRejection.notAllowed;
  }
  if (newDate == target.date) return MoveRejection.unchanged;
  if (newDate < today) return MoveRejection.beforeToday;
  final moved = movedDates(
    payments,
    seq: seq,
    newDate: newDate,
    shiftLater: shiftLater,
  );
  for (final MapEntry(key: other, value: date) in moved.entries) {
    if (other != seq && date < today) return MoveRejection.laterBeforeToday;
  }
  return null;
}

/// The new dates, by payment number, of the payments whose date changes
/// when payment [seq] moves to [newDate]. With [shiftLater], every later
/// unpaid payment (by number) moves by the same number of days; paid and
/// earlier payments never move. Empty when [newDate] is the payment's own
/// date or [seq] is not found.
Map<int, LocalDate> movedDates(
  List<MovablePayment> payments, {
  required int seq,
  required LocalDate newDate,
  required bool shiftLater,
}) {
  final target = payments.where((p) => p.seq == seq).firstOrNull;
  if (target == null) return const {};
  final days = target.date.daysUntil(newDate);
  if (days == 0) return const {};
  return {
    seq: newDate,
    if (shiftLater)
      for (final p in payments)
        if (p.seq > seq && !p.isPaid) p.seq: p.date.addDays(days),
  };
}

/// The original date to store after a payment dated [current] moves to
/// [newDate]: the stored one stays (never overwritten); the first change
/// keeps [current]. Null when the payment is back on its original date.
LocalDate? originalDateAfterMove({
  required LocalDate current,
  required LocalDate? stored,
  required LocalDate newDate,
}) {
  final original = stored ?? current;
  return newDate == original ? null : original;
}

/// The note on a payment with an original date.
enum MoveNote {
  /// "Moved later · originally …"
  later,

  /// "Moved earlier · originally …"
  earlier,
}

/// Which note [date] gets against [originalDate]; null when there is
/// none or the payment is on it.
MoveNote? moveNoteOf({required LocalDate date, LocalDate? originalDate}) {
  if (originalDate == null || date == originalDate) return null;
  return date > originalDate ? MoveNote.later : MoveNote.earlier;
}

/// Payment [seq] moved alone to [newDate] lands after the next unpaid
/// payment (by number): the numbers stay, the plan lists payments by
/// date. A paid payment is settled, so it is never "the next payment".
bool passesNextPayment(
  List<MovablePayment> payments, {
  required int seq,
  required LocalDate newDate,
}) {
  MovablePayment? next;
  for (final p in payments) {
    if (p.seq > seq && !p.isPaid && (next == null || p.seq < next.seq)) {
      next = p;
    }
  }
  return next != null && newDate > next.date;
}

/// How much one period's "spoken for" changes.
class PeriodChange {
  const PeriodChange(this.period, this.spokenForDeltaMinor);

  final PayPeriod period;

  /// Positive: more spoken for (less left). Never zero.
  final int spokenForDeltaMinor;

  /// What "left" changes by when income is set.
  int get leftDeltaMinor => -spokenForDeltaMinor;

  @override
  bool operator ==(Object other) =>
      other is PeriodChange &&
      other.period == period &&
      other.spokenForDeltaMinor == spokenForDeltaMinor;

  @override
  int get hashCode => Object.hash(period, spokenForDeltaMinor);

  @override
  String toString() => 'PeriodChange($period, $spokenForDeltaMinor)';
}

/// The periods whose total changes between [before] and [after], oldest
/// first: each item counts in the period of [schedule] that contains its
/// date (callers pass counting dates, the home screen's rule). Periods
/// whose total stays the same are left out, so moving a payment within a
/// period gives an empty list.
List<PeriodChange> periodChanges({
  required Iterable<DatedAmount> before,
  required Iterable<DatedAmount> after,
  required PaySchedule schedule,
}) {
  final deltas = <PayPeriod, int>{};
  void add(Iterable<DatedAmount> items, int sign) {
    for (final item in items) {
      final period = schedule.periodContaining(item.date);
      deltas[period] = (deltas[period] ?? 0) + sign * item.amountMinor;
    }
  }

  add(before, -1);
  add(after, 1);
  return [
    for (final MapEntry(key: period, value: delta) in deltas.entries)
      if (delta != 0) PeriodChange(period, delta),
  ]..sort((a, b) => a.period.start.compareTo(b.period.start));
}

/// A "Pay later" plan edited after "Change date" (20): the recorded
/// [movedDate] stays while the purchase date, the rule and a picked date
/// are as stored; otherwise the rule decides the date again (and the note
/// goes). The one check for the edit screen and the save.
bool keepsMovedPayLaterDate({
  required LocalDate movedDate,
  required LocalDate? storedPurchase,
  required PayLaterRule? storedRule,
  required LocalDate purchase,
  required PayLaterRule rule,
  LocalDate? chosen,
}) =>
    storedPurchase == purchase &&
    storedRule == rule &&
    (chosen == null || chosen == movedDate);
