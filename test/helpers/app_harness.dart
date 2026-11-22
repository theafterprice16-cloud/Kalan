import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:material_ui/material_ui.dart';

/// Default "today" in widget tests: Friday 20 November 2026.
final testToday = LocalDate(2026, 11, 20);

/// Starts the full app on an in-memory database.
///
/// The database is closed after the test. Call [seed] to insert data
/// before the first frame.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('tr', 'TR'),
  LocalDate? today,
  Future<void> Function(AppDatabase db)? seed,
  List<Override> overrides = const [],
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  if (seed != null) await seed(db);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(today ?? testToday),
        ...overrides,
      ],
      child: const KalanApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
  return db;
}

/// Monthly payday on the 15th.
Future<void> seedSettings(
  AppDatabase db, {
  String currency = 'TRY',
  int? incomeMinor,
  int? thresholdMinor,
  String? localeCode,
  int payDay = 15,
  // "None" unless a test is about holidays (26): fixed test dates that
  // happen to fall on a public holiday keep their old results.
  String holidayCountry = '',
}) => db
    .into(db.appSettings)
    .insert(
      AppSettingsCompanion.insert(
        currencyCode: currency,
        payFrequency: PayFrequency.monthly,
        payDay: Value(payDay),
        netIncomeMinor: Value(incomeMinor),
        tightThresholdMinor: Value(thresholdMinor),
        localeCode: Value(localeCode),
        holidayCountry: Value(holidayCountry),
      ),
    );

/// Pay in 4 at Klarna, 400.00 starting on [first].
Future<int> seedPayIn4(
  AppDatabase db, {
  LocalDate? first,
  int totalMinor = 40000,
  String source = 'Klarna',
  String? title,
}) async {
  final plans = PlanRepository(db);
  final sourceId = await SourceRepository(
    db,
    plans,
  ).findOrCreateProvider(source);
  return plans.saveDraft(
    PlanCalculator.payIn4(
      firstDate: first ?? testToday,
      totalMinor: totalMinor,
    ),
    sourceId: sourceId,
    origin: PlanOrigin.template,
    title: title,
  );
}

/// Monthly rent of 15,000.00 since January.
Future<int> seedRent(AppDatabase db) => RecurringRepository(db).create(
  RecurringPaymentsCompanion.insert(
    name: 'Kira',
    amountMinor: 1500000,
    recurrence: Recurrence.monthly,
    startDay: LocalDate(2026, 1, 1).epochDay,
  ),
);

/// Scrolls the first scrollable until [finder] is built and visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Opens a tab from the bottom navigation bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Picks [item] from the dropdown with [key].
Future<void> pickDropdown(
  WidgetTester tester,
  Key key,
  String item, {
  double delta = 48,
}) async {
  await scrollTo(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  // The open menu is the last scrollable; long menus build items lazily.
  await tester.scrollUntilVisible(
    find.text(item),
    delta,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

/// A credit card with statement day 25 and due day 5.
Future<int> seedCard(AppDatabase db, {String name = 'Bonus'}) =>
    SourceRepository(
      db,
      PlanRepository(db),
    ).create(name: name, kind: SourceKind.card, statementDay: 25, dueDay: 5);
