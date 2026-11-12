import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('switching the language to English', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
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
    expect(find.text('20.000 TL'), findsOneWidget);

    await tester.tap(find.text('Sıkışık dönem eşiği'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-amount')),
      '6000',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('6.000 TL'), findsOneWidget);

    await openTab(tester, 'Bu dönem');
    expect(find.text('5.000 TL'), findsOneWidget);
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

  testWidgets('currency changes the symbol, not the amounts', (tester) async {
    await pumpApp(tester, seed: (db) => seedSettings(db, incomeMinor: 5000000));
    await openTab(tester, 'Ayarlar');
    await tester.tap(find.text('Para birimi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tutarlar çevrilmez. Yalnızca para birimi değişir.'),
      findsOneWidget,
    );
    await tester.tap(find.text('ABD doları (USD)'));
    await tester.pumpAndSettle();
    expect(find.text(r'50.000 $'), findsOneWidget);
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
}
