import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/holidays/holidays.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/holiday_repository.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';

final shipped = parseHolidays(File(holidaysAsset).readAsStringSync());

LocalDate day(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return LocalDate(p[0], p[1], p[2]);
}

void main() {
  late AppDatabase db;
  late PlanRepository plans;
  late SourceRepository sources;
  late HolidayRepository holidays;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(db);
    sources = SourceRepository(db, plans);
    holidays = HolidayRepository(db, plans);
  });
  tearDown(() => db.close());

  /// Settings as an existing user has them right after the update (no
  /// holiday country yet).
  Future<void> settings({String currency = 'TRY'}) => db
      .into(db.appSettings)
      .insert(
        AppSettingsCompanion.insert(
          currencyCode: currency,
          payFrequency: PayFrequency.monthly,
          payDay: const Value(15),
        ),
      );

  /// Hakan's card: statement on the 19th, due on the 29th.
  Future<int> card({bool weekends = true}) => sources.create(
    name: 'Bonus',
    kind: SourceKind.card,
    statementDay: 19,
    dueDay: 29,
    shiftDueToBusinessDay: weekends,
  );

  const none = CardTerms(statementDay: 19, dueDay: 29);

  /// A card plan bought on 10 Oct 2026: 29 Oct, 30 Nov, 29 Dec (no
  /// holidays, the dates the app stored before this version).
  Future<int> cardPlan(int cardId, {String title = 'Telefon'}) =>
      plans.saveDraft(
        PlanCalculator.card(
          purchaseDate: day('2026-10-10'),
          totalMinor: 300000,
          count: 3,
          terms: none,
        ),
        sourceId: cardId,
        origin: PlanOrigin.template,
        title: title,
      );

  Future<List<LocalDate>> datesOf(int planId) async => [
    for (final p
        in await (db.select(db.payments)
              ..where((p) => p.planId.equals(planId))
              ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
            .get())
      p.date,
  ];

  Future<PaymentRow> firstOf(int planId) => (db.select(
    db.payments,
  )..where((p) => p.planId.equals(planId) & p.seq.equals(1))).getSingle();

  Future<SettingsRow> saved() => db.select(db.appSettings).getSingle();

  test('example 7: only the unpaid, unedited installment moves', () async {
    await settings();
    final cardId = await card();
    final open = await cardPlan(cardId);
    final edited = await cardPlan(cardId, title: 'Kulaklık');
    final paid = await cardPlan(cardId, title: 'Ayakkabı');
    await (db.update(db.payments)
          ..where((p) => p.planId.equals(edited) & p.seq.equals(1)))
        .write(const PaymentsCompanion(isEdited: Value(true)));
    await plans.setPaid((await firstOf(paid)).id, paid: true);

    expect(await holidays.sync(countries: shipped, region: 'TR'), isTrue);

    expect(await datesOf(open), [
      day('2026-10-30'),
      day('2026-11-30'),
      day('2026-12-29'),
    ]);
    expect((await datesOf(edited)).first, day('2026-10-29'));
    expect((await datesOf(paid)).first, day('2026-10-29'));
    // The later, unpaid installments of those plans follow the rule.
    expect((await datesOf(paid))[1], day('2026-11-30'));
    final s = await saved();
    expect(s.holidayCountry, 'TR');
    expect(
      s.appliedHolidays,
      shipped.firstWhere((c) => c.country == 'TR').toSnapshot(),
    );
  });

  test('running it again changes nothing', () async {
    await settings();
    final open = await cardPlan(await card());
    await holidays.sync(countries: shipped, region: 'TR');
    expect(await holidays.sync(countries: shipped, region: 'TR'), isFalse);
    expect((await datesOf(open)).first, day('2026-10-30'));
  });

  test('a new country, then "None": the dates follow, then return', () async {
    await settings();
    final open = await cardPlan(await card());
    await holidays.sync(countries: shipped, region: 'TR');
    await holidays.sync(countries: shipped, region: 'TR', choose: '');
    expect((await datesOf(open)).first, day('2026-10-29'));
    expect((await saved()).holidayCountry, '');
    expect((await saved()).appliedHolidays, isNull);
    await holidays.sync(countries: shipped, region: 'US', choose: 'TR');
    expect((await datesOf(open)).first, day('2026-10-30'));
  });

  test('the saved country wins over the region', () async {
    await settings();
    final open = await cardPlan(await card());
    await holidays.sync(countries: shipped, region: 'TR', choose: '');
    expect(await holidays.sync(countries: shipped, region: 'TR'), isFalse);
    expect((await datesOf(open)).first, day('2026-10-29'));
  });

  test('a new list in an app update moves the dates once', () async {
    await settings();
    final open = await cardPlan(await card());
    final tr = shipped.firstWhere((c) => c.country == 'TR');
    // An older list without 29 Oct.
    final older = CountryHolidays(
      country: 'TR',
      weekendDays: tr.weekendDays,
      lastYear: tr.lastYear,
      holidayDays: {...tr.holidayDays}..remove(day('2026-10-29').epochDay),
      sources: tr.sources,
      checked: tr.checked,
    );
    await holidays.sync(countries: [older], region: 'TR');
    expect((await datesOf(open)).first, day('2026-10-29'));
    expect(await holidays.sync(countries: shipped, region: 'TR'), isTrue);
    expect((await datesOf(open)).first, day('2026-10-30'));
  });

  test('the card holiday switch moves its dates both ways', () async {
    await settings();
    final cardId = await card();
    final open = await cardPlan(cardId);
    await holidays.sync(countries: shipped, region: 'TR');
    final row = (await sources.byId(cardId))!;
    await sources.update(row.copyWith(shiftDueForHolidays: false));
    expect(await datesOf(open), [
      day('2026-10-29'),
      day('2026-11-30'),
      day('2026-12-29'),
    ]);
    await sources.update(row.copyWith(shiftDueForHolidays: true));
    expect((await datesOf(open)).first, day('2026-10-30'));
  });

  test('example 3 in data: weekend switch off, New Year 2027', () async {
    await settings();
    final cardId = await sources.create(
      name: 'Gece',
      kind: SourceKind.card,
      statementDay: 20,
      dueDay: 1,
      shiftDueToBusinessDay: false,
    );
    final planId = await plans.saveDraft(
      PlanCalculator.card(
        purchaseDate: day('2026-12-10'),
        totalMinor: 100000,
        count: 1,
        terms: const CardTerms(
          statementDay: 20,
          dueDay: 1,
          shiftDueToBusinessDay: false,
        ),
      ),
      sourceId: cardId,
      origin: PlanOrigin.template,
    );
    expect((await datesOf(planId)).first, day('2027-01-01'));
    await holidays.sync(countries: shipped, region: 'TR');
    expect((await datesOf(planId)).first, day('2027-01-02'));
    final row = (await sources.byId(cardId))!;
    await sources.update(row.copyWith(shiftDueToBusinessDay: true));
    expect((await datesOf(planId)).first, day('2027-01-04'));
  });

  test('a card days change keeps the holiday shift', () async {
    await settings();
    final cardId = await card();
    final open = await cardPlan(cardId);
    await holidays.sync(countries: shipped, region: 'TR');
    final row = (await sources.byId(cardId))!;
    // Statement on the 20th: still due on the 29th, still 30 Oct.
    await sources.update(row.copyWith(statementDay: const Value(20)));
    expect(await datesOf(open), [
      day('2026-10-30'),
      day('2026-11-30'),
      day('2026-12-29'),
    ]);
  });

  test('other plan kinds never move (test 6)', () async {
    await settings();
    final provider = await sources.create(
      name: 'Klarna',
      kind: SourceKind.provider,
    );
    final monthly = await plans.saveDraft(
      PlanCalculator.monthly(
        firstDate: day('2026-10-29'),
        totalMinor: 30000,
        count: 3,
      ),
      sourceId: provider,
      origin: PlanOrigin.template,
    );
    final cardId = await card();
    await cardPlan(cardId);
    await holidays.sync(countries: shipped, region: 'TR');
    expect((await datesOf(monthly)).first, day('2026-10-29'));
  });

  test('a closed card plan never moves', () async {
    await settings();
    final cardId = await card();
    final closed = await cardPlan(cardId);
    await (db.update(db.plans)..where((p) => p.id.equals(closed))).write(
      const PlansCompanion(status: Value(PlanStatus.closed)),
    );
    await holidays.sync(countries: shipped, region: 'TR');
    expect((await datesOf(closed)).first, day('2026-10-29'));
  });

  test('a date entered by hand stays (a plan started midway)', () async {
    await settings();
    final cardId = await card();
    final planId = await plans.saveDraft(
      PlanCalculator.midway(
        totalCount: 6,
        remainingCount: 2,
        installmentMinor: 1000,
        nextDate: day('2026-10-27'),
        cardTerms: none,
      ),
      sourceId: cardId,
      origin: PlanOrigin.manual,
    );
    await holidays.sync(countries: shipped, region: 'TR');
    expect((await datesOf(planId)).first, day('2026-10-27'));
  });

  group('the suggestion is saved once (decision 5)', () {
    test('device region', () async {
      await settings(currency: 'USD');
      await holidays.sync(countries: shipped, region: 'DE');
      expect((await saved()).holidayCountry, 'DE');
    });

    test('the currency when the region has no data', () async {
      await settings(currency: 'JPY');
      await holidays.sync(countries: shipped, region: 'AU');
      expect((await saved()).holidayCountry, 'JP');
    });

    test('"None" for a shared currency', () async {
      await settings(currency: 'EUR');
      expect(await holidays.sync(countries: shipped, region: 'AU'), isFalse);
      expect((await saved()).holidayCountry, '');
      expect((await saved()).appliedHolidays, isNull);
    });

    test('nothing before onboarding', () async {
      expect(await holidays.sync(countries: shipped, region: 'TR'), isFalse);
    });
  });

  test('appliedHolidaysOf reads the saved calendar', () async {
    await settings();
    expect(await appliedHolidaysOf(db), isNull);
    await holidays.sync(countries: shipped, region: 'TR');
    final applied = (await appliedHolidaysOf(db))!;
    expect(applied.country, 'TR');
    final cardRow = (await sources.byId(await card()))!;
    expect(
      cardRow.cardTermsIn(applied)!.dueFor(day('2026-10-19')),
      day('2026-10-30'),
    );
  });
}
