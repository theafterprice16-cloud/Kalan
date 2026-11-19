import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

/// The rule before statement stepping: the card's due date of each month.
LocalDate oldDueAfter(LocalDate due, CardTerms terms, int offset) {
  final base = dueMonthOf(due, terms);
  return terms.dueInMonth(base.year, base.month + offset);
}

LocalDate oldNextDueAfter(LocalDate today, CardTerms terms) {
  for (var k = 0; k < 3; k++) {
    final due = terms.dueInMonth(today.year, today.month + k);
    if (due > today) return due;
  }
  return terms.dueInMonth(today.year, today.month + 3);
}

/// Two statements share a due date somewhere in four years: a statement
/// day of 28-30 with the due day a few days later.
bool sharesDueDates(CardTerms terms) {
  LocalDate? previous;
  for (var m = 0; m < 48; m++) {
    final due = terms.dueFor(terms.statementInMonth(2026, 1 + m));
    if (previous != null && due <= previous) return true;
    previous = due;
  }
  return false;
}

Iterable<CardTerms> allTerms() sync* {
  for (var s = 1; s <= 31; s++) {
    for (var due = 1; due <= 31; due++) {
      if (due == s) continue;
      for (final shift in [true, false]) {
        yield CardTerms(
          statementDay: s,
          dueDay: due,
          shiftDueToBusinessDay: shift,
        );
      }
    }
  }
}

void main() {
  test('only statement days 28-30 with a later due day share due dates', () {
    final sharing = {
      for (final t in allTerms())
        if (sharesDueDates(t)) (t.statementDay, t.dueDay),
    };
    expect(sharing, {
      (28, 29),
      (28, 30),
      (28, 31),
      (29, 30),
      (29, 31),
      (30, 31),
    });
  });

  test('every other card keeps the dates it had, unless out of order', () {
    // The old grid could put the payment before an entered date after it
    // when a weekend shift carried the previous due date into the month
    // (1 Nov entered, 31 Oct due 2 Nov). Everywhere else: identical.
    var changed = 0;
    for (final terms in allTerms()) {
      if (sharesDueDates(terms)) continue;
      for (var day = 0; day < 730; day += 5) {
        final date = d('2026-01-01').addDays(day);
        final oldOrdered =
            oldDueAfter(date, terms, -1) <= date &&
            oldDueAfter(date, terms, 1) >= date;
        for (final offset in const [-3, -1, 1, 2, 5]) {
          final now = dueAfterStatements(date, terms, offset);
          if (oldOrdered) {
            expect(
              now,
              oldDueAfter(date, terms, offset),
              reason: '$terms $date $offset',
            );
          } else {
            changed++;
            expect(offset < 0 ? now <= date : now >= date, isTrue);
          }
        }
        expect(
          nextCardDueAfter(date, terms),
          oldNextDueAfter(date, terms),
          reason: '$terms $date',
        );
      }
    }
    expect(changed, lessThan(1000)); // a few shifted month starts only
  });

  test('an underway card plan lands on the dates a purchase would give', () {
    // Every card, statement days 28-30 included: entering any installment
    // of a purchase-dated plan as "next" rebuilds the same dates, unless
    // the next installment is due the same day (then the entered one is
    // taken as the later statement's).
    for (final terms in allTerms()) {
      for (var day = 0; day < 730; day += 17) {
        final purchase = d('2026-01-01').addDays(day);
        final dates = cardInstallmentDates(
          purchaseDate: purchase,
          terms: terms,
          count: 6,
        );
        final first = terms.statementFor(purchase);
        for (var paid = 1; paid < dates.length; paid++) {
          // Shared with the next statement: the entered date is taken as
          // the later statement's (checked below).
          final after = terms.statementInMonth(
            first.year,
            first.month + paid + 1,
          );
          if (terms.dueFor(after) == dates[paid]) continue;
          expect(
            underwayDates(
              nextDate: dates[paid],
              paidCount: paid,
              totalCount: dates.length,
              pattern: CardPattern(terms),
            ),
            dates,
            reason:
                '${terms.statementDay}/${terms.dueDay} ${terms.shiftDueToBusinessDay}, paid $paid, next ${dates[paid]}, $dates',
          );
        }
      }
    }
  });

  group('statement 28, due 30 (shift off)', () {
    const terms = CardTerms(
      statementDay: 28,
      dueDay: 30,
      shiftDueToBusinessDay: false,
    );

    test('underway: no February due date, one installment a statement', () {
      final dates = underwayDates(
        nextDate: d('2027-03-30'),
        paidCount: 2,
        totalCount: 5,
        pattern: const CardPattern(terms),
      );
      expect(dates, [
        d('2027-01-30'),
        d('2027-03-30'), // 28 Feb statement
        d('2027-03-30'), // 28 Mar statement (entered)
        d('2027-04-30'),
        d('2027-05-30'),
      ]);
      final statements = cardStatements(
        terms: terms,
        today: d('2027-01-20'),
        installments: [
          for (final (i, date) in dates.indexed)
            StatementInstallment(
              paymentId: i + 1,
              planId: 1,
              seq: i + 1,
              installmentCount: 5,
              amountMinor: 1000,
              dueDate: date,
              isPaid: i < 2,
              paidBeforeKalan: i < 2,
            ),
        ],
      );
      expect([for (final s in statements) s.count], [1, 1, 1, 1, 1, 0]);
    });

    test(
      'started midway: the dates after the entered one follow statements',
      () {
        expect(
          cardDatesFromNextDue(
            nextDue: d('2027-01-30'),
            terms: terms,
            count: 4,
          ),
          [d('2027-01-30'), d('2027-03-30'), d('2027-03-30'), d('2027-04-30')],
        );
      },
    );

    test('the suggested next date is never 28 February', () {
      expect(nextCardDueAfter(d('2027-02-10'), terms), d('2027-03-30'));
      expect(nextCardDueAfter(d('2027-01-10'), terms), d('2027-01-30'));
    });

    test('an entered 28 February is paid with the February statement', () {
      expect(
        underwayDates(
          nextDate: d('2027-02-28'),
          paidCount: 1,
          totalCount: 3,
          pattern: const CardPattern(terms),
        ),
        [d('2027-01-30'), d('2027-02-28'), d('2027-03-30')],
      );
    });

    test('changed card days: a midway plan follows the new statements', () {
      const before = CardTerms(statementDay: 14, dueDay: 24);
      final moved = PlanCalculator.recomputeCardDates(
        payments: [
          for (final (i, date) in [
            d('2027-02-24'),
            d('2027-03-24'),
            d('2027-04-26'),
          ].indexed)
            DraftPayment(seq: i + 4, date: date, amountMinor: 1000),
        ],
        installmentCount: 6,
        oldTerms: before,
        newTerms: terms,
      );
      expect(moved, {
        4: d('2027-03-30'),
        5: d('2027-03-30'),
        6: d('2027-04-30'),
      });
    });
  });

  test('any entered date on any card keeps the payments in order', () {
    for (final terms in allTerms()) {
      for (var day = 0; day < 730; day += sharesDueDates(terms) ? 1 : 7) {
        final next = d('2026-01-01').addDays(day);
        final dates = underwayDates(
          nextDate: next,
          paidCount: 3,
          totalCount: 6,
          pattern: CardPattern(terms),
        );
        for (var i = 1; i < dates.length; i++) {
          expect(
            dates[i] >= dates[i - 1],
            isTrue,
            reason:
                '${terms.statementDay}/${terms.dueDay} '
                '${terms.shiftDueToBusinessDay}, next $next: $dates',
          );
        }
      }
    }
  });

  test('statement 28, due 30: a free date before the shared due date', () {
    const terms = CardTerms(
      statementDay: 28,
      dueDay: 30,
      shiftDueToBusinessDay: false,
    );
    expect(
      underwayDates(
        nextDate: d('2027-03-10'),
        paidCount: 2,
        totalCount: 4,
        pattern: const CardPattern(terms),
      ),
      // 10 Mar is the 28 Feb statement's payment, paid early: the paid ones
      // stay before it, the 28 Mar statement is still due 30 Mar.
      [d('2026-12-30'), d('2027-01-30'), d('2027-03-10'), d('2027-03-30')],
    );
  });
}
