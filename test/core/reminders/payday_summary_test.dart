import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/reminders/reminder_planner.dart';
import 'package:kalan/features/reminders/reminder_texts.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 2026: 20 November is a Friday, 14 November a Saturday.
LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

late tz.Location istanbul;

tz.TZDateTime at(LocalDate date, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, date.year, date.month, date.day, hour, minute);

ReminderTexts texts([String lang = 'tr', String currency = 'TRY']) =>
    L10nReminderTexts(
      l10n: lookupAppLocalizations(Locale(lang)),
      currency: Currency.fromCode(currency),
    );

PlannedReminder paymentAt(int id, tz.TZDateTime fireAt) => PlannedReminder(
  id: id,
  kind: ReminderKind.onDay,
  fireDate: LocalDate(fireAt.year, fireAt.month, fireAt.day),
  fireAt: fireAt,
  payments: const [],
  dueDates: const [],
  title: 'Kalan',
  body: 'p$id',
  expandedBody: 'p$id',
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    istanbul = tz.getLocation('Europe/Istanbul');
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('next payday', () {
    LocalDate next(PaySchedule s, tz.TZDateTime now, [int minute = 540]) =>
        nextPaydayPeriod(s, now, minute).start;

    test('monthly: the next 15th; today before the reminder time', () {
      const s = PaySchedule.monthly(15);
      expect(next(s, at(d(11, 20), 8)), d(12, 15));
      expect(next(s, at(d(11, 15), 8, 59)), d(11, 15));
      expect(next(s, at(d(11, 15), 9)), d(12, 15));
      expect(next(s, at(d(11, 14), 23)), d(11, 15));
      // The reminder time is the user's: 20:30.
      expect(next(s, at(d(11, 15), 20), 20 * 60 + 30), d(11, 15));
      expect(next(s, at(d(12, 20), 9)), d(1, 15, 2027));
    });

    test('monthly 31st: the last day of shorter months, as the engine', () {
      const s = PaySchedule.monthly(31);
      expect(next(s, at(d(1, 31, 2027), 10)), d(2, 28, 2027));
      expect(next(s, at(d(2, 28, 2027), 10)), d(3, 31, 2027));
      expect(next(s, at(d(4, 1, 2027), 10)), d(4, 30, 2027));
      for (final now in [at(d(11, 20), 8), at(d(2, 10, 2028), 12)]) {
        final today = LocalDate(now.year, now.month, now.day);
        expect(next(s, now), s.next(s.periodContaining(today)).start);
      }
    });

    test('a weekend payday is not moved', () {
      // 14 November 2026 is a Saturday.
      expect(next(const PaySchedule.monthly(14), at(d(11, 13), 9)), d(11, 14));
      final weekly = PaySchedule.weekly(d(11, 14));
      expect(next(weekly, at(d(11, 16), 9)), d(11, 21));
      expect(d(11, 21).toDateTime().weekday, DateTime.saturday);
    });

    test('every two weeks and weekly from the known payday', () {
      final biweekly = PaySchedule.biweekly(d(11, 6));
      expect(next(biweekly, at(d(11, 20), 8)), d(11, 20));
      expect(next(biweekly, at(d(11, 20), 10)), d(12, 4));
      expect(next(biweekly, at(d(11, 7), 10)), d(11, 20));
      final weekly = PaySchedule.weekly(d(11, 6));
      expect(next(weekly, at(d(11, 20), 10)), d(11, 27));
      expect(next(weekly, at(d(11, 21), 10)), d(11, 27));
    });
  });

  group('withPaydaySummary', () {
    final summary = PaydaySummary(
      date: d(12, 15),
      paymentCount: 6,
      totalMinor: 830000,
      leftMinor: 1245000,
    );

    List<PlannedReminder> add(
      List<PlannedReminder> planned, {
      ReminderSettings settings = const ReminderSettings(),
      tz.TZDateTime? now,
      PaydaySummary? payday,
      int limit = maxScheduledReminders,
    }) => withPaydaySummary(
      planned,
      payday: payday ?? summary,
      settings: settings,
      now: now ?? at(d(11, 20), 8),
      texts: texts(),
      limit: limit,
    );

    test('its own notification on the payday at the reminder time', () {
      final list = add(const []);
      expect(list, hasLength(1));
      final r = list.single;
      expect(r.isPaydaySummary, isTrue);
      expect(r.fireAt, at(d(12, 15), 9));
      expect(r.fireDate, d(12, 15));
      expect(r.id, PlannedReminder.idForPayday(d(12, 15)));
      expect(r.buttons, isEmpty);
      expect(r.data, equals(null));
      expect(r.payload, reminderPayload);
      expect(r.payments, isEmpty);
      expect(r.title, 'Kalan');
      final late = add(
        const [],
        settings: const ReminderSettings(minuteOfDay: 20 * 60 + 30),
      );
      expect(late.single.fireAt, at(d(12, 15), 20, 30));
    });

    test('ids stay clear of the other reminders', () {
      final id = PlannedReminder.idForPayday(LocalDate(2100, 12, 31));
      expect(id, lessThan(PlannedReminder.snoozeIdBase));
      expect(
        PlannedReminder.idForPayday(LocalDate(2000, 1, 1)),
        greaterThan(
          PlannedReminder.idForRepeat(
            LocalDate(2100, 12, 31),
            ReminderKind.ahead,
            evening: false,
          ),
        ),
      );
      expect(id, lessThan(1 << 31));
    });

    test('payment reminders are untouched, the summary goes in by time', () {
      final planned = [
        paymentAt(1, at(d(12, 13), 9)),
        paymentAt(2, at(d(12, 15), 9)),
        paymentAt(3, at(d(12, 16), 9)),
      ];
      final list = add(planned);
      expect(list.map((r) => r.body).toList(), [
        'p1',
        'p2',
        list[2].body,
        'p3',
      ]);
      expect(list[2].isPaydaySummary, isTrue);
      expect([
        for (final r in list)
          if (!r.isPaydaySummary) r,
      ], planned);
    });

    test('off, reminders off, or its time passed: nothing added', () {
      final planned = [paymentAt(1, at(d(12, 13), 9))];
      expect(
        add(planned, settings: const ReminderSettings(paydaySummary: false)),
        planned,
      );
      expect(
        add(planned, settings: const ReminderSettings(enabled: false)),
        planned,
      );
      expect(add(planned, now: at(d(12, 15), 9)), planned);
      expect(add(planned, now: at(d(12, 15), 8, 59)), hasLength(2));
    });

    test('limit: inside it, payment reminders keep priority', () {
      final full = [
        for (var i = 0; i < 60; i++) paymentAt(i, at(d(11, 21).addDays(i), 9)),
      ];
      expect(add(full), full);
      final room = full.sublist(0, 59);
      final list = add(room);
      expect(list, hasLength(60));
      expect(list.where((r) => r.isPaydaySummary), hasLength(1));
      expect(add(full.sublist(0, 3), limit: 3), hasLength(3));
    });
  });

  group('text', () {
    String body(
      PaydaySummary s, {
      String lang = 'tr',
      String currency = 'TRY',
      bool showAmounts = true,
    }) => texts(lang, currency).payday(s, showAmounts: showAmounts).body;

    PaydaySummary summary({
      int count = 6,
      int total = 830000,
      int? left = 1245000,
    }) => PaydaySummary(
      date: d(12, 15),
      paymentCount: count,
      totalMinor: total,
      leftMinor: left,
    );

    test('with an income: count, total and what is left', () {
      expect(
        body(summary()),
        'Yeni dönem başladı. Bu dönem 6 ödeme, toplam ₺8.300. '
        'Kalan ₺12.450.',
      );
      expect(
        body(summary(), lang: 'en'),
        'A new pay period has started. 6 payments this period, ₺8,300 in '
        'total. ₺12,450 left.',
      );
      expect(
        body(summary(count: 1, total: 85000, left: 0)),
        'Yeni dönem başladı. Bu dönem 1 ödeme, toplam ₺850. Kalan ₺0.',
      );
    });

    test('no income: count and total only', () {
      expect(
        body(summary(left: null)),
        'Yeni dönem başladı. Bu dönem 6 ödeme, toplam ₺8.300.',
      );
    });

    test('short: a calm line with the missing amount', () {
      final s = summary(count: 4, total: 920000, left: -120000);
      expect(
        body(s),
        'Yeni dönem başladı. Bu dönem 4 ödeme, toplam ₺9.200. '
        'Bu dönem ₺1.200 eksik kalıyor.',
      );
      expect(
        body(s, lang: 'en'),
        'A new pay period has started. 4 payments this period, ₺9,200 in '
        'total. This period is ₺1,200 short.',
      );
    });

    test('no payments', () {
      expect(
        body(summary(count: 0, total: 0, left: 2075000)),
        'Yeni dönem başladı. Bu dönem ödeme yok. Kalan ₺20.750.',
      );
      expect(
        body(summary(count: 0, total: 0, left: null), lang: 'en'),
        'A new pay period has started. No payments this period.',
      );
    });

    test('amounts hidden in notifications: the count only', () {
      for (final left in [1245000, -120000, null]) {
        expect(
          body(summary(left: left), showAmounts: false),
          'Yeni dönem başladı. Bu dönem 6 ödeme var.',
        );
      }
      expect(
        body(summary(count: 1), lang: 'en', showAmounts: false),
        'A new pay period has started. 1 payment this period.',
      );
    });

    test('three-decimal and zero-decimal currencies', () {
      expect(
        body(summary(total: 12000, left: 8000), currency: 'JPY'),
        contains('¥12.000'),
      );
      expect(
        body(summary(total: 1500, left: 500), currency: 'KWD'),
        contains('1,500'),
      );
    });
  });
}
