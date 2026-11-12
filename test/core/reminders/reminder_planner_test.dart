import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/core/reminders/reminder_time.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

ReminderPayment pay(
  int id,
  LocalDate date, {
  String name = 'Klarna',
  int amount = 62000,
  int? seq = 3,
  int? count = 4,
  bool paid = false,
  bool enabled = true,
}) => ReminderPayment(
  ref: PlanPaymentRef(id),
  name: name,
  date: date,
  amountMinor: amount,
  seq: seq,
  count: count,
  isPaid: paid,
  remindersEnabled: enabled,
);

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  ReminderSettings settings = const ReminderSettings(),
  LocalDate? today,
  int now = 8 * 60,
  int limit = maxScheduledReminders,
}) => planReminders(
  payments: payments,
  settings: settings,
  today: today ?? d(11, 9),
  nowMinuteOfDay: now,
  limit: limit,
);

void main() {
  group('default settings: 3 days before and on the day, 09:00', () {
    test('one payment gives two reminders; "Paid" only on the day', () {
      final r = plan([pay(1, d(11, 12))]);
      expect(r.map((x) => (x.fireDate, x.offset)), [
        (d(11, 9), ReminderOffset.days3),
        (d(11, 12), ReminderOffset.sameDay),
      ]);
      expect(r.every((x) => x.minuteOfDay == 540), isTrue);
      expect(r[0].paidAction, isNull);
      expect(r[1].paidAction, const PlanPaymentRef(1));
      expect(r[1].route, '/day/2026-11-12');
    });
  });

  group('each offset on its own', () {
    final cases = <(ReminderOffset, LocalDate)>[
      (ReminderOffset.days7, d(11, 13)),
      (ReminderOffset.days3, d(11, 17)),
      (ReminderOffset.days1, d(11, 19)),
      (ReminderOffset.sameDay, d(11, 20)),
    ];
    for (final (offset, fire) in cases) {
      test('${offset.name} fires on $fire', () {
        final r = plan([
          pay(1, d(11, 20)),
        ], settings: ReminderSettings(offsets: {offset}));
        expect(r.single.fireDate, fire);
        expect(r.single.offset, offset);
      });
    }

    test('all four together', () {
      final r = plan([
        pay(1, d(11, 20)),
      ], settings: const ReminderSettings(offsets: {...ReminderOffset.values}));
      expect(r.map((x) => x.fireDate), [
        d(11, 13),
        d(11, 17),
        d(11, 19),
        d(11, 20),
      ]);
    });
  });

  group('grouping', () {
    test('payments on the same day become one summary per offset', () {
      final r = plan([
        pay(1, d(11, 15), name: 'Zip', amount: 100000),
        pay(2, d(11, 15), name: 'Afterpay', amount: 50000),
        pay(3, d(11, 15), name: 'Kira', amount: 95000, seq: null, count: null),
      ]);
      expect(r, hasLength(2));
      for (final x in r) {
        expect(x.isSummary, isTrue);
        expect(x.totalMinor, 245000);
        expect(x.paidAction, isNull);
        expect(x.payments.map((p) => p.name), ['Afterpay', 'Kira', 'Zip']);
      }
    });

    test('a "3 days" and a "today" reminder on the same day stay apart', () {
      // 12 Nov: 3 days before 15 Nov, and the due day of 12 Nov.
      final r = plan([pay(1, d(11, 12)), pay(2, d(11, 15))]);
      final on12 = r.where((x) => x.fireDate == d(11, 12)).toList();
      expect(on12.map((x) => x.offset).toSet(), {
        ReminderOffset.sameDay,
        ReminderOffset.days3,
      });
      expect(on12.map((x) => x.id).toSet(), hasLength(2));
    });
  });

  group('what is never scheduled', () {
    final cases = <(String, List<ReminderPayment>, ReminderSettings)>[
      (
        'paid payment',
        [pay(1, d(11, 20), paid: true)],
        const ReminderSettings(),
      ),
      (
        'plan with reminders off',
        [pay(1, d(11, 20), enabled: false)],
        const ReminderSettings(),
      ),
      (
        'reminders switched off',
        [pay(1, d(11, 20))],
        const ReminderSettings(enabled: false),
      ),
      (
        'no offsets chosen',
        [pay(1, d(11, 20))],
        const ReminderSettings(offsets: {}),
      ),
      (
        'payment already in the past',
        [pay(1, d(11, 1))],
        const ReminderSettings(),
      ),
    ];
    for (final (name, payments, settings) in cases) {
      test(name, () => expect(plan(payments, settings: settings), isEmpty));
    }

    test('paying one of a group turns the summary into a single reminder', () {
      final r = plan([pay(1, d(11, 15)), pay(2, d(11, 15), paid: true)]);
      expect(r.every((x) => !x.isSummary), isTrue);
      expect(r.last.paidAction, const PlanPaymentRef(1));
    });
  });

  group('past times', () {
    final cases = <(int, bool)>[
      (8 * 60, true), // 08:00 now: today's 09:00 is still ahead
      (9 * 60, false), // exactly 09:00: skipped
      (10 * 60, false), // 10:00: skipped
    ];
    for (final (now, scheduled) in cases) {
      test('due today, now ${now ~/ 60}:00 -> scheduled: $scheduled', () {
        final r = plan([pay(1, d(11, 9))], now: now);
        expect(r.any((x) => x.offset == ReminderOffset.sameDay), scheduled);
      });
    }

    test('the "3 days" reminder of a payment due in 2 days is skipped', () {
      final r = plan([pay(1, d(11, 11))]);
      expect(r.map((x) => x.offset), [ReminderOffset.sameDay]);
    });
  });

  test('only the 60 soonest reminders, in order', () {
    final payments = [
      for (var i = 0; i < 100; i++) pay(i, d(11, 10).addDays(i)),
    ];
    final r = plan(payments);
    expect(r, hasLength(maxScheduledReminders));
    for (var i = 1; i < r.length; i++) {
      expect(r[i].fireDate >= r[i - 1].fireDate, isTrue);
    }
    // 12 Nov is three days after today, so its reminder fires today.
    expect(r.first.fireDate, d(11, 9));
  });

  test('ids are stable across runs and unique per day and offset', () {
    final payments = [pay(1, d(11, 15)), pay(2, d(11, 20)), pay(3, d(12, 1))];
    final a = plan(payments).map((x) => x.id).toList();
    final b = plan(payments.reversed.toList()).map((x) => x.id).toList();
    expect(a, b);
    expect(a.toSet(), hasLength(a.length));
    expect(
      PlannedReminder.idFor(d(11, 15), ReminderOffset.days3),
      isNot(PlannedReminder.idFor(d(11, 15), ReminderOffset.sameDay)),
    );
    expect(
      PlannedReminder.idFor(d(11, 15), ReminderOffset.days3),
      lessThan(1 << 31),
    );
  });

  test('card due date on a Saturday: reminders follow the shifted Monday', () {
    // Purchase 20 Nov, statement 25 Nov, due 5 Dec (Saturday) -> 7 Dec.
    final draft = PlanCalculator.card(
      purchaseDate: d(11, 20),
      totalMinor: 300000,
      count: 3,
      terms: const CardTerms(statementDay: 25, dueDay: 5),
    );
    final first = draft.payments.first;
    final r = plan([
      pay(1, first.date, seq: 1, count: 3, amount: first.amountMinor),
    ], today: d(11, 20));
    expect(r.map((x) => x.fireDate), [d(12, 4), d(12, 7)]);
    expect(r.last.dueDate, d(12, 7));
  });

  group('payment references', () {
    final cases = <(PaymentRef, String)>[
      (const PlanPaymentRef(12), 'p:12'),
      (const RecurringRef(3, 20405), 'r:3:20405'),
    ];
    for (final (ref, text) in cases) {
      test(text, () {
        expect(ref.encode(), text);
        expect(PaymentRef.decode(text), ref);
      });
    }
    test('bad payloads decode to null', () {
      for (final bad in [null, '', 'x', 'p:', 'p:a', 'r:1', 'r:1:x']) {
        expect(PaymentRef.decode(bad), isNull, reason: '$bad');
      }
    });
  });

  group('local wall clock', () {
    setUpAll(tzdata.initializeTimeZones);

    test('09:00 stays 09:00 across a daylight-saving change', () {
      final london = tz.getLocation('Europe/London');
      final before = localWallClock(d(3, 27, 2027), 540, london);
      final after = localWallClock(d(3, 28, 2027), 540, london);
      expect(before.hour, 9);
      expect(after.hour, 9);
      expect(before.toUtc().hour, 9); // GMT
      expect(after.toUtc().hour, 8); // BST

      final ny = tz.getLocation('America/New_York');
      expect(localWallClock(d(10, 31), 540, ny).toUtc().hour, 13); // EDT
      expect(localWallClock(d(11, 1), 540, ny).toUtc().hour, 14); // EST
    });

    test('a time inside the spring-forward gap moves forward', () {
      final london = tz.getLocation('Europe/London');
      final t = localWallClock(d(3, 28, 2027), 90, london); // 01:30
      expect(t.isAfter(localWallClock(d(3, 28, 2027), 0, london)), isTrue);
      expect(t.hour, 2);
    });

    test('moving to another time zone keeps the local time', () {
      final istanbul = localWallClock(
        d(11, 12),
        540,
        tz.getLocation('Europe/Istanbul'),
      );
      final london = localWallClock(
        d(11, 12),
        540,
        tz.getLocation('Europe/London'),
      );
      expect(istanbul.hour, 9);
      expect(london.hour, 9);
      expect(london.difference(istanbul), const Duration(hours: 3));
    });
  });
}
