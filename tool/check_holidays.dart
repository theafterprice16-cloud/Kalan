// Flags holiday lists (Roadmap 26) that end this year or earlier, as
// GitHub Actions warnings: the CI stays green. Run:
//   dart run tool/check_holidays.dart [--today=YYYY-MM-DD]
// An unreadable file fails (the schema test fails too). Before a release,
// renew the list and re-check every date on its sources
// (docs/YAYIN_KONTROL.md).
import 'dart:io';

import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/holidays/holidays.dart';

void main(List<String> args) {
  final now = DateTime.now();
  var today = LocalDate(now.year, now.month, now.day);
  for (final arg in args) {
    if (arg.startsWith('--today=')) {
      today = parseHolidayDate(arg.substring('--today='.length), '--today');
    }
  }
  final List<CountryHolidays> countries;
  try {
    countries = parseHolidays(File(holidaysAsset).readAsStringSync());
  } on HolidayFormatException catch (e) {
    stdout.writeln('::error file=$holidaysAsset::${e.message}');
    exitCode = 1;
    return;
  }
  final stale = staleHolidayCountries(countries, today);
  for (final c in stale) {
    stdout.writeln('::warning file=$holidaysAsset::${staleHolidayWarning(c)}');
  }
  for (final c in futureCheckedCountries(countries, today)) {
    stdout.writeln(
      '::warning file=$holidaysAsset::Tatil kontrol tarihi gelecekte: '
      '${c.country} (${c.checked})',
    );
  }
  stdout.writeln(
    '${countries.length} countries, ${stale.length} ending by ${today.year}.',
  );
}
