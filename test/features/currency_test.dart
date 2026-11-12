import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/data/db/app_database.dart';
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
    final db = await pumpApp(tester, locale: const Locale('id', 'ID'));
    expect(find.text('Rp · IDR · Rupiah Indonesia'), findsOneWidget);
    const income = ValueKey('net-income');
    await scrollTo(tester, find.byKey(income));
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(income),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.keyboardType.decimal, isFalse);

    await tester.enterText(find.byKey(income), '5.000.000,5');
    await scrollTo(tester, find.text('Mulai'));
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tulis jumlahnya dengan angka, misalnya 1250.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(income), '5.000.000');
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'IDR');
    expect(s.netIncomeMinor, 5000000);
    expect(find.text('Rp5.000.000'), findsOneWidget);
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

  testWidgets('plain dollar sign at home, distinctive abroad', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('es', 'MX'),
      seed: (db) => seedSettings(db, currency: 'MXN', incomeMinor: 123456),
    );
    expect(find.text('1.234,56 \$'), findsOneWidget);
  });

  group('every app language renders home', () {
    // language, region, currency, left label, formatted 1.234,56 left
    final cases = <(String, String, String, String, String)>[
      ('tr', 'TR', 'TRY', 'Kalan', '₺1.234,56'),
      ('en', 'US', 'USD', 'Left', r'$1,234.56'),
      ('es', 'ES', 'EUR', 'Te queda', '1.234,56 €'),
      ('fr', 'FR', 'EUR', 'Il te reste', '1 234,56 €'),
      ('de', 'DE', 'EUR', 'Übrig', '1.234,56 €'),
      ('pt', 'BR', 'BRL', 'Sobra', 'R\$ 1.234,56'),
      ('ru', 'RU', 'RUB', 'Остаётся', '1 234,56 ₽'),
      ('zh', 'CN', 'CNY', '剩余', '¥1,234.56'),
      ('it', 'IT', 'EUR', 'Ti resta', '1.234,56 €'),
      ('id', 'ID', 'IDR', 'Sisa', 'Rp1.235'),
    ];
    for (final (lang, region, code, label, amount) in cases) {
      testWidgets('$lang $code', (tester) async {
        await pumpApp(
          tester,
          locale: Locale(lang, region),
          seed: (db) => seedSettings(
            db,
            currency: code,
            incomeMinor: code == 'IDR' ? 1235 : 123456,
          ),
        );
        expect(find.text(label), findsOneWidget);
        expect(find.text(amount), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the language picker offers all ten languages', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    for (final code in appLanguageCodes) {
      expect(find.text(nativeLanguageName(code)), findsWidgets, reason: code);
    }
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache'), findsOneWidget);
    expect((await db.select(db.appSettings).getSingle()).localeCode, 'de');
    await db
        .update(db.appSettings)
        .write(const AppSettingsCompanion(localeCode: Value(null)));
  });
}
