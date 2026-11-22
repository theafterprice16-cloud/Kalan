import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/models.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/holidays/holiday_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// Hakan's card (statement 19, due 29) and a plan bought on 10 Oct 2026,
/// stored as the app stored it before Roadmap 26: 29 Oct, 30 Nov, 29 Dec.
/// With [country] null the settings carry no holiday country yet (the
/// first start of this version).
Future<({int card, int plan})> seedHakan(
  AppDatabase db, {
  String? country,
}) async {
  await db
      .into(db.appSettings)
      .insert(
        AppSettingsCompanion.insert(
          currencyCode: 'TRY',
          payFrequency: PayFrequency.monthly,
          payDay: const Value(15),
          holidayCountry: Value(country),
        ),
      );
  final plans = PlanRepository(db);
  final card = await SourceRepository(
    db,
    plans,
  ).create(name: 'Bonus', kind: SourceKind.card, statementDay: 19, dueDay: 29);
  final plan = await plans.saveDraft(
    PlanCalculator.card(
      purchaseDate: LocalDate(2026, 10, 10),
      totalMinor: 300000,
      count: 3,
      terms: const CardTerms(statementDay: 19, dueDay: 29),
    ),
    sourceId: card,
    origin: PlanOrigin.template,
    title: 'Telefon',
  );
  return (card: card, plan: plan);
}

Future<List<LocalDate>> datesOf(AppDatabase db, int planId) async => [
  for (final p
      in await (db.select(db.payments)
            ..where((p) => p.planId.equals(planId))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get())
    p.date,
];

/// Lets the database transaction the sync started finish.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  final today = LocalDate(2026, 10, 20);

  testWidgets('first start: the region is suggested and 29 Oct moves to '
      '30 Oct (example 1, decision 8)', (tester) async {
    late ({int card, int plan}) ids;
    final db = await pumpApp(
      tester,
      today: today,
      seed: (db) async => ids = await seedHakan(db),
    );
    await settle(tester);
    final s = await db.select(db.appSettings).getSingle();
    expect(s.holidayCountry, 'TR');
    expect(await datesOf(db, ids.plan), [
      LocalDate(2026, 10, 30),
      LocalDate(2026, 11, 30),
      LocalDate(2026, 12, 29),
    ]);
  });

  testWidgets('plan detail: the note only on the date moved for a holiday '
      '(test 4)', (tester) async {
    late ({int card, int plan}) ids;
    await pumpApp(
      tester,
      today: today,
      seed: (db) async => ids = await seedHakan(db),
    );
    await settle(tester);
    // Opened on top of home, as from a row.
    unawaited(
      ProviderScope.containerOf(tester.element(find.byType(KalanApp)))
          .read(routerProvider)
          .push(Routes.plan(ids.plan)),
    );
    await tester.pumpAndSettle();
    expect(find.text('30 Eki 2026'), findsOneWidget);
    expect(find.text('Resmî tatil nedeniyle kaydırıldı'), findsOneWidget);
    // 30 Nov: moved only off a weekend (29 Nov is a Sunday): no note.
    expect(find.text('30 Kas 2026'), findsOneWidget);
  });

  testWidgets('card settings: the switch under the weekend one, its note, '
      'and turning it off moves the date back (example 1 to 6)', (
    tester,
  ) async {
    late ({int card, int plan}) ids;
    final db = await pumpApp(
      tester,
      today: today,
      seed: (db) async => ids = await seedHakan(db),
      overrides: [initialRouteProvider.overrideWithValue(Routes.sources)],
    );
    await settle(tester);
    await tester.tap(find.text('Bonus').first);
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('holiday-shift'));
    await scrollTo(tester, toggle);
    expect(find.text('Resmî tatilde kaydır'), findsOneWidget);
    expect(
      find.text(
        'Tatil listesi 2028 sonuna kadar. Uygulama güncellemesiyle yenilenir.',
      ),
      findsOneWidget,
    );
    // Right under the weekend switch.
    final weekend = tester.getRect(
      find.text('Hafta sonuna denk gelirse sonraki iş gününe kaydır'),
    );
    expect(tester.getRect(toggle).top, greaterThanOrEqualTo(weekend.bottom));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('save-source')));
    await tester.tap(find.byKey(const ValueKey('save-source')));
    await settle(tester);
    final card = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(ids.card))).getSingle();
    expect(card.shiftDueForHolidays, isFalse);
    expect((await datesOf(db, ids.plan)).first, LocalDate(2026, 10, 29));
  });

  testWidgets('card settings with "None": a note points to Settings', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: today,
      seed: (db) => seedHakan(db, country: ''),
      overrides: [initialRouteProvider.overrideWithValue(Routes.sources)],
    );
    await settle(tester);
    await tester.tap(find.text('Bonus').first);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('holiday-shift')));
    expect(
      find.text('Tatil ülkesi seçili değil. Ayarlar\'dan seçebilirsin.'),
      findsOneWidget,
    );
  });

  testWidgets('Settings: "Holiday country" lists only countries with data, '
      'the chosen one checked; "None" moves the dates back (example 6)', (
    tester,
  ) async {
    late ({int card, int plan}) ids;
    final db = await pumpApp(
      tester,
      today: today,
      seed: (db) async => ids = await seedHakan(db),
      overrides: [initialRouteProvider.overrideWithValue(Routes.settings)],
    );
    await settle(tester);
    final row = find.byKey(const ValueKey('settings-holiday-country'));
    await scrollTo(tester, row);
    expect(
      find.descendant(of: row, matching: find.text('Türkiye')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Tatil ülkesi'), findsWidgets);
    expect(find.byKey(const ValueKey('choice-')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice-TR')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice-JP')), findsOneWidget);
    // No verified list: not offered.
    expect(find.byKey(const ValueKey('choice-TW')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('choice-TR')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('choice-')));
    await settle(tester);
    expect((await db.select(db.appSettings).getSingle()).holidayCountry, '');
    expect((await datesOf(db, ids.plan)).first, LocalDate(2026, 10, 29));
    expect(
      find.descendant(of: row, matching: find.text('Yok')),
      findsOneWidget,
    );
  });

  testWidgets('a holiday file that does not read changes nothing and '
      'hides the row', (tester) async {
    late ({int card, int plan}) ids;
    final db = await pumpApp(
      tester,
      today: today,
      seed: (db) async => ids = await seedHakan(db),
      overrides: [
        initialRouteProvider.overrideWithValue(Routes.settings),
        holidaysSourceProvider.overrideWith((ref) async => '{not json'),
      ],
    );
    await settle(tester);
    expect(
      (await db.select(db.appSettings).getSingle()).holidayCountry,
      isNull,
    );
    expect((await datesOf(db, ids.plan)).first, LocalDate(2026, 10, 29));
    // Next to the currency and language rows, where it would be.
    // (built with the list's cache extent).
    await scrollTo(tester, find.text('Dil'));
    expect(
      find.byKey(const ValueKey('settings-holiday-country')),
      findsNothing,
    );
  });

  testWidgets('onboarding: the settings saved while the app runs get the '
      'suggested country', (tester) async {
    final db = await pumpApp(tester, today: today);
    await settle(tester);
    await tester.runAsync(
      () => db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              currencyCode: 'TRY',
              payFrequency: PayFrequency.monthly,
              payDay: const Value(15),
            ),
          ),
    );
    await settle(tester);
    await settle(tester);
    expect((await db.select(db.appSettings).getSingle()).holidayCountry, 'TR');
  });

  testWidgets('English texts', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en', 'US'),
      today: today,
      seed: (db) => seedHakan(db, country: 'TR'),
      overrides: [initialRouteProvider.overrideWithValue(Routes.settings)],
    );
    await settle(tester);
    final row = find.byKey(const ValueKey('settings-holiday-country'));
    await scrollTo(tester, row);
    expect(find.text('Holiday country'), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('None'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(
      find.text(
        "Card installment due dates move for this country's weekend and "
        'public holidays.',
      ),
      findsOneWidget,
    );
  });
}
