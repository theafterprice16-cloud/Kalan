import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

const _income = ValueKey('net-income');

void main() {
  testWidgets('first launch shows setup; saving lands on home', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Bir dakikada kuralım.'), findsOneWidget);
    // Currency defaults to lira on a Turkish device.
    final lira = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Türk lirası (TL)'),
    );
    expect(lira.selected, isTrue);

    await scrollTo(tester, find.byKey(_income));
    await tester.enterText(find.byKey(_income), '50.000');
    await scrollTo(tester, find.text('Başla'));
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(find.text('Kalan'), findsWidgets);
    expect(find.text('50.000 TL'), findsWidgets);
    expect(find.text('Bu dönem ödeme yok.'), findsOneWidget);

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.currencyCode, 'TRY');
    expect(settings.payFrequency, PayFrequency.monthly);
    expect(settings.payDay, 1);
    expect(settings.netIncomeMinor, 5000000);
  });

  testWidgets('income is optional and validated', (tester) async {
    final db = await pumpApp(tester);
    await scrollTo(tester, find.byKey(_income));
    await tester.enterText(find.byKey(_income), 'abc');
    await scrollTo(tester, find.text('Başla'));
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Tutarı rakamla yaz, örneğin 1250,50.'), findsOneWidget);
    expect(await db.select(db.appSettings).getSingleOrNull(), isNull);

    await tester.enterText(find.byKey(_income), '');
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Söz verilmiş'), findsWidgets);
  });

  testWidgets('weekly pay stores the most recent payday', (tester) async {
    final db = await pumpApp(tester, locale: const Locale('en'));
    expect(find.text("Let's set up in a minute."), findsOneWidget);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    // Default weekday is Friday; 20 Nov 2026 is a Friday.
    expect(find.text('Friday'), findsOneWidget);
    await scrollTo(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'USD');
    expect(s.payFrequency, PayFrequency.weekly);
    expect(LocalDate.fromEpochDay(s.payAnchorDay!), testToday);
  });
}
