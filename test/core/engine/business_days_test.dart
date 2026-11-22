import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/holidays/holidays.dart';

import '../date/local_date_test.dart' show d;

/// A calendar written by hand: [weekend] days and [holidays].
class FakeCalendar implements HolidayCalendar {
  FakeCalendar(this.weekendDays, Iterable<String> holidays)
    : _days = {for (final h in holidays) d(h).epochDay};

  @override
  final Set<int> weekendDays;
  final Set<int> _days;

  @override
  bool isHoliday(LocalDate date) => _days.contains(date.epochDay);
}

/// The shipped file's country [code] (Roadmap 26 examples use Türkiye).
CountryHolidays shipped(String code) =>
    parseHolidays(File(holidaysAsset).readAsStringSync())
        .firstWhere((c) => c.country == code);

void main() {
  final tr = shipped('TR');

  group('nextBusinessDay: the one rule (decision 6)', () {
    // (date, weekends, holidays, expected, holiday note)
    final cases = <(String, bool, bool, String, bool)>[
      // Example 1: Republic Day, a Thursday.
      ('2026-10-29', true, true, '2026-10-30', true),
      // Example 2: New Year's Day 2027, a Friday, then the weekend.
      ('2027-01-01', true, true, '2027-01-04', true),
      // Example 3: the weekend switch off.
      ('2027-01-01', false, true, '2027-01-02', true),
      // The holiday switch off: the date stays (a Thursday).
      ('2026-10-29', true, false, '2026-10-29', false),
      // Only a weekend: no holiday note.
      ('2026-11-14', true, true, '2026-11-16', false),
      // Kurban Bayramı 27-30 May 2026 and the weekend after it in one
      // step, across the month end.
      ('2026-05-27', true, true, '2026-06-01', true),
      // A weekend day that is also a holiday (30 May 2026, a Saturday):
      // the weekend alone gives the same Monday, so no holiday note.
      ('2026-05-30', true, true, '2026-06-01', false),
      // 1 May 2027 is a Saturday: the weekend moves it, not the holiday.
      ('2027-05-01', true, true, '2027-05-03', false),
      // Weekend off: Saturday 30 May 2026 is still a holiday.
      ('2026-05-30', false, true, '2026-05-31', true),
      // Year end into New Year's Day 2028 (a Saturday) and Sunday.
      ('2027-12-31', true, true, '2027-12-31', false),
      ('2028-01-01', true, true, '2028-01-03', false),
      // Weekend off: the Saturday holiday alone moves it to Sunday.
      ('2028-01-01', false, true, '2028-01-02', true),
      // Example 5: after the list (2029), only the weekend moves.
      ('2029-01-01', true, true, '2029-01-01', false),
      ('2029-10-29', true, true, '2029-10-29', false),
      ('2029-04-28', true, true, '2029-04-30', false),
    ];
    for (final (date, weekends, holidays, expected, note) in cases) {
      test('TR $date weekend:$weekends holidays:$holidays -> $expected', () {
        final shift = nextBusinessDay(
          d(date),
          weekends: weekends,
          holidays: holidays,
          calendar: tr,
        );
        expect(shift.date, d(expected));
        expect(shift.skippedHoliday, note);
      });
    }

    test('example 4: a Friday-Saturday weekend moves a Friday to Sunday', () {
      final fridaySaturday = FakeCalendar({
        DateTime.friday,
        DateTime.saturday,
      }, const []);
      final shift = nextBusinessDay(
        d('2026-11-20'),
        weekends: true,
        holidays: true,
        calendar: fridaySaturday,
      );
      expect(shift.date, d('2026-11-22'));
      expect(shift.skippedHoliday, isFalse);
      // Sunday is a business day there.
      expect(
        nextBusinessDay(
          d('2026-11-22'),
          weekends: true,
          holidays: true,
          calendar: fridaySaturday,
        ).date,
        d('2026-11-22'),
      );
    });

    test('holidays, weekend and holidays again are passed at once', () {
      final cal = FakeCalendar(defaultWeekendDays, const [
        '2026-12-31',
        '2027-01-01',
        '2027-01-04',
      ]);
      final shift = nextBusinessDay(
        d('2026-12-31'),
        weekends: true,
        holidays: true,
        calendar: cal,
      );
      expect(shift.date, d('2027-01-05'));
      expect(shift.skippedHoliday, isTrue);
    });

    test('example 6 and decision 6: without a calendar the old rule, '
        'every day 2026-2029', () {
      LocalDate old(LocalDate date) => switch (date.weekday) {
        DateTime.saturday => date.addDays(2),
        DateTime.sunday => date.addDays(1),
        _ => date,
      };
      for (var day = d('2026-01-01'); day <= d('2029-12-31');) {
        for (final holidays in [true, false]) {
          final on = nextBusinessDay(day, weekends: true, holidays: holidays);
          expect(on.date, old(day), reason: '$day');
          expect(on.skippedHoliday, isFalse);
          expect(
            nextBusinessDay(day, weekends: false, holidays: holidays).date,
            day,
          );
        }
        expect(shiftToBusinessDay(day), old(day));
        day = day.addDays(1);
      }
    });
  });

  group('CardTerms with a holiday country', () {
    // Statement on the 19th, due on the 29th: Hakan's card.
    CardTerms card({
      bool weekends = true,
      bool holidays = true,
      HolidayCalendar? calendar,
    }) => CardTerms(
      statementDay: 19,
      dueDay: 29,
      shiftDueToBusinessDay: weekends,
      shiftDueForHolidays: holidays,
      holidays: calendar,
    );

    test('example 1: the October 2026 statement is due 30 Oct', () {
      final terms = card(calendar: tr);
      expect(terms.dueFor(d('2026-10-19')), d('2026-10-30'));
      expect(terms.movedForHoliday(d('2026-10-30')), isTrue);
      expect(terms.statementForDue(d('2026-10-30')), d('2026-10-19'));
    });

    test('only a weekend: no note (29 Nov 2026 is a Sunday)', () {
      final terms = card(calendar: tr);
      expect(terms.dueFor(d('2026-11-19')), d('2026-11-30'));
      expect(terms.movedForHoliday(d('2026-11-30')), isFalse);
    });

    test('a date the rule does not give has no note', () {
      final terms = card(calendar: tr);
      expect(terms.movedForHoliday(d('2026-10-29')), isFalse);
      expect(terms.movedForHoliday(d('2026-10-31')), isFalse);
    });

    test('the holiday switch off, or "None": the old dates', () {
      expect(
        card(holidays: false, calendar: tr).dueFor(d('2026-10-19')),
        d('2026-10-29'),
      );
      expect(card().dueFor(d('2026-10-19')), d('2026-10-29'));
      expect(card().movedForHoliday(d('2026-10-29')), isFalse);
    });

    test('card installments land after the holiday', () {
      final dates = cardInstallmentDates(
        purchaseDate: d('2026-10-10'),
        terms: card(calendar: tr),
        count: 3,
      );
      expect(dates, [d('2026-10-30'), d('2026-11-30'), d('2026-12-29')]);
    });

    test('without holidays every card date is the old one '
        '(31 x 31 days, weekend on and off, two years)', () {
      for (var s = 1; s <= 31; s++) {
        for (var due = 1; due <= 31; due++) {
          for (final weekends in [true, false]) {
            final plain = CardTerms(
              statementDay: s,
              dueDay: due,
              shiftDueToBusinessDay: weekends,
            );
            final off = CardTerms(
              statementDay: s,
              dueDay: due,
              shiftDueToBusinessDay: weekends,
              shiftDueForHolidays: false,
              holidays: tr,
            );
            for (var m = 0; m < 24; m++) {
              final statement = plain.statementInMonth(2026, 1 + m);
              final old = plain.dueFor(statement);
              final noHoliday = off.dueFor(statement);
              // The holiday switch off keeps the weekend shift only.
              expect(noHoliday, old, reason: '$s/$due $statement');
            }
          }
        }
      }
    });

    test('every date the rule gives maps back to its statement '
        '(31 x 31 days, Türkiye, 2026-2028)', () {
      for (var s = 1; s <= 31; s++) {
        for (var due = 1; due <= 31; due++) {
          final terms = CardTerms(statementDay: s, dueDay: due, holidays: tr);
          for (var m = 0; m < 36; m++) {
            final statement = terms.statementInMonth(2026, 1 + m);
            final date = terms.dueFor(statement);
            expect(
              terms.dueFor(terms.statementForDue(date)),
              date,
              reason: '$s/$due $statement',
            );
          }
        }
      }
    });
  });

  group('reshiftCardDue: only the dates the rule gave move', () {
    const none = CardTerms(statementDay: 19, dueDay: 29);
    final turkey = none.withHolidays(tr);

    test('example 7: 29 Oct 2026 moves to 30 Oct', () {
      expect(
        reshiftCardDue(d('2026-10-29'), oldTerms: none, newTerms: turkey),
        d('2026-10-30'),
      );
    });

    test('and back when the country is "None" again', () {
      expect(
        reshiftCardDue(d('2026-10-30'), oldTerms: turkey, newTerms: none),
        d('2026-10-29'),
      );
    });

    test('an entered date the rule does not give stays', () {
      expect(
        reshiftCardDue(d('2026-10-27'), oldTerms: none, newTerms: turkey),
        isNull,
      );
    });

    test('a date that does not change returns null', () {
      expect(
        reshiftCardDue(d('2026-12-29'), oldTerms: none, newTerms: turkey),
        isNull,
      );
    });
  });
}
