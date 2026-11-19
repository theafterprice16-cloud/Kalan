import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

void main() {
  final period = PayPeriod(d('2026-11-15'), d('2026-12-15'));
  final items = [
    DatedAmount(d('2026-11-14'), 9999), // previous period
    DatedAmount(d('2026-11-15'), 100000), // first day: included
    DatedAmount(d('2026-12-01'), 50000),
    DatedAmount(d('2026-12-14'), 25000), // last day: included
    DatedAmount(d('2026-12-15'), 7777), // next period
  ];

  test('spoken for counts payments inside the period only', () {
    final s = summarizePeriod(period: period, items: items);
    expect(s.spokenForMinor, 175000);
    expect(s.itemCount, 3);
    expect(s.leftMinor, isNull);
    expect(s.status, PeriodStatus.noIncome);
  });

  group('status', () {
    final cases = <(int, int?, int?, PeriodStatus)>[
      // income, threshold, expected left, status
      (300000, null, 125000, PeriodStatus.comfortable),
      (300000, 100000, 125000, PeriodStatus.comfortable),
      (300000, 125000, 125000, PeriodStatus.comfortable),
      (300000, 125001, 125000, PeriodStatus.tight),
      (175000, 100000, 0, PeriodStatus.tight),
      (175000, null, 0, PeriodStatus.comfortable),
      (174999, 100000, -1, PeriodStatus.negative),
    ];
    for (final (income, threshold, left, status) in cases) {
      test('income $income, threshold $threshold -> $status', () {
        final s = summarizePeriod(
          period: period,
          items: items,
          incomeMinor: income,
          tightThresholdMinor: threshold,
        );
        expect(s.leftMinor, left);
        expect(s.status, status);
      });
    }
  });

  group('shortMinor', () {
    // Spoken for is 175000 in [period].
    PeriodSummary withIncome(int? income) =>
        summarizePeriod(period: period, items: items, incomeMinor: income);

    test('no income: nothing is short', () {
      expect(withIncome(null).shortMinor, isNull);
    });

    test('income equal to spoken for: left 0, not short', () {
      final s = withIncome(175000);
      expect(s.leftMinor, 0);
      expect(s.shortMinor, isNull);
      expect(s.status, isNot(PeriodStatus.negative));
    });

    test('one minor unit over: short by exactly 1', () {
      final s = withIncome(174999);
      expect(s.shortMinor, 1);
      expect(s.status, PeriodStatus.negative);
    });

    test('positive amount, the opposite of left', () {
      final s = withIncome(0);
      expect(s.shortMinor, 175000);
      expect(s.leftMinor, -175000);
    });
  });

  test('overdue means unpaid and before the current period', () {
    expect(
      isOverdue(date: d('2026-11-14'), isPaid: false, current: period),
      isTrue,
    );
    expect(
      isOverdue(date: d('2026-11-14'), isPaid: true, current: period),
      isFalse,
    );
    expect(
      isOverdue(date: d('2026-11-15'), isPaid: false, current: period),
      isFalse,
    );
  });
}
