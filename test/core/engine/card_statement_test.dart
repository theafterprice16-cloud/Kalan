import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

/// Example 1: statement on the 14th, due ten days later (24th), weekend
/// shift on.
const aylin = CardTerms(statementDay: 14, dueDay: 24);

var _nextId = 1;

/// Every installment of a card plan bought on [purchase], as the engine
/// dates them.
List<StatementInstallment> planOn(
  String purchase,
  CardTerms terms, {
  required int count,
  required int amountMinor,
  int planId = 1,
  int paidCount = 0,
  int deferMonths = 0,
}) {
  final dates = cardInstallmentDates(
    purchaseDate: d(purchase),
    terms: terms,
    count: count,
    deferMonths: deferMonths,
  );
  return [
    for (var i = 0; i < count; i++)
      StatementInstallment(
        paymentId: _nextId++,
        planId: planId,
        seq: i + 1,
        installmentCount: count,
        amountMinor: amountMinor,
        dueDate: dates[i],
        isPaid: i < paidCount,
      ),
  ];
}

StatementInstallment one(
  String due, {
  int amountMinor = 100000,
  int planId = 9,
  bool isPaid = false,
}) => StatementInstallment(
  paymentId: _nextId++,
  planId: planId,
  seq: 1,
  installmentCount: 1,
  amountMinor: amountMinor,
  dueDate: d(due),
  isPaid: isPaid,
);

void main() {
  group('statementForDue: back from the due date to its statement', () {
    // (terms, due, statement)
    final cases = <(String, CardTerms, String, String)>[
      ('example 1: 24 Nov (Tue)', aylin, '2026-11-24', '2026-11-14'),
      ('24 Dec (Thu)', aylin, '2026-12-24', '2026-12-14'),
      (
        'weekend shift on: Sun 24 Jan moves to Mon 25 Jan',
        aylin,
        '2027-01-25',
        '2027-01-14',
      ),
      (
        'weekend shift off: Sun 24 Jan stays',
        const CardTerms(
          statementDay: 14,
          dueDay: 24,
          shiftDueToBusinessDay: false,
        ),
        '2027-01-24',
        '2027-01-14',
      ),
      (
        'due next month: statement 25, due 5',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2026-12-07', // Sat 5 Dec -> Mon 7 Dec
        '2026-11-25',
      ),
      (
        'month end: statement 31 in April is the 30th',
        const CardTerms(statementDay: 31, dueDay: 10),
        '2026-05-11', // Sun 10 May -> Mon 11 May
        '2026-04-30',
      ),
      (
        'February: statement 30 is the 28th',
        const CardTerms(statementDay: 30, dueDay: 9),
        '2027-03-09',
        '2027-02-28',
      ),
      (
        'leap February: statement 31 is the 29th',
        const CardTerms(statementDay: 31, dueDay: 10),
        '2028-03-10',
        '2028-02-29',
      ),
      (
        'across the year: Dec statement due in January',
        const CardTerms(statementDay: 20, dueDay: 2),
        '2027-01-04', // Sat 2 Jan -> Mon 4 Jan
        '2026-12-20',
      ),
      (
        'an edited date four days later stays with its statement',
        aylin,
        '2026-11-28',
        '2026-11-14',
      ),
      (
        'an edited date four days earlier stays with its statement',
        aylin,
        '2026-12-20',
        '2026-12-14',
      ),
      (
        'shift turned off: a paid Monday date stays with its statement',
        const CardTerms(
          statementDay: 14,
          dueDay: 24,
          shiftDueToBusinessDay: false,
        ),
        '2027-01-25',
        '2027-01-14',
      ),
      (
        'due day moved 10 -> 5: a paid 10 Mar stays on the Feb statement',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2027-03-10',
        '2027-02-25',
      ),
      (
        'a date on the statement day belongs to that statement',
        aylin,
        '2026-11-14',
        '2026-11-14',
      ),
    ];
    for (final (name, terms, due, statement) in cases) {
      test(name, () {
        expect(terms.statementForDue(d(due)), d(statement));
      });
    }
  });

  group('cardStatements groups the engine\'s card dates exactly', () {
    // Every statement day and due day, both weekend settings, two years of
    // purchases: each installment the engine dates lands on the statement
    // it came from, also when short months give two statements one due
    // date (statement 28, due 30).
    for (var statementDay = 1; statementDay <= 31; statementDay++) {
      test('statement day $statementDay', () {
        for (var dueDay = 1; dueDay <= 31; dueDay++) {
          if (dueDay == statementDay) continue;
          for (final shift in [true, false]) {
            final terms = CardTerms(
              statementDay: statementDay,
              dueDay: dueDay,
              shiftDueToBusinessDay: shift,
            );
            for (var day = 0; day < 730; day += 11) {
              final purchase = d('2026-01-01').addDays(day);
              final items = planOn(
                purchase.toString(),
                terms,
                count: 6,
                amountMinor: 1,
              );
              final statements = cardStatements(
                terms: terms,
                today: purchase,
                installments: items,
                count: 8,
              );
              final first = terms.statementFor(purchase);
              for (var i = 0; i < items.length; i++) {
                final holder = statements.where(
                  (s) => s.installments.contains(items[i]),
                );
                expect(
                  holder.single.statementDate,
                  terms.statementInMonth(first.year, first.month + i),
                  reason:
                      '$statementDay/$dueDay shift $shift, '
                      'purchase $purchase, installment ${i + 1}',
                );
                expect(holder.single.dueDate, items[i].dueDate);
              }
            }
          }
        }
      });
    }
  });

  group('cardStatements', () {
    test(
      'example 1: today 19 Nov, the 14 Nov statement is closed and next',
      () {
        final statements = cardStatements(
          terms: aylin,
          today: d('2026-11-19'),
          installments: const [],
        );
        expect(statements, hasLength(cardStatementCount));
        expect(
          [for (final s in statements) s.statementDate],
          [
            d('2026-11-14'),
            d('2026-12-14'),
            d('2027-01-14'),
            d('2027-02-14'),
            d('2027-03-14'),
            d('2027-04-14'),
          ],
        );
        expect(
          [for (final s in statements) s.dueDate],
          [
            d('2026-11-24'),
            d('2026-12-24'),
            d('2027-01-25'), // Sunday 24 Jan moves to Monday
            d('2027-02-24'),
            d('2027-03-24'),
            d('2027-04-26'), // Saturday 24 Apr moves to Monday
          ],
        );
        expect(
          [for (final s in statements) s.isClosed],
          [true, false, false, false, false, false],
        );
      },
    );

    test('example 1: three installments, 4.150 TL, due 24 Nov', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-19'),
        installments: [
          ...planOn('2026-10-20', aylin, count: 3, amountMinor: 150000),
          ...planOn(
            '2026-09-01',
            aylin,
            count: 6,
            amountMinor: 120000,
            planId: 2,
          ),
          ...planOn(
            '2026-11-02',
            aylin,
            count: 2,
            amountMinor: 145000,
            planId: 3,
          ),
        ],
      );
      final next = statements.first;
      expect(next.statementDate, d('2026-11-14'));
      expect(next.count, 3);
      expect(next.totalMinor, 415000);
      expect(next.dueDate, d('2026-11-24'));
    });

    test('the next statement is the first due today or later', () {
      // On the due day the statement is still the one to pay.
      expect(
        cardStatements(
          terms: aylin,
          today: d('2026-11-24'),
          installments: const [],
        ).first.statementDate,
        d('2026-11-14'),
      );
      // The day after, the next statement takes its place, not cut yet.
      final after = cardStatements(
        terms: aylin,
        today: d('2026-11-25'),
        installments: const [],
      ).first;
      expect(after.statementDate, d('2026-12-14'));
      expect(after.isClosed, isFalse);
    });

    test('on the statement day the statement is not closed yet', () {
      final first = cardStatements(
        terms: aylin,
        today: d('2026-12-14'),
        installments: const [],
      ).first;
      expect(first.statementDate, d('2026-12-14'));
      expect(first.isClosed, isFalse);
    });

    test('example 2: a purchase on the statement day lands on it', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-14'),
        installments: planOn('2026-11-14', aylin, count: 3, amountMinor: 1000),
      );
      expect([for (final s in statements.take(4)) s.count], [1, 1, 1, 0]);
      expect(statements.first.installments.single.seq, 1);
    });

    test('a purchase the day after the statement day starts next month', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-14'),
        installments: planOn('2026-11-15', aylin, count: 2, amountMinor: 1000),
      );
      expect([for (final s in statements.take(3)) s.count], [0, 1, 1]);
    });

    test('example 3: paid installments count in the total', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-19'),
        installments: [
          one('2026-11-24', amountMinor: 100000, isPaid: true),
          one('2026-11-24', amountMinor: 50000, planId: 10),
        ],
      );
      expect(statements.first.count, 2);
      expect(statements.first.totalMinor, 150000);
      expect(statements.first.installments.first.isPaid, isTrue);
    });

    test('installments before the next or after the sixth are left out', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-19'),
        installments: planOn('2026-08-01', aylin, count: 12, amountMinor: 1000),
      );
      // Aug statement onward: Aug..Oct are past, Nov..Apr shown, May..Jul
      // after the sixth.
      expect([for (final s in statements) s.count], [1, 1, 1, 1, 1, 1]);
      expect(statements.first.installments.single.seq, 4);
      expect(statements.last.installments.single.seq, 9);
    });

    test('a statement without installments is empty with a zero total', () {
      final statements = cardStatements(
        terms: aylin,
        today: d('2026-11-19'),
        installments: [one('2026-12-24')],
      );
      expect(statements.first.isEmpty, isTrue);
      expect(statements.first.totalMinor, 0);
      expect(statements[1].count, 1);
    });

    test('statements roll over the year end', () {
      final statements = cardStatements(
        terms: const CardTerms(statementDay: 31, dueDay: 10),
        today: d('2026-11-20'),
        installments: const [],
      );
      expect(
        [for (final s in statements) s.statementDate],
        [
          d('2026-11-30'),
          d('2026-12-31'),
          d('2027-01-31'),
          d('2027-02-28'),
          d('2027-03-31'),
          d('2027-04-30'),
        ],
      );
    });

    test('changed card days: recomputed dates group under the new days', () {
      const before = CardTerms(statementDay: 14, dueDay: 24);
      const after = CardTerms(statementDay: 2, dueDay: 12);
      final purchase = d('2026-10-20');
      final old = cardInstallmentDates(
        purchaseDate: purchase,
        terms: before,
        count: 4,
      );
      final moved = PlanCalculator.recomputeCardDates(
        payments: [
          for (var i = 0; i < 4; i++)
            DraftPayment(seq: i + 1, date: old[i], amountMinor: 1000),
        ],
        installmentCount: 4,
        oldTerms: before,
        newTerms: after,
        purchaseDate: purchase,
      );
      final statements = cardStatements(
        terms: after,
        today: d('2026-11-19'),
        installments: [
          for (final MapEntry(key: seq, value: date) in moved.entries)
            StatementInstallment(
              paymentId: seq,
              planId: 1,
              seq: seq,
              installmentCount: 4,
              amountMinor: 1000,
              dueDate: date,
              isPaid: false,
            ),
        ],
      );
      // New days: purchase 20 Oct lands on the 2 Nov statement (due 12 Nov,
      // already past on 19 Nov); the next is 2 Dec.
      expect(statements.first.statementDate, d('2026-12-02'));
      expect([for (final s in statements.take(4)) s.count], [1, 1, 1, 0]);
      expect(statements.first.installments.single.seq, 2);
    });
  });

  group('two statements with one due date (statement 28, due 30)', () {
    const terms = CardTerms(
      statementDay: 28,
      dueDay: 30,
      shiftDueToBusinessDay: false,
    );
    // Bought 10 Jan 2027: Jan statement due 30 Jan, Feb and Mar statements
    // both due 30 Mar, Apr statement due 30 Apr.
    List<StatementInstallment> plan({LocalDate? third}) => [
      for (final (seq, due) in [
        (1, d('2027-01-30')),
        (2, d('2027-03-30')),
        (3, third ?? d('2027-03-30')),
        (4, d('2027-04-30')),
      ])
        StatementInstallment(
          paymentId: seq,
          planId: 1,
          seq: seq,
          installmentCount: 4,
          amountMinor: 1000,
          dueDate: due,
          isPaid: false,
        ),
    ];
    List<int> counts(List<StatementInstallment> items) => [
      for (final s in cardStatements(
        terms: terms,
        today: d('2027-01-20'),
        installments: items,
      ).take(4))
        s.count,
    ];

    test('the engine dates fill one statement each', () {
      expect(counts(plan()), [1, 1, 1, 1]);
    });

    test('a shared due date edited two days earlier keeps its statement', () {
      expect(counts(plan(third: d('2027-03-28'))), [1, 1, 1, 1]);
    });

    test('an edited next installment does not pull the one before', () {
      // The third moved to 20 Apr belongs to the Apr statement; the second
      // stays on Feb.
      expect(counts(plan(third: d('2027-04-20'))), [1, 1, 0, 2]);
    });
  });
}
