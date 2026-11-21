import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// Product price (23) on screen. Putri's phone: IDR, 12 × Rp580.000,
/// price Rp6.000.000; today 15 Nov 2026.
final idr = Currency.fromCode('IDR');
final tryC = Currency.fromCode('TRY');
String rp(int minor) => formatMoney(minor, idr, localeName: 'tr');
String tl(int minor) => formatMoney(minor, tryC, localeName: 'tr');
final today = LocalDate(2026, 11, 15);

Future<int> seedPutri(
  AppDatabase db, {
  int? price,
  int? fee,
  PlanKind kind = PlanKind.monthly,
  String currency = 'IDR',
}) async {
  await seedSettings(db, currency: currency, payDay: 25);
  final plans = PlanRepository(db);
  final draft = PlanCalculator.monthly(
    firstDate: LocalDate(2026, 12, 10),
    totalMinor: 6960000,
    count: 12,
  );
  final sources = SourceRepository(db, plans);
  return plans.saveDraft(
    kind == PlanKind.monthly
        ? draft
              .withInstallmentFee(fee, InstallmentFeeScope.everyPayment)
              .withProductPrice(price)
        : PlanDraft(
            kind: kind,
            installmentCount: 12,
            payments: draft.payments,
          ).withProductPrice(price),
    sourceId: kind == PlanKind.card
        ? await sources.create(
            name: 'Maximum',
            kind: SourceKind.card,
            statementDay: 1,
            dueDay: 10,
          )
        : await sources.findOrCreateProvider('Kredivo'),
    origin: PlanOrigin.template,
    title: 'Telefon',
  );
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

Future<void> openPlan(WidgetTester tester, [String name = 'Telefon']) async {
  await openTab(tester, 'Planlar');
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> typePrice(WidgetTester tester, String text) async {
  final field = find.byKey(const ValueKey('product-price'));
  await scrollTo(tester, field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// A tall phone, so a plan's rows are all built.
Future<AppDatabase> pumpTall(
  WidgetTester tester, {
  required Future<void> Function(AppDatabase db) seed,
  Locale locale = const Locale('tr', 'TR'),
}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return pumpApp(tester, today: today, seed: seed, locale: locale);
}

void expectRow(String key, String amount) => expect(
  find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(amount)),
  findsOneWidget,
);

void expectNoPriceRows() {
  expect(find.byKey(const ValueKey('price-summary-price')), findsNothing);
  expect(find.byKey(const ValueKey('price-summary-difference')), findsNothing);
}

void main() {
  testWidgets('the field is only under "More details", on the right kinds', (
    tester,
  ) async {
    await pumpTall(tester, seed: (db) => seedSettings(db, currency: 'IDR'));
    await openAdd(tester, 'Aylık taksit');
    // Closed by default: the form keeps its fields.
    expect(find.byKey(const ValueKey('product-price')), findsNothing);
    await tapKey(tester, 'more-details');
    for (final (kind, shown) in [
      ('Aylık taksit', true),
      ('Kredi kartı taksidi', true),
      ('Elle giriş', true),
      ('4 ödemeli plan', false),
      ('Sonra öde', false),
    ]) {
      final chip = find.widgetWithText(ChoiceChip, kind);
      await scrollTo(tester, chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('more-details')),
        findsOneWidget,
        reason: kind,
      );
      expect(
        find.byKey(const ValueKey('product-price'), skipOffstage: false),
        shown ? findsOneWidget : findsNothing,
        reason: kind,
      );
    }
    await tester.tap(find.widgetWithText(ChoiceChip, 'Aylık taksit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Peşin alsaydın ödeyeceğin fiyat.', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('example 1: "Installment" entry, preview, saved, detail', (
    tester,
  ) async {
    final db = await pumpTall(
      tester,
      seed: (db) => seedSettings(db, currency: 'IDR'),
    );
    await openAdd(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Kredivo');
    final segment = find.descendant(
      of: find.byKey(const ValueKey('amount-entry')),
      matching: find.text('Taksit'),
    );
    await tester.ensureVisible(segment);
    await tester.pumpAndSettle();
    await tester.tap(segment);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('installment')), '580000');
    await tester.enterText(find.byKey(const ValueKey('count')), '12');
    await tester.pumpAndSettle();
    // Not entered: no summary rows.
    expect(find.byKey(const ValueKey('preview-fee-summary')), findsNothing);
    await tapKey(tester, 'more-details');
    await typePrice(tester, '6000000');
    await scrollTo(tester, find.byKey(const ValueKey('preview-fee-summary')));
    expectRow('fee-summary-total', rp(6960000));
    expectRow('price-summary-price', rp(6000000));
    expectRow('price-summary-difference', rp(960000));
    expect(find.text('Toplam geri ödeme'), findsOneWidget);
    expect(find.text('Fark'), findsOneWidget);
    // No fee: no plan amount and fee rows.
    expect(find.byKey(const ValueKey('fee-summary-plan')), findsNothing);
    await tapKey(tester, 'save-plan');
    final plan = await db.select(db.plans).getSingle();
    expect(plan.productPriceMinor, 6000000);
    final payments = await db.select(db.payments).get();
    expect(payments.map((p) => p.amountMinor), everyElement(580000));

    await openPlan(tester, 'Kredivo');
    expectRow('fee-summary-total', rp(6960000));
    expectRow('price-summary-difference', rp(960000));
    // One total: the plain "Total" line is gone.
    expect(find.text('Toplam ${rp(6960000)}'), findsNothing);
    expect(find.byKey(const ValueKey('fee-summary-total')), findsOneWidget);
  });

  testWidgets('example 3: "Total" entry in TRY', (tester) async {
    await pumpTall(tester, seed: (db) => seedSettings(db));
    await openAdd(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Banka');
    await tester.enterText(find.byKey(const ValueKey('total')), '12000');
    await tester.enterText(find.byKey(const ValueKey('count')), '12');
    await tester.pumpAndSettle();
    await tapKey(tester, 'more-details');
    await typePrice(tester, '10500');
    await scrollTo(tester, find.byKey(const ValueKey('preview-fee-summary')));
    expectRow('fee-summary-total', tl(1200000));
    expectRow('price-summary-difference', tl(150000));
  });

  testWidgets('examples 4 and 5: equal or above, saved without a word', (
    tester,
  ) async {
    final db = await pumpTall(
      tester,
      seed: (db) => seedSettings(db, currency: 'IDR'),
    );
    await openAdd(tester, 'Aylık taksit');
    await tester.enterText(find.byKey(const ValueKey('source')), 'Kredivo');
    await tester.enterText(find.byKey(const ValueKey('total')), '6960000');
    await tester.enterText(find.byKey(const ValueKey('count')), '12');
    await tester.pumpAndSettle();
    await tapKey(tester, 'more-details');
    await typePrice(tester, '6960000');
    expect(find.byKey(const ValueKey('preview-fee-summary')), findsNothing);
    await typePrice(tester, '7000000');
    expect(find.byKey(const ValueKey('preview-fee-summary')), findsNothing);
    await tapKey(tester, 'save-plan');
    expect((await db.select(db.plans).getSingle()).productPriceMinor, 7000000);
    await openPlan(tester, 'Kredivo');
    expectNoPriceRows();
    expect(find.byKey(const ValueKey('plan-fee-summary')), findsNothing);
    expect(find.text('Toplam ${rp(6960000)}'), findsOneWidget);
  });

  testWidgets('added later on the edit screen, then cleared', (tester) async {
    final db = await pumpTall(tester, seed: seedPutri);
    await openPlan(tester);
    expect(find.byKey(const ValueKey('plan-fee-summary')), findsNothing);
    await tapKey(tester, 'plan-edit');
    // No price: the section is closed.
    expect(find.byKey(const ValueKey('product-price')), findsNothing);
    await tapKey(tester, 'more-options');
    await typePrice(tester, '6000000');
    await tapKey(tester, 'save-plan-edit');
    expect((await db.select(db.plans).getSingle()).productPriceMinor, 6000000);
    expectRow('price-summary-difference', rp(960000));

    await tapKey(tester, 'plan-edit');
    // With a price: the section is open, the price filled in.
    expect(find.byKey(const ValueKey('product-price')), findsOneWidget);
    await typePrice(tester, '');
    await tapKey(tester, 'save-plan-edit');
    expect((await db.select(db.plans).getSingle()).productPriceMinor, isNull);
    expectNoPriceRows();
  });

  testWidgets('card edit: "More options" has the price, no fee', (
    tester,
  ) async {
    await pumpTall(
      tester,
      seed: (db) => seedPutri(db, kind: PlanKind.card, price: 6000000),
    );
    await openPlan(tester);
    expectRow('price-summary-difference', rp(960000));
    await tapKey(tester, 'plan-edit');
    expect(find.byKey(const ValueKey('product-price')), findsOneWidget);
    expect(find.byKey(const ValueKey('installment-fee')), findsNothing);
  });

  testWidgets('a fee per payment and a price: one "Total you repay"', (
    tester,
  ) async {
    // 12 × Rp580.000 with a Rp10.000 fee per payment.
    await pumpTall(
      tester,
      seed: (db) => seedPutri(db, price: 6000000, fee: 10000),
    );
    await openPlan(tester);
    expectRow('fee-summary-plan', rp(6960000));
    expectRow('fee-summary-fees', rp(120000));
    expectRow('fee-summary-total', rp(7080000));
    expectRow('price-summary-difference', rp(1080000));
    expect(find.text('Toplam geri ödeme'), findsOneWidget);
    expect(find.text('Toplam'), findsNothing);
  });

  testWidgets('on hold (19): no price rows', (tester) async {
    await pumpTall(
      tester,
      seed: (db) async {
        final id = await seedPutri(db, price: 6000000);
        await PlanRepository(db).hold(id, today: today);
      },
    );
    await openPlan(tester);
    expectNoPriceRows();
    expect(find.text('Toplam ${rp(6960000)}'), findsOneWidget);
  });

  testWidgets('English labels', (tester) async {
    await pumpTall(
      tester,
      locale: const Locale('en', 'US'),
      seed: (db) => seedPutri(db, price: 6000000),
    );
    await openTab(tester, 'Plans');
    await tester.tap(find.text('Telefon'));
    await tester.pumpAndSettle();
    expect(find.text('Total you repay'), findsOneWidget);
    expect(find.text('Product price'), findsOneWidget);
    expect(find.text('Difference'), findsOneWidget);
  });
}
