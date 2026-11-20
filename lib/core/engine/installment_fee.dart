import 'plan_draft.dart';

/// A fee per payment (22): a fixed fee a plan charges on its payments even
/// when they are paid on time (a fee for paying at a convenience store, a
/// provider's fee per installment, a service fee on the first payment).
/// Typed by the user with the plan; Kalan never computes, suggests or
/// fills one in. Different from an extra fee (21), which is added to one
/// payment later; a payment can have both.

/// Which payments of a plan take its fee per payment. Stored by name: the
/// names are kept as they are.
enum InstallmentFeeScope {
  /// Every payment (the default).
  everyPayment,

  /// Only payment number 1.
  firstPaymentOnly,
}

/// Whether a plan of [kind] can have a fee per payment: every kind except
/// card installments, whose statement estimate (16) stays as it is.
bool canHaveInstallmentFee(PlanKind kind) => kind != PlanKind.card;

/// The fee to store: null for an empty or zero fee ("no fee").
int? normalizeInstallmentFee(int? feeMinor) =>
    feeMinor == null || feeMinor <= 0 ? null : feeMinor;

/// The fee payment number [seq] takes under [feeMinor] and [scope]; null
/// when none. "First payment only" is payment number 1.
int? installmentFeeFor({
  required int? feeMinor,
  required InstallmentFeeScope? scope,
  required int seq,
}) {
  final fee = normalizeInstallmentFee(feeMinor);
  if (fee == null) return null;
  return switch (scope ?? InstallmentFeeScope.everyPayment) {
    InstallmentFeeScope.everyPayment => fee,
    InstallmentFeeScope.firstPaymentOnly => seq == 1 ? fee : null,
  };
}

/// A stored payment as the fee rule sees it.
typedef FeePayment = ({
  int seq,
  bool isPaid,
  bool paidBeforeKalan,
  int? feeMinor,
});

/// The fee each of [payments] keeps after the plan's fee becomes
/// [feeMinor] with [scope], in the same order:
///
/// - paid before Kalan ("already underway"): never a fee;
/// - paid in Kalan: its own fee, unchanged (a paid payment never changes);
/// - unpaid: the fee [installmentFeeFor] gives.
///
/// So "first payment only" with payment number 1 already paid adds the
/// fee to no payment.
List<int?> appliedInstallmentFees({
  required List<FeePayment> payments,
  required int? feeMinor,
  required InstallmentFeeScope? scope,
}) => [
  for (final p in payments)
    if (p.paidBeforeKalan)
      null
    else if (p.isPaid)
      p.feeMinor
    else
      installmentFeeFor(feeMinor: feeMinor, scope: scope, seq: p.seq),
];

/// How many unpaid payments get a different fee from this change: the
/// "This changes {count} unpaid payments." line.
int unpaidFeeChanges({
  required List<FeePayment> payments,
  required int? feeMinor,
  required InstallmentFeeScope? scope,
}) {
  final after = appliedInstallmentFees(
    payments: payments,
    feeMinor: feeMinor,
    scope: scope,
  );
  var count = 0;
  for (final (i, p) in payments.indexed) {
    if (!p.isPaid && p.feeMinor != after[i]) count++;
  }
  return count;
}

/// "First payment only" with a fee, while payment number 1 is paid (in
/// Kalan or before) or not kept: the fee goes on no payment, and the edit
/// screen says so calmly.
bool firstPaymentFeeAddsNothing({
  required List<FeePayment> payments,
  required int? feeMinor,
  required InstallmentFeeScope? scope,
}) {
  if (normalizeInstallmentFee(feeMinor) == null) return false;
  if (scope != InstallmentFeeScope.firstPaymentOnly) return false;
  final first = payments.where((p) => p.seq == 1).firstOrNull;
  return first == null || first.isPaid;
}
