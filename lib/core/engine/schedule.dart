import '../date/local_date.dart';

enum IntervalUnit { day, week, month }

/// Moves a Saturday or Sunday to the following Monday.
LocalDate shiftToBusinessDay(LocalDate date) => switch (date.weekday) {
  DateTime.saturday => date.addDays(2),
  DateTime.sunday => date.addDays(1),
  _ => date,
};

/// How often the payments of an installment plan repeat: the same day
/// each month, or every N days (30 days, two weeks, a week, any 1-365).
///
/// Every date of such a plan comes from [dateAt], so plans set up going
/// forward, plans already underway and added installments agree.
class PaymentInterval {
  /// Same day every month, clamped to month end without drifting
  /// (31 Jan, 28 Feb, 31 Mar).
  const PaymentInterval.sameDayEachMonth() : days = null;

  /// Every [days] days (1-365).
  const PaymentInterval.everyDays(int this.days);

  static const sameDay = PaymentInterval.sameDayEachMonth();
  static const every30Days = PaymentInterval.everyDays(30);
  static const biweekly = PaymentInterval.everyDays(14);
  static const weekly = PaymentInterval.everyDays(7);

  static const minDays = 1;
  static const maxDays = 365;

  /// Null for the same day each month.
  final int? days;

  bool get isValid => switch (days) {
    null => true,
    final n => n >= minDays && n <= maxDays,
  };

  /// The interval a plan stored as [days] (null: same day each month).
  static PaymentInterval fromDays(int? days) =>
      days == null ? sameDay : PaymentInterval.everyDays(days);

  /// The date [offset] payments after (negative: before) the payment on
  /// [anchor]. Monthly dates keep [anchor]'s day of month.
  LocalDate dateAt(LocalDate anchor, int offset) => switch (days) {
    null => anchor.addMonths(offset, preferredDay: anchor.day),
    final n => anchor.addDays(n * offset),
  };

  /// [count] dates, the first on [first].
  List<LocalDate> datesFrom(LocalDate first, int count) => [
    for (var i = 0; i < count; i++) dateAt(first, i),
  ];

  @override
  bool operator ==(Object other) =>
      other is PaymentInterval && other.days == days;

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() =>
      days == null ? 'PaymentInterval.sameDay' : 'PaymentInterval($days d)';
}

/// Months that hold more than one of [dates], in date order, with how
/// many fall in each: the preview's "same month" note.
List<({int year, int month, int count})> monthsWithSeveral(
  Iterable<LocalDate> dates,
) {
  final counts = <(int, int), int>{};
  for (final d in dates) {
    counts.update((d.year, d.month), (n) => n + 1, ifAbsent: () => 1);
  }
  final months = [
    for (final MapEntry(key: (y, m), value: n) in counts.entries)
      if (n > 1) (year: y, month: m, count: n),
  ]..sort((a, b) => a.year != b.year ? a.year - b.year : a.month - b.month);
  return months;
}

/// Pay in 4: the first payment on [first], then every 14 days (or every
/// [interval]).
List<LocalDate> payIn4Dates(
  LocalDate first, {
  PaymentInterval interval = PaymentInterval.biweekly,
}) => interval.datesFrom(first, 4);

/// Same day every month, clamped to month end without drifting
/// (31 Jan, 28 Feb, 31 Mar).
List<LocalDate> monthlyDates(LocalDate first, int count) =>
    PaymentInterval.sameDay.datesFrom(first, count);

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
    final thisMonth = statementInMonth(purchase.year, purchase.month);
    if (purchase <= thisMonth) return thisMonth;
    return statementInMonth(purchase.year, purchase.month + 1);
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

  /// The statement cut in [year]/[month] (clamped in short months).
  LocalDate statementInMonth(int year, int month) =>
      LocalDate.clamped(year, month, statementDay);

  /// The statement a card installment due on [due] belongs to: the one
  /// whose due date ([dueFor]) is nearest to [due], the earlier one on a
  /// tie.
  ///
  /// The engine's one statement rule for installments, the inverse of
  /// [dueFor]: every date [cardInstallmentDates] gives maps back to its own
  /// statement (distance 0), and a date moved a few days (an edited
  /// payment, a paid one kept after the card's days or weekend setting
  /// changed, a plan started midway) stays with the statement it was
  /// moved from.
  LocalDate statementForDue(LocalDate due) {
    LocalDate? best;
    var bestDistance = 0;
    // dueFor(statement) falls in the statement's month, the next one, or
    // (shifted past a month end) the one after.
    for (var offset = -3; offset <= 1; offset++) {
      final statement = statementInMonth(due.year, due.month + offset);
      final distance = due.daysUntil(dueFor(statement)).abs();
      if (best == null || distance < bestDistance) {
        best = statement;
        bestDistance = distance;
      }
    }
    return best!;
  }

  /// The statement still to pay on [today]: the earliest one whose due
  /// date is [today] or later, already cut or not.
  LocalDate nextStatement(LocalDate today) {
    // dueFor(statement) is at most two months after the statement.
    var statement = statementInMonth(today.year, today.month - 2);
    while (dueFor(statement) < today) {
      statement = statementInMonth(statement.year, statement.month + 1);
    }
    return statement;
  }
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
        terms.statementInMonth(first.year, first.month + i + deferMonths),
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

/// The due date [offset] statements after (negative: before) the
/// statement a card payment due on [due] is paid with: the forward rule
/// ([cardInstallmentDates], one installment per statement) stepped from a
/// date the user entered. Plans already underway and plans started midway
/// get every date but the entered one from here.
///
/// The entered date's statement comes from the month whose due date it is
/// ([dueMonthOf]). On almost every card each month has exactly one
/// statement due in it, so this is the card's due date of each month, as
/// before. Only when the statement day is 28-30 and the due day a few days
/// later do short months give two statements one due date (28 Feb and
/// 28 Mar statements both due 30 Mar) and leave a month without one (no
/// statement is due in February): the dates then follow the statements,
/// never a due date in February no purchase would get. On a shared due
/// date the entered payment is the later statement's, so the payments
/// after it fall one a month; a date entered before that due date is the
/// earlier statement's, so the dates stay in order.
LocalDate dueAfterStatements(LocalDate due, CardTerms terms, int offset) {
  final month = dueMonthOf(due, terms);
  final monthDue = terms.dueInMonth(month.year, month.month);
  LocalDate? statement;
  // On a shared due date the later statement, unless the entered date is
  // before it (then it is the earlier statement's payment, and every
  // earlier payment stays before it).
  for (final back in due < monthDue ? const [-1, 0] : const [0, -1]) {
    final candidate = terms.statementInMonth(month.year, month.month + back);
    if (terms.dueFor(candidate) == monthDue) {
      statement = candidate;
      break;
    }
  }
  // No statement is due in that month (February above): the entered
  // date is paid with the first statement due on or after it, so the
  // payments before it stay before it.
  statement ??= terms.nextStatement(due);
  LocalDate step(LocalDate s, int k) =>
      terms.statementInMonth(s.year, s.month + k);
  // A weekend shift can carry the previous month's due date past an
  // entered date early in the month (31 Oct, a Saturday, is due 2 Nov;
  // 1 Nov entered): the payments stay in order around the entered date.
  while (terms.dueFor(step(statement!, -1)) > due) {
    statement = step(statement, -1);
  }
  while (terms.dueFor(step(statement!, 1)) < due) {
    statement = step(statement, 1);
  }
  return terms.dueFor(step(statement, offset));
}

/// Card plan started midway: the next payment is on [nextDue] as the user
/// entered it; later payments follow the card's statements
/// ([dueAfterStatements]).
List<LocalDate> cardDatesFromNextDue({
  required LocalDate nextDue,
  required CardTerms terms,
  required int count,
}) => [
  for (var i = 0; i < count; i++)
    i == 0 ? nextDue : dueAfterStatements(nextDue, terms, i),
];
