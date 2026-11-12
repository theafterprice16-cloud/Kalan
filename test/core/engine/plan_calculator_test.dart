import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

void expectTotalPreserved(PlanDraft draft, int total) {
  expect(draft.totalMinor, total);
  expect(
    draft.payments.map((p) => p.seq).toList(),
    List.generate(draft.payments.length, (i) => draft.firstTrackedSeq + i),
  );
}

void main() {
  test('pay in 4 with leftover cents on the first payment', () {
    final draft = PlanCalculator.payIn4(
      firstDate: d('2026-11-20'),
      totalMinor: 10001,
    );
    expect(draft.kind, PlanKind.payIn4);
    expect(draft.installmentCount, 4);
    expect(draft.payments.map((p) => p.amountMinor), [2501, 2500, 2500, 2500]);
    expect(draft.payments.last.date, d('2027-01-01'));
    expectTotalPreserved(draft, 10001);
  });

  test('monthly installments from the 31st', () {
    final draft = PlanCalculator.monthly(
      firstDate: d('2026-12-31'),
      totalMinor: 100000,
      count: 3,
    );
    expect(draft.payments.map((p) => p.date), [
      d('2026-12-31'),
      d('2027-01-31'),
      d('2027-02-28'),
    ]);
    expect(draft.payments.map((p) => p.amountMinor), [33334, 33333, 33333]);
    expectTotalPreserved(draft, 100000);
  });

  test('card plan keeps purchase details', () {
    final draft = PlanCalculator.card(
      purchaseDate: d('2026-11-26'),
      totalMinor: 600000,
      count: 6,
      terms: const CardTerms(statementDay: 25, dueDay: 5),
      deferMonths: 1,
      isCashAdvance: true,
    );
    expect(draft.kind, PlanKind.card);
    expect(draft.purchaseDate, d('2026-11-26'));
    expect(draft.deferMonths, 1);
    expect(draft.isCashAdvance, isTrue);
    expect(draft.payments.first.date, d('2027-02-05'));
    expectTotalPreserved(draft, 600000);
  });

  test('manual plan every 10 days', () {
    final draft = PlanCalculator.manual(
      firstDate: d('2026-11-12'),
      totalMinor: 999,
      count: 5,
      unit: IntervalUnit.day,
      step: 10,
    );
    expect(draft.kind, PlanKind.manual);
    expect(draft.payments.map((p) => p.amountMinor), [203, 199, 199, 199, 199]);
    expect(draft.payments.last.date, d('2026-12-22'));
    expectTotalPreserved(draft, 999);
  });

  group('plan started midway', () {
    test('monthly: 9 of 12 left, progress counts from 4', () {
      final draft = PlanCalculator.midway(
        totalCount: 12,
        remainingCount: 9,
        installmentMinor: 25000,
        nextDate: d('2026-11-30'),
      );
      expect(draft.kind, PlanKind.monthly);
      expect(draft.startedMidway, isTrue);
      expect(draft.firstTrackedSeq, 4);
      expect(draft.payments.length, 9);
      expect(draft.payments.last.seq, 12);
      expect(draft.payments[3].date, d('2027-02-28'));
      expect(draft.totalMinor, 225000);
    });

    test('card: later payments follow the card due day', () {
      final draft = PlanCalculator.midway(
        totalCount: 6,
        remainingCount: 2,
        installmentMinor: 50000,
        nextDate: d('2026-12-07'),
        cardTerms: const CardTerms(statementDay: 25, dueDay: 5),
      );
      expect(draft.kind, PlanKind.card);
      expect(draft.payments.map((p) => p.date), [
        d('2026-12-07'),
        d('2027-01-05'),
      ]);
      expect(draft.payments.map((p) => p.seq), [5, 6]);
    });

    test('every two weeks is a manual plan', () {
      final draft = PlanCalculator.midway(
        totalCount: 4,
        remainingCount: 4,
        installmentMinor: 2500,
        nextDate: d('2026-11-20'),
        unit: IntervalUnit.week,
        step: 2,
      );
      expect(draft.kind, PlanKind.manual);
      expect(draft.startedMidway, isFalse);
    });

    test('rejects remaining greater than total', () {
      expect(
        () => PlanCalculator.midway(
          totalCount: 3,
          remainingCount: 4,
          installmentMinor: 1,
          nextDate: d('2026-11-20'),
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
    });
  });

  group('invalid inputs', () {
    final cases = <(String, PlanDraft Function())>[
      (
        'zero count',
        () => PlanCalculator.monthly(
          firstDate: d('2026-11-12'),
          totalMinor: 100,
          count: 0,
        ),
      ),
      (
        'total smaller than count',
        () => PlanCalculator.monthly(
          firstDate: d('2026-11-12'),
          totalMinor: 2,
          count: 3,
        ),
      ),
      (
        'defer beyond 12 months',
        () => PlanCalculator.card(
          purchaseDate: d('2026-11-12'),
          totalMinor: 100,
          count: 1,
          terms: const CardTerms(statementDay: 1, dueDay: 10),
          deferMonths: 13,
        ),
      ),
      (
        'too many installments',
        () => PlanCalculator.manual(
          firstDate: d('2026-11-12'),
          totalMinor: 100000,
          count: 121,
          unit: IntervalUnit.day,
        ),
      ),
    ];
    for (final (name, build) in cases) {
      test(name, () => expect(build, throwsA(isA<InvalidPlanInput>())));
    }
  });

  group('card dates after the card changes', () {
    const oldTerms = CardTerms(statementDay: 25, dueDay: 5);
    const newTerms = CardTerms(statementDay: 25, dueDay: 15);

    test('purchase-based plan is rebuilt', () {
      final draft = PlanCalculator.card(
        purchaseDate: d('2026-11-20'),
        totalMinor: 3000,
        count: 3,
        terms: oldTerms,
      );
      final dates = PlanCalculator.recomputeCardDates(
        payments: draft.payments,
        installmentCount: 3,
        oldTerms: oldTerms,
        newTerms: newTerms,
        purchaseDate: d('2026-11-20'),
      );
      // 15 Dec 2026 is a Tuesday; 15 Jan 2027 a Friday; 15 Feb 2027 a Monday.
      expect(dates, {
        1: d('2026-12-15'),
        2: d('2027-01-15'),
        3: d('2027-02-15'),
      });
    });

    test('midway plan keeps its months', () {
      final draft = PlanCalculator.midway(
        totalCount: 6,
        remainingCount: 2,
        installmentMinor: 1000,
        nextDate: d('2026-12-07'),
        cardTerms: oldTerms,
      );
      final dates = PlanCalculator.recomputeCardDates(
        payments: draft.payments,
        installmentCount: 6,
        oldTerms: oldTerms,
        newTerms: newTerms,
      );
      expect(dates, {5: d('2026-12-15'), 6: d('2027-01-15')});
    });
  });
}
