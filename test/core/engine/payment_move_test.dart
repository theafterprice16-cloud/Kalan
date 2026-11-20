import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  // The brief's examples: payday 25, today 15 Nov, 4 × 60 $ (cents).
  const schedule = PaySchedule.monthly(25);
  final today = d(2026, 11, 15);
  final tom = [
    MovablePayment(seq: 1, date: d(2026, 11, 20)),
    MovablePayment(seq: 2, date: d(2026, 12, 4)),
    MovablePayment(seq: 3, date: d(2026, 12, 18)),
    MovablePayment(seq: 4, date: d(2027, 1, 1)),
  ];
  final thisPeriod = PayPeriod(d(2026, 10, 25), d(2026, 11, 25));
  final nextPeriod = PayPeriod(d(2026, 11, 25), d(2026, 12, 25));
  final thirdPeriod = PayPeriod(d(2026, 12, 25), d(2027, 1, 25));

  /// The plan's counting items before and after [moved], as the data
  /// layer builds them (unpaid, not past due: the due date).
  List<PeriodChange> preview(
    List<MovablePayment> payments,
    Map<int, LocalDate> moved, {
    int amount = 6000,
  }) => periodChanges(
    before: [
      for (final p in payments)
        DatedAmount(
          countingDate(dueDate: p.date, isPaid: p.isPaid, today: today),
          amount,
        ),
    ],
    after: [
      for (final p in payments)
        DatedAmount(
          countingDate(
            dueDate: moved[p.seq] ?? p.date,
            isPaid: p.isPaid,
            today: today,
          ),
          amount,
        ),
    ],
    schedule: schedule,
  );

  group('preview (brief examples)', () {
    final cases = <(String, int, LocalDate, bool, List<PeriodChange>)>[
      (
        '1: 20 Nov → 27 Nov, alone: this period +60 left, next −60',
        1,
        d(2026, 11, 27),
        false,
        [PeriodChange(thisPeriod, -6000), PeriodChange(nextPeriod, 6000)],
      ),
      (
        '2: same, later ones too: the middle period is not listed',
        1,
        d(2026, 11, 27),
        true,
        [PeriodChange(thisPeriod, -6000), PeriodChange(thirdPeriod, 6000)],
      ),
      ('4: 4 Dec → 6 Dec: same period', 2, d(2026, 12, 6), false, []),
      (
        'last day of the period → payday: crosses',
        1,
        d(2026, 11, 25),
        false,
        [PeriodChange(thisPeriod, -6000), PeriodChange(nextPeriod, 6000)],
      ),
      ('onto the last day of the period: stays', 1, d(2026, 11, 24), false, []),
      (
        'earlier, into this period',
        2,
        d(2026, 11, 24),
        false,
        [PeriodChange(thisPeriod, 6000), PeriodChange(nextPeriod, -6000)],
      ),
      (
        'across the year: 1 Jan → 26 Jan',
        4,
        d(2027, 1, 26),
        false,
        [
          PeriodChange(thirdPeriod, -6000),
          PeriodChange(PayPeriod(d(2027, 1, 25), d(2027, 2, 25)), 6000),
        ],
      ),
    ];
    for (final (name, seq, date, shift, expected) in cases) {
      test(name, () {
        final moved = movedDates(
          tom,
          seq: seq,
          newDate: date,
          shiftLater: shift,
        );
        expect(preview(tom, moved), expected);
      });
    }

    test('1 with and without income: left is minus spoken for', () {
      final changes = preview(
        tom,
        movedDates(tom, seq: 1, newDate: d(2026, 11, 27), shiftLater: false),
      );
      expect(changes.map((c) => c.leftDeltaMinor), [6000, -6000]);
      expect(changes.map((c) => c.spokenForDeltaMinor), [-6000, 6000]);
    });

    test('a past-due payment counts today, then on its new date', () {
      final late = [
        MovablePayment(seq: 1, date: d(2026, 10, 1)),
        ...tom.skip(1),
      ];
      final moved = movedDates(
        late,
        seq: 1,
        newDate: d(2026, 11, 30),
        shiftLater: false,
      );
      expect(preview(late, moved), [
        PeriodChange(thisPeriod, -6000),
        PeriodChange(nextPeriod, 6000),
      ]);
    });

    test('nothing moved: nothing changes', () {
      expect(preview(tom, const {}), isEmpty);
    });
  });

  group('movedDates', () {
    test('alone: only the chosen payment', () {
      expect(
        movedDates(tom, seq: 2, newDate: d(2026, 12, 20), shiftLater: false),
        {2: d(2026, 12, 20)},
      );
    });

    test('later ones too: same number of days, earlier ones stay', () {
      expect(
        movedDates(tom, seq: 2, newDate: d(2026, 12, 11), shiftLater: true),
        {2: d(2026, 12, 11), 3: d(2026, 12, 25), 4: d(2027, 1, 8)},
      );
    });

    test('later ones too: paid payments never move', () {
      final payments = [
        tom[0],
        tom[1],
        MovablePayment(seq: 3, date: d(2026, 12, 18), isPaid: true),
        tom[3],
      ];
      expect(
        movedDates(payments, seq: 2, newDate: d(2026, 12, 6), shiftLater: true),
        {2: d(2026, 12, 6), 4: d(2027, 1, 3)},
      );
    });

    test('earlier, later ones too: moved back by the same days', () {
      expect(
        movedDates(tom, seq: 3, newDate: d(2026, 12, 16), shiftLater: true),
        {3: d(2026, 12, 16), 4: d(2026, 12, 30)},
      );
    });

    test('month end and leap year: plain days', () {
      final payments = [
        MovablePayment(seq: 1, date: d(2028, 1, 31)),
        MovablePayment(seq: 2, date: d(2028, 2, 29)),
        MovablePayment(seq: 3, date: d(2028, 3, 31)),
      ];
      expect(
        movedDates(payments, seq: 1, newDate: d(2028, 2, 3), shiftLater: true),
        {1: d(2028, 2, 3), 2: d(2028, 3, 3), 3: d(2028, 4, 3)},
      );
    });

    test('year change', () {
      expect(
        movedDates(tom, seq: 3, newDate: d(2026, 12, 25), shiftLater: true),
        {3: d(2026, 12, 25), 4: d(2027, 1, 8)},
      );
    });

    test('same date or unknown payment: nothing', () {
      expect(
        movedDates(tom, seq: 2, newDate: d(2026, 12, 4), shiftLater: true),
        isEmpty,
      );
      expect(
        movedDates(tom, seq: 9, newDate: d(2026, 12, 4), shiftLater: true),
        isEmpty,
      );
    });
  });

  group('original date', () {
    final cases = <(String, LocalDate, LocalDate?, LocalDate, LocalDate?)>[
      (
        'first change keeps the current date',
        d(2026, 11, 20),
        null,
        d(2026, 11, 27),
        d(2026, 11, 20),
      ),
      (
        'a second change never overwrites it',
        d(2026, 11, 27),
        d(2026, 11, 20),
        d(2026, 12, 2),
        d(2026, 11, 20),
      ),
      (
        'back to the original date: cleared',
        d(2026, 11, 27),
        d(2026, 11, 20),
        d(2026, 11, 20),
        null,
      ),
      (
        'earlier: kept the same way',
        d(2026, 12, 4),
        null,
        d(2026, 11, 30),
        d(2026, 12, 4),
      ),
    ];
    for (final (name, current, stored, next, expected) in cases) {
      test(name, () {
        expect(
          originalDateAfterMove(
            current: current,
            stored: stored,
            newDate: next,
          ),
          expected,
        );
      });
    }

    test('note: later, earlier, none', () {
      final original = d(2026, 11, 20);
      expect(
        moveNoteOf(date: d(2026, 11, 27), originalDate: original),
        MoveNote.later,
      );
      expect(
        moveNoteOf(date: d(2026, 11, 18), originalDate: original),
        MoveNote.earlier,
      );
      expect(moveNoteOf(date: original, originalDate: original), isNull);
      expect(moveNoteOf(date: original), isNull);
    });
  });

  group('passesNextPayment (example 5)', () {
    test('4 Dec → 20 Dec passes 18 Dec', () {
      expect(passesNextPayment(tom, seq: 2, newDate: d(2026, 12, 20)), isTrue);
    });
    test('on the next date or before: no', () {
      expect(passesNextPayment(tom, seq: 2, newDate: d(2026, 12, 18)), isFalse);
      expect(passesNextPayment(tom, seq: 2, newDate: d(2026, 12, 6)), isFalse);
    });
    test('a paid next payment is skipped', () {
      final payments = [
        tom[0],
        tom[1],
        MovablePayment(seq: 3, date: d(2026, 12, 18), isPaid: true),
        tom[3],
      ];
      expect(
        passesNextPayment(payments, seq: 2, newDate: d(2026, 12, 20)),
        isFalse,
      );
      expect(
        passesNextPayment(payments, seq: 2, newDate: d(2027, 1, 2)),
        isTrue,
      );
    });
    test('the last payment has no next', () {
      expect(passesNextPayment(tom, seq: 4, newDate: d(2027, 6, 1)), isFalse);
    });
  });

  group('canChangeDate', () {
    final cases = <(String, PlanStatus, PlanKind, bool, bool)>[
      ('open, unpaid, pay in 4', PlanStatus.open, PlanKind.payIn4, false, true),
      ('monthly', PlanStatus.open, PlanKind.monthly, false, true),
      ('manual', PlanStatus.open, PlanKind.manual, false, true),
      ('paid', PlanStatus.open, PlanKind.payIn4, true, false),
      ('on hold', PlanStatus.onHold, PlanKind.payIn4, false, false),
      ('closed', PlanStatus.closed, PlanKind.payIn4, false, false),
      ('card installment', PlanStatus.open, PlanKind.card, false, false),
      ('pay later', PlanStatus.open, PlanKind.payLater, false, true),
    ];
    for (final (name, status, kind, paid, expected) in cases) {
      test(name, () {
        expect(
          canChangeDate(status: status, kind: kind, isPaid: paid),
          expected,
        );
      });
    }
  });

  group('moveRejection', () {
    MoveRejection? check(
      List<MovablePayment> payments,
      int seq,
      LocalDate date, {
      bool shift = false,
      PlanStatus status = PlanStatus.open,
      PlanKind kind = PlanKind.payIn4,
    }) => moveRejection(
      payments,
      seq: seq,
      newDate: date,
      shiftLater: shift,
      today: today,
      status: status,
      kind: kind,
    );

    test('allowed: later, earlier down to today, past the next one', () {
      expect(check(tom, 1, d(2026, 11, 27)), isNull);
      expect(check(tom, 2, today), isNull);
      expect(check(tom, 2, d(2026, 12, 20)), isNull);
      expect(check(tom, 1, d(2030, 1, 1), shift: true), isNull);
    });

    test('before today, unchanged, unknown', () {
      expect(check(tom, 2, d(2026, 11, 14)), MoveRejection.beforeToday);
      expect(check(tom, 2, d(2026, 12, 4)), MoveRejection.unchanged);
      expect(check(tom, 7, d(2026, 12, 4)), MoveRejection.notFound);
    });

    test('paid, card, on hold, closed', () {
      final paid = [
        MovablePayment(seq: 1, date: d(2026, 11, 20), isPaid: true),
      ];
      expect(check(paid, 1, d(2026, 11, 27)), MoveRejection.notAllowed);
      expect(
        check(tom, 1, d(2026, 11, 27), kind: PlanKind.card),
        MoveRejection.notAllowed,
      );
      expect(
        check(tom, 1, d(2026, 11, 27), status: PlanStatus.onHold),
        MoveRejection.notAllowed,
      );
      expect(
        check(tom, 1, d(2026, 11, 27), status: PlanStatus.closed),
        MoveRejection.notAllowed,
      );
    });

    test('a later payment pushed before today', () {
      // Payment 3 was moved alone to 16 Nov earlier on.
      final payments = [
        tom[0],
        MovablePayment(seq: 2, date: d(2026, 12, 4)),
        MovablePayment(seq: 3, date: d(2026, 11, 16)),
      ];
      expect(
        check(payments, 2, d(2026, 11, 30), shift: true),
        MoveRejection.laterBeforeToday,
      );
      expect(check(payments, 2, d(2026, 11, 30)), isNull);
    });
  });

  test('keepsMovedPayLaterDate: only while nothing it follows changes', () {
    final moved = d(2026, 12, 1);
    final purchase = d(2026, 11, 10);
    const rule = PayLaterRule.days(14);
    bool keeps({LocalDate? p, PayLaterRule r = rule, LocalDate? chosen}) =>
        keepsMovedPayLaterDate(
          movedDate: moved,
          storedPurchase: purchase,
          storedRule: rule,
          purchase: p ?? purchase,
          rule: r,
          chosen: chosen,
        );
    expect(keeps(), isTrue);
    expect(keeps(chosen: moved), isTrue);
    expect(keeps(p: d(2026, 11, 11)), isFalse);
    expect(keeps(r: const PayLaterRule.days(30)), isFalse);
    expect(keeps(chosen: d(2026, 12, 2)), isFalse);
  });
}
