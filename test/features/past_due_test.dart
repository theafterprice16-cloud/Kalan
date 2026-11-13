import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

LocalDate d(int m, int day, [int y = 2026]) => LocalDate(y, m, day);

/// A one-payment plan named [name] due on [due].
Future<void> seedOne(
  AppDatabase db,
  String name,
  LocalDate due,
  int amountMinor,
) async {
  final plans = PlanRepository(db);
  final source = await SourceRepository(db, plans).findOrCreateProvider(name);
  await plans.saveDraft(
    PlanCalculator.monthly(firstDate: due, totalMinor: amountMinor, count: 1),
    sourceId: source,
    origin: PlanOrigin.template,
  );
}

/// Zeynep: periods start on the 1st, income 30,000. November's own
/// payments are 12,000; Klarna's 850 from 28 Oct is unpaid.
Future<AppDatabase> pumpZeynep(
  WidgetTester tester, {
  LocalDate? today,
  List<Override> overrides = const [],
}) => pumpApp(
  tester,
  today: today ?? d(11, 1),
  overrides: overrides,
  seed: (db) async {
    await seedSettings(db, incomeMinor: 3000000, payDay: 1);
    await seedOne(db, 'Telefon', d(11, 10), 1200000);
    await seedOne(db, 'Klarna', d(10, 28), 85000);
  },
);

Finder get section => find.byKey(const ValueKey('past-due'));

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Ödendi').first);
  await tester.pumpAndSettle();
  expect(find.text('Ne zaman ödedin?'), findsOneWidget);
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  testWidgets('Zeynep: one past-due payment, deducted from November', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpZeynep(tester);
    expect(find.text('Günü geçen 1 ödeme'), findsOneWidget);
    expect(
      find.text('Ödenmemiş olanlar bu dönemin kalanından düşüldü.'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('4 gün önce')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('₺850')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Klarna, ₺850, son ödeme günü 4 gün önce geçti'),
      findsOneWidget,
    );
    // 30,000 - (12,000 + 850).
    expect(find.text('₺17.150'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('"Today": the row leaves, November stays at 17,150', (
    tester,
  ) async {
    final db = await pumpZeynep(tester);
    await openSheet(tester);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Bu dönemin hesabında kalır.'), findsOneWidget);
    expect(find.text('Gününde, 28 Ekim'), findsOneWidget);
    expect(find.text('Ödeme o döneme yazılır.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paid-when-today')));
    await tester.pumpAndSettle();
    expect(section, findsNothing);
    expect(find.text('Günü geçen 1 ödeme'), findsNothing);
    expect(find.text('₺17.150'), findsOneWidget);
    // Listed in November now, as paid.
    expect(find.text('Klarna'), findsOneWidget);
    final klarna = (await db.select(db.payments).get()).firstWhere(
      (p) => p.dueDay == d(10, 28).epochDay,
    );
    expect(klarna.paidOnDay, d(11, 1).epochDay);
  });

  testWidgets('"On the due date": back to October, November gains 850', (
    tester,
  ) async {
    final db = await pumpZeynep(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('paid-when-due')));
    await tester.pumpAndSettle();
    expect(section, findsNothing);
    expect(find.text('₺18.000'), findsOneWidget);
    expect(find.text('Klarna'), findsNothing);
    final klarna = (await db.select(db.payments).get()).firstWhere(
      (p) => p.dueDay == d(10, 28).epochDay,
    );
    expect(klarna.paidOnDay, d(10, 28).epochDay);
  });

  testWidgets('cancel leaves everything as it was', (tester) async {
    await pumpZeynep(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('paid-when-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Günü geçen 1 ödeme'), findsOneWidget);
    expect(find.text('₺17.150'), findsOneWidget);
  });

  testWidgets('nothing past due: no section at all', (tester) async {
    await pumpApp(
      tester,
      today: d(11, 1),
      seed: (db) async {
        await seedSettings(db, incomeMinor: 3000000, payDay: 1);
        await seedOne(db, 'Telefon', d(11, 10), 1200000);
        // Due today: not past due.
        await seedOne(db, 'Zip', d(11, 1), 40000);
      },
    );
    expect(section, findsNothing);
    expect(find.textContaining('Günü geçen'), findsNothing);
    expect(find.text('Zip'), findsOneWidget);
    expect(find.text('₺17.600'), findsOneWidget);
  });

  testWidgets('same period: listed once, the total does not move', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: d(11, 10),
      seed: (db) async {
        await seedSettings(db, incomeMinor: 3000000, payDay: 1);
        await seedOne(db, 'Zip', d(11, 5), 40000);
        await seedOne(db, 'Telefon', d(11, 20), 1200000);
      },
    );
    expect(find.text('Günü geçen 1 ödeme'), findsOneWidget);
    expect(find.text('5 gün önce'), findsOneWidget);
    expect(
      find.text('Ödenmemiş olanlar bu dönemin kalanından düşüldü.'),
      findsNothing,
    );
    expect(find.text('Zip'), findsOneWidget); // only in the section
    expect(find.text('₺17.600'), findsOneWidget);
  });

  testWidgets('more than three: oldest first, "Show all" opens the rest', (
    tester,
  ) async {
    await pumpApp(
      tester,
      today: d(11, 1),
      seed: (db) async {
        await seedSettings(db, incomeMinor: 3000000, payDay: 1);
        await seedOne(db, 'Dördüncü', d(10, 23), 1000);
        await seedOne(db, 'Birinci', d(9, 20), 1000);
        await seedOne(db, 'İkinci', d(10, 21), 1000);
        await seedOne(db, 'Üçüncü', d(10, 22), 1000);
      },
    );
    expect(find.text('Günü geçen 4 ödeme'), findsOneWidget);
    expect(find.text('Tümünü göster (4)'), findsOneWidget);
    expect(find.text('Dördüncü'), findsNothing);
    final top = [
      for (final name in ['Birinci', 'İkinci', 'Üçüncü'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(top, [...top]..sort());
    await tester.ensureVisible(find.text('Tümünü göster (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tümünü göster (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Dördüncü'), findsOneWidget);
    expect(find.text('Tümünü göster (4)'), findsNothing);
  });

  testWidgets('plan detail: days note, and "paid" asks when', (tester) async {
    await pumpZeynep(tester);
    await tester.tap(
      find.descendant(of: section, matching: find.text('Klarna')),
    );
    await tester.pumpAndSettle();
    expect(find.text('4 gün önce'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    await tester.tap(find.byTooltip('Ödendi olarak işaretle'));
    await tester.pumpAndSettle();
    expect(find.text('Ne zaman ödedin?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paid-when-due')));
    await tester.pumpAndSettle();
    expect(find.text('4 gün önce'), findsNothing);
  });

  testWidgets('paid before Kalan is never past due', (tester) async {
    await pumpApp(
      tester,
      today: d(11, 13),
      seed: (db) async {
        await seedSettings(db, incomeMinor: 3000000, payDay: 1);
        final plans = PlanRepository(db);
        final source = await SourceRepository(
          db,
          plans,
        ).findOrCreateProvider('Telefon');
        await plans.saveDraft(
          underwayPlan(
            kind: PlanKind.monthly,
            totalMinor: 850000,
            count: 10,
            paidCount: 3,
            nextDate: d(12, 5),
          ),
          sourceId: source,
          origin: PlanOrigin.template,
        );
      },
    );
    expect(section, findsNothing);
  });

  testWidgets('marking paid reschedules reminders; none for past due', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway();
    await pumpZeynep(
      tester,
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 1, 5)),
      ],
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    final before = gateway.replaceCalls;
    expect(
      gateway.pending.expand((r) => r.payments).map((p) => p.date),
      isNot(contains(d(10, 28))),
    );
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('paid-when-today')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(gateway.replaceCalls, greaterThan(before));
  });
}
