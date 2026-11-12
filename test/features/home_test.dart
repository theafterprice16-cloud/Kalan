import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/colors.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

void main() {
  // Period: 15 Nov - 14 Dec 2026. Klarna payments on 20 Nov and 4 Dec fall
  // inside (₺100 each), rent on 1 Dec (₺15.000).

  testWidgets('shows left, the summary sentence and dated rows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedPayIn4(db);
        await seedRent(db);
      },
    );
    expect(find.text('15 Kas – 14 Ara'), findsOneWidget);
    expect(find.text('₺34.800'), findsOneWidget);
    expect(find.text('Bu dönem 3 ödeme var. Toplam ₺15.200.'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('3/4'), findsNothing);
    expect(find.text('Sabit'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('4 ödemenin 1. ödemesi')),
      findsOneWidget,
    );
    semantics.dispose();
    final number = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home-number')),
        matching: find.byType(Text),
      ),
    );
    expect(number.style!.color, KalanColors.darkGreen);
  });

  testWidgets('one tap marks paid; paid still counts as spoken for', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedPayIn4(db);
      },
    );
    expect(find.byTooltip('Ödendi olarak işaretle'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
    await tester.pumpAndSettle();
    expect(find.text('Ödendi olarak işaretlendi.'), findsOneWidget);
    expect(find.text('Ödendi'), findsOneWidget);
    expect(find.byTooltip('Ödenmedi olarak işaretle'), findsOneWidget);
    expect(find.text('₺49.800'), findsOneWidget);
    final paid = await (db.select(
      db.payments,
    )..where((p) => p.paidAt.isNotNull())).get();
    expect(paid.single.seq, 1);
  });

  testWidgets('negative period uses coral and says how much is short', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 1000000);
        await seedPayIn4(db);
        await seedRent(db);
      },
    );
    expect(find.text('-₺5.200'), findsOneWidget);
    expect(find.text('Bu dönem ₺5.200 eksik kalıyor.'), findsOneWidget);
    final number = tester.widget<Text>(find.text('-₺5.200'));
    expect(number.style!.color, KalanColors.coral);
    expect(find.byKey(const ValueKey('bar-excess')), findsOneWidget);
  });

  testWidgets('tight period shows an amber note, never coral', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 2000000, thresholdMinor: 500000);
        await seedPayIn4(db);
        await seedRent(db);
      },
    );
    expect(find.text('₺4.800'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-tight')), findsOneWidget);
    expect(
      find.text('Sıkışık dönem. Kalan, belirlediğin ₺5.000 eşiğinin altında.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('status-negative')), findsNothing);
    expect(find.byKey(const ValueKey('bar-excess')), findsNothing);
  });

  testWidgets('without income only spoken for is shown', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db);
        await seedPayIn4(db);
        await seedRent(db);
      },
    );
    expect(find.text('Söz verilmiş'), findsOneWidget);
    expect(find.text('₺15.200'), findsWidgets);
    expect(
      find.text("Net tutarı Ayarlar'da girersen kalanı da gösteririm."),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bar-left')), findsNothing);
  });

  testWidgets('unpaid payments from earlier periods are listed separately', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        // 30 Oct, 13 Nov (previous period), 27 Nov, 11 Dec.
        await seedPayIn4(db, first: LocalDate(2026, 10, 30), source: 'Zip');
      },
    );
    expect(find.text('Ödenmemiş'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    // Only 27 Nov and 11 Dec count toward this period.
    expect(find.text('Bu dönem 2 ödeme var. Toplam ₺200.'), findsOneWidget);
  });

  testWidgets('English and dollars', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en', 'US'),
      seed: (db) async {
        await seedSettings(db, currency: 'USD', incomeMinor: 250000);
        await seedPayIn4(db, totalMinor: 25000, source: 'Afterpay');
      },
    );
    expect(find.text('Left'), findsOneWidget);
    expect(find.text(r'$2,375'), findsOneWidget);
    expect(find.text(r'2 payments this period. Total $125.'), findsOneWidget);
    expect(find.text('Nov 15 – Dec 14'), findsOneWidget);
  });

  testWidgets('large text on a small phone does not overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 1000000, thresholdMinor: 100);
        await seedPayIn4(db, title: 'Çok uzun bir plan adı, telefon ve kılıf');
        await seedRent(db);
      },
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch targets are at least 48x48', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, incomeMinor: 5000000);
        await seedPayIn4(db);
      },
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
