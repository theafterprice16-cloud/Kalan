import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

Future<void> openAddPlan(WidgetTester tester) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
}

Future<void> chooseMode(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pumpAndSettle();
}

Finder segment(String label) => find.descendant(
  of: find.byKey(const ValueKey('amount-entry')),
  matching: find.text(label),
);

Future<void> chooseEntry(WidgetTester tester, String label) async {
  await tester.ensureVisible(segment(label));
  await tester.pumpAndSettle();
  await tester.tap(segment(label));
  await tester.pumpAndSettle();
}

Future<void> type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await scrollTo(tester, f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> scrollUp(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tapKey(tester, 'save-plan');
}

AmountEntry selectedEntry(WidgetTester tester) => tester
    .widget<SegmentedButton<AmountEntry>>(
      find.byKey(const ValueKey('amount-entry')),
    )
    .selected
    .single;

String computedLine(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('amount-computed'))).data!;

String fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

Future<List<PaymentRow>> paymentsOf(AppDatabase db) =>
    (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();

Future<AppDatabase> pump(WidgetTester tester, {String currency = 'TRY'}) =>
    pumpApp(
      tester,
      seed: (db) => seedSettings(db, incomeMinor: 5000000, currency: currency),
    );

void main() {
  testWidgets('first time: the total, the installment worked out', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    expect(selectedEntry(tester), AmountEntry.total);
    expect(find.text('Toplam tutar'), findsOneWidget);
    expect(find.byKey(const ValueKey('installment')), findsNothing);
    // Nothing worked out until both values are there.
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);

    await type(tester, 'total', '12000');
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);
    await type(tester, 'count', '6');
    expect(computedLine(tester), 'Taksit ₺2.000 · hesaplandı');

    // Uneven: the first installment carries the leftover kuruş, said so.
    await type(tester, 'total', '1000');
    await type(tester, 'count', '3');
    expect(
      computedLine(tester),
      'İlk taksit ₺333,34, diğer 2 taksit ₺333,33 · hesaplandı',
    );
    await scrollTo(tester, find.byKey(const ValueKey('preview-summary')));
    expect(find.text('3 ödeme, toplam ₺1.000.'), findsOneWidget);
  });

  testWidgets('the worked-out value is muted and the choice is 48 high', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'total', '12000');
    await type(tester, 'count', '6');
    final context = tester.element(find.byKey(const ValueKey('amount-entry')));
    final line = tester.widget<Text>(
      find.byKey(const ValueKey('amount-computed')),
    );
    expect(line.style?.color, context.colors.textMuted);
    expect(
      tester.getSize(find.byKey(const ValueKey('amount-entry'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('Deniz: 850 TL x 9, total worked out, 9 equal payments', (
    tester,
  ) async {
    final db = await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'source', 'Telefon');
    await chooseEntry(tester, 'Taksit');
    expect(find.text('Taksit tutarı'), findsOneWidget);
    expect(find.byKey(const ValueKey('total')), findsNothing);
    await type(tester, 'installment', '850');
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);
    await type(tester, 'count', '9');
    expect(computedLine(tester), 'Toplam ₺7.650 · hesaplandı');
    await scrollTo(tester, find.byKey(const ValueKey('preview-summary')));
    expect(find.text('9 ödeme, toplam ₺7.650.'), findsOneWidget);

    await save(tester);
    final rows = await paymentsOf(db);
    expect(rows, hasLength(9));
    expect(rows.map((r) => r.amountMinor), everyElement(85000));
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.lastAmountEntry, AmountEntry.installment);

    // Next time the form opens with the installment.
    await openAddPlan(tester);
    await chooseMode(tester, 'Kredi kartı taksidi');
    expect(selectedEntry(tester), AmountEntry.installment);
    expect(find.byKey(const ValueKey('installment')), findsOneWidget);
  });

  testWidgets('saving with the total remembers the total', (tester) async {
    final db = await pump(tester);
    await db
        .update(db.appSettings)
        .write(
          const AppSettingsCompanion(
            lastAmountEntry: Value(AmountEntry.installment),
          ),
        );
    await openAddPlan(tester);
    expect(selectedEntry(tester), AmountEntry.installment);
    await type(tester, 'source', 'Klarna');
    await chooseEntry(tester, 'Toplam');
    await type(tester, 'total', '400');
    await save(tester);
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.lastAmountEntry, AmountEntry.total);
  });

  testWidgets('switching keeps the count and carries the amount', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'total', '12000');
    await type(tester, 'count', '6');
    await chooseEntry(tester, 'Taksit');
    expect(fieldText(tester, 'installment'), '2000');
    expect(fieldText(tester, 'count'), '6');
    expect(computedLine(tester), 'Toplam ₺12.000 · hesaplandı');

    await type(tester, 'installment', '850');
    await type(tester, 'count', '9');
    await chooseEntry(tester, 'Toplam');
    expect(fieldText(tester, 'total'), '7650');
    expect(fieldText(tester, 'count'), '9');
    expect(computedLine(tester), 'Taksit ₺850 · hesaplandı');

    // An uneven total: the equal share, rounded down, and the new total.
    await type(tester, 'total', '1000');
    await type(tester, 'count', '3');
    await chooseEntry(tester, 'Taksit');
    expect(fieldText(tester, 'installment'), '333,33');
    expect(computedLine(tester), 'Toplam ₺999,99 · hesaplandı');

    // Nothing to work out without a count: what was typed stays.
    await type(tester, 'count', '');
    await chooseEntry(tester, 'Toplam');
    expect(fieldText(tester, 'total'), '1000');
    expect(fieldText(tester, 'count'), '');
  });

  testWidgets('only looking at the other amount changes nothing', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'total', '1000');
    await type(tester, 'count', '3');
    await chooseEntry(tester, 'Taksit');
    expect(fieldText(tester, 'installment'), '333,33');
    await chooseEntry(tester, 'Toplam');
    expect(fieldText(tester, 'total'), '1000');
    expect(
      computedLine(tester),
      'İlk taksit ₺333,34, diğer 2 taksit ₺333,33 · hesaplandı',
    );

    // Without a count, both fields keep what was typed.
    await type(tester, 'count', '');
    await chooseEntry(tester, 'Taksit');
    await chooseEntry(tester, 'Toplam');
    expect(fieldText(tester, 'total'), '1000');

    // A changed count is worked out again on the way back.
    await type(tester, 'count', '3');
    await chooseEntry(tester, 'Taksit');
    await type(tester, 'count', '4');
    await chooseEntry(tester, 'Toplam');
    expect(fieldText(tester, 'total'), '1333,32');
  });

  testWidgets('one payment: nothing to work out', (tester) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'total', '500');
    await type(tester, 'count', '1');
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);
  });

  testWidgets('Pay in 4: only the installment, always 4', (tester) async {
    final db = await pump(tester);
    await openAddPlan(tester);
    await type(tester, 'source', 'Klarna');
    await chooseEntry(tester, 'Taksit');
    expect(find.byKey(const ValueKey('count')), findsNothing);
    await type(tester, 'installment', '375');
    expect(computedLine(tester), 'Toplam ₺1.500 · hesaplandı');
    await save(tester);
    final rows = await paymentsOf(db);
    expect(rows, hasLength(4));
    expect(rows.map((r) => r.amountMinor), everyElement(37500));
    final plan = await db.select(db.plans).getSingle();
    expect(plan.kind, PlanKind.payIn4);
  });

  testWidgets('already underway: the count is the total installments', (
    tester,
  ) async {
    final db = await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'source', 'Telefon');
    await chooseEntry(tester, 'Taksit');
    await type(tester, 'installment', '850');
    await type(tester, 'count', '10');
    await tapKey(tester, 'underway');
    await scrollUp(tester, find.byKey(const ValueKey('count')));
    expect(find.text('Toplam taksit'), findsOneWidget);
    await type(tester, 'paid-count', '3');
    await scrollUp(tester, find.byKey(const ValueKey('amount-computed')));
    expect(computedLine(tester), 'Toplam ₺8.500 · hesaplandı');
    await save(tester);
    final rows = await paymentsOf(db);
    expect(rows, hasLength(10));
    expect(rows.map((r) => r.amountMinor), everyElement(85000));
    expect(rows.where((r) => r.paidBeforeKalan), hasLength(3));
  });

  testWidgets('manual entry with an installment', (tester) async {
    final db = await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Elle giriş');
    await type(tester, 'source', 'Mağaza');
    await chooseEntry(tester, 'Taksit');
    await type(tester, 'installment', '120,50');
    await type(tester, 'count', '5');
    expect(computedLine(tester), 'Toplam ₺602,50 · hesaplandı');
    await save(tester);
    final rows = await paymentsOf(db);
    expect(rows.map((r) => r.amountMinor), everyElement(12050));
    expect(rows, hasLength(5));
  });

  testWidgets('a total too large to keep is refused', (tester) async {
    final db = await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'source', 'Telefon');
    await chooseEntry(tester, 'Taksit');
    // 14 digits in total: more than the total field takes.
    await type(tester, 'installment', '9000000000000');
    await type(tester, 'count', '9');
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);
    await save(tester);
    await scrollUp(tester, find.byKey(const ValueKey('installment')));
    expect(
      find.text(
        'Toplam çok büyük oluyor. Taksiti ya da taksit sayısını küçült.',
      ),
      findsOneWidget,
    );
    expect(await db.select(db.plans).get(), isEmpty);
  });

  testWidgets('an amount with too many digits is called too large', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'total', '12345678901234');
    await type(tester, 'count', '3');
    await save(tester);
    await scrollUp(tester, find.byKey(const ValueKey('total')));
    expect(find.text('Bu tutar çok büyük.'), findsOneWidget);
    // A badly written amount still gets the example.
    await type(tester, 'total', '12.34.5');
    await save(tester);
    await scrollUp(tester, find.byKey(const ValueKey('total')));
    expect(find.text('Tutarı rakamla yaz, örneğin 1250,50.'), findsOneWidget);
  });

  testWidgets('switching while typing keeps the keyboard on the amount', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Aylık taksit');
    await type(tester, 'count', '6');
    await tester.tap(find.byKey(const ValueKey('total')));
    await tester.enterText(find.byKey(const ValueKey('total')), '12000');
    await tester.pumpAndSettle();
    bool focused(String key) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode
        .hasFocus;
    expect(focused('total'), isTrue);
    await tester.tap(segment('Taksit'));
    await tester.pumpAndSettle();
    expect(focused('installment'), isTrue);
    await tester.tap(segment('Toplam'));
    await tester.pumpAndSettle();
    expect(focused('total'), isTrue);
  });

  testWidgets('"Pay later" has no choice: one payment, as before', (
    tester,
  ) async {
    await pump(tester);
    await openAddPlan(tester);
    await chooseMode(tester, 'Sonra öde');
    expect(find.byKey(const ValueKey('amount-entry')), findsNothing);
    expect(find.byKey(const ValueKey('amount-computed')), findsNothing);
  });

  for (final (code, total, first, others) in [
    ('JPY', '10000', 3334, 3333),
    ('KWD', '10', 3334, 3333),
  ]) {
    testWidgets('$code: the leftover is in whole minor units', (tester) async {
      await pump(tester, currency: code);
      await openAddPlan(tester);
      await chooseMode(tester, 'Aylık taksit');
      await type(tester, 'total', total);
      await type(tester, 'count', '3');
      final currency = Currency.fromCode(code);
      String money(int minor) => formatMoney(minor, currency, localeName: 'tr');
      expect(
        computedLine(tester),
        'İlk taksit ${money(first)}, diğer 2 taksit ${money(others)} '
        '· hesaplandı',
      );
    });
  }
}
