import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

/// Product price (23): "Total you repay" and "Difference".
List<RepaidPayment> times(int count, int amount, {int? fee}) => [
  for (var i = 0; i < count; i++)
    (amountMinor: amount, installmentFeeMinor: fee),
];

void main() {
  group('canHaveProductPrice', () {
    final cases = <(PlanKind, bool)>[
      (PlanKind.monthly, true),
      (PlanKind.card, true),
      (PlanKind.manual, true),
      (PlanKind.payIn4, false),
      (PlanKind.payLater, false),
    ];
    for (final (kind, expected) in cases) {
      test('$kind -> $expected', () {
        expect(canHaveProductPrice(kind), expected);
      });
    }
  });

  group('normalizeProductPrice', () {
    for (final (typed, expected) in <(int?, int?)>[
      (null, null),
      (0, null),
      (-1, null),
      (1, 1),
      (600000000, 600000000),
    ]) {
      test('$typed -> $expected', () {
        expect(normalizeProductPrice(typed), expected);
      });
    }
  });

  group('examples', () {
    // (name, payments, price, total you repay, difference or null)
    final cases = <(String, List<RepaidPayment>, int?, int, int?)>[
      // 1) IDR (no decimals): 12 x Rp580.000, price Rp6.000.000.
      ('1 IDR 12 x 580.000', times(12, 580000), 6000000, 6960000, 960000),
      // 2) TRY: 6 x 1.100,00 with a 10,00 fee per payment, price 6.000,00.
      (
        '2 TRY 6 x 1.100,00 + fee 10,00',
        times(6, 110000, fee: 1000),
        600000,
        666000,
        66000,
      ),
      // 3) TRY "Total" entry 12.000,00 in 12 payments, price 10.500,00.
      ('3 TRY total 12.000,00', times(12, 100000), 1050000, 1200000, 150000),
      // 4) Price equal to the total: rows hidden.
      ('4 price = total', times(12, 580000), 6960000, 6960000, null),
      // 5) Price above the total: rows hidden, no warning.
      ('5 price > total', times(12, 580000), 7000000, 6960000, null),
      // Not entered.
      ('no price', times(12, 580000), null, 6960000, null),
      ('zero price', times(12, 580000), 0, 6960000, null),
      // An uneven split: the first payment keeps the extra minor unit.
      (
        'uneven split',
        [
          (amountMinor: 33334, installmentFeeMinor: null),
          (amountMinor: 33333, installmentFeeMinor: null),
          (amountMinor: 33333, installmentFeeMinor: null),
        ],
        90000,
        100000,
        10000,
      ),
      // "First payment only" fee: only payment 1 carries it.
      (
        'first payment fee',
        [
          (amountMinor: 50000, installmentFeeMinor: 2500),
          (amountMinor: 50000, installmentFeeMinor: null),
        ],
        100000,
        102500,
        2500,
      ),
      // Large amounts stay exact in int (no floating point).
      (
        'large exact',
        times(48, 999999999999),
        47999999999951,
        47999999999952,
        1,
      ),
    ];
    for (final (name, payments, price, total, difference) in cases) {
      test(name, () {
        final repaid = totalRepaidMinor(payments);
        expect(repaid, total);
        final d = priceDifference(
          totalRepaidMinor: repaid,
          productPriceMinor: price,
        );
        expect(d?.differenceMinor, difference);
        if (d != null) {
          expect(d.totalRepaidMinor, total);
          expect(d.productPriceMinor, price);
        }
      });
    }
  });

  test('6) already underway: paid-before payments count', () {
    // 12 x Rp580.000 with 5 paid before Kalan; the draft keeps all 12.
    final draft = PlanCalculator.monthly(
      totalMinor: 6960000,
      count: 12,
      firstDate: LocalDate(2026, 1, 15),
    ).withPaidBefore(5);
    expect(draft.payments, hasLength(12));
    final repaid = totalRepaidMinor([
      for (var i = 0; i < draft.payments.length; i++)
        (
          amountMinor: draft.payments[i].amountMinor,
          installmentFeeMinor: draft.feeAt(i),
        ),
    ]);
    expect(repaid, 6960000);
    expect(
      priceDifference(
        totalRepaidMinor: repaid,
        productPriceMinor: 6000000,
      )?.differenceMinor,
      960000,
    );
  });

  test('extra fees (21) are not an input: the total stays the same', () {
    // 2) with a later extra fee of 50,00: nothing in RepaidPayment holds it.
    final repaid = totalRepaidMinor(times(6, 110000, fee: 1000));
    expect(repaid, 666000);
  });

  group('status (19)', () {
    for (final (status, shown) in [
      (PlanStatus.open, true),
      (PlanStatus.onHold, false),
      (PlanStatus.closed, false),
    ]) {
      test('$status -> ${shown ? 'shown' : 'hidden'}', () {
        final d = priceDifference(
          totalRepaidMinor: 6960000,
          productPriceMinor: 6000000,
          status: status,
        );
        expect(d != null, shown);
      });
    }
  });
}
