import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

/// Fee per payment (22): which payments take the plan's fee.
FeePayment p(int seq, {bool paid = false, bool before = false, int? fee}) =>
    (seq: seq, isPaid: paid || before, paidBeforeKalan: before, feeMinor: fee);

void main() {
  group('installmentFeeFor', () {
    const every = InstallmentFeeScope.everyPayment;
    const first = InstallmentFeeScope.firstPaymentOnly;
    final cases = <(int?, InstallmentFeeScope?, int, int?)>[
      (390, every, 1, 390),
      (390, every, 4, 390),
      (390, null, 2, 390),
      (250, first, 1, 250),
      (250, first, 2, null),
      (0, every, 1, null),
      (null, every, 1, null),
      (-5, first, 1, null),
    ];
    for (final (fee, scope, seq, expected) in cases) {
      test('fee $fee, $scope, #$seq -> $expected', () {
        expect(
          installmentFeeFor(feeMinor: fee, scope: scope, seq: seq),
          expected,
        );
      });
    }
  });

  test('card installments have no fee per payment; every other kind can', () {
    expect(canHaveInstallmentFee(PlanKind.card), isFalse);
    for (final k in [
      PlanKind.payIn4,
      PlanKind.monthly,
      PlanKind.manual,
      PlanKind.payLater,
    ]) {
      expect(canHaveInstallmentFee(k), isTrue, reason: '$k');
    }
  });

  group('appliedInstallmentFees (table)', () {
    const every = InstallmentFeeScope.everyPayment;
    const first = InstallmentFeeScope.firstPaymentOnly;
    final cases =
        <(String, List<FeePayment>, int?, InstallmentFeeScope, List<int?>)>[
          (
            'example 1: every payment',
            [p(1), p(2), p(3), p(4)],
            390,
            every,
            [390, 390, 390, 390],
          ),
          (
            'example 2: first payment only',
            [p(1), p(2), p(3)],
            250,
            first,
            [250, null, null],
          ),
          (
            'example 3: first paid keeps no fee, others take it',
            [p(1, paid: true), p(2), p(3), p(4)],
            390,
            every,
            [null, 390, 390, 390],
          ),
          (
            'example 4: first only, first paid: nothing',
            [p(1, paid: true), p(2), p(3), p(4)],
            390,
            first,
            [null, null, null, null],
          ),
          (
            'example 5: removed: unpaid lose it, paid keep theirs',
            [p(1, paid: true, fee: 390), p(2, fee: 390), p(3, fee: 390)],
            null,
            every,
            [390, null, null],
          ),
          ('zero is no fee', [p(1, fee: 100), p(2)], 0, every, [null, null]),
          (
            'already underway payments never take a fee',
            [p(1, before: true, fee: 9), p(2, before: true), p(3), p(4)],
            390,
            every,
            [null, null, 390, 390],
          ),
          (
            'first only on an underway plan: nothing',
            [p(1, before: true), p(2), p(3)],
            390,
            first,
            [null, null, null],
          ),
          (
            'a changed fee: unpaid follow, paid keep the old one',
            [p(1, paid: true, fee: 300), p(2, fee: 300)],
            390,
            every,
            [300, 390],
          ),
          ('pay later: one payment takes the fee', [p(1)], 150, every, [150]),
        ];
    for (final (name, payments, fee, scope, expected) in cases) {
      test(name, () {
        expect(
          appliedInstallmentFees(
            payments: payments,
            feeMinor: fee,
            scope: scope,
          ),
          expected,
        );
      });
    }
  });

  test('unpaidFeeChanges counts unpaid payments whose fee changes', () {
    final plan = [p(1, paid: true), p(2), p(3), p(4)];
    expect(
      unpaidFeeChanges(
        payments: plan,
        feeMinor: 390,
        scope: InstallmentFeeScope.everyPayment,
      ),
      3,
    );
    expect(
      unpaidFeeChanges(
        payments: plan,
        feeMinor: 390,
        scope: InstallmentFeeScope.firstPaymentOnly,
      ),
      0,
    );
    // Already the fee: nothing changes.
    expect(
      unpaidFeeChanges(
        payments: [p(1, fee: 390), p(2, fee: 390)],
        feeMinor: 390,
        scope: InstallmentFeeScope.everyPayment,
      ),
      0,
    );
  });

  test('firstPaymentFeeAddsNothing', () {
    const first = InstallmentFeeScope.firstPaymentOnly;
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(1, paid: true), p(2)],
        feeMinor: 390,
        scope: first,
      ),
      isTrue,
    );
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(1, before: true), p(2)],
        feeMinor: 390,
        scope: first,
      ),
      isTrue,
    );
    // Plans kept from their remaining payments only (before schema v4).
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(3), p(4)],
        feeMinor: 390,
        scope: first,
      ),
      isTrue,
    );
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(1), p(2)],
        feeMinor: 390,
        scope: first,
      ),
      isFalse,
    );
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(1, paid: true)],
        feeMinor: 390,
        scope: InstallmentFeeScope.everyPayment,
      ),
      isFalse,
    );
    expect(
      firstPaymentFeeAddsNothing(
        payments: [p(1, paid: true)],
        feeMinor: null,
        scope: first,
      ),
      isFalse,
    );
  });

  test('spokenForAmount adds both fees in one place', () {
    expect(spokenForAmount(amountMinor: 2500), 2500);
    expect(spokenForAmount(amountMinor: 2500, installmentFeeMinor: 390), 2890);
    expect(
      spokenForAmount(
        amountMinor: 2500,
        installmentFeeMinor: 390,
        extraFeeMinor: 600,
      ),
      3490,
    );
    expect(
      installmentAmount(amountMinor: 4000, installmentFeeMinor: 250),
      4250,
    );
  });
}
