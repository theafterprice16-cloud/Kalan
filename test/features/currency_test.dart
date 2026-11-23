import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('picker lists all 75 currencies with symbol, code and name', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    // Below "Privacy" (28): scroll to it.
    await scrollTo(tester, find.text('Para birimi'));
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    // Suggested first: a Turkish phone gets the lira.
    expect(find.text('Önerilen'), findsOneWidget);
    expect(find.byKey(const ValueKey('suggested-TRY')), findsOneWidget);
    expect(find.text('Tüm para birimleri'), findsOneWidget);
    // Walk the whole list once; every currency shows its picker label.
    final seen = <String>{};
    for (var i = 0; i < 80 && seen.length < Currency.all.length; i++) {
      for (final c in Currency.all) {
        final row = find.byKey(ValueKey('currency-${c.code}'));
        if (row.evaluate().isEmpty) continue;
        expect(
          find.descendant(of: row, matching: find.text(c.pickerLabel)),
          findsWidgets, // CHF's symbol is its label too
        );
        // The plain symbol, intact (also right-to-left ones like ر.س).
        expect(
          find.descendant(of: row, matching: find.text(c.symbol)),
          findsWidgets,
        );
        seen.add(c.code);
      }
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(seen, hasLength(75));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 30000));
    await tester.pumpAndSettle();

    Future<void> search(String q) async {
      await tester.enterText(find.byKey(const ValueKey('currency-search')), q);
      await tester.pumpAndSettle();
    }

    // By symbol, by distinctive symbol, by code, by name.
    await search('Rp');
    expect(find.text('Endonezya rupisi'), findsOneWidget);
    await search(r'COL$');
    expect(find.text('Kolombiya pesosu'), findsOneWidget);
    await search('kwd');
    expect(find.text('Kuveyt dinarı'), findsOneWidget);
    await search('sterlin');
    expect(find.text('£ · GBP'), findsOneWidget);
    await search('israil');
    expect(find.text('İsrail şekeli'), findsOneWidget);
    await search('د.ك');
    expect(find.text('Kuveyt dinarı'), findsOneWidget);
    await search('¥');
    expect(find.text('Japon yeni'), findsOneWidget);
    expect(find.text('Çin yuanı'), findsOneWidget);
    await search('xyz');
    expect(find.text('Eşleşen para birimi yok.'), findsOneWidget);
  });

  Future<void> openPicker(WidgetTester tester, Locale locale) async {
    await pumpApp(tester, locale: locale);
    await tester.tap(find.byKey(const ValueKey('currency-field')));
    await tester.pumpAndSettle();
  }

  List<String> suggested(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((t) => (t.key! as ValueKey<String>).value)
      .where((k) => k.startsWith('suggested-'))
      .map((k) => k.substring('suggested-'.length))
      .toList();

  testWidgets('suggestions follow the region', (tester) async {
    await openPicker(tester, const Locale('es', 'MX'));
    expect(suggested(tester), ['MXN']);
  });

  testWidgets('Panama suggests the balboa and the dollar', (tester) async {
    await openPicker(tester, const Locale('es', 'PA'));
    expect(suggested(tester), ['PAB', 'USD']);
  });

  testWidgets('without a known region, the language decides', (tester) async {
    await openPicker(tester, const Locale('tr'));
    expect(suggested(tester), ['TRY']);
  });

  testWidgets('setup suggests by region; rupiah takes no decimals', (
    tester,
  ) async {
    // An Indonesian phone: the app opens in English, the currency is IDR.
    final db = await pumpApp(tester, locale: const Locale('id', 'ID'));
    expect(find.text('Rp · IDR · Indonesian rupiah'), findsOneWidget);
    const income = ValueKey('net-income');
    await scrollTo(tester, find.byKey(income));
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(income),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.keyboardType.decimal, isFalse);

    // A decimal separator never gets in.
    await tester.enterText(find.byKey(income), '5,000,000.5');
    expect(find.text('5,000,000.5'), findsNothing);

    await tester.enterText(find.byKey(income), '5,000,000');
    await scrollTo(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'IDR');
    expect(s.netIncomeMinor, 5000000);
    expect(find.text('Rp5,000,000'), findsOneWidget);
  });

  testWidgets('a three-digit dinar is entered, stored and shown', (
    tester,
  ) async {
    final db = await pumpApp(tester, locale: const Locale('en', 'KW'));
    expect(find.text('KWD · Kuwaiti dinar'), findsOneWidget);
    const income = ValueKey('net-income');
    await scrollTo(tester, find.byKey(income));
    await tester.enterText(find.byKey(income), '1,250.5005');
    expect(find.text('1,250.5005'), findsNothing); // four digits stay out
    await tester.enterText(find.byKey(income), '1,250.500');
    expect(find.text('1,250.500'), findsOneWidget);
    await scrollTo(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'KWD');
    expect(s.netIncomeMinor, 1250500);
    expect(find.textContaining('1,250.500'), findsWidgets);
  });

  testWidgets('a yen amount has no decimal key', (tester) async {
    await pumpApp(tester, locale: const Locale('en', 'JP'));
    expect(find.text('JP¥ · JPY · Japanese yen'), findsOneWidget);
    const income = ValueKey('net-income');
    await scrollTo(tester, find.byKey(income));
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(income),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.keyboardType.decimal, isFalse);
    await tester.enterText(find.byKey(income), '12500.5');
    expect(find.text('12500.5'), findsNothing);
  });

  testWidgets('a currency picked during setup is saved', (tester) async {
    final db = await pumpApp(tester, locale: const Locale('en', 'US'));
    expect(find.text(r'US$ · USD · US dollar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('currency-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'mex',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-MXN')));
    await tester.pumpAndSettle();
    // Fields name the currency with its distinctive symbol and code.
    expect(find.text(r'MX$ · MXN · Mexican peso'), findsOneWidget);
    await scrollTo(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect((await db.select(db.appSettings).getSingle()).currencyCode, 'MXN');
  });

  testWidgets('a Mexican phone: English app, plain dollar sign', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('es', 'MX'),
      seed: (db) => seedSettings(db, currency: 'MXN', incomeMinor: 123456),
    );
    expect(find.text('Left'), findsOneWidget);
    expect(find.text(r'$1,234.56'), findsOneWidget);
  });

  testWidgets('a German phone: English app, euro in English format', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('de', 'DE'),
      seed: (db) => seedSettings(db, currency: 'EUR', incomeMinor: 123456),
    );
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('€1,234.56'), findsOneWidget);
  });

  testWidgets('the language picker offers only Turkish and English', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Dil'));
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    final options = find.descendant(
      of: find.byType(SimpleDialog),
      matching: find.byType(ListTile),
    );
    expect(options, findsNWidgets(3)); // System, Türkçe, English
    expect(find.text('Deutsch'), findsNothing);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect((await db.select(db.appSettings).getSingle()).localeCode, 'en');
  });
}
