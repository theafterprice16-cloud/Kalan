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
