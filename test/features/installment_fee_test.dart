import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// Fee per payment (22) on screen. JPY, payday 25, income 100.000 ¥,
/// today 15 Nov 2026; Kenji's 10.000 ¥ in 4 × 2.500 ¥ from 10 Dec.
final jpy = Currency.fromCode('JPY');
String tr(int minor) => formatMoney(minor, jpy, localeName: 'tr');
final today = LocalDate(2026, 11, 15);

Future<int> seedKenji(
  AppDatabase db, {
  int? fee,
  InstallmentFeeScope scope = InstallmentFeeScope.everyPayment,
  bool firstPaid = false,
}) async {
  await seedSettings(db, currency: 'JPY', payDay: 25, incomeMinor: 100000);
  final plans = PlanRepository(db);
  final id = await plans.saveDraft(
    PlanCalculator.monthly(
      firstDate: LocalDate(2026, 12, 10),
      totalMinor: 10000,
      count: 4,
    ),
    sourceId: await SourceRepository(db, plans).findOrCreateProvider('Paidy'),
    origin: PlanOrigin.template,
    title: 'Kenji',
  );
  if (firstPaid) {
    final first = await (db.select(
      db.payments,
    )..where((p) => p.seq.equals(1))).getSingle();
    await plans.setPaid(first.id, paid: true);
  }
  if (fee != null) {
    await plans.editPlan(
      id,
      count: 4,
      paidBefore: 0,
      installmentFee: (feeMinor: fee, scope: scope),
    );
  }
  return id;
}

Future<List<PaymentRow>> rows(AppDatabase db) =>
    (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

Future<void> openKenji(WidgetTester tester) async {
  await openTab(tester, 'Planlar');
  await tester.tap(find.text('Kenji'));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await scrollTo(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openAdd(WidgetTester tester, String kind) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, kind));
  await tester.pumpAndSettle();
}

/// A tall phone, so a plan's rows are all built.
Future<AppDatabase> pumpTall(
  WidgetTester tester, {
  required LocalDate today,
  required Future<void> Function(AppDatabase db) seed,
}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return pumpApp(tester, today: today, seed: seed);
}

void main() {
  testWidgets('the add form looks the same until "More details" opens', (
    tester,
  ) async {
    await pumpTall(tester, today: today, seed: seedKenji);
    await openAdd(tester, 'Aylık taksit');
    expect(find.byKey(const ValueKey('installment-fee')), findsNothing);
    await tapKey(tester, 'more-details');
    expect(find.byKey(const ValueKey('installment-fee')), findsOneWidget);
    // No fee yet: no scope choice.
    expect(find.byKey(const ValueKey('installment-fee-scope')), findsNothing);
  });

  testWidgets('card installments have no fee field', (tester) async {
    await pumpTall(tester, today: today, seed: seedKenji);
    await openAdd(tester, 'Kredi kartı taksidi');
    await tapKey(tester, 'more-details');
    expect(find.byKey(const ValueKey('installment-fee')), findsNothing);
  });

  testWidgets('pay later: the fee without a scope choice', (tester) async {
    await pumpTall(tester, today: today, seed: seedKenji);
    await openAdd(tester, 'Sonra öde');
    await tapKey(tester, 'more-details');
    final field = find.byKey(const ValueKey('installment-fee'));
    await scrollTo(tester, field);
    await tester.enterText(field, '150');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('installment-fee-scope')), findsNothing);
  });

  testWidgets('example 1: the preview with the fee, then the saved plan', (
    tester,
  ) async {
    final db = await pumpTall(
      tester,
      today: today,
      seed: (db) => seedSettings(db, currency: 'JPY', payDay: 25),
    );
    await openAdd(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Paidy');
    await tester.enterText(find.byKey(const ValueKey('total')), '10000');
    await tester.enterText(find.byKey(const ValueKey('count')), '4');
    await tapKey(tester, 'more-details');
    final field = find.byKey(const ValueKey('installment-fee'));
    await scrollTo(tester, field);
    await tester.enterText(field, '390');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('installment-fee-scope')), findsOneWidget);
    final summary = find.byKey(const ValueKey('preview-fee-summary'));
    await scrollTo(tester, summary);
    for (final (key, amount) in [
      ('fee-summary-plan', 10000),
      ('fee-summary-fees', 1560),
      ('fee-summary-total', 11560),
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.text(tr(amount)),
        ),
        findsOneWidget,
      );
    }
    expect(find.text(tr(2890)), findsNWidgets(4));
    expect(find.text('${tr(390)} taksit ücreti dahil'), findsNWidgets(4));
    await tapKey(tester, 'save-plan');
    final saved = await rows(db);
    expect(saved.map((p) => p.amountMinor), everyElement(2500));
    expect(saved.map((p) => p.installmentFeeMinor), everyElement(390));
  });

  testWidgets('a zero fee is no fee', (tester) async {
    final db = await pumpTall(
      tester,
      today: today,
      seed: (db) => seedSettings(db, currency: 'JPY', payDay: 25),
    );
    await openAdd(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Paidy');
    await tester.enterText(find.byKey(const ValueKey('total')), '10000');
    await tester.enterText(find.byKey(const ValueKey('count')), '4');
    await tapKey(tester, 'more-details');
    final field = find.byKey(const ValueKey('installment-fee'));
    await scrollTo(tester, field);
    await tester.enterText(field, '0');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-fee-summary')), findsNothing);
    await tapKey(tester, 'save-plan');
    final plan = await db.select(db.plans).getSingle();
    expect(plan.installmentFeeMinor, isNull);
    expect(
      (await rows(db)).map((p) => p.installmentFeeMinor),
      everyElement(equals(null)),
    );
  });

  testWidgets('example 3: plan detail rows and summary', (tester) async {
    await pumpTall(
      tester,
      today: today,
      seed: (db) => seedKenji(db, fee: 390, firstPaid: true),
    );
    await openKenji(tester);
    expect(find.byKey(const ValueKey('plan-fee-summary')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('fee-summary-fees')),
        matching: find.text(tr(1170)),
      ),
      findsOneWidget,
    );
    // The paid payment keeps 2.500 ¥; the others show 2.890 ¥.
    expect(find.text(tr(2500)), findsOneWidget);
    expect(find.text(tr(2890)), findsNWidgets(3));
    expect(find.text('${tr(390)} taksit ücreti dahil'), findsNWidgets(3));
    // To pay includes the fees.
    expect(find.text('Ödenecek ${tr(8670)}'), findsOneWidget);
  });

  testWidgets('example 3: added later on the edit screen', (tester) async {
    final db = await pumpTall(
      tester,
      today: today,
      seed: (db) => seedKenji(db, firstPaid: true),
    );
    await openKenji(tester);
    await tapKey(tester, 'plan-edit');
    // No fee: the section is closed.
    expect(find.byKey(const ValueKey('installment-fee')), findsNothing);
    await tapKey(tester, 'more-options');
    final field = find.byKey(const ValueKey('installment-fee'));
    await scrollTo(tester, field);
    await tester.enterText(field, '390');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu değişiklik ödenmemiş 3 taksiti etkiler.'),
      findsOneWidget,
    );
    await tapKey(tester, 'save-plan-edit');
    expect((await rows(db)).map((p) => p.installmentFeeMinor), [
      null,
      390,
      390,
      390,
    ]);
    expect((await rows(db)).first.amountMinor, 2500);
  });

  testWidgets('example 4: first only, first paid, said calmly', (tester) async {
    await pumpTall(
      tester,
      today: today,
      seed: (db) => seedKenji(
        db,
        fee: 390,
        scope: InstallmentFeeScope.firstPaymentOnly,
        firstPaid: true,
      ),
    );
    await openKenji(tester);
    await tapKey(tester, 'plan-edit');
    // A plan with a fee opens with the section open.
    expect(find.byKey(const ValueKey('installment-fee')), findsOneWidget);
    expect(
      find.text('İlk taksit ödendiği için ücret hiçbir taksite eklenmez.'),
      findsOneWidget,
    );
  });

  testWidgets('example 5: removing the fee keeps the paid one', (tester) async {
    final db = await pumpTall(
      tester,
      today: today,
      seed: (db) async {
        await seedKenji(db, fee: 390);
        final first = await (db.select(
          db.payments,
        )..where((p) => p.seq.equals(1))).getSingle();
        await PlanRepository(db).setPaid(first.id, paid: true);
      },
    );
    await openKenji(tester);
    await tapKey(tester, 'plan-edit');
    final field = find.byKey(const ValueKey('installment-fee'));
    await scrollTo(tester, field);
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(
      find.text('Bu değişiklik ödenmemiş 3 taksiti etkiler.'),
      findsOneWidget,
    );
    await tapKey(tester, 'save-plan-edit');
    expect((await rows(db)).map((p) => p.installmentFeeMinor), [
      390,
      null,
      null,
      null,
    ]);
  });

  testWidgets('home rows show the installment with its fee', (tester) async {
    await pumpTall(
      tester,
      today: LocalDate(2026, 12, 1),
      seed: (db) => seedKenji(db, fee: 390),
    );
    expect(find.text(tr(2890)), findsWidgets);
    expect(find.text('${tr(390)} taksit ücreti dahil'), findsWidgets);
  });
}
