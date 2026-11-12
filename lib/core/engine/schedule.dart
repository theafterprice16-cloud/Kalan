import '../date/local_date.dart';

enum IntervalUnit { day, week, month }

/// Moves a Saturday or Sunday to the following Monday.
LocalDate shiftToBusinessDay(LocalDate date) => switch (date.weekday) {
  DateTime.saturday => date.addDays(2),
  DateTime.sunday => date.addDays(1),
  _ => date,
};

/// Pay in 4: the first payment on [first], then every 14 days.
List<LocalDate> payIn4Dates(LocalDate first) => [
  for (var i = 0; i < 4; i++) first.addDays(14 * i),
];

/// Same day every month, clamped to month end without drifting
/// (31 Jan, 28 Feb, 31 Mar).
List<LocalDate> monthlyDates(LocalDate first, int count) => [
  for (var i = 0; i < count; i++) first.addMonths(i, preferredDay: first.day),
];

/// Every [step] [unit]s starting at [first].
List<LocalDate> intervalDates(
  LocalDate first,
  int count, {
  required IntervalUnit unit,
  int step = 1,
}) {
  if (step < 1) throw ArgumentError.value(step, 'step', 'must be >= 1');
  return [
    for (var i = 0; i < count; i++)
      switch (unit) {
        IntervalUnit.day => first.addDays(i * step),
        IntervalUnit.week => first.addDays(i * step * 7),
        IntervalUnit.month => first.addMonths(
          i * step,
          preferredDay: first.day,
        ),
      },
  ];
}

/// A credit card's billing cycle.
class CardTerms {
  const CardTerms({
    required this.statementDay,
    required this.dueDay,
    this.shiftDueToBusinessDay = true,
  }) : assert(statementDay >= 1 && statementDay <= 31, 'statementDay 1-31'),
       assert(dueDay >= 1 && dueDay <= 31, 'dueDay 1-31');

  /// Day of month the statement is cut (clamped in short months).
  final int statementDay;

  /// Day of month the statement must be paid (clamped in short months).
  final int dueDay;

  /// Moves a due date on a weekend to the next Monday.
  final bool shiftDueToBusinessDay;

  /// The statement a purchase on [purchase] lands on. A purchase on the
  /// statement day itself is included in that statement.
  LocalDate statementFor(LocalDate purchase) {
    final thisMonth = LocalDate.clamped(
      purchase.year,
      purchase.month,
      statementDay,
    );
    if (purchase <= thisMonth) return thisMonth;
    return LocalDate.clamped(purchase.year, purchase.month + 1, statementDay);
  }

  /// Nominal (unshifted) due date in [year]/[month].
  LocalDate nominalDue(int year, int month) =>
      LocalDate.clamped(year, month, dueDay);

  LocalDate _shift(LocalDate date) =>
      shiftDueToBusinessDay ? shiftToBusinessDay(date) : date;

  /// The first due date strictly after [statement], shifted if enabled.
  LocalDate dueFor(LocalDate statement) {
    var nominal = nominalDue(statement.year, statement.month);
    if (nominal <= statement) {
      nominal = nominalDue(statement.year, statement.month + 1);
    }
    return _shift(nominal);
  }

  /// Due date for the month [year]/[month], shifted if enabled.
  LocalDate dueInMonth(int year, int month) => _shift(nominalDue(year, month));
}

/// Card installments: installment `i` (0-based) lands on the statement
/// `i + deferMonths` months after the purchase's statement, and is paid on
/// that statement's due date.
List<LocalDate> cardInstallmentDates({
  required LocalDate purchaseDate,
  required CardTerms terms,
  required int count,
  int deferMonths = 0,
}) {
  final first = terms.statementFor(purchaseDate);
  return [
    for (var i = 0; i < count; i++)
      terms.dueFor(
        LocalDate.clamped(
          first.year,
          first.month + i + deferMonths,
          terms.statementDay,
        ),
      ),
  ];
}

/// Finds the month whose (possibly shifted) due date is [due]. Falls back to
/// [due]'s own month when the date does not match the card's due day.
({int year, int month}) dueMonthOf(LocalDate due, CardTerms terms) {
  for (final offset in const [0, -1]) {
    final candidate = LocalDate.clamped(due.year, due.month + offset, 1);
    if (terms.dueInMonth(candidate.year, candidate.month) == due) {
      return (year: candidate.year, month: candidate.month);
    }
  }
  return (year: due.year, month: due.month);
}

/// Card plan started midway: the next payment is on [nextDue] as the user
/// entered it; later payments follow the card's due day.
List<LocalDate> cardDatesFromNextDue({
  required LocalDate nextDue,
  required CardTerms terms,
  required int count,
}) {
  final base = dueMonthOf(nextDue, terms);
  return [
    for (var i = 0; i < count; i++)
      i == 0 ? nextDue : terms.dueInMonth(base.year, base.month + i),
  ];
}
