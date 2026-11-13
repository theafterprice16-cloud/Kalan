import '../date/local_date.dart';

/// How a plan's payments were laid out. Stored with the plan.
enum PlanKind { payIn4, monthly, card, manual }

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

  /// The same draft with its first [count] payments paid before Kalan.
  PlanDraft withPaidBefore(int count) => PlanDraft(
    kind: kind,
    installmentCount: installmentCount,
    payments: payments,
    purchaseDate: purchaseDate,
    deferMonths: deferMonths,
    isCashAdvance: isCashAdvance,
    paidBeforeCount: count,
  );

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  int get firstTrackedSeq => payments.first.seq;

  bool get startedMidway => firstTrackedSeq > 1;
}
