import '../date/local_date.dart';

/// Where a plan stands (19). Three states, nothing more: open, on hold
/// while a return, cancellation or dispute is waited on, and closed.
enum PlanStatus {
  /// Every payment counts as usual.
  open,

  /// Unpaid payments are left out of every total, period, past-due list
  /// and reminder; paid ones stay where they are. Counts toward the free
  /// open plan limit (Decision 1).
  onHold,

  /// In the archive. Unpaid payments are left out everywhere; paid ones
  /// stay in history. No longer counts toward the limit.
  closed,
}

/// Why a plan was closed.
enum CloseReason { refund, cancel }

/// Whether a payment of a plan in [status] counts anywhere money is
/// summed, listed by date or reminded. The one status rule: applied once,
/// where a plan's payment list is built (`PlanWithPayments.payments`).
/// Paid payments always count, so what was paid stays in its period.
bool countsInTotals(PlanStatus status, {required bool isPaid}) =>
    isPaid || status == PlanStatus.open;

/// Whether a plan is open: not closed and not every payment paid. A plan
/// on hold stays open (it counts toward the free limit, Decision 1);
/// otherwise the plan is in the archive. The one rule: the plan list and
/// the exported spreadsheet (29) both read it.
bool planIsOpen(PlanStatus status, {required bool anyUnpaid}) =>
    status != PlanStatus.closed && anyUnpaid;

/// The day of the hold on which the plan asks "Still waiting on the
/// return?": the day it was put on hold is day 1.
const holdCheckOnDay = 30;

/// Whether a plan on hold since [since] (or since "Keep on hold" was last
/// chosen) asks again on [today]: from its 30th day on, counting [since]
/// as day 1. Never a notification; only a line on the plan.
bool holdCheckDue({required LocalDate since, required LocalDate today}) =>
    since.daysUntil(today) + 1 >= holdCheckOnDay;

/// Unpaid payments whose date passed while the plan was on hold, from
/// [heldSince] up to the day it was reopened ([reopenedOn], excluded).
int passedDuringHold({
  required Iterable<({LocalDate date, bool isPaid})> payments,
  required LocalDate heldSince,
  required LocalDate reopenedOn,
}) => payments
    .where(
      (p) =>
          !p.isPaid &&
          heldSince.daysUntil(p.date) >= 0 &&
          p.date.daysUntil(reopenedOn) > 0,
    )
    .length;
