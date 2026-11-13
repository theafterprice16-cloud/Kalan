import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// Statement on the 20th, due 10 days later (the 30th).
const card = CardTerms(statementDay: 20, dueDay: 30);
const cardNoShift = CardTerms(
  statementDay: 20,
  dueDay: 30,
  shiftDueToBusinessDay: false,
);

void main() {
  group('monthly: backwards from the next payment', () {
    // next, paid, total, expected dates
    final cases = <(LocalDate, int, int, List<LocalDate>)>[
      // Mehmet: 3 of 10 paid, next on 5 Dec 2026.
      (
        d(2026, 12, 5),
        3,
        10,
        [
          d(2026, 9, 5), d(2026, 10, 5), d(2026, 11, 5), d(2026, 12, 5), //
          d(2027, 1, 5), d(2027, 2, 5), d(2027, 3, 5), d(2027, 4, 5),
          d(2027, 5, 5), d(2027, 6, 5),
        ],
      ),
      // Month end: the 31st clamps without drifting.
      (
        d(2027, 3, 31),
        2,
        6,
        [
          d(2027, 1, 31), d(2027, 2, 28), d(2027, 3, 31), d(2027, 4, 30), //
          d(2027, 5, 31), d(2027, 6, 30),
        ],
      ),
      // The 30th in February.
      (d(2027, 3, 30), 1, 3, [d(2027, 2, 28), d(2027, 3, 30), d(2027, 4, 30)]),
      // The 29th in a leap year.
      (d(2028, 3, 29), 1, 2, [d(2028, 2, 29), d(2028, 3, 29)]),
      // Year change.
      (
        d(2027, 2, 15),
        3,
        5,
        [
          d(2026, 11, 15), d(2026, 12, 15), d(2027, 1, 15), d(2027, 2, 15), //
          d(2027, 3, 15),
        ],
      ),
    ];
    for (final (next, paid, total, expected) in cases) {
      test('$next, $paid of $total paid', () {
        expect(
          underwayDates(
            nextDate: next,
            paidCount: paid,
            totalCount: total,
            pattern: const MonthlyPattern(),
          ),
          expected,
        );
      });
    }

    // Going forward from the first date gives the same list (whenever the
    // first date keeps the plan's day of month).
    final consistency = <(LocalDate, int, int)>[
      (d(2026, 12, 5), 3, 10),
      (d(2027, 3, 31), 2, 6),
      (d(2027, 2, 15), 3, 5),
      (d(2026, 8, 31), 7, 12),
      (d(2027, 1, 1), 1, 24),
    ];
    for (final (next, paid, total) in consistency) {
      test('forward from the first date: $next, $paid of $total', () {
        final back = underwayDates(
          nextDate: next,
          paidCount: paid,
          totalCount: total,
          pattern: const MonthlyPattern(),
        );
        expect(back.first.day, next.day);
        expect(monthlyDates(back.first, total), back);
        expect(back[paid], next);
      });
    }
  });

  group('Pay in 4', () {
    final cases = <(int, List<LocalDate>)>[
      (1, [d(2026, 11, 6), d(2026, 11, 20), d(2026, 12, 4), d(2026, 12, 18)]),
      (2, [d(2026, 10, 23), d(2026, 11, 6), d(2026, 11, 20), d(2026, 12, 4)]),
      (3, [d(2026, 10, 9), d(2026, 10, 23), d(2026, 11, 6), d(2026, 11, 20)]),
    ];
    for (final (paid, expected) in cases) {
      test('$paid paid, next 20 Nov 2026', () {
        final back = underwayDates(
          nextDate: d(2026, 11, 20),
          paidCount: paid,
          totalCount: 4,
          pattern: const PayIn4Pattern(),
        );
        expect(back, expected);
        expect(payIn4Dates(back.first), back);
      });
    }
  });

  group('card: the card cycle backwards', () {
    // terms, next, paid, total, expected
    final cases = <(CardTerms, LocalDate, int, int, List<LocalDate>)>[
      // Example 4: 4 of 9 paid, next due Monday 30 Nov 2026. 30 Aug 2026 is
      // a Sunday, so that due date moved to Monday 31 Aug.
      (
        card,
        d(2026, 11, 30),
        4,
        9,
        [
          d(2026, 7, 30), d(2026, 8, 31), d(2026, 9, 30), d(2026, 10, 30), //
          d(2026, 11, 30), d(2026, 12, 30), d(2027, 2, 1), d(2027, 3, 1),
          d(2027, 3, 30),
        ],
      ),
      // Without the weekend shift the nominal days stay.
      (
        cardNoShift,
        d(2026, 11, 30),
        4,
        9,
        [
          d(2026, 7, 30), d(2026, 8, 30), d(2026, 9, 30), d(2026, 10, 30), //
          d(2026, 11, 30), d(2026, 12, 30), d(2027, 1, 30), d(2027, 2, 28),
          d(2027, 3, 30),
        ],
      ),
      // A shifted next due (Sat 30 Jan 2027 -> Mon 1 Feb) is recognised as
      // January's.
      (
        card,
        d(2027, 2, 1),
        2,
        4,
        [d(2026, 11, 30), d(2026, 12, 30), d(2027, 2, 1), d(2027, 3, 1)],
      ),
    ];
    for (final (terms, next, paid, total, expected) in cases) {
      test('${terms.shiftDueToBusinessDay ? 'shift' : 'no shift'}: '
          '$next, $paid of $total', () {
        final back = underwayDates(
          nextDate: next,
          paidCount: paid,
          totalCount: total,
          pattern: CardPattern(terms),
        );
        expect(back, expected);
        // Same as the card plan bought on the first statement date, and as
        // the existing "from next due" rule run from the first date.
        final statement = LocalDate.clamped(
          dueMonthOf(back.first, terms).year,
          dueMonthOf(back.first, terms).month,
          terms.statementDay,
        );
        expect(
          cardInstallmentDates(
            purchaseDate: statement,
            terms: terms,
            count: total,
          ),
          back,
        );
        expect(
          cardDatesFromNextDue(nextDue: back.first, terms: terms, count: total),
          back,
        );
      });
    }
  });

  group('suggested next due for a card', () {
    // today -> first due date after it
    final cases = <(CardTerms, LocalDate, LocalDate)>[
      (card, d(2026, 11, 13), d(2026, 11, 30)),
      (card, d(2026, 11, 20), d(2026, 11, 30)), // statement day
      (card, d(2026, 11, 29), d(2026, 11, 30)),
      (card, d(2026, 11, 30), d(2026, 12, 30)), // due today: the next one
      (card, d(2026, 12, 31), d(2027, 2, 1)), // Sat 30 Jan -> Mon 1 Feb
      (cardNoShift, d(2026, 12, 31), d(2027, 1, 30)),
      (card, d(2027, 1, 31), d(2027, 2, 1)), // shifted into February
      (cardNoShift, d(2027, 1, 31), d(2027, 2, 28)),
    ];
    for (final (terms, today, expected) in cases) {
      test('$today -> $expected', () {
        expect(nextCardDueAfter(today, terms), expected);
      });
    }
  });

  group('drafts', () {
    test('Mehmet: 10 payments of 850, the first 3 paid before Kalan', () {
      final draft = underwayPlan(
        kind: PlanKind.monthly,
        totalMinor: 850000,
        count: 10,
        paidCount: 3,
        nextDate: d(2026, 12, 5),
      );
      expect(draft.paidBeforeCount, 3);
      expect(draft.installmentCount, 10);
      expect(draft.payments.map((p) => p.seq), [
        for (var i = 1; i <= 10; i++) i,
      ]);
      expect(draft.payments.every((p) => p.amountMinor == 85000), isTrue);
      final before = draft.payments.take(3);
      expect(before.fold(0, (s, p) => s + p.amountMinor), 255000);
      expect(draft.payments[3].date, d(2026, 12, 5));
    });

    test(
      'leftover minor units stay on the first payment, as for new plans',
      () {
        final draft = underwayPlan(
          kind: PlanKind.monthly,
          totalMinor: 10003,
          count: 10,
          paidCount: 2,
          nextDate: d(2026, 12, 5),
        );
        expect(
          draft.payments.map((p) => p.amountMinor),
          splitEvenly(10003, 10),
        );
        expect(draft.payments.first.amountMinor, 1003);
        expect(draft.totalMinor, 10003);
      },
    );

    test('card and Pay in 4 kinds', () {
      final c = underwayPlan(
        kind: PlanKind.card,
        totalMinor: 900000,
        count: 9,
        paidCount: 4,
        nextDate: d(2026, 11, 30),
        terms: card,
      );
      expect(c.kind, PlanKind.card);
      expect(c.purchaseDate, isNull);
      expect(c.payments[4].date, d(2026, 11, 30));
      final p4 = underwayPlan(
        kind: PlanKind.payIn4,
        totalMinor: 40000,
        count: 4,
        paidCount: 2,
        nextDate: d(2026, 11, 20),
      );
      expect(p4.payments.map((p) => p.date), [
        d(2026, 10, 23),
        d(2026, 11, 6),
        d(2026, 11, 20),
        d(2026, 12, 4),
      ]);
    });

    test('manual entry: the entered dates stay, the first N are paid', () {
      final manual = PlanCalculator.manual(
        firstDate: d(2026, 9, 1),
        totalMinor: 60000,
        count: 6,
        unit: IntervalUnit.week,
        step: 2,
      );
      final marked = markPaidBefore(manual, 2);
      expect(marked.paidBeforeCount, 2);
      expect(marked.payments, manual.payments);
      expect(manual.paidBeforeCount, 0);
    });

    test('IDR: the paid-before total has no decimals', () {
      final draft = underwayPlan(
        kind: PlanKind.monthly,
        totalMinor: 1000003,
        count: 3,
        paidCount: 2,
        nextDate: d(2026, 12, 5),
      );
      final before = draft.payments
          .take(draft.paidBeforeCount)
          .fold(0, (s, p) => s + p.amountMinor);
      expect(before, 666669);
      expect(
        formatMoney(before, Currency.fromCode('IDR'), localeName: 'tr'),
        'Rp666.669',
      );
    });

    // Invalid inputs.
    final invalid = <(String, PlanDraft Function())>[
      (
        'nothing paid',
        () => underwayPlan(
          kind: PlanKind.monthly,
          totalMinor: 1000,
          count: 10,
          paidCount: 0,
          nextDate: d(2026, 12, 5),
        ),
      ),
      (
        'everything paid',
        () => underwayPlan(
          kind: PlanKind.monthly,
          totalMinor: 1000,
          count: 10,
          paidCount: 10,
          nextDate: d(2026, 12, 5),
        ),
      ),
      (
        'Pay in 4 with 5 payments',
        () => underwayPlan(
          kind: PlanKind.payIn4,
          totalMinor: 1000,
          count: 5,
          paidCount: 1,
          nextDate: d(2026, 12, 5),
        ),
      ),
      (
        'card without terms',
        () => underwayPlan(
          kind: PlanKind.card,
          totalMinor: 1000,
          count: 5,
          paidCount: 1,
          nextDate: d(2026, 12, 5),
        ),
      ),
      (
        'manual plan fully paid',
        () => markPaidBefore(
          PlanCalculator.manual(
            firstDate: d(2026, 9, 1),
            totalMinor: 300,
            count: 3,
            unit: IntervalUnit.month,
          ),
          3,
        ),
      ),
    ];
    for (final (name, build) in invalid) {
      test('rejected: $name', () {
        expect(build, throwsA(isA<InvalidPlanInput>()));
      });
    }
  });
}
