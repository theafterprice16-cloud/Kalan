import '../date/local_date.dart';
import 'schedule.dart';

/// How many statements a card shows: the next one and five more.
const cardStatementCount = 6;

/// One installment of a card plan, as the statement view needs it.
class StatementInstallment {
  const StatementInstallment({
    required this.paymentId,
    required this.planId,
    required this.seq,
    required this.installmentCount,
    required this.amountMinor,
    required this.dueDate,
    required this.isPaid,
    this.paidBeforeKalan = false,
  });

  final int paymentId;
  final int planId;

  /// "3" of "3/10".
  final int seq;

  /// "10" of "3/10".
  final int installmentCount;
  final int amountMinor;

  /// The due date the engine stored for this payment.
  final LocalDate dueDate;
  final bool isPaid;

  /// Paid before the plan was added to Kalan: counted, never listed one by
  /// one.
  final bool paidBeforeKalan;

  @override
  String toString() =>
      'StatementInstallment(#$paymentId $seq/$installmentCount $dueDate '
      '$amountMinor${isPaid ? ' paid' : ''})';
}

/// One statement of a card: its statement and due dates and the card
/// plan installments on it, paid or not (a statement's amount does not
/// depend on what was paid).
class CardStatement {
  const CardStatement({
    required this.statementDate,
    required this.dueDate,
    required this.isClosed,
    required this.installments,
  });

  final LocalDate statementDate;
  final LocalDate dueDate;

  /// The statement date has passed; the statement is not paid yet.
  final bool isClosed;

  /// In due date order, then plan, then seq.
  final List<StatementInstallment> installments;

  int get count => installments.length;
  bool get isEmpty => installments.isEmpty;

  int get totalMinor => installments.fold(0, (sum, i) => sum + i.amountMinor);
}

/// The card's next statement and the [count] - 1 after it, each with the
/// [installments] it holds.
///
/// The next statement is [CardTerms.nextStatement]: the first one whose
/// due date is [today] or later, which the user still has to pay even
/// when it is already cut ([CardStatement.isClosed]). Each installment
/// belongs to the statement [CardTerms.statementForDue] gives for its
/// stored due date. Installments of earlier or later statements are left
/// out.
List<CardStatement> cardStatements({
  required CardTerms terms,
  required LocalDate today,
  required Iterable<StatementInstallment> installments,
  int count = cardStatementCount,
}) {
  final first = terms.nextStatement(today);
  final firstIndex = _monthIndex(first);
  LocalDate statementAt(int index) =>
      terms.statementInMonth(index ~/ 12, index % 12 + 1);

  final byPlan = <int, List<StatementInstallment>>{};
  for (final i in installments) {
    byPlan.putIfAbsent(i.planId, () => []).add(i);
  }
  final byStatement = List.generate(count, (_) => <StatementInstallment>[]);
  for (final plan in byPlan.values) {
    plan.sort((a, b) => a.seq.compareTo(b.seq));
    final indexes = [
      for (final i in plan) _monthIndex(terms.statementForDue(i.dueDate)),
    ];
    // Short months can give two statements one due date (statement 28,
    // due 30: the Feb and Mar statements are both due 30 Mar), and the
    // date alone cannot tell them apart. The engine puts a plan's
    // consecutive installments on consecutive statements, so the plan's
    // neighbours decide: a later installment on its predecessor's
    // statement moves on, and an earlier one a statement short of its
    // successor moves up. A lone payment stays on the earlier statement,
    // which is due the same day.
    bool sharesDue(int index, LocalDate due) =>
        terms.dueFor(statementAt(index)) == due;
    for (var n = 1; n < plan.length; n++) {
      if (indexes[n] <= indexes[n - 1] &&
          sharesDue(indexes[n - 1] + 1, plan[n].dueDate)) {
        indexes[n] = indexes[n - 1] + 1;
      }
    }
    for (var n = plan.length - 2; n >= 0; n--) {
      if (indexes[n + 1] - indexes[n] > 1 &&
          plan[n + 1].seq == plan[n].seq + 1 &&
          sharesDue(indexes[n] + 1, plan[n].dueDate)) {
        indexes[n] = indexes[n] + 1;
      }
    }
    for (var n = 0; n < plan.length; n++) {
      final k = indexes[n] - firstIndex;
      if (k >= 0 && k < count) byStatement[k].add(plan[n]);
    }
  }
  return [
    for (var k = 0; k < count; k++)
      () {
        final statement = statementAt(firstIndex + k);
        return CardStatement(
          statementDate: statement,
          dueDate: terms.dueFor(statement),
          isClosed: statement < today,
          installments: byStatement[k]..sort(_byDueThenPlan),
        );
      }(),
  ];
}

int _monthIndex(LocalDate date) => date.year * 12 + date.month - 1;

int _byDueThenPlan(StatementInstallment a, StatementInstallment b) {
  final byDue = a.dueDate.compareTo(b.dueDate);
  if (byDue != 0) return byDue;
  final byPlan = a.planId.compareTo(b.planId);
  return byPlan != 0 ? byPlan : a.seq.compareTo(b.seq);
}
