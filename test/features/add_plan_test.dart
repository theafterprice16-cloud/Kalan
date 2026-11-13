import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/form_fields.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

Future<void> openAddPlan(WidgetTester tester) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
  expect(find.text('Plan türü'), findsOneWidget);
}

int visibleInputCount(WidgetTester tester) =>
    find.byType(TextFormField).evaluate().length +
    find.byType(DateField).evaluate().length +
    find
        .byWidgetPredicate((w) => w is DropdownButtonFormField)
        .evaluate()
        .length;

void main() {
  testWidgets('templates ask for at most four fields', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedCard(db);
      },
    );
    await openAddPlan(tester);
    final expected = {
      '4 ödemeli plan': 3,
      'Aylık taksit': 4,
      'Kredi kartı taksidi': 4,
    };
    for (final MapEntry(key: label, value: count) in expected.entries) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(visibleInputCount(tester), count, reason: label);
      expect(visibleInputCount(tester), lessThanOrEqualTo(4));
    }
  });

  testWidgets('pay in 4: draft preview, then save to home', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => seedSettings(db, incomeMinor: 5000000),
    );
    await openAddPlan(tester);
    expect(
      find.text('Alanları doldurunca ödemeleri burada görürsün.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const ValueKey('source')), 'Klarna');
    await tester.enterText(find.byKey(const ValueKey('total')), '400,01');
    await tester.pumpAndSettle();
    expect(find.text('4 ödeme, toplam ₺400,01.'), findsOneWidget);
    expect(find.text('₺100,01'), findsOneWidget);
    expect(find.text('1 Oca 2027'), findsOneWidget);

    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Plan eklendi.'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    final plan = await db.select(db.plans).getSingle();
    expect(plan.kind, PlanKind.payIn4);
    expect(plan.origin, PlanOrigin.template);
    final source = await db.select(db.sources).getSingle();
    expect(source.name, 'Klarna');
    expect(source.kind, SourceKind.provider);
  });

  testWidgets('card installments land on the statement due date', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedCard(db);
      },
    );
    await openAddPlan(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kredi kartı taksidi'));
    await tester.pumpAndSettle();
    await pickDropdown(tester, const ValueKey('card'), 'Bonus');
    await tester.enterText(find.byKey(const ValueKey('total')), '3000');
    await tester.enterText(find.byKey(const ValueKey('count')), '3');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('5 Şub 2027'));
    // Purchase on 20 Nov, statement 25 Nov, due 5 Dec (Saturday) -> 7 Dec.
    expect(find.text('7 Ara 2026'), findsOneWidget);
    expect(find.text('5 Oca 2027'), findsOneWidget);
    expect(find.text('5 Şub 2027'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();
    final plan = await db.select(db.plans).getSingle();
    expect(plan.kind, PlanKind.card);
    expect(plan.purchaseDay, testToday.epochDay);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('empty form explains what is missing', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openAddPlan(tester);
    await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
    await tester.tap(find.byKey(const ValueKey('save-plan')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bir ad yaz.'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bir ad yaz.'), findsOneWidget);
    expect(find.text('Bu alan gerekli.'), findsOneWidget);
    expect(await db.select(db.plans).get(), isEmpty);
  });

  testWidgets('free tier stops at four open plans; debug Pro lifts it', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        for (final name in ['A', 'B', 'C', 'D']) {
          await seedPayIn4(db, source: name);
        }
        await seedRent(db);
      },
    );
    await tester.tap(find.text('Plan ekle'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ücretsiz sürümde en çok 4 açık plan olur. '
        'Bir plan bitince yenisini ekleyebilirsin.',
      ),
      findsOneWidget,
    );
    expect(find.text('Plan türü'), findsNothing);

    await db
        .update(db.appSettings)
        .write(const AppSettingsCompanion(debugPro: Value(true)));
    await tester.pumpAndSettle();
    expect(find.text('Plan türü'), findsOneWidget);
  });
}
