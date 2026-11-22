/// Public holidays (Roadmap 26): each country's weekend and nationwide
/// public holidays, shipped with the app in `assets/holidays.json` and
/// renewed only with an app update. Nothing is fetched.
///
/// A date is in the file only when an official state source published it
/// (or a law fixes it); religious holidays only for the years they were
/// announced. Regional holidays, half days, make-up working days and
/// banks' own closures are not modelled. Holiday names are not stored: the
/// app never shows them.
///
/// Pure Dart: no Flutter import (the CI check runs it with `dart run`).
library;

import 'dart:convert';

import '../date/local_date.dart';
import '../engine/business_days.dart';

/// The asset path, declared in pubspec.yaml.
const holidaysAsset = 'assets/holidays.json';

/// The only schema version this build reads.
const holidaysSchemaVersion = 1;

/// Every key the file may use, by level. Anything else is refused.
const holidayKeys = (
  file: {'schemaVersion', 'countries'},
  country: {'country', 'weekend', 'lastYear', 'sources', 'checked', 'years'},
);

/// Weekday names the file uses, to ISO weekdays.
const weekdayCodes = <String, int>{
  'mon': DateTime.monday,
  'tue': DateTime.tuesday,
  'wed': DateTime.wednesday,
  'thu': DateTime.thursday,
  'fri': DateTime.friday,
  'sat': DateTime.saturday,
  'sun': DateTime.sunday,
};

/// The earliest year the file may hold (the first year Kalan shipped it).
const firstHolidayYear = 2026;

/// One country's weekend and public holidays for the years it covers.
class CountryHolidays implements HolidayCalendar {
  CountryHolidays({
    required this.country,
    required Set<int> weekendDays,
    required this.lastYear,
    required Set<int> holidayDays,
    this.sources = const [],
    this.checked,
  }) : weekendDays = Set.unmodifiable(weekendDays),
       holidayDays = Set.unmodifiable(holidayDays);

  /// ISO 3166-1 alpha-2.
  final String country;

  @override
  final Set<int> weekendDays;

  /// The last year whose holidays are all in the file. After it only the
  /// weekend moves a date (product owner decision 3).
  final int lastYear;

  /// Holidays as epoch days.
  final Set<int> holidayDays;

  /// Official pages the dates come from (https).
  final List<String> sources;

  /// When the dates were last checked against [sources]; null in a stored
  /// snapshot.
  final LocalDate? checked;

  @override
  bool isHoliday(LocalDate date) => holidayDays.contains(date.epochDay);

  /// The holidays in date order.
  List<LocalDate> get dates =>
      ([...holidayDays]..sort()).map(LocalDate.fromEpochDay).toList();

  /// What the app stores as the calendar its card dates were computed
  /// with ([AppliedHolidays]): country, weekend, last year and dates.
  String toSnapshot() => jsonEncode({
    'country': country,
    'weekend': ([...weekendDays]..sort()),
    'lastYear': lastYear,
    'days': ([...holidayDays]..sort()),
  });

  /// Reads [toSnapshot]; null for a missing or unreadable value (then the
  /// stored dates were computed with "None").
  static CountryHolidays? fromSnapshot(String? snapshot) {
    if (snapshot == null || snapshot.isEmpty) return null;
    try {
      final m = jsonDecode(snapshot) as Map<String, Object?>;
      return CountryHolidays(
        country: m['country']! as String,
        weekendDays: {for (final d in m['weekend']! as List) d as int},
        lastYear: m['lastYear']! as int,
        holidayDays: {for (final d in m['days']! as List) d as int},
      );
    } on Object {
      return null;
    }
  }
}

/// The calendar stored dates were computed with: the snapshot of a
/// country, or "None". Two values are equal when they move every date the
/// same way.
String? snapshotOf(CountryHolidays? calendar) => calendar?.toSnapshot();

class HolidayFormatException implements Exception {
  const HolidayFormatException(this.message);
  final String message;
  @override
  String toString() => 'HolidayFormatException: $message';
}

final _countryPattern = RegExp(r'^[A-Z]{2}$');
final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Reads the holidays file. Throws [HolidayFormatException] on a key
/// outside [holidayKeys], a missing or out-of-range value, a date outside
/// its year or out of order, a repeated date or country, a gap in the
/// years, or a weekend of other than one or two days.
List<CountryHolidays> parseHolidays(String json) {
  final Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException catch (e) {
    throw HolidayFormatException('not JSON: ${e.message}');
  }
  final file = _map(root, 'file', holidayKeys.file);
  if (file['schemaVersion'] != holidaysSchemaVersion) {
    throw const HolidayFormatException('unknown schemaVersion');
  }
  final list = file['countries'];
  if (list is! List) {
    throw const HolidayFormatException('countries is not a list');
  }
  final countries = [
    for (final (i, c) in list.indexed) _country(c, 'countries[$i]'),
  ];
  final seen = <String>{};
  for (final c in countries) {
    if (!seen.add(c.country)) {
      throw HolidayFormatException('duplicate country ${c.country}');
    }
  }
  return countries;
}

CountryHolidays _country(Object? value, String at) {
  final m = _map(value, at, holidayKeys.country);
  final code = m['country'];
  if (code is! String || !_countryPattern.hasMatch(code)) {
    throw HolidayFormatException('$at.country must be ISO 3166-1 alpha-2');
  }
  at = '$at ($code)';
  final weekend = m['weekend'];
  if (weekend is! List || weekend.isEmpty || weekend.length > 2) {
    throw HolidayFormatException('$at.weekend must hold one or two days');
  }
  final weekendDays = <int>{};
  for (final d in weekend) {
    final day = weekdayCodes[d];
    if (day == null || !weekendDays.add(day)) {
      throw HolidayFormatException('$at.weekend has "$d"');
    }
  }
  final lastYear = m['lastYear'];
  if (lastYear is! int || lastYear < firstHolidayYear || lastYear > 2100) {
    throw HolidayFormatException('$at.lastYear is out of range');
  }
  final sources = m['sources'];
  if (sources is! List ||
      sources.isEmpty ||
      sources.any((s) => s is! String || !s.startsWith('https://'))) {
    throw HolidayFormatException('$at.sources must be https links');
  }
  final checked = m['checked'];
  if (checked is! String) {
    throw HolidayFormatException('$at.checked is missing');
  }
  final years = m['years'];
  if (years is! Map<String, Object?>) {
    throw HolidayFormatException('$at.years is not an object');
  }
  final days = <int>{};
  var expectedYear = firstHolidayYear;
  for (final MapEntry(:key, value: list) in years.entries) {
    if (key != '$expectedYear') {
      throw HolidayFormatException(
        '$at.years must run $firstHolidayYear-$lastYear in order, '
        'found "$key"',
      );
    }
    if (list is! List) {
      throw HolidayFormatException('$at.years.$key is not a list');
    }
    LocalDate? previous;
    for (final d in list) {
      final date = d is String ? _date(d, '$at.years.$key') : null;
      if (date == null || date.year != expectedYear) {
        throw HolidayFormatException('$at.years.$key has "$d"');
      }
      if (previous != null && date <= previous) {
        throw HolidayFormatException(
          '$at.years.$key is not in order or repeats $d',
        );
      }
      previous = date;
      days.add(date.epochDay);
    }
    expectedYear++;
  }
  if (expectedYear - 1 != lastYear) {
    throw HolidayFormatException('$at.years must end at lastYear $lastYear');
  }
  return CountryHolidays(
    country: code,
    weekendDays: weekendDays,
    lastYear: lastYear,
    holidayDays: days,
    sources: [for (final s in sources) s as String],
    checked: parseHolidayDate(checked, '$at.checked'),
  );
}

Map<String, Object?> _map(Object? value, String at, Set<String> allowed) {
  if (value is! Map<String, Object?>) {
    throw HolidayFormatException('$at is not an object');
  }
  for (final key in value.keys) {
    if (!allowed.contains(key)) {
      throw HolidayFormatException('$at has unknown key "$key"');
    }
  }
  for (final key in allowed) {
    if (!value.containsKey(key)) {
      throw HolidayFormatException('$at is missing "$key"');
    }
  }
  return value;
}

LocalDate? _date(String value, String at) {
  final match = _datePattern.firstMatch(value);
  if (match == null) return null;
  final (y, mo, d) = (
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  if (mo < 1 || mo > 12 || d < 1 || d > LocalDate.daysInMonth(y, mo)) {
    return null;
  }
  return LocalDate(y, mo, d);
}

/// "2026-11-22" as a date; throws [HolidayFormatException] otherwise.
LocalDate parseHolidayDate(String value, String at) =>
    _date(value, at) ??
    (throw HolidayFormatException('$at must be YYYY-MM-DD, found "$value"'));

/// The holiday country Kalan suggests (decision 5): the device region
/// when the file has it; otherwise the country of the chosen currency
/// when that currency belongs to one country only (none for the euro or
/// any shared currency); otherwise none ("None": Saturday and Sunday, as
/// before).
String? suggestHolidayCountry({
  required String? region,
  required Set<String> currencyCountries,
  required Set<String> available,
}) {
  final r = region?.toUpperCase();
  if (r != null && available.contains(r)) return r;
  if (currencyCountries.length == 1) {
    final c = currencyCountries.single;
    if (available.contains(c)) return c;
  }
  return null;
}

/// A country whose list ends this year or earlier: the CI check warns
/// (decision 11). The app keeps working: after [CountryHolidays.lastYear]
/// only the weekend moves a date.
bool isHolidayListStale(CountryHolidays country, LocalDate today) =>
    country.lastYear <= today.year;

/// The stale countries, in file order.
List<CountryHolidays> staleHolidayCountries(
  List<CountryHolidays> all,
  LocalDate today,
) => [
  for (final c in all)
    if (isHolidayListStale(c, today)) c,
];

/// Countries checked after [today]: a typo in a check date.
List<CountryHolidays> futureCheckedCountries(
  List<CountryHolidays> all,
  LocalDate today,
) => [
  for (final c in all)
    if (c.checked case final d? when d > today) c,
];

/// "Tatil listesi 2026 sonunda bitiyor: TR".
String staleHolidayWarning(CountryHolidays c) =>
    'Tatil listesi ${c.lastYear} sonunda bitiyor: ${c.country}. '
    'Listeyi yenile ve kaynaklardan doğrula.';
