import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('picker lists all 17 currencies with symbol, code and name', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    for (final c in Currency.all) {
      final row = find.byKey(ValueKey('currency-${c.code}'));
      await tester.scrollUntilVisible(
        row,
        64,
        scrollable: find.byType(Scrollable).last,
      );
      // CHF's symbol is its code, so it may appear twice.
      expect(
        find.descendant(of: row, matching: find.text(c.code)),
        findsWidgets,
      );
    }
    // Searching by symbol and by localized name.
    await tester.enterText(find.byKey(const ValueKey('currency-search')), 'Rp');
    await tester.pumpAndSettle();
    expect(find.text('Endonezya rupisi'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'sterlin',
    );
    await tester.pumpAndSettle();
    expect(find.text('GBP'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'xyz',
    );
    await tester.pumpAndSettle();
    expect(find.text('Eşleşen para birimi yok.'), findsOneWidget);
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

    await tester.enterText(find.byKey(income), '5,000,000.5');
    await scrollTo(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter the amount in numbers, like 1250.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(income), '5,000,000');
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'IDR');
    expect(s.netIncomeMinor, 5000000);
    expect(find.text('Rp5,000,000'), findsOneWidget);
  });

  testWidgets('a currency picked during setup is saved', (tester) async {
    final db = await pumpApp(tester, locale: const Locale('en', 'US'));
    expect(find.text(r'$ · USD · US dollar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('currency-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'mex',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-MXN')));
    await tester.pumpAndSettle();
    // Outside Mexico the peso shows its distinctive symbol.
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
