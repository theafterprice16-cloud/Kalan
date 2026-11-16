import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/core/reminders/reminder_time.dart';
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

ReminderPayment pay(
  LocalDate date, {
  String name = 'Klarna',
  int amount = 85000,
  bool paid = false,
  ReminderChoice choice = ReminderChoice.general,
  PaymentMethod? method,
}) => ReminderPayment(
  name: name,
  date: date,
  amountMinor: amount,
  isPaid: paid,
  choice: choice,
  method: method,
);

ReminderTexts texts([String lang = 'tr', String currency = 'TRY']) =>
    L10nReminderTexts(
      l10n: lookupAppLocalizations(Locale(lang)),
      currency: Currency.fromCode(currency),
    );

List<PlannedReminder> plan(
  List<ReminderPayment> payments, {
  ReminderSettings settings = const ReminderSettings(),
  tz.TZDateTime? now,
  String lang = 'tr',
  String currency = 'TRY',
  int limit = maxScheduledReminders,
}) => planReminders(
  payments: payments,
  settings: settings,
  now: now ?? at(d(11, 10), 20),
  texts: texts(lang, currency),
  limit: limit,
);

List<(LocalDate, ReminderKind)> slots(List<PlannedReminder> r) => [
  for (final x in r) (x.fireDate, x.kind),
];

const ahead = ReminderKind.ahead;
const onDay = ReminderKind.onDay;

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting();
  });

  group('the product examples', () {
    test('Ayşe: two notifications for one payment, at 09:00', () {
      final r = plan([pay(d(11, 14))]);
      expect(slots(r), [(d(11, 12), ahead), (d(11, 14), onDay)]);
      expect(r.map((x) => x.fireAt), [at(d(11, 12), 9), at(d(11, 14), 9)]);
      expect(r[0].body, '14 Kasım Cuma günü 1 ödeme var: Klarna, ₺850');
      expect(r[1].body, 'Bugün 1 ödeme var: Klarna, ₺850');
      expect(r.every((x) => x.title == 'Kalan'), isTrue);
      expect(r.every((x) => x.payload == reminderPayload), isTrue);
    });

    test('A, B (3 days) and paid C', () {
      final r = plan([
        pay(d(11, 14), name: 'A'),
        pay(
          d(11, 14),
          name: 'B',
          amount: 160000,
          choice: ReminderChoice.days(3),
        ),
        pay(d(11, 12), name: 'C', paid: true),
      ]);
      expect(slots(r), [
        (d(11, 11), ahead),
        (d(11, 12), ahead),
        (d(11, 14), onDay),
      ]);
      expect(r[0].payments.map((p) => p.name), ['B']);
      expect(r[1].payments.map((p) => p.name), ['A']);
      expect(r[2].payments.map((p) => p.name), ['A', 'B']);
      expect(r[2].body, 'Bugün 2 ödeme var, toplam ₺2.450');
      expect(r[2].expandedBody, 'Bugün 2 ödeme var, toplam ₺2.450\nA, B');
      expect(r.expand((x) => x.payments).any((p) => p.name == 'C'), isFalse);
    });

    // (lead days, amounts shown, payments, language, expected body)
    final bodies = <(ReminderKind, bool, int, String, String)>[
      (ahead, true, 1, 'tr', '14 Kasım Cuma günü 1 ödeme var: Klarna, ₺850'),
      (ahead, true, 3, 'tr', '14 Kasım Cuma günü 3 ödeme var, toplam ₺2.550'),
      (onDay, true, 1, 'tr', 'Bugün 1 ödeme var: Klarna, ₺850'),
      (onDay, false, 3, 'tr', 'Bugün 3 ödeme var'),
      (ahead, false, 1, 'tr', '14 Kasım Cuma günü 1 ödeme var: Klarna'),
      (ahead, true, 1, 'en', '1 payment on Friday, November 14: Klarna, ₺850'),
      (
        ahead,
        true,
        3,
        'en',
        '3 payments on Friday, November 14, ₺2,550 in total',
      ),
      (onDay, true, 1, 'en', '1 payment today: Klarna, ₺850'),
      (onDay, false, 3, 'en', '3 payments today'),
      (ahead, false, 1, 'en', '1 payment on Friday, November 14: Klarna'),
    ];
    for (final (kind, show, count, lang, body) in bodies) {
      test('$lang ${kind.name} x$count -> "$body"', () {
        final r = plan(
          [for (var i = 0; i < count; i++) pay(d(11, 14))],
          settings: ReminderSettings(showAmounts: show),
          lang: lang,
        );
        expect(r.firstWhere((x) => x.kind == kind).body, body);
      });
    }
  });

  group('grouping', () {
    test('same day and same kind: always one notification', () {
      final r = plan([
        pay(d(11, 14), name: 'Klarna'),
        pay(d(11, 14), name: 'Afterpay'),
      ]);
      expect(slots(r), [(d(11, 12), ahead), (d(11, 14), onDay)]);
      expect(r[0].payments.map((p) => p.name), ['Afterpay', 'Klarna']);
    });

    test('different lead days meeting on one day merge by fire day', () {
      final r = plan([
        pay(d(11, 13), name: 'A', amount: 100000), // 2 days -> 11 Nov
        pay(
          d(11, 14),
          name: 'B',
          amount: 50000,
          choice: ReminderChoice.days(3), // -> 11 Nov
        ),
      ]);
      final first = r.first;
      expect((first.fireDate, first.kind), (d(11, 11), ahead));
      expect(first.dueDates, [d(11, 13), d(11, 14)]);
      expect(
        first.body,
        '13 Kasım Perşembe gününden itibaren 2 ödeme var, toplam ₺1.500',
      );
    });

    test('an "ahead" and an "on day" on the same day stay apart', () {
      final r = plan([pay(d(11, 12), name: 'A'), pay(d(11, 14), name: 'B')]);
      final onTwelfth = r.where((x) => x.fireDate == d(11, 12)).toList();
      expect(onTwelfth.map((x) => x.kind), [ahead, onDay]);
    });
  });

  group('never scheduled', () {
    final cases = <(String, List<ReminderPayment>, ReminderSettings)>[
      ('paid', [pay(d(11, 14), paid: true)], const ReminderSettings()),
      (
        'plan set to "Off"',
        [pay(d(11, 14), choice: ReminderChoice.disabled)],
        const ReminderSettings(),
      ),
      (
        'master switch off',
        [pay(d(11, 14))],
        const ReminderSettings(enabled: false),
      ),
      ('nothing due', [], const ReminderSettings()),
    ];
    for (final (name, payments, settings) in cases) {
      test(name, () => expect(plan(payments, settings: settings), isEmpty));
    }
  });

  group('past times', () {
    test('a past "ahead" is skipped; the "on day" stays', () {
      final r = plan([pay(d(11, 14))], now: at(d(11, 13), 10));
      expect(slots(r), [(d(11, 14), onDay)]);
    });

    // now on the due day -> on-day reminder scheduled?
    final cases = <(int, int, bool)>[
      (8, 59, true),
      (9, 0, false),
      (10, 0, false),
    ];
    for (final (h, m, scheduled) in cases) {
      test('due today, now $h:$m -> $scheduled', () {
        final r = plan([pay(d(11, 14))], now: at(d(11, 14), h, m));
        expect(r.isNotEmpty, scheduled);
      });
    }

    test('an overdue unpaid payment gets nothing', () {
      expect(plan([pay(d(11, 1))]), isEmpty);
    });
  });

  test('100 payments: the 60 soonest, in time order', () {
    final payments = [
      for (var i = 0; i < 100; i++) pay(d(11, 11).addDays(i), name: 'P$i'),
    ];
    final all = plan(payments, limit: 1000);
    final r = plan(payments);
    expect(r, hasLength(maxScheduledReminders));
    expect(r.map((x) => x.id), all.take(60).map((x) => x.id));
    for (var i = 1; i < r.length; i++) {
      expect(r[i].fireAt.isBefore(r[i - 1].fireAt), isFalse);
    }
  });

  test('amounts hidden: no amount anywhere in the text', () {
    final r = plan([
      pay(d(11, 14)),
      pay(d(11, 20), name: 'A'),
      pay(d(11, 20), name: 'B'),
    ], settings: const ReminderSettings(showAmounts: false));
    for (final x in r) {
      expect(x.body, isNot(contains('₺')));
      expect(x.expandedBody, isNot(contains('₺')));
      expect(x.body, isNot(contains('850')));
    }
  });

  group('calendar edges', () {
    // due date, lead days, expected "ahead" date
    final cases = <(LocalDate, int, LocalDate)>[
      (LocalDate(2026, 3, 1), 2, LocalDate(2026, 2, 27)), // 28-day February
      (LocalDate(2028, 3, 1), 2, LocalDate(2028, 2, 28)), // leap year
      (LocalDate(2026, 5, 1), 1, LocalDate(2026, 4, 30)), // 30-day month
      (LocalDate(2026, 1, 31), 7, LocalDate(2026, 1, 24)),
      (LocalDate(2027, 1, 1), 3, LocalDate(2026, 12, 29)), // year change
      (LocalDate(2027, 1, 2), 5, LocalDate(2026, 12, 28)),
    ];
    for (final (due, lead, expected) in cases) {
      test('$due, $lead days before -> $expected', () {
        final r = plan([
          pay(due, choice: ReminderChoice.days(lead)),
        ], now: at(LocalDate(2025, 12, 1), 12));
        expect(slots(r), [(expected, ahead), (due, onDay)]);
      });
    }
  });

  test('card on a weekend: reminders follow the shifted due date', () {
    // Statement 25 Nov 2026, due day 5: Saturday 5 Dec -> Monday 7 Dec.
    final draft = PlanCalculator.card(
      purchaseDate: LocalDate(2026, 11, 20),
      totalMinor: 300000,
      count: 3,
      terms: const CardTerms(statementDay: 25, dueDay: 5),
    );
    final first = draft.payments.first;
    expect(first.date, LocalDate(2026, 12, 7));
    final r = plan([
      pay(first.date, amount: first.amountMinor),
    ], now: at(LocalDate(2026, 11, 20), 12));
    expect(slots(r).take(2), [
      (LocalDate(2026, 12, 5), ahead),
      (LocalDate(2026, 12, 7), onDay),
    ]);
    expect(r.first.body, startsWith('7 Aralık Pazartesi'));
  });

  group('daylight saving (Europe/Berlin)', () {
    late tz.Location berlin;
    setUpAll(() => berlin = tz.getLocation('Europe/Berlin'));

    List<PlannedReminder> inBerlin(LocalDate due) => planReminders(
      payments: [pay(due, choice: ReminderChoice.days(1))],
      settings: const ReminderSettings(),
      now: tz.TZDateTime(berlin, 2026, 1, 1),
      texts: texts(),
    );

    test('March: 09:00 before and after the change', () {
      // Clocks go forward on Sunday 29 March 2026.
      final r = inBerlin(LocalDate(2026, 3, 29));
      expect(r.map((x) => x.fireAt.hour), [9, 9]);
      expect(r.map((x) => x.fireAt.toUtc().hour), [8, 7]); // CET, CEST
    });

    test('October: 09:00 before and after the change', () {
      // Clocks go back on Sunday 25 October 2026.
      final r = inBerlin(LocalDate(2026, 10, 25));
      expect(r.map((x) => x.fireAt.hour), [9, 9]);
      expect(r.map((x) => x.fireAt.toUtc().hour), [7, 8]); // CEST, CET
    });

    test('a time inside the spring-forward gap moves forward', () {
      final t = localWallClock(LocalDate(2026, 3, 29), 150, berlin); // 02:30
      expect(t.hour, 3);
    });

    test('another time zone keeps the local time', () {
      final i = localWallClock(d(11, 12), 540, istanbul);
      final b = localWallClock(d(11, 12), 540, berlin);
      expect((i.hour, b.hour), (9, 9));
      expect(b.difference(i), const Duration(hours: 2));
    });
  });

  test('7 days before names the full date', () {
    final r = plan([
      pay(d(11, 14), choice: ReminderChoice.days(7)),
    ], now: at(d(11, 1), 12));
    expect(r.first.fireDate, d(11, 7));
    expect(r.first.body, '14 Kasım Cuma günü 1 ödeme var: Klarna, ₺850');
    final en = plan(
      [pay(d(11, 14), choice: ReminderChoice.days(7))],
      now: at(d(11, 1), 12),
      lang: 'en',
    );
    expect(en.first.body, contains('Friday, November 14'));
  });

  group('currencies', () {
    test('IDR has no decimals', () {
      final r = plan([pay(d(11, 14), amount: 1250000)], currency: 'IDR');
      expect(r.last.body, 'Bugün 1 ödeme var: Klarna, Rp1.250.000');
    });

    test('KWD has three decimals', () {
      final r = plan([pay(d(11, 14), amount: 1250500)], currency: 'KWD');
      expect(r.last.body, contains('1.250,500'));
    });
  });

  test('ids are deterministic, unique and fit in 32 bits', () {
    final payments = [
      for (var i = 0; i < 30; i++) pay(d(11, 11).addDays(i ~/ 2), name: 'P$i'),
    ];
    final first = plan(payments).map((x) => x.id).toList();
    final second = plan(payments.reversed.toList()).map((x) => x.id).toList();
    expect(second, first);
    expect(first.toSet(), hasLength(first.length));
    expect(PlannedReminder.idFor(d(11, 12), ahead), d(11, 12).epochDay * 2 + 0);
    expect(
      PlannedReminder.idFor(LocalDate(2100, 1, 1), onDay),
      lessThan(1 << 31),
    );
  });

  group('lead days', () {
    test('the global setting is the default for "General"', () {
      const s = ReminderSettings(leadDays: 5);
      expect(defaultLeadDaysFor(null, s), 5);
      expect(leadDaysFor(pay(d(11, 14)), s), 5);
      expect(leadDaysFor(pay(d(11, 14), choice: ReminderChoice.days(1)), s), 1);
    });

    test('defaults: on, 2 days, 09:00, amounts shown', () {
      const s = ReminderSettings();
      expect(
        (s.enabled, s.leadDays, s.minuteOfDay, s.showAmounts),
        (true, 2, 540, true),
      );
      expect(leadDayChoices, [1, 2, 3, 5, 7]);
    });

    for (final days in leadDayChoices) {
      test('$days days before never lands on the due day', () {
        final r = plan([
          pay(d(11, 14), choice: ReminderChoice.days(days)),
        ], now: at(d(11, 1), 12));
        expect(r.first.kind, ahead);
        expect(r.first.fireDate, d(11, 14).addDays(-days));
      });
    }
  });

  group('payment method', () {
    const auto = PaymentMethod.automatic;
    const manual = PaymentMethod.manual;

    test('days before: automatic and not set follow the global, manual '
        'is one day earlier', () {
      for (final days in leadDayChoices) {
        final s = ReminderSettings(leadDays: days);
        expect(defaultLeadDaysFor(null, s), days);
        expect(defaultLeadDaysFor(auto, s), days);
        expect(defaultLeadDaysFor(manual, s), days + 1);
        expect(leadDaysFor(pay(d(11, 14), method: manual), s), days + 1);
      }
    });

    test("a plan's own choice always wins", () {
      const s = ReminderSettings();
      for (final method in [null, auto, manual]) {
        final own = pay(
          d(11, 14),
          method: method,
          choice: ReminderChoice.days(5),
        );
        expect(leadDaysFor(own, s), 5);
        expect(slots(plan([own], now: at(d(11, 1), 20))), [
          (d(11, 9), ReminderKind.ahead),
          (d(11, 14), ReminderKind.onDay),
        ]);
        final off = pay(
          d(11, 14),
          method: method,
          choice: ReminderChoice.disabled,
        );
        expect(plan([off]), isEmpty);
      }
    });

    test('not set: times and text exactly as before', () {
      final r = plan([pay(d(11, 14))]);
      expect(slots(r), [
        (d(11, 12), ReminderKind.ahead),
        (d(11, 14), ReminderKind.onDay),
      ]);
      expect(r[0].body, '14 Kasım Cuma günü 1 ödeme var: Klarna, ₺850');
      expect(r[1].body, 'Bugün 1 ödeme var: Klarna, ₺850');
      final en = plan([pay(d(11, 14))], lang: 'en');
      expect(en[0].body, '1 payment on Friday, November 14: Klarna, ₺850');
    });

    test('automatic: the global day, and the money in the account', () {
      final r = plan([
        pay(d(11, 14), name: 'Zip', amount: 12000, method: auto),
      ], currency: 'JPY');
      expect(slots(r), [
        (d(11, 12), ReminderKind.ahead),
        (d(11, 14), ReminderKind.onDay),
      ]);
      final yen = formatMoney(
        12000,
        Currency.fromCode('JPY'),
        localeName: 'tr',
      );
      expect(
        r[0].body,
        '14 Kasım Cuma günü 1 ödeme var: Zip, $yen. '
        'Otomatik çekilir; tutar hesabında bulunsun.',
      );
      expect(
        r[1].body,
        'Bugün 1 ödeme var: Zip, $yen. '
        'Otomatik çekilir; tutar hesabında bulunsun.',
      );
    });

    test('manual: one day earlier, and a note to pay', () {
      final r = plan([pay(d(11, 14), name: 'Market', method: manual)]);
      expect(slots(r), [
        (d(11, 11), ReminderKind.ahead),
        (d(11, 14), ReminderKind.onDay),
      ]);
      expect(
        r[0].body,
        '14 Kasım Cuma günü 1 ödeme var: Market, ₺850. '
        'Bu ödemeyi sen yapıyorsun.',
      );
      expect(
        r[1].body,
        'Bugün 1 ödeme var: Market, ₺850. Bu ödemeyi sen yapıyorsun.',
      );
      final en = plan([
        pay(d(11, 14), name: 'Market', method: manual),
      ], lang: 'en');
      expect(
        en[1].body,
        '1 payment today: Market, ₺850. You make this payment yourself.',
      );
    });

    test('amounts hidden: the note stays, no amount', () {
      final r = plan([
        pay(d(11, 14), method: auto),
      ], settings: const ReminderSettings(showAmounts: false));
      expect(
        r[1].body,
        'Bugün 1 ödeme var: Klarna. Otomatik çekilir; tutar hesabında '
        'bulunsun.',
      );
      expect(r[1].body, isNot(contains('850')));
    });

    test('merged: one method keeps its text, mixed ones the general text', () {
      final same = plan([
        pay(d(11, 14), name: 'A', method: manual),
        pay(d(11, 14), name: 'B', amount: 160000, method: manual),
      ]);
      expect(
        same.last.body,
        'Bugün 2 ödeme var, toplam ₺2.450. Bu ödemeleri sen yapıyorsun.',
      );
      for (final other in [auto, null]) {
        final mixed = plan([
          pay(d(11, 14), name: 'A', method: manual),
          pay(d(11, 14), name: 'B', amount: 160000, method: other),
        ]);
        final onDay = mixed.firstWhere((x) => x.kind == ReminderKind.onDay);
        expect(onDay.body, 'Bugün 2 ödeme var, toplam ₺2.450');
      }
    });

    test('reminderMethodOf: shared method for ahead and on day only', () {
      final a = pay(d(11, 14), method: auto);
      final m = pay(d(11, 14), method: manual);
      expect(reminderMethodOf(ReminderKind.ahead, [a, a]), auto);
      expect(reminderMethodOf(ReminderKind.onDay, [m]), manual);
      expect(reminderMethodOf(ReminderKind.onDay, [a, m]), equals(null));
      expect(reminderMethodOf(ReminderKind.overdue, [a]), equals(null));
      expect(reminderMethodOf(ReminderKind.ahead, const []), equals(null));
    });
  });
}
