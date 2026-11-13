import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/features/reminders/reminder_texts.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The examples use 2025, where 14 November is a Friday.
LocalDate d(int m, int day, [int y = 2025]) => LocalDate(y, m, day);

late tz.Location istanbul;

tz.TZDateTime at(LocalDate date, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, date.year, date.month, date.day, hour, minute);

const paid = ReminderAction.paid;
const allPaid = ReminderAction.allPaid;
const tonight = ReminderAction.remindTonight;
const tomorrow = ReminderAction.remindTomorrow;

ReminderPayment pay(
  int id,
  LocalDate date, {
  String name = 'Tabby',
  int amount = 40000,
  bool isPaid = false,
  ReminderChoice choice = ReminderChoice.general,
}) => ReminderPayment(
  name: name,
  date: date,
  amountMinor: amount,
  isPaid: isPaid,
  choice: choice,
  ref: PlanPaymentRef(id),
);

ReminderTexts texts([String lang = 'tr']) => L10nReminderTexts(
  l10n: lookupAppLocalizations(Locale(lang)),
  currency: Currency.fromCode('TRY'),
);

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  List<ReminderSnooze> snoozes = const [],
  ReminderSettings settings = const ReminderSettings(),
  tz.TZDateTime? now,
  String lang = 'tr',
  int limit = maxScheduledReminders,
}) => planReminders(
  payments: payments,
  snoozes: snoozes,
  settings: settings,
  now: now ?? at(d(11, 10), 20),
  texts: texts(lang),
  limit: limit,
);

List<ReminderAction> actionsOf(PlannedReminder r) => [
  for (final b in r.buttons) b.action,
];

PlannedReminder only(
  List<PlannedReminder> list,
  LocalDate fireDate,
  ReminderKind kind,
) => list.singleWhere(
  (r) => r.fireDate == fireDate && r.kind == kind && !r.isSnoozed,
);

ReminderSnooze snooze(
  int id,
  List<int> paymentIds, {
  ReminderKind kind = ReminderKind.onDay,
  LocalDate? fireDate,
  int minute = remindTonightMinute,
}) => ReminderSnooze(
  id: id,
  kind: kind,
  fireDate: fireDate ?? d(11, 14),
  minuteOfDay: minute,
  refs: [for (final p in paymentIds) PlanPaymentRef(p)],
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('Can: "1 payment today: Tabby"', () {
    test('on the day: [Paid] [Remind tonight], ahead: [Paid] '
        '[Remind tomorrow]', () {
      final list = plan([pay(7, d(11, 14))]);
      final onDay = only(list, d(11, 14), ReminderKind.onDay);
      expect(onDay.body, 'Bugün 1 ödeme var: Tabby, ₺400');
      expect(onDay.buttons, const [
        ReminderButton(paid, 'Ödendi'),
        ReminderButton(tonight, 'Akşam hatırlat'),
      ]);
      final ahead = only(list, d(11, 12), ReminderKind.ahead);
      expect(ahead.body, '14 Kasım Cuma günü 1 ödeme var: Tabby, ₺400');
      expect(ahead.buttons, const [
        ReminderButton(paid, 'Ödendi'),
        ReminderButton(tomorrow, 'Yarın hatırlat'),
      ]);
      // A tap still opens the home screen.
      expect(onDay.payload, reminderPayload);
    });

    test('button names in English', () {
      final list = plan([
        pay(7, d(11, 14)),
        pay(8, d(11, 14), name: 'Zip'),
      ], lang: 'en');
      expect(only(list, d(11, 14), ReminderKind.onDay).buttons, const [
        ReminderButton(allPaid, 'All paid'),
        ReminderButton(tonight, 'Remind tonight'),
      ]);
      expect(only(list, d(11, 12), ReminderKind.ahead).buttons, const [
        ReminderButton(allPaid, 'All paid'),
        ReminderButton(tomorrow, 'Remind tomorrow'),
      ]);
      expect(
        plan([pay(7, d(11, 14))], lang: 'en').first.buttons.first.title,
        'Paid',
      );
    });

    test('the payload carries kind, time and payments', () {
      final onDay = only(plan([pay(7, d(11, 14))]), d(11, 14), .onDay);
      final data = ReminderPayload.decode(onDay.data!.encode())!;
      expect(data.kind, ReminderKind.onDay);
      expect(data.snoozed, isFalse);
      expect(data.fireDate, d(11, 14));
      expect(data.minuteOfDay, 540);
      expect(data.refs, [const PlanPaymentRef(7)]);
    });
  });

  group('which buttons', () {
    // kind, minute, payment due dates, fire day, snoozed, expected
    final cases =
        <
          (
            String,
            ReminderKind,
            int,
            List<LocalDate>,
            LocalDate,
            bool,
            List<ReminderAction>,
          )
        >[
          (
            'on day, 09:00',
            .onDay,
            540,
            [d(11, 14)],
            d(11, 14),
            false,
            [paid, tonight],
          ),
          (
            'on day, 18:00',
            .onDay,
            1080,
            [d(11, 14)],
            d(11, 14),
            false,
            [paid, tonight],
          ),
          (
            'on day, 18:01',
            .onDay,
            1081,
            [d(11, 14)],
            d(11, 14),
            false,
            [paid],
          ),
          (
            'on day, 20:30 (Example 5)',
            .onDay,
            1230,
            [d(11, 14)],
            d(11, 14),
            false,
            [paid],
          ),
          (
            'on day, three payments',
            .onDay,
            540,
            [d(11, 14), d(11, 14), d(11, 14)],
            d(11, 14),
            false,
            [allPaid, tonight],
          ),
          (
            'ahead, 2 days before',
            .ahead,
            540,
            [d(11, 14)],
            d(11, 12),
            false,
            [paid, tomorrow],
          ),
          (
            'ahead, 1 day before',
            .ahead,
            540,
            [d(11, 14)],
            d(11, 13),
            false,
            [paid],
          ),
          (
            'ahead, one of two due tomorrow',
            .ahead,
            540,
            [d(11, 14), d(11, 16)],
            d(11, 13),
            false,
            [allPaid],
          ),
          (
            'snoozed on-day',
            .onDay,
            1200,
            [d(11, 14)],
            d(11, 14),
            true,
            [paid],
          ),
          (
            'snoozed ahead, several',
            .ahead,
            540,
            [d(11, 14), d(11, 14)],
            d(11, 13),
            true,
            [allPaid],
          ),
        ];
    for (final (name, kind, minute, dates, fire, snoozed, expected) in cases) {
      test(name, () {
        expect(
          reminderActions(
            kind: kind,
            snoozed: snoozed,
            payments: [for (final (i, date) in dates.indexed) pay(i, date)],
            fireDate: fire,
            minuteOfDay: minute,
          ),
          expected,
        );
      });
    }

    test('a payment without a stored id: no buttons, no data', () {
      final list = plan([
        ReminderPayment(name: 'Tabby', date: d(11, 14), amountMinor: 40000),
      ]);
      expect(list, isNotEmpty);
      for (final r in list) {
        expect(r.buttons, isEmpty);
        expect(r.data, isNull);
      }
    });

    test('"Remind tomorrow" hidden with 1 day before', () {
      final list = plan([pay(7, d(11, 14), choice: ReminderChoice.days(1))]);
      expect(actionsOf(only(list, d(11, 13), .ahead)), [paid]);
    });
  });

  group('when a snooze fires', () {
    test('"Remind tonight": 20:00 on the day it fired', () {
      final data = ReminderPayload(
        kind: ReminderKind.onDay,
        fireDate: d(11, 14),
        minuteOfDay: 540,
        refs: const [PlanPaymentRef(7)],
      );
      expect(snoozeTarget(data, tonight), (
        fireDate: d(11, 14),
        minuteOfDay: 1200,
      ));
      expect(snoozeTarget(data, tomorrow), isNull);
      expect(snoozeTarget(data, paid), isNull);
    });

    test('"Remind tomorrow": the next day, same time', () {
      final data = ReminderPayload(
        kind: ReminderKind.ahead,
        fireDate: d(11, 12),
        minuteOfDay: 615,
        refs: const [PlanPaymentRef(7)],
      );
      expect(snoozeTarget(data, tomorrow), (
        fireDate: d(11, 13),
        minuteOfDay: 615,
      ));
      expect(snoozeTarget(data, tonight), isNull);
    });

    test('a snoozed reminder is never snoozed again', () {
      final data = ReminderPayload(
        kind: ReminderKind.onDay,
        snoozed: true,
        fireDate: d(11, 14),
        minuteOfDay: 1200,
        refs: const [PlanPaymentRef(7)],
      );
      expect(snoozeTarget(data, tonight), isNull);
    });
  });

  group('snoozed reminders in the plan', () {
    final payments = [
      pay(1, d(11, 14), name: 'Tabby', amount: 40000),
      pay(2, d(11, 14), name: 'Klarna', amount: 85000),
      pay(3, d(11, 14), name: 'Zip', amount: 120000),
    ];
    tz.TZDateTime morning() => at(d(11, 14), 9, 5);

    test('Example 4: same text, only "All paid", at 20:00', () {
      final list = plan(
        payments,
        snoozes: [
          snooze(5, [1, 2, 3]),
        ],
        now: morning(),
      );
      final s = list.singleWhere((r) => r.isSnoozed);
      expect(s.fireAt, at(d(11, 14), 20));
      expect(s.body, 'Bugün 3 ödeme var, toplam ₺2.450');
      expect(s.buttons, const [ReminderButton(allPaid, 'Hepsi ödendi')]);
      expect(s.id, PlannedReminder.idForSnooze(5));
      expect(s.data!.snoozed, isTrue);
      expect(ReminderPayload.decode(s.data!.encode())!.snoozed, isTrue);
    });

    test('"show amount" off: the snoozed text has no amount', () {
      final list = plan(
        payments,
        snoozes: [
          snooze(5, [1]),
        ],
        now: morning(),
        settings: const ReminderSettings(showAmounts: false),
      );
      expect(
        list.singleWhere((r) => r.isSnoozed).body,
        'Bugün 1 ödeme var: Tabby',
      );
    });

    test('one paid meanwhile: the snooze carries the other two', () {
      final list = plan(
        [
          payments[0],
          pay(2, d(11, 14), name: 'Klarna', amount: 85000, isPaid: true),
          payments[2],
        ],
        snoozes: [
          snooze(5, [1, 2, 3]),
        ],
        now: morning(),
      );
      final s = list.singleWhere((r) => r.isSnoozed);
      expect(s.payments.map((p) => p.name), ['Tabby', 'Zip']);
      expect(s.body, 'Bugün 2 ödeme var, toplam ₺1.600');
    });

    test('kept by a full reschedule: same input, same snooze', () {
      final first = plan(
        payments,
        snoozes: [
          snooze(5, [1, 2, 3]),
        ],
        now: morning(),
      );
      final again = plan(
        payments,
        snoozes: [
          snooze(5, [1, 2, 3]),
        ],
        now: morning(),
      );
      expect(again.map((r) => r.id), first.map((r) => r.id));
      expect(again.where((r) => r.isSnoozed), hasLength(1));
    });

    test('none when all are paid, the time has passed or reminders off', () {
      final allPaidNow = [
        for (final p in payments)
          pay((p.ref! as PlanPaymentRef).paymentId, p.date, isPaid: true),
      ];
      expect(
        plan(
          allPaidNow,
          snoozes: [
            snooze(5, [1, 2, 3]),
          ],
          now: morning(),
        ).where((r) => r.isSnoozed),
        isEmpty,
      );
      expect(
        plan(
          payments,
          snoozes: [
            snooze(5, [1]),
          ],
          now: at(d(11, 14), 20, 1),
        ).where((r) => r.isSnoozed),
        isEmpty,
      );
      expect(
        plan(
          [pay(1, d(11, 14), choice: ReminderChoice.disabled)],
          snoozes: [
            snooze(5, [1]),
          ],
          now: morning(),
        ),
        isEmpty,
      );
      expect(
        plan(
          payments,
          snoozes: [
            snooze(5, [1]),
          ],
          now: morning(),
          settings: const ReminderSettings(enabled: false),
        ),
        isEmpty,
      );
    });

    test('a deleted payment is left out', () {
      final list = plan(
        [payments[0]],
        snoozes: [
          snooze(5, [1, 99]),
        ],
        now: morning(),
      );
      expect(list.singleWhere((r) => r.isSnoozed).payments, [payments[0]]);
    });

    test('stale snoozes: passed, all paid or gone; live ones stay', () {
      final stale = staleSnoozeIds(
        snoozes: [
          snooze(1, [1]), // live: Tabby unpaid, 20:00 still ahead
          snooze(2, [1], fireDate: d(11, 13)), // yesterday
          snooze(3, [4]), // paid
          snooze(4, [99]), // deleted
          snooze(5, [4, 1]), // one paid, one not: live
        ],
        payments: [payments[0], pay(4, d(11, 14), isPaid: true)],
        now: morning(),
      );
      expect(stale, {2, 3, 4});
    });

    test('snoozes count towards the 60 limit, by time', () {
      // 40 payments a day apart: 80 notifications, the cap keeps 60.
      final many = [
        for (var i = 0; i < 40; i++) pay(100 + i, d(11, 20).addDays(i)),
      ];
      final withSnooze = plan(
        [...many, payments[0]],
        snoozes: [
          snooze(5, [1]),
        ],
        now: morning(),
      );
      expect(withSnooze, hasLength(maxScheduledReminders));
      expect(withSnooze.where((r) => r.isSnoozed), hasLength(1));
      // The snooze is today, so it is among the soonest; the latest
      // regular reminder made room for it.
      final without = plan([...many, payments[0]], now: morning());
      expect(withSnooze.map((r) => r.id), isNot(contains(without.last.id)));
      expect(
        withSnooze.where((r) => !r.isSnoozed).map((r) => r.id),
        without.take(maxScheduledReminders - 1).map((r) => r.id),
      );
      expect(
        withSnooze.map((r) => r.fireAt).toList(),
        [...withSnooze.map((r) => r.fireAt)]..sort(),
      );
    });
  });

  group('payload', () {
    test('round trip, both kinds and recurring payments', () {
      final data = ReminderPayload(
        kind: ReminderKind.ahead,
        fireDate: d(11, 12),
        minuteOfDay: 540,
        refs: [const PlanPaymentRef(12), RecurringRef(3, d(12, 1))],
      );
      final back = ReminderPayload.decode(data.encode())!;
      expect(back.kind, ReminderKind.ahead);
      expect(back.refs, data.refs);
      expect((back.refs[1] as RecurringRef).date, d(12, 1));
    });

    test('old, damaged or foreign payloads are null, never an error', () {
      for (final raw in [
        null,
        '',
        'home',
        '{',
        '[]',
        '{"v":2,"t":"onDay","k":"onDay","d":1,"m":540,"r":["p1"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":540,"r":[]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":540,"r":["x1"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":540,"r":["p"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":540,"r":["r1"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":1440,"r":["p1"]}',
        '{"v":1,"t":"ahead","k":"onDay","d":1,"m":540,"r":["p1"]}',
        '{"v":1,"t":"onDay","k":"later","d":1,"m":540,"r":["p1"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":"1","m":540,"r":["p1"]}',
        '{"v":1,"t":"onDay","k":"onDay","d":1,"m":540,"r":[1]}',
      ]) {
        expect(ReminderPayload.decode(raw), isNull, reason: raw);
      }
    });

    test('payment keys', () {
      expect(const PlanPaymentRef(12).key, 'p12');
      expect(RecurringRef(3, d(12, 1)).key, 'r3.${d(12, 1).epochDay}');
      expect(PaymentRef.parse('p12'), const PlanPaymentRef(12));
      expect(PaymentRef.parse('p-1'), isNull);
      expect(PaymentRef.parse('r3'), isNull);
      expect(PaymentRef.parse('r3.x'), isNull);
    });
  });
}
