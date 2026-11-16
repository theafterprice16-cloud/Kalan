import 'plan_calculator.dart';
import 'split.dart';

/// Which amount the user types for a plan with several payments: the
/// plan's total or one installment. The other one is worked out; the
/// engine always builds the plan from the total.
enum AmountEntry { total, installment }

/// The largest total worked out from an installment: the largest integer
/// that stays exact on every platform Kalan builds for (2^53 - 1).
const maxEntryTotalMinor = 9007199254740991;

/// The total of [count] installments of [installmentMinor] each. Nothing
/// is left over: every installment is the same.
///
/// Throws [InvalidPlanInput] for a count outside 1-[PlanCalculator.maxInstallments],
/// an installment under one minor unit, or a total above
/// [maxEntryTotalMinor].
int totalFromInstallment({required int installmentMinor, required int count}) {
  if (count < 1 || count > PlanCalculator.maxInstallments) {
    throw const InvalidPlanInput('count');
  }
  if (installmentMinor < 1) throw const InvalidPlanInput('installment');
  if (installmentMinor > maxEntryTotalMinor ~/ count) {
    throw const InvalidPlanInput('total');
  }
  return installmentMinor * count;
}

/// How a total is shared out: the first installment, which carries the
/// leftover minor units, and each of the others.
class InstallmentSplit {
  const InstallmentSplit({
    required this.count,
    required this.first,
    required this.others,
  });

  final int count;
  final int first;

  /// Each installment after the first: the total divided by the count,
  /// rounded down.
  final int others;

  /// Every installment is the same (always for a single one).
  bool get isEven => first == others;

  int get othersCount => count - 1;

  @override
  bool operator ==(Object other) =>
      other is InstallmentSplit &&
      other.count == count &&
      other.first == first &&
      other.others == others;

  @override
  int get hashCode => Object.hash(count, first, others);

  @override
  String toString() => 'InstallmentSplit($count: $first, $others)';
}

/// The installments [splitEvenly] makes of [totalMinor] in [count]
/// payments, summed up. Works in minor units for every currency: the
/// leftover is whole yen for JPY and fils for KWD.
///
/// Throws [InvalidPlanInput] when the plan could not be built from these
/// inputs either.
InstallmentSplit installmentSplit({
  required int totalMinor,
  required int count,
}) {
  if (count < 1 || count > PlanCalculator.maxInstallments) {
    throw const InvalidPlanInput('count');
  }
  if (totalMinor < count) throw const InvalidPlanInput('total');
  final parts = splitEvenly(totalMinor, count);
  return InstallmentSplit(count: count, first: parts.first, others: parts.last);
}
