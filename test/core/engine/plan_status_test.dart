import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// [count] monthly payments of [each] from 5 Dec 2026; the first [paid]
/// paid.
List<PaymentState> plan(int count, int each, {int paid = 0}) => [
  for (var i = 0; i < count; i++)
    PaymentState(
      seq: i + 1,
      date: d(2026, 12, 5).addMonths(i, preferredDay: 5),
      amountMinor: each,
      isPaid: i < paid,
    ),
];

int sum(List<PaymentState> p) => p.fold(0, (s, x) => s + x.amountMinor);

void main() {
  group('countsInTotals', () {
    // status, paid, counts
    final cases = <(PlanStatus, bool, bool)>[
      (PlanStatus.open, false, true),
      (PlanStatus.open, true, true),
      (PlanStatus.onHold, false, false),
      (PlanStatus.onHold, true, true),
      (PlanStatus.closed, false, false),
      (PlanStatus.closed, true, true),
    ];
    for (final (status, paid, counts) in cases) {
      test('$status, paid: $paid -> $counts', () {
        expect(countsInTotals(status, isPaid: paid), counts);
      });
    }
  });

  group('holdCheckDue (from the 30th day, the hold day is day 1)', () {
    final since = d(2026, 11, 1);
    // day of the hold, due
    final cases = <(int, bool)>[
      (1, false),
      (2, false),
      (29, false),
      (30, true),
      (31, true),
      (400, true),
    ];
    for (final (day, due) in cases) {
      test('day $day -> $due', () {
        expect(holdCheckDue(since: since, today: since.addDays(day - 1)), due);
      });
    }

    test('hold on 1 Nov: 29 Nov is day 29, 30 Nov is day 30', () {
      expect(holdCheckDue(since: since, today: d(2026, 11, 29)), isFalse);
      expect(holdCheckDue(since: since, today: d(2026, 11, 30)), isTrue);
    });

    test('"Keep on hold" starts the 30 days again', () {
      final kept = d(2026, 11, 30);
      expect(holdCheckDue(since: kept, today: kept.addDays(28)), isFalse);
      expect(holdCheckDue(since: kept, today: kept.addDays(29)), isTrue);
    });
  });

  group('passedDuringHold', () {
    final payments = [
      (date: d(2026, 10, 30), isPaid: false), // before the hold
      (date: d(2026, 11, 1), isPaid: false), // first day of the hold
      (date: d(2026, 11, 10), isPaid: true), // paid meanwhile
      (date: d(2026, 11, 20), isPaid: false), // during the hold
      (date: d(2026, 11, 25), isPaid: false), // the day it was reopened
      (date: d(2026, 12, 5), isPaid: false), // still to come
    ];
    test('unpaid payments dated from the hold to the reopen day', () {
      expect(
        passedDuringHold(
          payments: payments,
          heldSince: d(2026, 11, 1),
          reopenedOn: d(2026, 11, 25),
        ),
        2,
      );
    });
    test('payments already past due before the hold are not counted', () {
      expect(
        passedDuringHold(
          payments: [(date: d(2026, 10, 30), isPaid: false)],
          heldSince: d(2026, 11, 1),
          reopenedOn: d(2026, 12, 1),
        ),
        0,
      );
    });
    test('reopened the same day: none', () {
      expect(
        passedDuringHold(
          payments: payments,
          heldSince: d(2026, 11, 1),
          reopenedOn: d(2026, 11, 1),
        ),
        0,
      );
    });
  });

  group('adjustPlanTotal (Example 3: 300 EUR, 4 x 75, first paid)', () {
    final payments = plan(4, 7500, paid: 1);

    // new total, expected amounts (paid one first)
    final applied = <(int, List<int>)>[
      (15000, [7500, 2500, 2500, 2500]),
      (20000, [7500, 4166, 4166, 4168]),
      (29999, [7500, 7499, 7499, 7501]),
      (7503, [7500, 1, 1, 1]),
    ];
    for (final (total, amounts) in applied) {
      test('$total -> $amounts', () {
        final result = adjustPlanTotal(payments, total);
        expect(result, isA<AdjustApplied>());
        final next = (result as AdjustApplied).payments;
        expect([for (final p in next) p.amountMinor], amounts);
        expect(sum(next), total);
        // Dates, order, paid state and edits never change.
        for (var i = 0; i < next.length; i++) {
          expect(next[i].date, payments[i].date);
          expect(next[i].seq, payments[i].seq);
          expect(next[i].isPaid, payments[i].isPaid);
          expect(next[i].isEdited, payments[i].isEdited);
        }
      });
    }

    // new total, reason
    final rejected = <(int, AdjustRejection)>[
      (6000, AdjustRejection.belowPaid),
      (0, AdjustRejection.belowPaid),
      (7500, AdjustRejection.nothingLeft),
      (7502, AdjustRejection.cannotSplit),
      (30000, AdjustRejection.unchanged),
      (30001, AdjustRejection.aboveTotal),
    ];
    for (final (total, reason) in rejected) {
      test('$total -> $reason', () {
        final result = adjustPlanTotal(payments, total);
        expect(result, isA<AdjustRejected>());
        expect((result as AdjustRejected).reason, reason);
      });
    }

    test('paid total is what was paid', () {
      expect(paidTotalOf(payments), 7500);
    });
  });

  group('adjustPlanTotal, other plans', () {
    test('IDR (no minor units): 3 x 1.000.000, none paid, to 2.000.000', () {
      final result =
          adjustPlanTotal(plan(3, 1000000), 2000000) as AdjustApplied;
      expect(
        [for (final p in result.payments) p.amountMinor],
        [666666, 666666, 666668],
      );
    });

    test('a single payment takes the whole new total', () {
      final result = adjustPlanTotal(plan(1, 24000), 12000) as AdjustApplied;
      expect(result.payments.single.amountMinor, 12000);
    });

    test('a single paid payment: nothing to adjust', () {
      expect(
        (adjustPlanTotal(
          plan(1, 24000, paid: 1),
          12000,
        ) as AdjustRejected).reason,
        AdjustRejection.belowPaid,
      );
    });

    test('paid payments in the middle stay as they are', () {
      final payments = [
        PaymentState(seq: 1, date: d(2026, 12, 5), amountMinor: 5000),
        PaymentState(
          seq: 2,
          date: d(2027, 1, 5),
          amountMinor: 5000,
          isPaid: true,
        ),
        PaymentState(
          seq: 3,
          date: d(2027, 2, 5),
          amountMinor: 5000,
          isEdited: true,
        ),
      ];
      final result = adjustPlanTotal(payments, 10001) as AdjustApplied;
      expect(
        [for (final p in result.payments) p.amountMinor],
        [2500, 5000, 2501],
      );
      expect(result.payments[2].isEdited, isTrue);
    });
  });

  test('property: the payments always add up to the new total', () {
    final random = Random(19);
    for (var run = 0; run < 2000; run++) {
      final count = 1 + random.nextInt(36);
      final paid = random.nextInt(count + 1);
      final payments = [
        for (var i = 0; i < count; i++)
          PaymentState(
            seq: i + 1,
            date: d(2026, 1, 1).addDays(i * 30),
            amountMinor: 1 + random.nextInt(500000),
            isPaid: i < paid,
          ),
      ];
      final total = sum(payments);
      final paidTotal = paidTotalOf(payments);
      final newTotal = paidTotal + random.nextInt(total - paidTotal + 1);
      final result = adjustPlanTotal(payments, newTotal);
      switch (result) {
        case AdjustApplied(payments: final next):
          expect(sum(next), newTotal);
          expect(next.length, count);
          for (var i = 0; i < count; i++) {
            expect(next[i].date, payments[i].date);
            if (payments[i].isPaid) {
              expect(next[i].amountMinor, payments[i].amountMinor);
            } else {
              expect(next[i].amountMinor, greaterThanOrEqualTo(1));
            }
          }
          // Even split: unpaid amounts differ only on the last one.
          final unpaid = [
            for (var i = 0; i < count; i++)
              if (!payments[i].isPaid) next[i].amountMinor,
          ];
          expect(unpaid.take(unpaid.length - 1).toSet().length, lessThan(2));
          expect(unpaid.last, greaterThanOrEqualTo(unpaid.first));
          expect(unpaid.last - unpaid.first, lessThan(unpaid.length));
        case AdjustRejected(:final reason):
          expect(reason, isNot(AdjustRejection.belowPaid));
          expect(reason, isNot(AdjustRejection.aboveTotal));
      }
    }
  });
}
