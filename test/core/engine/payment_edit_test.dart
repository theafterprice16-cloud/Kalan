import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

List<PaymentState> plan(
  List<int> amounts, {
  Set<int> paid = const {},
  Set<int> edited = const {},
}) => [
  for (var i = 0; i < amounts.length; i++)
    PaymentState(
      seq: i + 1,
      date: d('2026-11-15').addMonths(i),
      amountMinor: amounts[i],
      isPaid: paid.contains(i + 1),
      isEdited: edited.contains(i + 1),
    ),
];

int total(List<PaymentState> ps) => ps.fold(0, (sum, p) => sum + p.amountMinor);

void main() {
  group('applyPaymentEdit keeps the plan total', () {
    final cases = <(String, List<PaymentState>, int, int, List<int>)>[
      (
        'raise first, later ones absorb evenly',
        plan([1000, 1000, 1000, 1000]),
        1,
        1300,
        [1300, 900, 900, 900],
      ),
      (
        'lower second, leftover cent on the first absorber',
        plan([1000, 1000, 1000, 1000]),
        2,
        999,
        [1000, 999, 1001, 1000],
      ),
      (
        'odd difference across two absorbers',
        plan([1000, 1000, 1000]),
        1,
        1003,
        [1003, 998, 999],
      ),
      (
        'paid and edited payments do not absorb',
        plan([1000, 1000, 1000, 1000], paid: {3}, edited: {2}),
        1,
        1500,
        [1500, 1000, 1000, 500],
      ),
    ];
    for (final (name, payments, seq, amount, expected) in cases) {
      test(name, () {
        final target = payments.firstWhere((p) => p.seq == seq);
        final result = applyPaymentEdit(
          payments,
          seq: seq,
          date: target.date,
          amountMinor: amount,
        );
        expect(result, isA<EditApplied>());
        final updated = (result as EditApplied).payments;
        expect(updated.map((p) => p.amountMinor).toList(), expected);
        expect(total(updated), total(payments));
        expect(updated.firstWhere((p) => p.seq == seq).isEdited, isTrue);
      });
    }
  });

  test('date-only edit needs no absorbers', () {
    final payments = plan([1000, 1000]);
    final result = applyPaymentEdit(
      payments,
      seq: 2,
      date: d('2027-01-02'),
      amountMinor: 1000,
    );
    final updated = (result as EditApplied).payments;
    expect(updated[1].date, d('2027-01-02'));
    expect(updated[1].isEdited, isTrue);
    expect(updated[0].isEdited, isFalse);
  });

  group('rejections', () {
    final cases = <(String, List<PaymentState>, int, int, EditRejection)>[
      (
        'last payment has nobody to absorb',
        plan([1000, 1000]),
        2,
        1200,
        EditRejection.noAbsorbers,
      ),
      (
        'paid payment',
        plan([1000, 1000], paid: {1}),
        1,
        900,
        EditRejection.alreadyPaid,
      ),
      (
        'zero amount',
        plan([1000, 1000]),
        1,
        0,
        EditRejection.nonPositiveAmount,
      ),
      (
        'absorber would drop to zero',
        plan([1000, 1000]),
        1,
        2000,
        EditRejection.absorberWouldBeNonPositive,
      ),
      ('missing seq', plan([1000]), 7, 10, EditRejection.notFound),
    ];
    for (final (name, payments, seq, amount, reason) in cases) {
      test(name, () {
        final result = applyPaymentEdit(
          payments,
          seq: seq,
          date: d('2026-11-15'),
          amountMinor: amount,
        );
        expect(result, isA<EditRejected>());
        expect((result as EditRejected).reason, reason);
      });
    }
  });
}
