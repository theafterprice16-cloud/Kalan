import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

List<LocalDate> ds(List<String> isos) => isos.map(d).toList();

void main() {
  group('shiftToBusinessDay', () {
    final cases = <(String, String)>[
      ('2026-11-14', '2026-11-16'), // Saturday
      ('2026-11-15', '2026-11-16'), // Sunday
      ('2026-11-16', '2026-11-16'), // Monday
      ('2026-05-30', '2026-06-01'), // Saturday across month end
      ('2027-01-02', '2027-01-04'), // Saturday in a new year
    ];
    for (final (input, expected) in cases) {
      test('$input -> $expected', () {
        expect(shiftToBusinessDay(d(input)), d(expected));
      });
    }
  });

  test('pay in 4: every 14 days from the first payment', () {
    expect(
      payIn4Dates(d('2026-11-20')),
      ds(['2026-11-20', '2026-12-04', '2026-12-18', '2027-01-01']),
    );
  });

  group('monthly dates clamp without drifting', () {
    final cases = <(String, int, List<String>)>[
      (
        '2026-01-31',
        4,
        ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30'],
      ),
      ('2027-12-30', 3, ['2027-12-30', '2028-01-30', '2028-02-29']),
      ('2026-11-15', 2, ['2026-11-15', '2026-12-15']),
    ];
    for (final (first, count, expected) in cases) {
      test('$first x$count', () {
        expect(monthlyDates(d(first), count), ds(expected));
      });
    }
  });

  group('interval dates', () {
    test('every 10 days', () {
      expect(
        intervalDates(d('2026-11-25'), 3, unit: IntervalUnit.day, step: 10),
        ds(['2026-11-25', '2026-12-05', '2026-12-15']),
      );
    });
    test('every 3 weeks', () {
      expect(
        intervalDates(d('2026-11-12'), 3, unit: IntervalUnit.week, step: 3),
        ds(['2026-11-12', '2026-12-03', '2026-12-24']),
      );
    });
    test('every 2 months from the 31st', () {
      expect(
        intervalDates(d('2026-08-31'), 3, unit: IntervalUnit.month, step: 2),
        ds(['2026-08-31', '2026-10-31', '2026-12-31']),
      );
    });
  });

  group('card statement placement', () {
    const terms = CardTerms(statementDay: 25, dueDay: 5);
    final cases = <(String, String)>[
      ('2026-11-20', '2026-11-25'), // before statement day
      ('2026-11-25', '2026-11-25'), // on statement day: included
      ('2026-11-26', '2026-12-25'), // after statement day
      ('2026-12-31', '2027-01-25'), // year boundary
    ];
    for (final (purchase, statement) in cases) {
      test('purchase $purchase -> statement $statement', () {
        expect(terms.statementFor(d(purchase)), d(statement));
      });
    }

    test('statement day 31 clamps to February end', () {
      const t = CardTerms(statementDay: 31, dueDay: 10);
      expect(t.statementFor(d('2026-02-15')), d('2026-02-28'));
      expect(t.statementFor(d('2026-01-31')), d('2026-01-31'));
      expect(t.statementFor(d('2028-02-29')), d('2028-02-29'));
    });
  });

  group('card installment dates', () {
    final cases = <(String, CardTerms, String, int, int, List<String>)>[
      (
        'before statement day; first due on a Saturday shifts to Monday',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2026-11-20',
        3,
        0,
        ['2026-12-07', '2027-01-05', '2027-02-05'],
      ),
      (
        'on statement day',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2026-11-25',
        1,
        0,
        ['2026-12-07'],
      ),
      (
        'after statement day moves to next statement',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2026-11-26',
        3,
        0,
        ['2027-01-05', '2027-02-05', '2027-03-05'],
      ),
      (
        'weekend shift off keeps Saturday',
        const CardTerms(
          statementDay: 25,
          dueDay: 5,
          shiftDueToBusinessDay: false,
        ),
        '2026-11-20',
        1,
        0,
        ['2026-12-05'],
      ),
      (
        'due day later in the same month; Sunday shifts',
        const CardTerms(statementDay: 5, dueDay: 15),
        '2026-02-03',
        2,
        0,
        ['2026-02-16', '2026-03-16'],
      ),
      (
        'due day 30 in February clamps to 28, Saturday shifts',
        const CardTerms(statementDay: 15, dueDay: 30),
        '2026-02-10',
        2,
        0,
        ['2026-03-02', '2026-03-30'],
      ),
      (
        'statement day 31 in February',
        const CardTerms(statementDay: 31, dueDay: 10),
        '2026-02-15',
        2,
        0,
        ['2026-03-10', '2026-04-10'],
      ),
      (
        'first installment deferred by 3 months',
        const CardTerms(statementDay: 25, dueDay: 5),
        '2026-11-20',
        2,
        3,
        ['2027-03-05', '2027-04-05'],
      ),
    ];
    for (final (name, terms, purchase, count, defer, expected) in cases) {
      test(name, () {
        expect(
          cardInstallmentDates(
            purchaseDate: d(purchase),
            terms: terms,
            count: count,
            deferMonths: defer,
          ),
          ds(expected),
        );
      });
    }
  });

  group('card plan started midway', () {
    test('next due entered as a shifted Monday keeps its month', () {
      const terms = CardTerms(statementDay: 15, dueDay: 30);
      expect(
        cardDatesFromNextDue(nextDue: d('2026-08-31'), terms: terms, count: 3),
        ds(['2026-08-31', '2026-09-30', '2026-10-30']),
      );
    });
    test('shift that crosses into the next month', () {
      const terms = CardTerms(statementDay: 20, dueDay: 31);
      // 31 Jan 2027 is a Sunday -> 1 Feb; 28 Feb 2027 Sunday -> 1 Mar.
      expect(
        cardDatesFromNextDue(nextDue: d('2027-02-01'), terms: terms, count: 3),
        ds(['2027-02-01', '2027-03-01', '2027-03-31']),
      );
    });
    test('date that does not match the due day keeps the entered date', () {
      const terms = CardTerms(statementDay: 25, dueDay: 5);
      expect(
        cardDatesFromNextDue(nextDue: d('2026-12-09'), terms: terms, count: 2),
        ds(['2026-12-09', '2027-01-05']),
      );
    });
  });
}
