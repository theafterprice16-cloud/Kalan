import 'payment_edit.dart';

/// Why "Adjust amount" cannot store a new total.
enum AdjustRejection {
  /// Less than what is already paid.
  belowPaid,

  /// More than the plan's current total: an adjustment only lowers it.
  aboveTotal,

  /// The same as the current total: nothing to change.
  unchanged,

  /// Exactly what is paid: no payment would be left. Closing the plan is
  /// offered instead.
  nothingLeft,

  /// What is left cannot give every unpaid payment at least one minor
  /// unit.
  cannotSplit,
}

sealed class AdjustResult {
  const AdjustResult();
}

class AdjustApplied extends AdjustResult {
  const AdjustApplied(this.payments);

  /// Every payment, in order; only unpaid amounts differ.
  final List<PaymentState> payments;
}

class AdjustRejected extends AdjustResult {
  const AdjustRejected(this.reason);
  final AdjustRejection reason;
}

/// The total already paid (paid before Kalan included).
int paidTotalOf(List<PaymentState> payments) =>
    payments.where((p) => p.isPaid).fold(0, (sum, p) => sum + p.amountMinor);

/// "Adjust amount" (19, Decision 4): a lower [newTotalMinor] for a plan.
///
/// Paid payments never change. What is left (`newTotal − paid`) is split
/// evenly in minor units across the unpaid payments; leftover minor units
/// go to the last one. Dates and the number of payments do not change, so
/// the payments always add up to [newTotalMinor]. Works the same for
/// every kind, card installments included. Unpaid amounts edited by hand
/// are split again too and keep their "edited" mark (it protects their
/// dates). Unlike [splitEvenly] (leftover on the first), the leftover goes
/// to the last payment here (Decision 4).
AdjustResult adjustPlanTotal(List<PaymentState> payments, int newTotalMinor) {
  final total = payments.fold(0, (sum, p) => sum + p.amountMinor);
  final paid = paidTotalOf(payments);
  if (newTotalMinor < paid) {
    return const AdjustRejected(AdjustRejection.belowPaid);
  }
  if (newTotalMinor > total) {
    return const AdjustRejected(AdjustRejection.aboveTotal);
  }
  if (newTotalMinor == total) {
    return const AdjustRejected(AdjustRejection.unchanged);
  }
  if (newTotalMinor == paid) {
    return const AdjustRejected(AdjustRejection.nothingLeft);
  }
  final unpaid = [
    for (var i = 0; i < payments.length; i++)
      if (!payments[i].isPaid) i,
  ];
  final left = newTotalMinor - paid;
  if (left < unpaid.length) {
    return const AdjustRejected(AdjustRejection.cannotSplit);
  }
  final base = left ~/ unpaid.length;
  final extra = left - base * unpaid.length;
  final next = [...payments];
  for (final (k, i) in unpaid.indexed) {
    final last = k == unpaid.length - 1;
    next[i] = next[i].copyWith(amountMinor: last ? base + extra : base);
  }
  return AdjustApplied(List.unmodifiable(next));
}
