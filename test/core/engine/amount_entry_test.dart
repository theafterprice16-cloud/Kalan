import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

import '../date/local_date_test.dart' show d;

void main() {
  group('totalFromInstallment', () {
    test('multiplies: 850 TL x 9 is 7,650 TL', () {
      expect(totalFromInstallment(installmentMinor: 85000, count: 9), 765000);
    });

    test('Pay in 4: 375 TL x 4 is 1,500 TL', () {
      expect(totalFromInstallment(installmentMinor: 37500, count: 4), 150000);
    });

    test('one minor unit and one payment are allowed', () {
      expect(totalFromInstallment(installmentMinor: 1, count: 1), 1);
      expect(
        totalFromInstallment(
          installmentMinor: 1,
          count: PlanCalculator.maxInstallments,
        ),
        PlanCalculator.maxInstallments,
      );
    });

    for (final (installment, count, field) in [
      (0, 3, 'installment'),
      (-5, 3, 'installment'),
      (100, 0, 'count'),
      (100, PlanCalculator.maxInstallments + 1, 'count'),
      (maxEntryTotalMinor ~/ 3 + 1, 3, 'total'),
      (maxEntryTotalMinor, 2, 'total'),
    ]) {
      test('refuses $installment x $count ($field)', () {
        expect(
          () =>
              totalFromInstallment(installmentMinor: installment, count: count),
          throwsA(
            isA<InvalidPlanInput>().having((e) => e.field, 'field', field),
          ),
        );
      });
    }

    test('a lower limit, such as the total field\'s, is kept', () {
      expect(
        totalFromInstallment(
          installmentMinor: 300,
          count: 3,
          maxTotalMinor: 900,
        ),
        900,
      );
      expect(
        () => totalFromInstallment(
          installmentMinor: 301,
          count: 3,
          maxTotalMinor: 900,
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
      // Never above the exact-integer limit, whatever is passed.
      expect(
        () => totalFromInstallment(
          installmentMinor: maxEntryTotalMinor ~/ 2 + 1,
          count: 2,
          maxTotalMinor: maxEntryTotalMinor * 4,
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
    });

    test('the largest total that fits is accepted', () {
      const count = 7;
      const installment = maxEntryTotalMinor ~/ count;
      expect(
        totalFromInstallment(installmentMinor: installment, count: count),
        installment * count,
      );
    });
  });

  group('installmentSplit matches splitEvenly', () {
    // (currency, typed total, count, first, others) in each currency's
    // minor units: kuruş, whole yen, fils.
    final cases = <(String, String, int, String, String)>[
      ('TRY', '12000', 6, '2000', '2000'),
      ('TRY', '1000', 3, '333,34', '333,33'),
      ('TRY', '400,01', 4, '100,01', '100'),
      ('JPY', '10000', 3, '3334', '3333'),
      ('JPY', '100', 7, '16', '14'),
      ('KWD', '10', 3, '3,334', '3,333'),
      ('KWD', '1', 7, '0,148', '0,142'),
    ];
    for (final (code, total, count, first, others) in cases) {
      test('$code $total / $count', () {
        final currency = Currency.fromCode(code);
        int minor(String s) => parseAmount(s, currency, localeName: 'tr')!;
        final totalMinor = minor(total);
        final split = installmentSplit(totalMinor: totalMinor, count: count);
        final parts = splitEvenly(totalMinor, count);

        expect(split.first, minor(first));
        expect(split.others, minor(others));
        expect(split.first, parts.first);
        expect(parts.skip(1), everyElement(split.others));
        expect(split.first + split.others * split.othersCount, totalMinor);
        expect(split.isEven, first == others);
      });
    }

    test('one payment is even', () {
      final split = installmentSplit(totalMinor: 999, count: 1);
      expect(split, const InstallmentSplit(count: 1, first: 999, others: 999));
      expect(split.isEven, isTrue);
      expect(split.othersCount, 0);
    });

    test('refuses what the plan would refuse', () {
      expect(
        () => installmentSplit(totalMinor: 2, count: 3),
        throwsA(isA<InvalidPlanInput>()),
      );
      expect(
        () => installmentSplit(totalMinor: 100, count: 0),
        throwsA(isA<InvalidPlanInput>()),
      );
      expect(
        () => installmentSplit(
          totalMinor: 100000,
          count: PlanCalculator.maxInstallments + 1,
        ),
        throwsA(isA<InvalidPlanInput>()),
      );
    });
  });

  group('a draft built from an installment', () {
    test('monthly: 9 equal payments of 850 TL, 7,650 TL in total', () {
      final total = totalFromInstallment(installmentMinor: 85000, count: 9);
      final draft = PlanCalculator.monthly(
        firstDate: d('2026-12-01'),
        totalMinor: total,
        count: 9,
      );
      expect(draft.payments, hasLength(9));
      expect(draft.payments.map((p) => p.amountMinor), everyElement(85000));
      expect(draft.totalMinor, 765000);
    });

    test('Pay in 4 with a JPY installment', () {
      final total = totalFromInstallment(installmentMinor: 3333, count: 4);
      final draft = PlanCalculator.payIn4(
        firstDate: d('2026-12-01'),
        totalMinor: total,
      );
      expect(draft.payments.map((p) => p.amountMinor), everyElement(3333));
      expect(draft.totalMinor, 13332);
    });

    test('card and manual plans in KWD fils', () {
      final total = totalFromInstallment(installmentMinor: 1250, count: 6);
      final card = PlanCalculator.card(
        purchaseDate: d('2026-11-20'),
        totalMinor: total,
        count: 6,
        terms: const CardTerms(statementDay: 5, dueDay: 15),
      );
      final manual = PlanCalculator.manual(
        firstDate: d('2026-12-01'),
        totalMinor: total,
        count: 6,
        unit: IntervalUnit.week,
      );
      for (final draft in [card, manual]) {
        expect(draft.payments.map((p) => p.amountMinor), everyElement(1250));
        expect(draft.totalMinor, 7500);
      }
    });

    test('a plan already underway keeps every installment equal', () {
      final total = totalFromInstallment(installmentMinor: 85000, count: 9);
      final draft = underwayPlan(
        kind: PlanKind.monthly,
        totalMinor: total,
        count: 9,
        paidCount: 3,
        nextDate: d('2026-12-01'),
      );
      expect(draft.paidBeforeCount, 3);
      expect(draft.payments.map((p) => p.amountMinor), everyElement(85000));
      expect(draft.totalMinor, 765000);
    });
  });
}
