import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

/// Extra fee (21): what it adds, which payments can have one, and what is
/// never stored.
void main() {
  group('spokenForAmount', () {
    final cases = <(String, int, int?, int)>[
      ('no fee: exactly the amount', 6000, null, 6000),
      ('EUR 60 + 6', 6000, 600, 6600),
      ('IDR 500.000 + 25.000 (no minor digits)', 500000, 25000, 525000),
      ('KWD three digits', 12345, 1, 12346),
    ];
    for (final (name, amount, fee, expected) in cases) {
      test(name, () {
        expect(
          spokenForAmount(amountMinor: amount, extraFeeMinor: fee),
          expected,
        );
      });
    }
  });

  group('canHaveExtraFee', () {
    // (status, paid, paid before Kalan) → allowed
    final cases = <(PlanStatus, bool, bool, bool)>[
      (PlanStatus.open, false, false, true),
      (PlanStatus.open, true, false, true),
      (PlanStatus.open, true, true, false),
      (PlanStatus.onHold, false, false, false),
      (PlanStatus.onHold, true, false, true),
      (PlanStatus.onHold, true, true, false),
      (PlanStatus.closed, false, false, false),
      (PlanStatus.closed, true, false, false),
    ];
    for (final (status, paid, before, allowed) in cases) {
      test('${status.name}, paid $paid, before Kalan $before → $allowed', () {
        expect(
          canHaveExtraFee(
            status: status,
            isPaid: paid,
            paidBeforeKalan: before,
          ),
          allowed,
        );
      });
    }
  });

  group('extraFeeRejection', () {
    ExtraFeeRejection? check(
      int amount, {
      String? note,
      PlanStatus status = PlanStatus.open,
      bool paid = false,
    }) => extraFeeRejection(
      status: status,
      isPaid: paid,
      paidBeforeKalan: false,
      amountMinor: amount,
      note: note,
    );

    test('a positive fee with or without a note is stored', () {
      expect(check(600), isNull);
      expect(check(1, note: 'İkinci ücret'), isNull);
      expect(check(600, note: 'x' * extraFeeNoteMaxLength), isNull);
    });

    test('zero and negative are never stored', () {
      expect(check(0), ExtraFeeRejection.nonPositiveAmount);
      expect(check(-600), ExtraFeeRejection.nonPositiveAmount);
    });

    test('a note over 80 is refused; spaces around it do not count', () {
      expect(check(600, note: 'x' * 81), ExtraFeeRejection.noteTooLong);
      expect(check(600, note: '  ${'x' * 80}  '), isNull);
    });

    test('the note is measured as stored (UTF-16), not by what is seen', () {
      // 41 emoji are 41 characters on screen but 82 code units.
      expect(check(600, note: '😀' * 41), ExtraFeeRejection.noteTooLong);
      expect(check(600, note: '😀' * 40), isNull);
    });

    test('a payment that cannot have one is refused first', () {
      expect(
        check(0, status: PlanStatus.closed, paid: true),
        ExtraFeeRejection.notAllowed,
      );
      expect(
        check(600, status: PlanStatus.onHold),
        ExtraFeeRejection.notAllowed,
      );
    });
  });

  group('normalizeExtraFeeNote', () {
    test('trimmed; empty and blank are no note', () {
      expect(normalizeExtraFeeNote(null), isNull);
      expect(normalizeExtraFeeNote(''), isNull);
      expect(normalizeExtraFeeNote('   '), isNull);
      expect(normalizeExtraFeeNote(' İkinci ücret '), 'İkinci ücret');
    });
  });
}
