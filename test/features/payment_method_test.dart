import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

Future<void> openDetails(WidgetTester tester) async {
  await scrollTo(tester, find.text('Ayrıntı ekle'));
  await tester.tap(find.text('Ayrıntı ekle'));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
  await tester.tap(find.byKey(const ValueKey('save-plan')));
  await tester.pumpAndSettle();
}

/// A card plan at Bonus (6 × 2,000.00 from today's purchase).
Future<int> seedCardPlan(AppDatabase db, {PaymentMethod? method}) async {
  final card = await seedCard(db);
  final id = await PlanRepository(db).saveDraft(
    PlanCalculator.card(
      purchaseDate: testToday,
      totalMinor: 1200000,
      count: 6,
      terms: const CardTerms(statementDay: 25, dueDay: 5),
    ),
    sourceId: card,
    origin: PlanOrigin.template,
    title: 'Telefon',
    paymentMethod: method,
  );
  return id;
}

void main() {
  group('add plan', () {
    testWidgets('a card plan is taken automatically from its card; the '
        'choice stays inside "More details"', (tester) async {
      final db = await pumpApp(
        tester,
        seed: (db) async {
          await seedSettings(db, incomeMinor: 5000000);
          await seedCard(db);
        },
      );
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kredi kartı taksidi'));
      await tester.pumpAndSettle();
      await pickDropdown(tester, const ValueKey('card'), 'Bonus');
      await tester.enterText(find.byKey(const ValueKey('total')), '3000');
      await tester.enterText(find.byKey(const ValueKey('count')), '3');
      // No new field on the form itself: the four fields as before.
      expect(find.byKey(const ValueKey('payment-method')), findsNothing);
      expect(find.byKey(const ValueKey('charge-source-1')), findsNothing);

      await openDetails(tester);
      await scrollTo(tester, find.byKey(const ValueKey('charge-source-1')));
      expect(chipSelected(tester, 'Otomatik çekilir'), isTrue);
      expect(chipSelected(tester, 'Elle ödenir'), isFalse);
      expect(chipSelected(tester, 'Belirtilmedi'), isFalse);
      // Its own card is chosen; a card plan has no "Not chosen".
      final dropdown = find.byKey(const ValueKey('charge-source-1'));
      expect(
        find.descendant(of: dropdown, matching: find.text('Bonus')),
        findsOneWidget,
      );
      expect(find.text('Seçilmedi'), findsNothing);

      await save(tester);
      final plan = await db.select(db.plans).getSingle();
      expect(plan.paymentMethod, PaymentMethod.automatic);
      // Stored empty: it follows the plan's card.
      expect(plan.chargeSourceId, equals(null));
    });

    testWidgets('other plans start "not set"; manual is saved', (tester) async {
      final db = await pumpApp(
        tester,
        seed: (db) => seedSettings(db, incomeMinor: 5000000),
      );
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('source')), 'Market');
      await tester.enterText(find.byKey(const ValueKey('total')), '850');
      await openDetails(tester);
      await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Belirtilmedi'));
      expect(chipSelected(tester, 'Belirtilmedi'), isTrue);
      expect(find.byKey(const ValueKey('payment-method-hint')), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Elle ödenir'));
      await tester.pumpAndSettle();
      expect(chipSelected(tester, 'Elle ödenir'), isTrue);
      expect(
        find.text('Hatırlatma bir gün daha erken gelir; ödemeye vaktin kalır.'),
        findsOneWidget,
      );
      await save(tester);
      final plan = await db.select(db.plans).getSingle();
      expect(plan.paymentMethod, PaymentMethod.manual);
      expect(plan.chargeSourceId, equals(null));
    });

    testWidgets('automatic: where it is taken from is optional', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        seed: (db) async {
          await seedSettings(db, incomeMinor: 5000000);
          await seedCard(db);
        },
      );
      await tester.tap(find.text('Plan ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
      await tester.enterText(find.byKey(const ValueKey('total')), '120');
      await openDetails(tester);
      await scrollTo(
        tester,
        find.widgetWithText(ChoiceChip, 'Otomatik çekilir'),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Otomatik çekilir'));
      await tester.pumpAndSettle();
      // Not chosen until picked.
      await scrollTo(tester, find.byKey(const ValueKey('charge-source-null')));
      expect(find.text('Seçilmedi'), findsOneWidget);
      await pickDropdown(tester, const ValueKey('charge-source-null'), 'Bonus');
      await save(tester);
      final plan = await db.select(db.plans).getSingle();
      final card = await db.select(db.sources).get();
      expect(plan.paymentMethod, PaymentMethod.automatic);
      expect(plan.chargeSourceId, card.firstWhere((s) => s.name == 'Bonus').id);
    });
  });

  group('plan details', () {
    testWidgets('shows icon and word; a manual plan reminds a day earlier', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        seed: (db) async {
          await seedSettings(db, incomeMinor: 5000000);
          await seedCardPlan(db, method: PaymentMethod.automatic);
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Telefon'));
      await tester.pumpAndSettle();
      expect(find.text('Genel ayar (2 gün önce)'), findsOneWidget);
      const tile = ValueKey('item-payment-method');
      await scrollTo(tester, find.byKey(tile));
      expect(find.text('Otomatik çekilir · Bonus'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(tile),
          matching: find.byIcon(Icons.account_balance_outlined),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(tile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elle ödenir').last);
      await tester.pumpAndSettle();
      final plan = await db.select(db.plans).getSingle();
      expect(plan.paymentMethod, PaymentMethod.manual);
      expect(plan.chargeSourceId, equals(null));
      expect(find.text('Elle ödenir'), findsOneWidget);
      expect(
        find.text('Genel ayar (3 gün önce)', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('automatic with a card plan: its card is chosen', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        seed: (db) async {
          await seedSettings(db, incomeMinor: 5000000);
          await seedCardPlan(db);
          await seedCard(db, name: 'Maximum');
        },
      );
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Telefon'));
      await tester.pumpAndSettle();
      const tile = ValueKey('item-payment-method');
      await scrollTo(tester, find.byKey(tile));
      expect(find.text('Belirtilmedi'), findsOneWidget);
      await tester.tap(find.byKey(tile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otomatik çekilir').last);
      await tester.pumpAndSettle();
      // The plan's card carries the check mark; no "Not chosen".
      expect(find.text('Seçilmedi'), findsNothing);
      final bonus = find.ancestor(
        of: find.text('Bonus').last,
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: bonus, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      await tester.tap(find.text('Maximum').last);
      await tester.pumpAndSettle();
      final plan = await db.select(db.plans).getSingle();
      final maximum = await (db.select(
        db.sources,
      )..where((s) => s.name.equals('Maximum'))).getSingle();
      expect(plan.paymentMethod, PaymentMethod.automatic);
      expect(plan.chargeSourceId, maximum.id);
      expect(find.text('Otomatik çekilir · Maximum'), findsOneWidget);
    });
  });

  testWidgets('home: an icon per method, read out as its word; none when '
      'not set', (tester) async {
    final semantics = tester.ensureSemantics();
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedCardPlan(db, method: PaymentMethod.automatic);
        await seedPayIn4(db, title: 'Market');
        await seedPayIn4(db, source: 'Zip', title: 'Kulaklık');
      },
    );
    await (db.update(db.plans)..where((p) => p.title.equals('Market'))).write(
      const PlansCompanion(paymentMethod: Value(PaymentMethod.manual)),
    );
    await tester.pumpAndSettle();
    // Market is manual (two payments this period), Telefon automatic.
    expect(
      find.byKey(const ValueKey('payment-method-icon-manual')),
      findsNWidgets(2),
    );
    expect(find.bySemanticsLabel(RegExp('Elle ödenir')), findsNWidgets(2));
    await scrollTo(tester, find.text('Telefon'));
    expect(
      find.byKey(const ValueKey('payment-method-icon-automatic')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Otomatik çekilir')), findsOneWidget);
    // The plan without a method has no icon.
    final rows = find.bySemanticsLabel(RegExp('Kulaklık'));
    expect(rows, findsWidgets);
    for (final row in rows.evaluate()) {
      final label = tester.getSemantics(find.byWidget(row.widget)).label;
      expect(label, isNot(contains('Otomatik')));
      expect(label, isNot(contains('Elle')));
    }
    semantics.dispose();
  });
}
