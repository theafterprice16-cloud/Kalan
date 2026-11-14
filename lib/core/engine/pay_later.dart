import '../date/local_date.dart';
import 'plan_calculator.dart' show InvalidPlanInput;

/// How a "Pay later" due date is found from the purchase date.
enum PayLaterRuleKind {
  /// The purchase date plus a number of days (14, 30 or any 1-180).
  days,

  /// The given day of the month after the purchase; the month's last day
  /// when it has no such day.
  nextMonthDay,

  /// A date the user picked.
  chosenDate,
}

/// The rule of a "Pay later" plan, stored with it so the due date can be
/// worked out again when the purchase date changes.
class PayLaterRule {
  const PayLaterRule.days(int this.value) : kind = PayLaterRuleKind.days;

  const PayLaterRule.nextMonthDay(int this.value)
    : kind = PayLaterRuleKind.nextMonthDay;

  const PayLaterRule.chosenDate()
    : kind = PayLaterRuleKind.chosenDate,
      value = null;

  /// Rebuilds a stored rule; null when the stored values do not fit.
  static PayLaterRule? from(PayLaterRuleKind? kind, int? value) {
    final rule = switch (kind) {
      PayLaterRuleKind.days when value != null => PayLaterRule.days(value),
      PayLaterRuleKind.nextMonthDay when value != null =>
        PayLaterRule.nextMonthDay(value),
      PayLaterRuleKind.chosenDate => const PayLaterRule.chosenDate(),
      _ => null,
    };
    return rule != null && rule.isValid ? rule : null;
  }

  final PayLaterRuleKind kind;

  /// Days for [PayLaterRuleKind.days], the day of the month for
  /// [PayLaterRuleKind.nextMonthDay]; null for a chosen date.
  final int? value;

  static const maxDays = 180;

  bool get isValid => switch (kind) {
    PayLaterRuleKind.days => value! >= 1 && value! <= maxDays,
    PayLaterRuleKind.nextMonthDay => value! >= 1 && value! <= 31,
    PayLaterRuleKind.chosenDate => true,
  };

  @override
  bool operator ==(Object other) =>
      other is PayLaterRule && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'PayLaterRule(${kind.name}, $value)';
}

/// The rule offered before the user has used one.
const defaultPayLaterRule = PayLaterRule.days(30);

/// The due date of a "Pay later" purchase on [purchase]: a date only, no
/// time, and no weekend shift (the provider sets the date, not Kalan).
///
/// - days: [purchase] + N days;
/// - next month on the N-th: the month after [purchase], the N-th, or that
///   month's last day when it is shorter (the engine's month-end rule,
///   [LocalDate.addMonths]);
/// - chosen date: [chosen].
///
/// Throws [InvalidPlanInput] for an out-of-range rule or a missing chosen
/// date.
LocalDate payLaterDueDate({
  required LocalDate purchase,
  required PayLaterRule rule,
  LocalDate? chosen,
}) {
  if (!rule.isValid) throw const InvalidPlanInput('payLaterRule');
  return switch (rule.kind) {
    PayLaterRuleKind.days => purchase.addDays(rule.value!),
    PayLaterRuleKind.nextMonthDay => purchase.addMonths(
      1,
      preferredDay: rule.value,
    ),
    PayLaterRuleKind.chosenDate =>
      chosen ?? (throw const InvalidPlanInput('dueDate')),
  };
}
