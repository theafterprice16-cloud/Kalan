import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

DatedAmount pay(String iso, [int minor = 130000]) => DatedAmount(d(iso), minor);

void main() {
  // Monthly payday on the 15th: 15 Dec - 14 Jan.
  final december = PayPeriod(d('2026-12-15'), d('2027-01-15'));

  test('the rule lives in one place', () {
    expect(BusyWeekRule.windowDays, 7);
    expect(BusyWeekRule.minPayments, 3);
    expect(BusyWeekRule.shareNumerator / BusyWeekRule.shareDenominator, 0.5);
  });

  group('table', () {
    final cases = <(String, List<DatedAmount>, PayPeriod, BusyWeek?)>[
      (
        'example 1: 4 of 6 in 17-21 Dec is busy',
        [
          pay('2026-12-17', 100000),
          pay('2026-12-18', 150000),
          pay('2026-12-20', 120000),
          pay('2026-12-21', 150000),
          pay('2027-01-02'),
          pay('2027-01-10'),
        ],
        december,
        BusyWeek(
          first: d('2026-12-17'),
          last: d('2026-12-21'),
          count: 4,
          totalMinor: 520000,
        ),
      ),
      (
        'example 2: 3 of 10 in one week is not busy (under half)',
        [
          pay('2026-12-16'),
          pay('2026-12-17'),
          pay('2026-12-18'),
          pay('2026-12-24'),
          pay('2026-12-28'),
          pay('2027-01-01'),
          pay('2027-01-04'),
          pay('2027-01-07'),
          pay('2027-01-10'),
          pay('2027-01-14'),
        ],
        december,
        null,
      ),
      (
        '2 payments in a week is not busy, even if all of them',
        [pay('2026-12-17'), pay('2026-12-18')],
        december,
        null,
      ),
      (
        '3 payments in a week, all of the period: busy',
        [pay('2026-12-17'), pay('2026-12-18'), pay('2026-12-19')],
        december,
        BusyWeek(
          first: d('2026-12-17'),
          last: d('2026-12-19'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'exactly half (3 of 6) is busy',
        [
          pay('2026-12-17'),
          pay('2026-12-18'),
          pay('2026-12-19'),
          pay('2026-12-28'),
          pay('2027-01-05'),
          pay('2027-01-12'),
        ],
        december,
        BusyWeek(
          first: d('2026-12-17'),
          last: d('2026-12-19'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'just under half (3 of 7) is not busy',
        [
          pay('2026-12-17'),
          pay('2026-12-18'),
          pay('2026-12-19'),
          pay('2026-12-28'),
          pay('2027-01-03'),
          pay('2027-01-09'),
          pay('2027-01-14'),
        ],
        december,
        null,
      ),
      (
        'the window is 7 days: first and 8th day are not together',
        [pay('2026-12-17'), pay('2026-12-20'), pay('2026-12-24')],
        december,
        null,
      ),
      (
        'the 7th day is still inside the window',
        [pay('2026-12-17'), pay('2026-12-20'), pay('2026-12-23')],
        december,
        BusyWeek(
          first: d('2026-12-17'),
          last: d('2026-12-23'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'a window never crosses the period end',
        // 12-14 Jan in this period, 15-16 Jan in the next one.
        [
          pay('2027-01-12'),
          pay('2027-01-14'),
          pay('2027-01-15'),
          pay('2027-01-16'),
        ],
        december,
        null,
      ),
      (
        'the last days of the period still form a window',
        [pay('2027-01-12'), pay('2027-01-13'), pay('2027-01-14')],
        december,
        BusyWeek(
          first: d('2027-01-12'),
          last: d('2027-01-14'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'payments before the period start do not count',
        [
          pay('2026-12-12'),
          pay('2026-12-14'),
          pay('2026-12-15'),
          pay('2026-12-16'),
        ],
        december,
        null,
      ),
      (
        'the window with the most payments wins',
        [
          pay('2026-12-16'),
          pay('2026-12-17'),
          pay('2026-12-18'),
          pay('2027-01-05', 1),
          pay('2027-01-06', 1),
          pay('2027-01-07', 1),
          pay('2027-01-08', 1),
        ],
        december,
        BusyWeek(
          first: d('2027-01-05'),
          last: d('2027-01-08'),
          count: 4,
          totalMinor: 4,
        ),
      ),
      (
        'on a tie the earliest window wins',
        [
          pay('2026-12-16'),
          pay('2026-12-17'),
          pay('2026-12-18'),
          pay('2027-01-05'),
          pay('2027-01-06'),
          pay('2027-01-07'),
        ],
        december,
        BusyWeek(
          first: d('2026-12-16'),
          last: d('2026-12-18'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'several payments on one day count one by one',
        [pay('2026-12-20'), pay('2026-12-20'), pay('2026-12-20')],
        december,
        BusyWeek(
          first: d('2026-12-20'),
          last: d('2026-12-20'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      (
        'a biweekly period works the same way',
        [pay('2026-12-04'), pay('2026-12-05'), pay('2026-12-09')],
        PayPeriod(d('2026-12-04'), d('2026-12-18')),
        BusyWeek(
          first: d('2026-12-04'),
          last: d('2026-12-09'),
          count: 3,
          totalMinor: 390000,
        ),
      ),
      ('no payments, no busy week', [], december, null),
    ];
    for (final (name, payments, period, expected) in cases) {
      test(name, () {
        expect(busyWeekOf(period: period, planPayments: payments), expected);
      });
    }
  });

  test('order of the input does not matter', () {
    final a = busyWeekOf(
      period: december,
      planPayments: [pay('2026-12-21'), pay('2026-12-17'), pay('2026-12-19')],
    );
    expect(a?.first, d('2026-12-17'));
    expect(a?.last, d('2026-12-21'));
  });

  test('contains covers the shown range only', () {
    final w = BusyWeek(
      first: d('2026-12-17'),
      last: d('2026-12-21'),
      count: 4,
      totalMinor: 1,
    );
    expect(w.contains(d('2026-12-16')), isFalse);
    expect(w.contains(d('2026-12-17')), isTrue);
    expect(w.contains(d('2026-12-21')), isTrue);
    expect(w.contains(d('2026-12-22')), isFalse);
  });
}
