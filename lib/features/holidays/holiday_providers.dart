import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/holidays/holidays.dart';
import '../../data/repositories/holiday_repository.dart';

/// The holidays file shipped with the app (Roadmap 26). Never fetched: it
/// changes only with an app update. Overridden in tests.
final holidaysSourceProvider = FutureProvider<String>(
  (ref) => rootBundle.loadString(holidaysAsset, cache: false),
);

/// Every country in the file, or null while it loads or when it cannot be
/// read: then nothing is synced (the stored dates stay as they are) and
/// the holiday country list is empty.
final holidayCountriesProvider = Provider<List<CountryHolidays>?>((ref) {
  final json = ref.watch(holidaysSourceProvider).value;
  if (json == null) return null;
  try {
    return parseHolidays(json);
  } on HolidayFormatException {
    return null;
  }
});

final holidayRepositoryProvider = Provider(
  (ref) => HolidayRepository(
    ref.watch(databaseProvider),
    ref.watch(planRepositoryProvider),
  ),
);

/// The calendar the stored card dates were computed with: every card
/// date the screens compute or explain uses it (null: "None").
final appliedHolidaysProvider = Provider<CountryHolidays?>(
  (ref) => CountryHolidays.fromSnapshot(
    ref.watch(settingsProvider.select((s) => s.value?.appliedHolidays)),
  ),
);

/// Keeps the stored card dates in line with the shipped list and the
/// holiday country (decision 8): on start (a new list in an app update,
/// the first start of this version), once onboarding saves the settings
/// (the suggested country) and whenever they drift apart. Read once by
/// the app; a no-op when everything already agrees.
final holidaySyncProvider = Provider<void>((ref) {
  final countries = ref.watch(holidayCountriesProvider);
  final settings = ref.watch(settingsProvider).value;
  if (countries == null || settings == null) return;
  final code = settings.holidayCountry;
  if (code != null) {
    final calendar = [
      for (final c in countries)
        if (c.country == code) c,
    ].firstOrNull;
    if ((code.isEmpty || calendar != null) &&
        snapshotOf(calendar) == settings.appliedHolidays) {
      return;
    }
  }
  unawaited(
    ref
        .read(holidayRepositoryProvider)
        .sync(countries: countries, region: ref.read(deviceRegionProvider)),
  );
});
