import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

Future<void> seedFull(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 5000000, thresholdMinor: 100);
  await seedCard(db);
  await seedPayIn4(db, title: 'Çok uzun bir plan adı, telefon ve kılıf');
  await seedRent(db);
}

void useSmallPhoneWithLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('payment row reads as one item; the toggle is separate', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedPayIn4(db);
      },
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Klarna.*20 Kas.*4 ödemenin 1\..*₺100', dotAll: true),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('^Kalan')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('gelirin .* kadarı söz verilmiş')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every tab meets tap target and label guidelines', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedFull);
    for (final tab in ['Bu dönem', 'Planlar', 'Ayarlar']) {
      await openTab(tester, tab);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    await openTab(tester, 'Bu dönem');
    await tester.tap(find.text('Plan ekle'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('add plan works with large text on a small phone', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    await pumpApp(tester, seed: seedFull);
    await tester.tap(find.text('Plan ekle'));
    await tester.pumpAndSettle();
    for (final mode in [
      '4 ödemeli plan',
      'Aylık taksit',
      'Kredi kartı taksidi',
      'Elle giriş',
    ]) {
      // Back to the top, where the plan types are.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.widgetWithText(ChoiceChip, mode));
      await tester.tap(find.widgetWithText(ChoiceChip, mode));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: mode);
      // "This plan is already underway" and its fields, in every mode.
      const underway = ValueKey('underway');
      await scrollTo(tester, find.byKey(underway));
      final on = tester.widget<SwitchListTile>(find.byKey(underway)).value;
      if (!on) {
        await tester.tap(find.byKey(underway));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: '$mode, underway');
    }
  });

  testWidgets('other screens survive large text', (tester) async {
    useSmallPhoneWithLargeText(tester);
    await pumpApp(tester, seed: seedFull);
    for (final tab in ['Planlar', 'Ayarlar']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: tab);
    }
    await openTab(tester, 'Planlar');
    await tester.tap(find.textContaining('Çok uzun'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode uses ink ground and green left number', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, seed: seedFull);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(
      scaffold.backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).last))
              .scaffoldBackgroundColor,
      KalanColors.dark.bg,
    );
    final number = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home-number')),
        matching: find.byType(Text),
      ),
    );
    expect(number.style!.color, KalanColors.dark.accent);
  });
}
