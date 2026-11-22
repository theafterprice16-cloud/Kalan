import 'package:drift/drift.dart';

import '../../core/holidays/holidays.dart';
import '../../core/money/currency.dart';
import '../db/app_database.dart';
import '../models.dart';
import 'plan_repository.dart';

/// The calendar the stored card dates were computed with (Roadmap 26):
/// the settings' applied holidays; null for "None" and before onboarding.
/// Every card date the app computes uses it, so new dates agree with the
/// stored ones, also in a background isolate that cannot read assets.
Future<CountryHolidays?> appliedHolidaysOf(AppDatabase db) async {
  final s = await db.select(db.appSettings).getSingleOrNull();
  return CountryHolidays.fromSnapshot(s?.appliedHolidays);
}

/// The holiday country and the dates it moves (Roadmap 26, decisions 5
/// and 8).
class HolidayRepository {
  HolidayRepository(this._db, this._plans);

  final AppDatabase _db;
  final PlanRepository _plans;

  /// Brings the stored card dates in line with the shipped holiday list
  /// ([countries]) and the holiday country, in one transaction:
  ///
  /// - [choose]: the country picked in Settings ('' for "None");
  /// - otherwise the saved country; none saved yet (first start of this
  ///   version, or right after onboarding): the suggestion
  ///   ([suggestHolidayCountry]) from [region] and the currency, saved.
  ///
  /// When the calendar differs from the one the dates were computed with
  /// (a new country, a new list in an app update, the first start), every
  /// card's unpaid, unedited payments move ([PlanRepository.reshiftCardPlans])
  /// and the new calendar is saved. Returns whether any date could have
  /// moved. Running it again changes nothing. Before onboarding (no
  /// settings) it does nothing.
  Future<bool> sync({
    required List<CountryHolidays> countries,
    required String? region,
    String? choose,
  }) => _db.transaction(() async {
    final settings = await _db.select(_db.appSettings).getSingleOrNull();
    if (settings == null) return false;
    final byCode = {for (final c in countries) c.country: c};
    var code =
        choose ??
        settings.holidayCountry ??
        suggestHolidayCountry(
          region: region,
          currencyCountries: Currency.fromCode(settings.currencyCode).countries,
          available: byCode.keys.toSet(),
        ) ??
        '';
    // A country no longer in the list (never shipped so far) reads as
    // "None".
    final calendar = byCode[code];
    if (calendar == null) code = '';
    final applied = settings.appliedHolidays;
    final next = snapshotOf(calendar);
    if (code != settings.holidayCountry || next != applied) {
      await _db
          .update(_db.appSettings)
          .write(
            AppSettingsCompanion(
              holidayCountry: Value(code),
              appliedHolidays: Value(next),
            ),
          );
    }
    if (next == applied) return false;
    final old = CountryHolidays.fromSnapshot(applied);
    final cards = await (_db.select(
      _db.sources,
    )..where((s) => s.kind.equalsValue(SourceKind.card))).get();
    for (final card in cards) {
      final oldTerms = card.cardTermsIn(old);
      final newTerms = card.cardTermsIn(calendar);
      if (oldTerms == null || newTerms == null) continue;
      await _plans.reshiftCardPlans(
        sourceId: card.id,
        oldTerms: oldTerms,
        newTerms: newTerms,
      );
    }
    return true;
  });
}
