import '../date/local_date.dart';
import 'payment_edit.dart';
import 'plan_calculator.dart';
import 'split.dart';

enum ResizeRejection {
  /// Fewer installments than the paid ones plus one still to pay.
  tooFew,

  /// More than [PlanCalculator.maxInstallments].
  tooMany,

  /// What is left to pay cannot be split into that many payments of at
  /// least one minor unit (or there is no payment left to absorb it).
  cannotSplit,
}

sealed class ResizeResult {
  const ResizeResult();
}

class ResizeApplied extends ResizeResult {
  const ResizeApplied(this.payments);
  final List<PaymentState> payments;
}

class ResizeRejected extends ResizeResult {
  const ResizeRejected(this.reason);
  final ResizeRejection reason;
}

/// The smallest installment count a plan can be changed to: every paid
/// payment stays, and at least one payment is left to pay.
int minInstallmentCount(List<PaymentState> payments) {
  var lastPaid = -1;
  for (var i = 0; i < payments.length; i++) {
    if (payments[i].isPaid) lastPaid = i;
  }
  return lastPaid + 2;
}

/// Changes how many installments a plan has, keeping its total.
///
/// Paid payments and unpaid payments edited by hand keep their date and
/// amount. Shrinking removes payments from the end (never a paid one);
/// growing adds payments dated by [dateAt] (0-based index). What is left
/// to pay is split again ([splitEvenly]: leftover minor units on the
/// first) across the other unpaid payments. The same count changes
/// nothing.
ResizeResult resizePlan({
  required List<PaymentState> payments,
  required int newCount,
  required LocalDate Function(int index) dateAt,
}) {
  if (newCount > PlanCalculator.maxInstallments) {
    return const ResizeRejected(ResizeRejection.tooMany);
  }
  if (newCount < minInstallmentCount(payments) || newCount < 1) {
    return const ResizeRejected(ResizeRejection.tooFew);
  }
  if (newCount == payments.length) return ResizeApplied(payments);

  final total = payments.fold(0, (sum, p) => sum + p.amountMinor);
  final firstSeq = payments.isEmpty ? 1 : payments.first.seq;
  final next = <PaymentState>[
    ...payments.take(newCount),
    for (var i = payments.length; i < newCount; i++)
      PaymentState(seq: firstSeq + i, date: dateAt(i), amountMinor: 0),
  ];
  bool fixed(PaymentState p) => p.isPaid || p.isEdited;
  final fixedSum = next.where(fixed).fold(0, (sum, p) => sum + p.amountMinor);
  final flexible = [
    for (var i = 0; i < next.length; i++)
      if (!fixed(next[i])) i,
  ];
  final remaining = total - fixedSum;
  if (flexible.isEmpty || remaining < flexible.length) {
    return const ResizeRejected(ResizeRejection.cannotSplit);
  }
  final amounts = splitEvenly(remaining, flexible.length);
  for (var k = 0; k < flexible.length; k++) {
    final i = flexible[k];
    next[i] = next[i].copyWith(amountMinor: amounts[k]);
  }
  return ResizeApplied(List.unmodifiable(next));
}
