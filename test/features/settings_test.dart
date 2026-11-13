import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('switching the language to English', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Dil'));
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect((await db.select(db.appSettings).getSingle()).localeCode, 'en');
  });

  testWidgets('income and threshold drive the home screen', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedRent(db);
      },
    );
    await openTab(tester, 'Ayarlar');
    expect(find.text('Girilmedi'), findsOneWidget);
    expect(find.text('Kapalı'), findsOneWidget);

    await tester.tap(find.text('Net tutar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-amount')),
      '20000',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('₺20.000'), findsOneWidget);

    await tester.tap(find.text('Sıkışık dönem eşiği'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-amount')),
      '6000',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('₺6.000'), findsOneWidget);

    await openTab(tester, 'Bu dönem');
    expect(find.text('₺5.000'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-tight')), findsOneWidget);

    // Clearing the threshold turns tight periods off.
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Sıkışık dönem eşiği'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('settings-amount')), '');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Kapalı'), findsOneWidget);
  });

  testWidgets('currency changes the label after a preview, not the amounts', (
    tester,
  ) async {
    await pumpApp(tester, seed: (db) => seedSettings(db, incomeMinor: 5000000));
    await openTab(tester, 'Ayarlar');
    expect(find.text('₺ · TRY · Türk lirası'), findsOneWidget);
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'abd',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('currency-EUR')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('currency-USD')));
    await tester.pumpAndSettle();
    expect(
      find.text('Tutarlar çevrilmez, yalnızca para birimi etiketi değişir.'),
      findsOneWidget,
    );
    expect(find.text(r'Örnek: ₺1.234,56 → $1.234,56'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('currency-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(r'US$ · USD · ABD doları'), findsOneWidget);
    await openTab(tester, 'Bu dönem');
    expect(find.text(r'$50.000'), findsOneWidget);
  });

  testWidgets('switching to rupiah rounds amounts to whole rupiah', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 123456);
        await seedPayIn4(db, totalMinor: 40002);
      },
    );
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'IDR',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-IDR')));
    await tester.pumpAndSettle();
    expect(find.text('Örnek: ₺1.234,56 → Rp1.235'), findsOneWidget);
    expect(
      find.text(
        'Bu para biriminin ondalık sayısı farklı, tutarlar yuvarlanır.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('currency-confirm')));
    await tester.pumpAndSettle();
    final s = await db.select(db.appSettings).getSingle();
    expect(s.currencyCode, 'IDR');
    expect(s.netIncomeMinor, 1235);
    final amounts = (await db.select(db.payments).get()).map(
      (p) => p.amountMinor,
    );
    expect(amounts, [100, 100, 100, 100]);
    await openTab(tester, 'Bu dönem');
    expect(find.text('Rp1.035'), findsOneWidget);
  });

  testWidgets('cancelling the change keeps the currency', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('currency-EUR')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('currency-EUR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect((await db.select(db.appSettings).getSingle()).currencyCode, 'TRY');
  });

  testWidgets('changing the payday moves the period', (tester) async {
    await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    expect(find.text('Ayda bir, ayın 15. günü'), findsOneWidget);
    await tester.tap(find.text('Maaş').last);
    await tester.pumpAndSettle();
    await pickDropdown(tester, const ValueKey('pay-day'), '1', delta: -48);
    await tester.tap(find.byKey(const ValueKey('save-pay')));
    await tester.pumpAndSettle();
    expect(find.text('Ayda bir, ayın 1. günü'), findsOneWidget);
    await openTab(tester, 'Bu dönem');
    expect(find.text('1 Kas – 30 Kas'), findsOneWidget);
  });

  testWidgets('debug builds show the Pro switch', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.byKey(const ValueKey('debug-pro')));
    await tester.tap(find.byKey(const ValueKey('debug-pro')));
    await tester.pumpAndSettle();
    expect((await db.select(db.appSettings).getSingle()).debugPro, isTrue);
  });

  testWidgets('theme follows the system by default; Light and Dark stick', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, seed: seedSettings);
    Color ground() =>
        Theme.of(tester.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor;
    expect(ground(), KalanColors.dark.bg);

    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Tema'));
    expect(find.text('Sistem'), findsOneWidget);
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Açık').last);
    await tester.pumpAndSettle();
    expect(ground(), KalanColors.light.bg);

    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(ground(), KalanColors.dark.bg);
  });

  testWidgets('the theme choice survives a restart', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = MemoryThemeModeStore();
    final overrides = [themeModeStoreProvider.overrideWithValue(store)];
    Color ground() =>
        Theme.of(tester.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor;

    await pumpApp(tester, seed: seedSettings, overrides: overrides);
    expect(store.read(), ThemeMode.system);
    expect(ground(), KalanColors.light.bg);
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Tema'));
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(store.read(), ThemeMode.dark);

    // A fresh app on the same device storage starts dark.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, seed: seedSettings, overrides: overrides);
    expect(ground(), KalanColors.dark.bg);
  });
}
