import '../date/local_date.dart';
import 'split.dart';

/// A stored payment as the edit rules see it.
class PaymentState {
  const PaymentState({
    required this.seq,
    required this.date,
    required this.amountMinor,
    this.isPaid = false,
    this.isEdited = false,
  });

  final int seq;
  final LocalDate date;
  final int amountMinor;
  final bool isPaid;
  final bool isEdited;

  PaymentState copyWith({LocalDate? date, int? amountMinor, bool? isEdited}) =>
      PaymentState(
        seq: seq,
        date: date ?? this.date,
        amountMinor: amountMinor ?? this.amountMinor,
        isPaid: isPaid,
        isEdited: isEdited ?? this.isEdited,
      );

  @override
  bool operator ==(Object other) =>
      other is PaymentState &&
      other.seq == seq &&
      other.date == date &&
      other.amountMinor == amountMinor &&
      other.isPaid == isPaid &&
      other.isEdited == isEdited;

  @override
  int get hashCode => Object.hash(seq, date, amountMinor, isPaid, isEdited);

  @override
  String toString() =>
      'PaymentState(#$seq $date $amountMinor'
      '${isPaid ? ' paid' : ''}${isEdited ? ' edited' : ''})';
}

enum EditRejection {
  /// Paid payments cannot be edited; unmark first.
  alreadyPaid,

  /// The new amount must be at least one minor unit.
  nonPositiveAmount,

  /// No later unpaid, unedited payment can absorb the difference.
  noAbsorbers,

  /// Absorbing the difference would push a payment to zero or below.
  absorberWouldBeNonPositive,

  /// The payment does not exist.
  notFound,
}

sealed class EditResult {
  const EditResult();
}

class EditApplied extends EditResult {
  const EditApplied(this.payments);
  final List<PaymentState> payments;
}

class EditRejected extends EditResult {
  const EditRejected(this.reason);
  final EditRejection reason;
}

/// Changes one payment's date and amount while keeping the plan total.
///
/// The amount difference is spread evenly across later payments that are
/// neither paid nor manually edited; leftover minor units go to the first
/// of them.
EditResult applyPaymentEdit(
  List<PaymentState> payments, {
  required int seq,
  required LocalDate date,
  required int amountMinor,
}) {
  final index = payments.indexWhere((p) => p.seq == seq);
  if (index < 0) return const EditRejected(EditRejection.notFound);
  final target = payments[index];
  if (target.isPaid) return const EditRejected(EditRejection.alreadyPaid);
  if (amountMinor < 1) {
    return const EditRejected(EditRejection.nonPositiveAmount);
  }

  final changed = date != target.date || amountMinor != target.amountMinor;
  final result = [...payments];
  result[index] = target.copyWith(
    date: date,
    amountMinor: amountMinor,
    isEdited: target.isEdited || changed,
  );

  final delta = target.amountMinor - amountMinor;
  if (delta == 0) return EditApplied(result);

  final absorbers = <int>[
    for (var i = 0; i < result.length; i++)
      if (result[i].seq > seq && !result[i].isPaid && !result[i].isEdited) i,
  ];
  if (absorbers.isEmpty) return const EditRejected(EditRejection.noAbsorbers);

  final parts = splitEvenly(delta.abs(), absorbers.length);
  for (var k = 0; k < absorbers.length; k++) {
    final i = absorbers[k];
    final next = result[i].amountMinor + (delta > 0 ? parts[k] : -parts[k]);
    if (next < 1) {
      return const EditRejected(EditRejection.absorberWouldBeNonPositive);
    }
    result[i] = result[i].copyWith(amountMinor: next);
  }
  return EditApplied(result);
}
