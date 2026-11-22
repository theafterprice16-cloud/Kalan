import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/holidays/holidays.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/l10n/app_locales.dart';

/// The main countries of the 22 local versions (Ülke Notları; es-419 and
/// ar name several, decision 1) whose official sources could not be
/// verified on 22 November 2026. They are not in the file.
const unverified = {'TW', 'VN', 'SA', 'AE', 'EG'};

/// Every main country decision 1 asks for, by local version.
const mainCountries = <String, List<String>>{
  'tr': ['TR'],
  'en': ['US'],
  'en_GB': ['GB'],
  'es': ['ES'],
  'es_419': ['MX', 'AR', 'CO', 'CL'],
  'pt_BR': ['BR'],
  'pt_PT': ['PT'],
  'de': ['DE'],
  'de_CH': ['CH'],
  'fr': ['FR'],
  'fr_CA': ['CA'],
  'it': ['IT'],
  'id': ['ID'],
  'ru': ['RU'],
  'zh': ['CN'],
  'zh_Hant': ['TW'],
  'ar': ['SA', 'AE', 'EG'],
  'pl': ['PL'],
  'nl': ['NL'],
  'sv': ['SE'],
  'ja': ['JP'],
  'vi': ['VN'],
};

String file() => File(holidaysAsset).readAsStringSync();

Map<String, Object?> fileJson() => jsonDecode(file()) as Map<String, Object?>;

String withCountry(Map<String, Object?> country) => jsonEncode({
  'schemaVersion': holidaysSchemaVersion,
  'countries': [country],
});

Map<String, Object?> valid() => {
  'country': 'XX',
  'weekend': ['sat', 'sun'],
  'lastYear': 2027,
  'sources': ['https://example.gov/holidays'],
  'checked': '2026-11-22',
  'years': {
    '2026': ['2026-01-01', '2026-10-29'],
    '2027': ['2027-01-01'],
  },
};

void main() {
  final countries = parseHolidays(file());
  final now = DateTime.now();
  final today = LocalDate(now.year, now.month, now.day);

  group('the shipped file (test 1)', () {
    test('reads, one entry per country', () {
      expect(countries, isNotEmpty);
      expect(countries.map((c) => c.country).toSet().length, countries.length);
    });

    test('every main country is in the file or listed as unverified', () {
      expect(mainCountries.keys.toSet(), {for (final l in appLocales) l.code});
      final inFile = countries.map((c) => c.country).toSet();
      for (final code in mainCountries.values.expand((l) => l)) {
        expect(
          inFile.contains(code) != unverified.contains(code),
          isTrue,
          reason: code,
        );
      }
      // Nothing else: only the countries decision 1 names.
      expect(
        inFile.difference(mainCountries.values.expand((l) => l).toSet()),
        isEmpty,
      );
    });

    for (final c in countries) {
      test('${c.country}: weekend, years, sources, check date', () {
        expect(c.weekendDays, isNotEmpty);
        expect(c.weekendDays.length, lessThanOrEqualTo(2));
        expect(c.lastYear, inInclusiveRange(firstHolidayYear, 2028));
        expect(c.sources, isNotEmpty);
        for (final s in c.sources) {
          expect(s, startsWith('https://'));
        }
        expect(c.checked, isNotNull);
        expect(c.checked! <= today, isTrue, reason: 'checked in the future');
        final dates = c.dates;
        expect(dates.first.year, firstHolidayYear);
        expect(dates.last.year, c.lastYear);
        for (final date in dates) {
          expect(date.year, inInclusiveRange(firstHolidayYear, c.lastYear));
        }
      });
    }

    test('dates are in order and never repeat inside the file', () {
      for (final raw in fileJson()['countries']! as List) {
        final years = (raw as Map<String, Object?>)['years']! as Map;
        for (final list in years.values) {
          final dates = [for (final s in list as List) s as String];
          expect(dates, [...dates]..sort());
          expect(dates.toSet().length, dates.length);
        }
      }
    });

    test('the examples of the brief hold in the data', () {
      final tr = countries.firstWhere((c) => c.country == 'TR');
      expect(tr.isHoliday(LocalDate(2026, 10, 29)), isTrue);
      expect(tr.isHoliday(LocalDate(2027, 1, 1)), isTrue);
      expect(tr.isHoliday(LocalDate(2026, 10, 30)), isFalse);
      expect(tr.weekendDays, {DateTime.saturday, DateTime.sunday});
      expect(tr.lastYear, 2028);
    });
  });

  group('parseHolidays refuses', () {
    void refuses(Map<String, Object?> country, String why) => expect(
      () => parseHolidays(withCountry(country)),
      throwsA(isA<HolidayFormatException>()),
      reason: why,
    );

    test('a valid entry reads', () {
      final c = parseHolidays(withCountry(valid())).single;
      expect(c.lastYear, 2027);
      expect(c.isHoliday(LocalDate(2026, 10, 29)), isTrue);
      expect(c.checked, LocalDate(2026, 11, 22));
    });

    test('unknown keys (a holiday name, a note)', () {
      refuses({...valid(), 'names': <String>[]}, 'names');
    });

    test('missing keys', () {
      for (final key in holidayKeys.country) {
        refuses({...valid()}..remove(key), key);
      }
    });

    test('a weekend of none, three days or an unknown day', () {
      refuses({...valid(), 'weekend': <String>[]}, 'none');
      refuses({
        ...valid(),
        'weekend': ['fri', 'sat', 'sun'],
      }, 'three');
      refuses({
        ...valid(),
        'weekend': ['sat', 'sat'],
      }, 'twice');
      refuses({
        ...valid(),
        'weekend': ['saturday'],
      }, 'unknown');
    });

    test('a date outside its year, out of order or repeated', () {
      refuses({
        ...valid(),
        'years': {
          '2026': ['2027-01-01'],
          '2027': ['2027-01-02'],
        },
      }, 'wrong year');
      refuses({
        ...valid(),
        'years': {
          '2026': ['2026-10-29', '2026-01-01'],
          '2027': <String>[],
        },
      }, 'order');
      refuses({
        ...valid(),
        'years': {
          '2026': ['2026-01-01', '2026-01-01'],
          '2027': <String>[],
        },
      }, 'repeat');
      refuses({
        ...valid(),
        'years': {
          '2026': ['2026-02-30'],
          '2027': <String>[],
        },
      }, 'no such day');
    });

    test('a gap in the years or a last year that does not match', () {
      refuses({
        ...valid(),
        'lastYear': 2028,
        'years': {'2026': <String>[], '2028': <String>[]},
      }, 'gap');
      refuses({...valid(), 'lastYear': 2028}, 'last year');
    });

    test('a link that is not https', () {
      refuses({
        ...valid(),
        'sources': ['http://example.gov'],
      }, 'http');
      refuses({...valid(), 'sources': <String>[]}, 'none');
    });

    test('a repeated country', () {
      expect(
        () => parseHolidays(
          jsonEncode({
            'schemaVersion': holidaysSchemaVersion,
            'countries': [valid(), valid()],
          }),
        ),
        throwsA(isA<HolidayFormatException>()),
      );
    });

    test('another schema version', () {
      expect(
        () => parseHolidays(jsonEncode({'schemaVersion': 2, 'countries': []})),
        throwsA(isA<HolidayFormatException>()),
      );
    });
  });

  test('a snapshot reads back the same calendar', () {
    for (final c in countries) {
      final back = CountryHolidays.fromSnapshot(c.toSnapshot())!;
      expect(back.country, c.country);
      expect(back.weekendDays, c.weekendDays);
      expect(back.lastYear, c.lastYear);
      expect(back.holidayDays, c.holidayDays);
      expect(back.toSnapshot(), c.toSnapshot());
    }
    expect(CountryHolidays.fromSnapshot(null), isNull);
    expect(CountryHolidays.fromSnapshot('not json'), isNull);
    expect(snapshotOf(null), isNull);
  });

  group('suggestHolidayCountry (test 7)', () {
    final available = countries.map((c) => c.country).toSet();
    Set<String> of(String code) => Currency.fromCode(code).countries;

    test('the device region first', () {
      expect(
        suggestHolidayCountry(
          region: 'DE',
          currencyCountries: of('TRY'),
          available: available,
        ),
        'DE',
      );
      expect(
        suggestHolidayCountry(
          region: 'tr',
          currencyCountries: of('USD'),
          available: available,
        ),
        'TR',
      );
    });

    test('a region without data falls back to the currency country', () {
      expect(
        suggestHolidayCountry(
          region: 'AU',
          currencyCountries: of('TRY'),
          available: available,
        ),
        'TR',
      );
      expect(
        suggestHolidayCountry(
          region: null,
          currencyCountries: of('JPY'),
          available: available,
        ),
        'JP',
      );
    });

    test('no suggestion for a shared currency', () {
      expect(of('EUR').length, greaterThan(1));
      expect(
        suggestHolidayCountry(
          region: 'AU',
          currencyCountries: of('EUR'),
          available: available,
        ),
        isNull,
      );
    });

    test('"None" when neither has data', () {
      expect(
        suggestHolidayCountry(
          region: 'TW',
          currencyCountries: of('TWD'),
          available: available,
        ),
        isNull,
      );
    });
  });

  group('isHolidayListStale: the CI warning (test 8)', () {
    final c = CountryHolidays(
      country: 'XX',
      weekendDays: const {6, 7},
      lastYear: 2028,
      holidayDays: const {},
    );

    test('warns once the list ends this year or earlier', () {
      expect(isHolidayListStale(c, LocalDate(2027, 12, 31)), isFalse);
      expect(isHolidayListStale(c, LocalDate(2028, 1, 1)), isTrue);
      expect(isHolidayListStale(c, LocalDate(2029, 6, 1)), isTrue);
      expect(staleHolidayWarning(c), contains('2028'));
      expect(staleHolidayWarning(c), contains('XX'));
    });

    test('a check date in the future is flagged', () {
      final future = CountryHolidays(
        country: 'XX',
        weekendDays: const {6, 7},
        lastYear: 2028,
        holidayDays: const {},
        checked: LocalDate(2026, 12, 1),
      );
      expect(futureCheckedCountries([future], LocalDate(2026, 11, 22)), [
        future,
      ]);
      expect(futureCheckedCountries([future], LocalDate(2026, 12, 1)), isEmpty);
    });
  });
}
