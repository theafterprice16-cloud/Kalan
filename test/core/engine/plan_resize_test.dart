import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// 10 monthly payments of 850 from 5 Sep 2026; the first [paid] paid.
List<PaymentState> mehmet({int paid = 3, Set<int> edited = const {}}) => [
  for (var i = 0; i < 10; i++)
    PaymentState(
      seq: i + 1,
      date: d(2026, 9, 5).addMonths(i, preferredDay: 5),
      amountMinor: edited.contains(i) ? 100000 : 85000,
      isPaid: i < paid,
      isEdited: edited.contains(i),
    ),
];

LocalDate monthlyFrom(int i) => d(2026, 9, 5).addMonths(i, preferredDay: 5);

int sum(List<PaymentState> p) => p.fold(0, (s, x) => s + x.amountMinor);

List<PaymentState> applied(ResizeResult r) => switch (r) {
  ResizeApplied(:final payments) => payments,
  ResizeRejected(:final reason) => fail('rejected: $reason'),
};

void main() {
  group('the plan total stays', () {
    // payments, new count, expected unpaid amounts
    final cases = <(String, List<PaymentState>, int, List<int>)>[
      ('10 -> 12, 3 paid', mehmet(), 12, [66112, ...List.filled(8, 66111)]),
      (
        '10 -> 8, 3 paid',
        mehmet(),
        8,
        [119000, 119000, 119000, 119000, 119000],
      ),
      ('10 -> 4, 3 paid', mehmet(), 4, [595000]),
      (
        '10 -> 11, none paid',
        mehmet(paid: 0),
        11,
        [77280, ...List.filled(10, 77272)],
      ),
    ];
    for (final (name, payments, count, unpaid) in cases) {
      test(name, () {
        final r = applied(
          resizePlan(payments: payments, newCount: count, dateAt: monthlyFrom),
        );
        expect(r, hasLength(count));
        expect(sum(r), sum(payments));
        expect([
          for (final p in r)
            if (!p.isPaid) p.amountMinor,
        ], unpaid);
        // Paid payments keep amount and date.
        for (var i = 0; i < payments.length && i < count; i++) {
          if (payments[i].isPaid) expect(r[i], payments[i]);
        }
        expect(r.map((p) => p.seq), [for (var i = 1; i <= count; i++) i]);
      });
    }

    test('growing: 9 unpaid share 5,950.00 evenly, the extra cent first', () {
      final r = applied(
        resizePlan(payments: mehmet(), newCount: 12, dateAt: monthlyFrom),
      );
      expect(
        [for (final p in r.skip(3)) p.amountMinor],
        [66112, ...List.filled(8, 66111)],
      );
      expect(r[10].date, d(2027, 7, 5));
      expect(r[11].date, d(2027, 8, 5));
    });

    test('a payment edited by hand keeps its date and amount', () {
      final r = applied(
        resizePlan(
          payments: mehmet(edited: {5}),
          newCount: 9,
          dateAt: monthlyFrom,
        ),
      );
      expect(r[5].amountMinor, 100000);
      expect(r[5].isEdited, isTrue);
      expect(sum(r), sum(mehmet(edited: {5})));
    });

    test('the same count changes nothing', () {
      final p = mehmet();
      expect(
        applied(resizePlan(payments: p, newCount: 10, dateAt: monthlyFrom)),
        p,
      );
    });
  });

  group('rejected', () {
    // A payment marked paid in the app at index 5.
    final markedLater = [
      for (final (i, p) in mehmet().indexed)
        i == 5
            ? PaymentState(
                seq: p.seq,
                date: p.date,
                amountMinor: p.amountMinor,
                isPaid: true,
              )
            : p,
    ];
    final cases = <(String, List<PaymentState>, int, ResizeRejection)>[
      ('all paid would remain', mehmet(), 3, ResizeRejection.tooFew),
      ('below a paid payment', markedLater, 6, ResizeRejection.tooFew),
      ('over 120', mehmet(), 121, ResizeRejection.tooMany),
      (
        'cannot split what is left',
        [
          for (var i = 0; i < 4; i++)
            PaymentState(
              seq: i + 1,
              date: monthlyFrom(i),
              amountMinor: i == 0 ? 997 : 1,
              isPaid: i == 0,
            ),
        ],
        8,
        ResizeRejection.cannotSplit,
      ),
    ];
    for (final (name, payments, count, reason) in cases) {
      test(name, () {
        final r = resizePlan(
          payments: payments,
          newCount: count,
          dateAt: monthlyFrom,
        );
        expect(r, isA<ResizeRejected>());
        expect((r as ResizeRejected).reason, reason);
      });
    }

    test('the smallest count keeps every paid payment and one to pay', () {
      expect(minInstallmentCount(mehmet()), 4);
      expect(minInstallmentCount(markedLater), 7);
      expect(minInstallmentCount(mehmet(paid: 0)), 1);
    });
  });
}
