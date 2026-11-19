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

/// 2026: 14 November is a Saturday.
LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

late tz.Location istanbul;

tz.TZDateTime at(LocalDate date, int hour, [int minute = 0]) =>
    tz.TZDateTime(istanbul, date.year, date.month, date.day, hour, minute);

ReminderTexts texts([String lang = 'tr']) => L10nReminderTexts(
  l10n: lookupAppLocalizations(Locale(lang)),
  currency: Currency.fromCode('TRY'),
);

StatementCard card({
  int id = 7,
  String name = 'Maximum',
  int statementDay = 14,
  int dueDay = 24,
  int leadDays = 2,
}) => StatementCard(
  id: id,
  name: name,
  terms: CardTerms(statementDay: statementDay, dueDay: dueDay),
  leadDays: leadDays,
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

const maximum14 =
    'Maximum kartının hesabı 2 gün sonra, 14 Kasım tarihinde kesiliyor. '
    'Bu tarihten sonraki taksitler 14 Aralık ekstresine girer.';

void main() {
  // The table below builds its times while the tests are declared.
  tzdata.initializeTimeZones();
  istanbul = tz.getLocation('Europe/Istanbul');
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  List<PlannedReminder> add(
    List<PlannedReminder> planned, {
    List<StatementCard>? cards,
    ReminderSettings settings = const ReminderSettings(),
    tz.TZDateTime? now,
    String lang = 'tr',
    int limit = maxScheduledReminders,
  }) => withStatementClosings(
    planned,
    cards: cards ?? [card()],
    settings: settings,
    now: now ?? at(d(11, 11), 10),
    texts: texts(lang),
    limit: limit,
  );

  group('when and what', () {
    // (case, cards, settings, now, first fire, first body)
    final cases =
        <
          (
            String,
            List<StatementCard>,
            ReminderSettings,
            tz.TZDateTime,
            tz.TZDateTime,
            String,
          )
        >[
          (
            'Example 1: statement 14, 2 days, today 11 Nov',
            [card()],
            const ReminderSettings(),
            at(d(11, 11), 10),
            at(d(11, 12), 9),
            maximum14,
          ),
          (
            'Example 2: 1 day before',
            [card(leadDays: 1)],
            const ReminderSettings(),
            at(d(11, 11), 10),
            at(d(11, 13), 9),
            'Maximum kartının hesabı 1 gün sonra, 14 Kasım tarihinde '
                'kesiliyor. Bu tarihten sonraki taksitler 14 Aralık '
                'ekstresine girer.',
          ),
          (
            'the reminder time is the user\'s: 20:30',
            [card()],
            const ReminderSettings(minuteOfDay: 20 * 60 + 30),
            at(d(11, 11), 10),
            at(d(11, 12), 20, 30),
            maximum14,
          ),
          (
            'on the fire day before the time: still today',
            [card()],
            const ReminderSettings(),
            at(d(11, 12), 8, 59),
            at(d(11, 12), 9),
            maximum14,
          ),
          (
            'on the fire day after the time: next month',
            [card()],
            const ReminderSettings(),
            at(d(11, 12), 9),
            at(d(12, 12), 9),
            'Maximum kartının hesabı 2 gün sonra, 14 Aralık tarihinde '
                'kesiliyor. Bu tarihten sonraki taksitler 14 Ocak '
                'ekstresine girer.',
          ),
          (
            'month end: the 31st is the 30th in November',
            [card(statementDay: 31, dueDay: 10)],
            const ReminderSettings(),
            at(d(11, 20), 10),
            at(d(11, 28), 9),
            'Maximum kartının hesabı 2 gün sonra, 30 Kasım tarihinde '
                'kesiliyor. Bu tarihten sonraki taksitler 31 Aralık '
                'ekstresine girer.',
          ),
          (
            'month end: February 2027 is cut on the 28th',
            [card(statementDay: 31, dueDay: 10)],
            const ReminderSettings(),
            at(d(2, 1, 2027), 10),
            at(d(2, 26, 2027), 9),
            'Maximum kartının hesabı 2 gün sonra, 28 Şubat tarihinde '
                'kesiliyor. Bu tarihten sonraki taksitler 31 Mart '
                'ekstresine girer.',
          ),
          (
            'a statement past the fire day this month: the next one',
            [card()],
            const ReminderSettings(),
            at(d(11, 14), 10),
            at(d(12, 12), 9),
            'Maximum kartının hesabı 2 gün sonra, 14 Aralık tarihinde '
                'kesiliyor. Bu tarihten sonraki taksitler 14 Ocak '
                'ekstresine girer.',
          ),
        ];

    for (final (name, cards, settings, now, fireAt, body) in cases) {
      test(name, () {
        final list = add(const [], cards: cards, settings: settings, now: now);
        expect(list.first.fireAt, fireAt);
        expect(list.first.body, body);
        expect(list.first.expandedBody, body);
      });
    }

    test('a notification of its own: no amount, no button, opens the card', () {
      final r = add(const []).first;
      expect(r.isStatementClosing, isTrue);
      expect(r.isPaydaySummary, isFalse);
      expect(r.buttons, isEmpty);
      expect(r.data, equals(null));
      expect(r.payments, isEmpty);
      expect(r.totalMinor, 0);
      expect(r.title, 'Kalan');
      expect(r.payload, cardStatementPayload(7));
      expect(cardIdOfPayload(r.payload), 7);
      expect(r.fireDate, d(11, 12));
      expect(r.id, PlannedReminder.idForStatementClosing(7, d(11, 12)));
    });

    test('the statement date is the engine\'s, never moved off a weekend', () {
      // 14 November 2026 is a Saturday: the statement stays on the 14th.
      expect(d(11, 14).toDateTime().weekday, DateTime.saturday);
      final terms = card().terms;
      final list = add(const []);
      for (final r in list) {
        final statement = r.fireDate.addDays(2);
        expect(terms.statementFor(statement), statement);
      }
      expect(list.first.body, contains('14 Kasım'));
    });

    test('a year of statements per card, soonest first', () {
      final list = add(const []);
      expect(list, hasLength(statementClosingHorizon));
      expect(list.map((r) => r.fireDate).take(3), [
        d(11, 12),
        d(12, 12),
        d(1, 12, 2027),
      ]);
      expect(list.map((r) => r.id).toSet(), hasLength(list.length));
    });

    test('English', () {
      expect(
        add(const [], lang: 'en').first.body,
        'Your Maximum statement closes in 2 days, on November 14. '
        'Installments after that go on the December 14 statement.',
      );
      expect(
        add(const [], cards: [card(leadDays: 1)], lang: 'en').first.body,
        'Your Maximum statement closes in 1 day, on November 14. '
        'Installments after that go on the December 14 statement.',
      );
    });

    test('a days value other than 1 or 2 counts as 2', () {
      expect(
        add(const [], cards: [card(leadDays: 5)]).first.fireDate,
        d(11, 12),
      );
    });
  });

  group('two cards and priority', () {
    test('two cards on the same day: one notification each', () {
      final list = add(
        const [],
        cards: [
          card(id: 9, name: 'Bonus'),
          card(),
        ],
      );
      final first = list.where((r) => r.fireDate == d(11, 12)).toList();
      expect(first, hasLength(2));
      expect(first.map((r) => r.payload), ['card:7', 'card:9']);
      expect(first.map((r) => r.body), [
        maximum14,
        maximum14.replaceFirst('Maximum', 'Bonus'),
      ]);
      expect(first.map((r) => r.id).toSet(), hasLength(2));
    });

    test('Example 3: 60 payment reminders leave no room', () {
      final payments = [
        for (var i = 0; i < maxScheduledReminders; i++)
          paymentAt(i, at(d(12, 1).addDays(i), 9)),
      ];
      final list = add(payments);
      expect(identical(list, payments), isTrue);
      expect(list.any((r) => r.isStatementClosing), isFalse);
    });

    test('Example 4: no card with the switch on, the list is untouched', () {
      final payments = [
        paymentAt(1, at(d(11, 12), 9)),
        paymentAt(2, at(d(11, 20), 9)),
      ];
      expect(identical(add(payments, cards: const []), payments), isTrue);
      expect(add(const [], cards: const []), isEmpty);
    });

    test('only in the room left, the soonest first; payments keep theirs', () {
      // 58 payment reminders and the payday summary leave one place.
      final planned = [
        for (var i = 0; i < maxScheduledReminders - 1; i++)
          paymentAt(i, at(d(12, 1).addDays(i), 9)),
      ];
      final list = add(planned);
      expect(list, hasLength(maxScheduledReminders));
      expect(
        list.where((r) => r.isStatementClosing).single.fireDate,
        d(11, 12),
      );
      expect([
        for (final r in list)
          if (!r.isStatementClosing) r,
      ], planned);
    });

    test('in time order; after the others at the same moment', () {
      final planned = [
        paymentAt(1, at(d(11, 12), 9)),
        paymentAt(2, at(d(11, 20), 9)),
      ];
      final list = add(planned, limit: 4);
      expect(list.map((r) => r.isStatementClosing ? 'c' : r.body), [
        'p1',
        'c',
        'p2',
        'c',
      ]);
      expect(list[1].fireDate, d(11, 12));
      expect(list[3].fireDate, d(12, 12));
    });

    test('reminders off: nothing', () {
      expect(
        add(const [], settings: const ReminderSettings(enabled: false)),
        isEmpty,
      );
    });
  });

  group('ids and payloads', () {
    test('ids stay between the payment ids and the repeat ids', () {
      for (final (id, date) in [
        (1, d(1, 1, 2000)),
        (262143, LocalDate(2100, 12, 31)),
        (7, d(11, 12)),
      ]) {
        final value = PlannedReminder.idForStatementClosing(id, date);
        expect(value, greaterThanOrEqualTo(PlannedReminder.statementIdBase));
        expect(value, lessThan(PlannedReminder.repeatIdBase));
        expect(
          value,
          greaterThan(PlannedReminder.idFor(date, ReminderKind.onDay)),
        );
      }
    });

    test('payloads: only a card key reads as a card', () {
      expect(cardIdOfPayload('card:12'), 12);
      expect(cardIdOfPayload(reminderPayload), equals(null));
      expect(cardIdOfPayload(null), equals(null));
      expect(cardIdOfPayload('card:'), equals(null));
      expect(cardIdOfPayload('card:-3'), equals(null));
      expect(cardIdOfPayload('{"k":0}'), equals(null));
    });
  });
}
