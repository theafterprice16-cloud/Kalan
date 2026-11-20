import 'plan_status.dart';

/// An extra fee (21): a one-off amount a provider added to a payment (a
/// late fee, a fee for extending the due date), typed by the user. Kalan
/// never computes or suggests one. One fee per payment; a second fee is
/// recorded by correcting the amount.

/// The longest note an extra fee takes.
const extraFeeNoteMaxLength = 80;

/// What a payment adds to "spoken for": its amount plus its fee per
/// payment (22) plus its extra fee (21). The one place both fees are
/// added. The fees follow the payment: unpaid, they are still to pay with
/// it; paid, they were paid with it. Applied where period totals are made
/// (`spokenForItems`), and in reminders (`ReminderPayment.dueMinor`). A
/// plan's total never includes either fee, and neither does a card
/// statement (16; card plans have no fee per payment). The installment
/// shown includes the fee per payment ([installmentAmount]).
int spokenForAmount({
  required int amountMinor,
  int? installmentFeeMinor,
  int? extraFeeMinor,
}) =>
    installmentAmount(
      amountMinor: amountMinor,
      installmentFeeMinor: installmentFeeMinor,
    ) +
    (extraFeeMinor ?? 0);

/// The installment as shown on a payment row and in a reminder line: its
/// amount plus its fee per payment (22), without the extra fee (21),
/// which has its own note.
int installmentAmount({required int amountMinor, int? installmentFeeMinor}) =>
    amountMinor + (installmentFeeMinor ?? 0);

/// Whether a payment can take, change or lose an extra fee:
///
/// - never one paid before Kalan ("already underway"): its dates are not
///   kept, it is not listed;
/// - never on a closed plan, which is read-only (a fee it has stays
///   visible);
/// - on a plan on hold, only a paid payment (unpaid ones count nowhere);
/// - every other payment, paid or not, card installments included.
bool canHaveExtraFee({
  required PlanStatus status,
  required bool isPaid,
  required bool paidBeforeKalan,
}) =>
    !paidBeforeKalan &&
    switch (status) {
      PlanStatus.open => true,
      PlanStatus.onHold => isPaid,
      PlanStatus.closed => false,
    };

/// Why an extra fee is not stored.
enum ExtraFeeRejection {
  /// The payment does not exist.
  notFound,

  /// Paid before Kalan, on a closed plan, or unpaid on a plan on hold
  /// ([canHaveExtraFee]).
  notAllowed,

  /// Zero or less: an empty or zero fee is never stored; removing one is
  /// "Delete".
  nonPositiveAmount,

  /// The note is longer than [extraFeeNoteMaxLength].
  noteTooLong,
}

/// The note to store: trimmed, null when empty.
String? normalizeExtraFeeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Why [amountMinor] and [note] cannot be stored on a payment in this
/// state; null when they can.
ExtraFeeRejection? extraFeeRejection({
  required PlanStatus status,
  required bool isPaid,
  required bool paidBeforeKalan,
  required int amountMinor,
  String? note,
}) {
  if (!canHaveExtraFee(
    status: status,
    isPaid: isPaid,
    paidBeforeKalan: paidBeforeKalan,
  )) {
    return ExtraFeeRejection.notAllowed;
  }
  if (amountMinor <= 0) return ExtraFeeRejection.nonPositiveAmount;
  final normalized = normalizeExtraFeeNote(note);
  if (normalized != null && normalized.length > extraFeeNoteMaxLength) {
    return ExtraFeeRejection.noteTooLong;
  }
  return null;
}
