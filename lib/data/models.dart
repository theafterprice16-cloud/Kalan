import '../core/engine/engine.dart';
import 'db/app_database.dart';

extension SourceRowX on SourceRow {
  bool get isCard => kind == SourceKind.card;

  /// Card terms, or null for providers and incomplete cards.
  CardTerms? get cardTerms => isCard && statementDay != null && dueDay != null
      ? CardTerms(
          statementDay: statementDay!,
          dueDay: dueDay!,
          shiftDueToBusinessDay: shiftDueToBusinessDay,
        )
      : null;
}

/// Payments from the start of a plan that are not marked paid in Kalan:
/// the ones "already underway" may cover.
int leadingRunOf(List<PaymentRow> payments) {
  var run = 0;
  for (final p in payments) {
    if (p.isPaid && !p.paidBeforeKalan) break;
    run++;
  }
  return run;
}

/// The highest "installments paid" a plan can take: its leading run, and
/// always at least one payment left.
int maxPaidBeforeOf(List<PaymentRow> payments) {
  final run = leadingRunOf(payments);
  return run < payments.length ? run : payments.length - 1;
}

extension PaymentRowX on PaymentRow {
  LocalDate get date => LocalDate.fromEpochDay(dueDay);
  bool get isPaid => paidAt != null;

  PaymentState toState() => PaymentState(
    seq: seq,
    date: date,
    amountMinor: amountMinor,
    isPaid: isPaid,
    isEdited: isEdited,
  );
}

/// A plan with its source and payments ordered by seq.
class PlanWithPayments {
  const PlanWithPayments({
    required this.plan,
    required this.source,
    required this.payments,
  });

  final PlanRow plan;
  final SourceRow source;
  final List<PaymentRow> payments;

  /// The plan's title, or its source's name when untitled.
  String get displayName =>
      (plan.title?.trim().isNotEmpty ?? false) ? plan.title! : source.name;

  /// A plan is open while any payment is unpaid; then it moves to the
  /// archive.
  bool get isOpen => payments.any((p) => !p.isPaid);

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  int get remainingMinor =>
      payments.where((p) => !p.isPaid).fold(0, (sum, p) => sum + p.amountMinor);

  /// Paid before Kalan plus paid in Kalan.
  int get paidCount =>
      (payments.isEmpty ? 0 : payments.first.seq - 1) +
      payments.where((p) => p.isPaid).length;

  /// Payments paid before the plan was added to Kalan: shown only as one
  /// summary line, never one by one.
  List<PaymentRow> get paidBefore => [
    for (final p in payments)
      if (p.paidBeforeKalan) p,
  ];

  int get paidBeforeMinor =>
      paidBefore.fold(0, (sum, p) => sum + p.amountMinor);

  /// The payments to list: everything except those paid before Kalan.
  List<PaymentRow> get listedPayments => [
    for (final p in payments)
      if (!p.paidBeforeKalan) p,
  ];

  /// Plans added with only their remaining payments (before schema v4) do
  /// not have the earlier ones; they cannot be edited as "underway".
  bool get startsAtFirstPayment => payments.isEmpty || payments.first.seq == 1;

  PaymentRow? get nextUnpaid {
    for (final p in payments) {
      if (!p.isPaid) return p;
    }
    return null;
  }
}

/// A recurring payment with the occurrence days marked as paid.
class RecurringWithMarks {
  const RecurringWithMarks({required this.item, required this.paidDays});

  final RecurringPaymentRow item;
  final Set<int> paidDays;

  LocalDate get start => LocalDate.fromEpochDay(item.startDay);
  LocalDate? get end =>
      item.endDay == null ? null : LocalDate.fromEpochDay(item.endDay!);

  List<LocalDate> occurrences(LocalDate from, LocalDate toExclusive) =>
      recurringOccurrences(
        start: start,
        recurrence: item.recurrence,
        from: from,
        toExclusive: toExclusive,
        endDate: end,
      );
}
