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

/// 2025, as the other reminder tests: 14 November is a Friday.
LocalDate d(int m, int day, [int y = 2025]) => LocalDate(y, m, day);

late tz.Location istanbul;

tz.TZDateTime at(LocalDate date, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, date.year, date.month, date.day, hour, minute);

const ahead = ReminderKind.ahead;
const onDay = ReminderKind.onDay;
const overdue = ReminderKind.overdue;
const paidAction = ReminderAction.paid;
const allPaid = ReminderAction.allPaid;
const tomorrow = ReminderAction.remindTomorrow;
const tonight = ReminderAction.remindTonight;

ReminderPayment pay(
  int id,
  LocalDate due, {
  String name = 'Tabby',
  int amount = 40000,
  bool isPaid = false,
  ReminderChoice choice = ReminderChoice.general,
  ReminderRepeat? repeat,
}) => ReminderPayment(
  name: name,
  date: due,
  amountMinor: amount,
  isPaid: isPaid,
  choice: choice,
  ref: PlanPaymentRef(id),
  repeat: repeat,
);

ReminderSettings settings({
  ReminderRepeat mode = ReminderRepeat.daily,
  int minute = 540,
  int leadDays = 2,
  bool showAmounts = true,
}) => ReminderSettings(
  repeatMode: mode,
  minuteOfDay: minute,
  leadDays: leadDays,
  showAmounts: showAmounts,
);

ReminderTexts texts([String lang = 'tr']) => L10nReminderTexts(
  l10n: lookupAppLocalizations(Locale(lang)),
  currency: Currency.fromCode('TRY'),
);

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  required ReminderSettings settings,
  required tz.TZDateTime now,
  List<ReminderSnooze> snoozes = const [],
  String lang = 'tr',
  int limit = maxScheduledReminders,
  tz.Location? location,
}) => planReminders(
  payments: payments,
  settings: settings,
  now: now,
  texts: texts(lang),
  snoozes: snoozes,
  limit: limit,
);

/// (day, hour, minute, kind) of each reminder, in order.
List<(LocalDate, int, int, ReminderKind)> slots(List<PlannedReminder> list) => [
  for (final r in list) (r.fireDate, r.fireAt.hour, r.fireAt.minute, r.kind),
];

PlannedReminder atMoment(
  List<PlannedReminder> list,
  LocalDate day,
  int hour, [
  int minute = 0,
]) => list.singleWhere(
  (r) =>
      r.fireDate == day && r.fireAt.hour == hour && r.fireAt.minute == minute,
);

List<ReminderAction> actionsOf(PlannedReminder r) => [
  for (final b in r.buttons) b.action,
];

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('Example 1: Hiroshi, every day, 3 days before, 09:00', () {
    final due = d(11, 27);
    final s = settings(leadDays: 3);
    final payments = [pay(1, due, name: 'Konbini', amount: 120000)];

    test('from the "ahead" day, twice a day, all "ahead" before the 27th', () {
      final list = plan(payments, settings: s, now: at(d(11, 23), 20));
      expect(slots(list).take(8), [
        (d(11, 24), 9, 0, ahead),
        (d(11, 24), 20, 0, ahead),
        (d(11, 25), 9, 0, ahead),
        (d(11, 25), 20, 0, ahead),
        (d(11, 26), 9, 0, ahead),
        (d(11, 26), 20, 0, ahead),
        (d(11, 27), 9, 0, onDay),
        (d(11, 27), 20, 0, onDay),
      ]);
      // The same text every time, as the first reminder.
      final first = list.first.body;
      expect(first, '27 Kasım Perşembe günü 1 ödeme var: Konbini, ₺1.200');
      for (final r in list.take(6)) {
        expect(r.body, first);
      }
      // The morning of the 24th is the usual "ahead" reminder (same id).
      expect(list.first.id, PlannedReminder.idFor(d(11, 24), ahead));
    });

    test('paid at 12:00 on the 26th: nothing more for it', () {
      final list = plan(
        [pay(1, due, isPaid: true)],
        settings: s,
        now: at(d(11, 26), 12),
      );
      expect(list, isEmpty);
    });

    test('the window ends 7 days after the due date', () {
      final list = plan(payments, settings: s, now: at(d(11, 23), 20));
      // 24 Nov .. 4 Dec: 11 days, twice a day.
      expect(list, hasLength(22));
      expect(list.last.fireDate, d(12, 4));
      expect(list.last.fireAt.hour, 20);
    });
  });

  group('Example 2: once more in the evening, 2 days before', () {
    final s = settings(mode: ReminderRepeat.evening);

    test('the reminder days get 20:00 too; nothing in between or after', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: s,
        now: at(d(11, 10), 20),
      );
      expect(slots(list), [
        (d(11, 12), 9, 0, ahead),
        (d(11, 12), 20, 0, ahead),
        (d(11, 14), 9, 0, onDay),
        (d(11, 14), 20, 0, onDay),
      ]);
    });

    test('morning buttons: [Paid] [Remind tomorrow], not "tonight"', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: s,
        now: at(d(11, 10), 20),
      );
      expect(actionsOf(atMoment(list, d(11, 14), 9)), [paidAction, tomorrow]);
      expect(actionsOf(atMoment(list, d(11, 12), 9)), [paidAction, tomorrow]);
      expect(actionsOf(atMoment(list, d(11, 14), 20)), [paidAction, tomorrow]);
      expect(atMoment(list, d(11, 14), 9).data!.repeating, isTrue);
    });
  });

  group('Example 3: the longest it goes on', () {
    test('overdue twice a day for 7 days, then nothing', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: settings(),
        now: at(d(11, 14), 21),
      );
      expect(list, hasLength(14));
      expect(list.every((r) => r.kind == overdue), isTrue);
      expect(list.first.fireDate, d(11, 15));
      expect(list.last.fireDate, d(11, 21));
      expect(list.last.fireAt.hour, 20);
      for (final r in list) {
        expect(
          r.body,
          "14 Kasım'daki 1 ödeme henüz işaretlenmedi: Tabby, ₺400",
        );
      }
      // 21 November 20:00: no "Remind tomorrow", there is no tomorrow.
      expect(actionsOf(list.last), [paidAction]);
      expect(actionsOf(atMoment(list, d(11, 21), 9)), [paidAction]);
      expect(actionsOf(atMoment(list, d(11, 20), 20)), [paidAction, tomorrow]);
      expect(
        plan([pay(1, d(11, 14))], settings: settings(), now: at(d(11, 21), 21)),
        isEmpty,
      );
    });

    test('overdue texts: hidden amount, English, several', () {
      final now = at(d(11, 14), 21);
      expect(
        plan(
          [pay(1, d(11, 14))],
          settings: settings(showAmounts: false),
          now: now,
        ).first.body,
        "14 Kasım'daki 1 ödeme henüz işaretlenmedi: Tabby",
      );
      expect(
        plan(
          [pay(1, d(11, 14))],
          settings: settings(),
          now: now,
          lang: 'en',
        ).first.body,
        "1 payment from November 14 isn't marked paid yet: Tabby, ₺400",
      );
      expect(
        plan(
          [pay(1, d(11, 14))],
          settings: settings(showAmounts: false),
          now: now,
          lang: 'en',
        ).first.body,
        "1 payment from November 14 isn't marked paid yet: Tabby",
      );
    });

    test('the Turkish date ending follows the month', () {
      for (final (due, phrase) in [
        (d(1, 6), "6 Ocak'taki"),
        (d(4, 7), "7 Nisan'daki"),
        (d(9, 9), "9 Eylül'deki"),
        (d(10, 8), "8 Ekim'deki"),
        (d(12, 1), "1 Aralık'taki"),
      ]) {
        final list = plan(
          [pay(1, due)],
          settings: settings(),
          now: at(due, 21),
        );
        expect(list.first.body, startsWith(phrase), reason: '$due');
      }
    });
  });

  group('Example 4: "Remind tomorrow" on a repeat', () {
    final due = d(11, 27);
    final s = settings(leadDays: 3);

    test('the rest of the 25th is skipped; from the 26th as usual', () {
      final list = plan(
        [pay(1, due)],
        settings: s,
        now: at(d(11, 25), 9, 5),
        snoozes: [
          ReminderSnooze(
            id: 3,
            kind: ahead,
            fireDate: d(11, 26),
            minuteOfDay: 540,
            refs: const [PlanPaymentRef(1)],
            skipsDay: true,
          ),
        ],
      );
      expect(list.any((r) => r.fireDate == d(11, 25)), isFalse);
      expect(slots(list).take(3), [
        (d(11, 26), 9, 0, ahead),
        (d(11, 26), 20, 0, ahead),
        (d(11, 27), 9, 0, onDay),
      ]);
      // No second notification at 26 Nov 09:00.
      expect(list.where((r) => r.fireDate == d(11, 26)), hasLength(2));
    });

    test('"once more in the evening": tomorrow is reminded once', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: settings(mode: ReminderRepeat.evening),
        now: at(d(11, 14), 9, 5),
        snoozes: [
          ReminderSnooze(
            id: 3,
            kind: onDay,
            fireDate: d(11, 15),
            minuteOfDay: 540,
            refs: const [PlanPaymentRef(1)],
            skipsDay: true,
          ),
        ],
      );
      expect(slots(list), [(d(11, 15), 9, 0, overdue)]);
      expect(actionsOf(list.single), [paidAction, tomorrow]);
    });

    test('a snooze at a repeat moment is not a second notification', () {
      final list = plan(
        [pay(1, due)],
        settings: s,
        now: at(d(11, 24), 9, 5),
        snoozes: [
          // "Remind tomorrow" from before repeats were turned on.
          ReminderSnooze(
            id: 4,
            kind: ahead,
            fireDate: d(11, 25),
            minuteOfDay: 540,
            refs: const [PlanPaymentRef(1)],
          ),
        ],
      );
      expect(
        list.where((r) => r.fireDate == d(11, 25) && r.fireAt.hour == 9),
        hasLength(1),
      );
      expect(list.any((r) => r.isSnoozed), isFalse);
    });

    test('a skip for another payment changes nothing', () {
      final before = plan([pay(1, due)], settings: s, now: at(d(11, 25), 9, 5));
      final after = plan(
        [pay(1, due)],
        settings: s,
        now: at(d(11, 25), 9, 5),
        snoozes: [
          ReminderSnooze(
            id: 3,
            kind: ahead,
            fireDate: d(11, 26),
            minuteOfDay: 540,
            refs: const [PlanPaymentRef(2)],
            skipsDay: true,
          ),
        ],
      );
      expect(after.map((r) => r.id), before.map((r) => r.id));
    });
  });

  group('Example 5: reminder time 19:30', () {
    test('every day: once a day at 19:30, never at 20:00', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: settings(minute: 19 * 60 + 30),
        now: at(d(11, 10), 20),
      );
      expect(list.every((r) => r.fireAt.hour == 19), isTrue);
      expect(list.every((r) => r.fireAt.minute == 30), isTrue);
      // 12 Nov .. 21 Nov, one a day.
      expect(list, hasLength(10));
    });

    test('"once more in the evening" does nothing', () {
      final s = settings(mode: ReminderRepeat.evening, minute: 19 * 60 + 30);
      final off = settings(mode: ReminderRepeat.off, minute: 19 * 60 + 30);
      final now = at(d(11, 10), 20);
      final a = plan([pay(1, d(11, 14))], settings: s, now: now);
      final b = plan([pay(1, d(11, 14))], settings: off, now: now);
      expect(a.map((r) => r.id), b.map((r) => r.id));
      expect(
        [for (final r in a) actionsOf(r)],
        [for (final r in b) actionsOf(r)],
      );
    });
  });

  group('Example 6: merged overdue', () {
    test('one notification for A and B at 20:00', () {
      final list = plan(
        [
          pay(1, d(11, 18), name: 'Zip', amount: 85000),
          pay(2, d(11, 17), name: 'Tabby', amount: 40000),
        ],
        settings: settings(),
        now: at(d(11, 20), 19),
      );
      final r = atMoment(list, d(11, 20), 20);
      expect(r.kind, overdue);
      expect(r.body, '2 ödeme henüz işaretlenmedi, toplam ₺1.250');
      expect(actionsOf(r), [allPaid, tomorrow]);
      expect(r.payments.map((p) => p.name), ['Tabby', 'Zip']);
      expect(
        plan(
          [
            pay(1, d(11, 18), name: 'Zip', amount: 85000),
            pay(2, d(11, 17), name: 'Tabby', amount: 40000),
          ],
          settings: settings(showAmounts: false),
          now: at(d(11, 20), 19),
          lang: 'en',
        ).first.body,
        "2 payments aren't marked paid yet",
      );
    });
  });

  group('modes', () {
    final payments = [
      pay(1, d(11, 14)),
      pay(2, d(11, 14), name: 'Zip'),
      pay(3, d(11, 20), choice: ReminderChoice.days(5)),
      pay(4, d(12, 1), name: 'Kira', amount: 1500000),
    ];
    tz.TZDateTime now() => at(d(11, 10), 20);

    test('off: exactly the reminders from before repeat reminders', () {
      final off = plan(
        payments,
        settings: settings(mode: ReminderRepeat.off),
        now: now(),
      );
      // Payments without a repeat field and default settings: the old path.
      final old = planReminders(
        payments: [
          for (final p in payments)
            ReminderPayment(
              name: p.name,
              date: p.date,
              amountMinor: p.amountMinor,
              choice: p.choice,
              ref: p.ref,
            ),
        ],
        settings: const ReminderSettings(),
        now: now(),
        texts: texts(),
      );
      expect(off.map((r) => r.id), old.map((r) => r.id));
      expect(off.map((r) => r.body), old.map((r) => r.body));
      expect(off.map((r) => r.fireAt), old.map((r) => r.fireAt));
      expect(
        [for (final r in off) actionsOf(r)],
        [for (final r in old) actionsOf(r)],
      );
      expect(off.every((r) => r.kind != overdue), isTrue);
      expect(off.every((r) => r.data?.repeating != true), isTrue);
    });

    test('the plan choice wins over the global one', () {
      final s = settings(mode: ReminderRepeat.daily);
      expect(repeatModeFor(pay(1, d(11, 14)), s), ReminderRepeat.daily);
      expect(
        repeatModeFor(pay(1, d(11, 14), repeat: ReminderRepeat.off), s),
        ReminderRepeat.off,
      );
      expect(
        repeatModeFor(
          pay(1, d(11, 14), repeat: ReminderRepeat.evening),
          settings(mode: ReminderRepeat.off),
        ),
        ReminderRepeat.evening,
      );
      // The plan's reminders off: no repeats either.
      expect(
        repeatModeFor(pay(1, d(11, 14), choice: ReminderChoice.disabled), s),
        ReminderRepeat.off,
      );
      expect(
        plan(
          [pay(1, d(11, 14), choice: ReminderChoice.disabled)],
          settings: s,
          now: now(),
        ),
        isEmpty,
      );
    });

    test('paid (also before Kalan) gets no repeats', () {
      expect(
        plan(
          [pay(1, d(11, 5), isPaid: true), pay(2, d(11, 14), isPaid: true)],
          settings: settings(),
          now: now(),
        ),
        isEmpty,
      );
    });

    test('past moments are left out', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: settings(),
        now: at(d(11, 16), 9),
      );
      expect(list.first.fireAt, at(d(11, 16), 20));
    });

    test('kinds follow the day: ahead, on day, overdue', () {
      final list = plan(
        [pay(1, d(11, 14), choice: ReminderChoice.days(1))],
        settings: settings(),
        now: at(d(11, 10), 20),
      );
      expect(slots(list).take(6), [
        (d(11, 13), 9, 0, ahead),
        (d(11, 13), 20, 0, ahead),
        (d(11, 14), 9, 0, onDay),
        (d(11, 14), 20, 0, onDay),
        (d(11, 15), 9, 0, overdue),
        (d(11, 15), 20, 0, overdue),
      ]);
    });

    test('7 days before: a 15-day window', () {
      final list = plan(
        [pay(1, d(11, 30), choice: ReminderChoice.days(7))],
        settings: settings(),
        now: at(d(11, 20), 20),
      );
      expect(list.first.fireDate, d(11, 23));
      expect(list.last.fireDate, d(12, 7));
      expect(list, hasLength(30));
    });

    test('the 60 limit: soonest first, repeats included', () {
      final many = [
        for (var i = 0; i < 10; i++)
          pay(i, d(11, 20).addDays(i * 3), name: 'P$i'),
      ];
      final list = plan(many, settings: settings(), now: at(d(11, 10), 20));
      expect(list, hasLength(maxScheduledReminders));
      final times = list.map((r) => r.fireAt).toList();
      expect(times, [...times]..sort());
      expect(list.any((r) => r.kind == overdue), isTrue);
    });

    test('ids: the same every run, all different', () {
      final a = plan(payments, settings: settings(), now: now());
      final b = plan(payments, settings: settings(), now: now());
      expect(a.map((r) => r.id), b.map((r) => r.id));
      expect(a.map((r) => r.id).toSet(), hasLength(a.length));
      for (final r in a) {
        expect(r.id, lessThan(PlannedReminder.snoozeIdBase));
      }
    });

    test('daylight saving: 09:00 and 20:00 stay local', () {
      final london = tz.getLocation('Europe/London');
      // Clocks go back on Sunday 26 October 2025.
      final list = planReminders(
        payments: [pay(1, d(10, 27))],
        settings: settings(leadDays: 2),
        now: tz.TZDateTime(london, 2025, 10, 24, 12),
        texts: texts(),
      );
      for (final r in list.take(8)) {
        expect([9, 20], contains(r.fireAt.hour), reason: '${r.fireDate}');
        expect(r.fireAt.minute, 0);
      }
      final before = list.firstWhere((r) => r.fireDate == d(10, 25));
      final after = list.firstWhere((r) => r.fireDate == d(10, 27));
      expect(before.fireAt.toUtc().hour, 8); // BST
      expect(after.fireAt.toUtc().hour, 9); // GMT
    });
  });

  group('buttons with repeats', () {
    test('"Remind tomorrow" skips: a skip date, never a snooze', () {
      final data = ReminderPayload(
        kind: overdue,
        fireDate: d(11, 25),
        minuteOfDay: 1200,
        refs: const [PlanPaymentRef(1)],
        repeating: true,
      );
      expect(repeatSkipDate(data, tomorrow), d(11, 26));
      expect(repeatSkipDate(data, paidAction), isNull);
      expect(snoozeTarget(data, tomorrow), isNull);
      final back = ReminderPayload.decode(data.encode())!;
      expect(back.repeating, isTrue);
      expect(back.kind, overdue);
    });

    test('without repeats the 4th item buttons stay as they were', () {
      final list = plan(
        [pay(1, d(11, 14))],
        settings: settings(mode: ReminderRepeat.off),
        now: at(d(11, 10), 20),
      );
      expect(actionsOf(atMoment(list, d(11, 14), 9)), [paidAction, tonight]);
      expect(actionsOf(atMoment(list, d(11, 12), 9)), [paidAction, tomorrow]);
      expect(atMoment(list, d(11, 12), 9).data!.repeating, isFalse);
    });
  });
}
