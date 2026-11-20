import '../date/local_date.dart';
import 'installment_fee.dart';
import 'pay_later.dart';
import 'schedule.dart';

/// How a plan's payments were laid out. Stored with the plan.
enum PlanKind {
  payIn4,
  monthly,
  card,
  manual,

  /// "Pay later": one payment on a set day after the purchase.
  payLater,
}

/// One payment of a draft plan. [seq] counts from the plan's first-ever
/// payment, so a plan started midway can show "4/12".
class DraftPayment {
  const DraftPayment({
    required this.seq,
    required this.date,
    required this.amountMinor,
  });

  final int seq;
  final LocalDate date;
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is DraftPayment &&
      other.seq == seq &&
      other.date == date &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(seq, date, amountMinor);

  @override
  String toString() => 'DraftPayment(#$seq $date $amountMinor)';
}

/// A plan that is not saved yet. Every way of creating a plan (template,
/// manual entry, a future screenshot reader) produces a draft that the user
/// confirms before it is stored.
class PlanDraft {
  const PlanDraft({
    required this.kind,
    required this.installmentCount,
    required this.payments,
    this.purchaseDate,
    this.deferMonths = 0,
    this.isCashAdvance = false,
    this.paidBeforeCount = 0,
    this.payLaterRule,
    this.interval,
    this.installmentFeeMinor,
    this.installmentFeeScope = InstallmentFeeScope.everyPayment,
  });

  final PlanKind kind;

  /// Total number of installments, including ones paid before the plan was
  /// added to Kalan.
  final int installmentCount;

  /// The payments Kalan tracks, ordered by [DraftPayment.seq].
  final List<DraftPayment> payments;

  /// Only for card plans built from a purchase date.
  final LocalDate? purchaseDate;
  final int deferMonths;
  final bool isCashAdvance;

  /// The first [paidBeforeCount] payments were paid before the plan was
  /// added to Kalan ("this plan is already underway"). They are stored as
  /// paid and marked so; they are never overdue and never reminded.
  final int paidBeforeCount;

  /// Only for "Pay later": how the due date was found.
  final PayLaterRule? payLaterRule;

  /// Only for "Monthly installments" and "Pay in 4": how often the
  /// payments repeat. Null for other kinds.
  final PaymentInterval? interval;

  /// The fee per payment as typed (22); null for none. Never on card
  /// installments ([canHaveInstallmentFee]).
  final int? installmentFeeMinor;

  /// Which payments take [installmentFeeMinor].
  final InstallmentFeeScope installmentFeeScope;

  /// The same draft with its first [count] payments paid before Kalan.
  PlanDraft withPaidBefore(int count) => _copy(paidBeforeCount: count);

  /// The same draft with a fee per payment (22): ignored on card
  /// installments; empty or zero is no fee. "Pay later" is always "every
  /// payment" (one payment).
  PlanDraft withInstallmentFee(int? feeMinor, InstallmentFeeScope scope) =>
      _copy(
        feeMinor: canHaveInstallmentFee(kind)
            ? normalizeInstallmentFee(feeMinor)
            : null,
        scope: kind == PlanKind.payLater
            ? InstallmentFeeScope.everyPayment
            : scope,
      );

  PlanDraft _copy({
    int? paidBeforeCount,
    int? feeMinor,
    InstallmentFeeScope? scope,
  }) => PlanDraft(
    kind: kind,
    installmentCount: installmentCount,
    payments: payments,
    purchaseDate: purchaseDate,
    deferMonths: deferMonths,
    isCashAdvance: isCashAdvance,
    paidBeforeCount: paidBeforeCount ?? this.paidBeforeCount,
    payLaterRule: payLaterRule,
    interval: interval,
    installmentFeeMinor: scope == null ? installmentFeeMinor : feeMinor,
    installmentFeeScope: scope ?? installmentFeeScope,
  );

  /// The fee the payment at [index] of [payments] takes: none for one
  /// paid before Kalan ("already underway", 22 decision 8).
  int? feeAt(int index) => index < paidBeforeCount
      ? null
      : installmentFeeFor(
          feeMinor: installmentFeeMinor,
          scope: installmentFeeScope,
          seq: payments[index].seq,
        );

  /// The installment at [index] as shown: its amount plus its fee.
  int installmentAt(int index) =>
      payments[index].amountMinor + (feeAt(index) ?? 0);

  /// "Payment fees": the fees all payments take.
  int get installmentFeesMinor =>
      [for (var i = 0; i < payments.length; i++) feeAt(i) ?? 0]
          .fold(0, (a, b) => a + b);

  /// "First payment only" while payment number 1 is paid before Kalan or
  /// not kept: the fee goes on no payment.
  bool get feeAddsNothing => firstPaymentFeeAddsNothing(
    payments: [
      for (final (i, p) in payments.indexed)
        (
          seq: p.seq,
          isPaid: i < paidBeforeCount,
          paidBeforeKalan: i < paidBeforeCount,
          feeMinor: null,
        ),
    ],
    feeMinor: installmentFeeMinor,
    scope: installmentFeeScope,
  );

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  /// "Total": the plan amount and its fees per payment (22).
  int get totalWithFeesMinor => totalMinor + installmentFeesMinor;

  int get firstTrackedSeq => payments.first.seq;

  bool get startedMidway => firstTrackedSeq > 1;
}
