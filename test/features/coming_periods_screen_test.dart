import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/periods/coming_periods.dart';
import 'package:kalan/features/periods/period_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/pump.dart';

/// Income ₺50.000, payday 15. Klarna ₺100 on 20 Nov, 4 Dec, 18 Dec and
/// 1 Jan; rent ₺15.000 on the 1st. Period 0 (15 Nov – 14 Dec) and period
/// 1 (15 Dec – 14 Jan) are both ₺15.200 spoken for, ₺34.800 left.
Future<void> seed(AppDatabase db, {int? income = 5000000}) async {
  await seedSettings(db, incomeMinor: income);
  await seedPayIn4(db);
  await seedRent(db);
}

Future<void> openStrip(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
  await tester.pumpAndSettle();
}

Finder summary(String text) => find.descendant(
  of: find.byKey(const ValueKey('coming-period-summary')),
  matching: find.text(text),
);

void main() {
  testWidgets('the home strip opens the screen with this period selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, seed: seed);
    expect(find.text('İleriki dönemler'), findsOneWidget);
    // The strip is one button.
    expect(find.bySemanticsLabel('İleriki dönemler'), findsOneWidget);
    expect(find.byType(ComingPeriodsMiniBars), findsOneWidget);
    await openStrip(tester);

    expect(find.byType(ComingPeriodsChart), findsOneWidget);
    expect(summary('15 Kas – 14 Ara'), findsOneWidget);
    // The same numbers as the home screen: 3 payments, ₺15.200, ₺34.800.
    expect(
      summary('Bu dönem 3 ödeme. Toplam ₺15.200. Kalan ₺34.800.'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('coming-period-0'))),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('coming-period-1'))),
      isSemantics(isSelected: false, isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('tapping a bar shows that period and its payments', (
    tester,
  ) async {
    await pumpApp(tester, seed: seed);
    await openStrip(tester);
    expect(find.text('20 Kas'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('coming-period-1')));
    await tester.pumpAndSettle();
    expect(summary('15 Ara – 14 Oca'), findsOneWidget);
    expect(
      summary('Bu dönem 3 ödeme. Toplam ₺15.200. Kalan ₺34.800.'),
      findsOneWidget,
    );
    expect(find.text('20 Kas'), findsNothing);
    expect(find.text('18 Ara'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
  });

  testWidgets('without income: spoken-for bars, no left, an invite', (
    tester,
  ) async {
    await pumpApp(tester, seed: (db) => seed(db, income: null));
    await openStrip(tester);
    expect(summary('Bu dönem 3 ödeme. Toplam ₺15.200.'), findsOneWidget);
    expect(find.byKey(const ValueKey('coming-bar-left')), findsNothing);
    expect(
      find.byKey(const ValueKey('coming-bar-spoken-for')),
      findsNWidgets(6),
    );
    final invite = find.text(
      'Gelirini girersen her dönemde ne kaldığını da görürsün.',
    );
    expect(invite, findsOneWidget);
    await tester.tap(invite);
    await tester.pumpAndSettle();
    // The same income dialog as in Settings.
    expect(find.text('Net tutar'), findsWidgets);
    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(invite, findsNothing);
    expect(
      summary('Bu dönem 3 ödeme. Toplam ₺15.200. Kalan ₺4.800.'),
      findsOneWidget,
    );
  });

  testWidgets('a short period says so in words, in negativeText', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, seed: (db) => seed(db, income: 1500000));
    await openStrip(tester);
    // Periods 0 and 1 are both ₺200 short: under both bars, with the
    // minus sign; the note under the summary reads as on the home screen.
    expect(find.text('-₺200 eksik'), findsNWidgets(2));
    expect(find.text('Bu dönem ₺200 eksik kalıyor.'), findsWidgets);
    final note = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('coming-period-short')),
        matching: find.byType(Text),
      ),
    );
    expect(note.style!.color, KalanColors.light.negativeText);
    expect(find.byKey(const ValueKey('coming-bar-income-line')), findsWidgets);
    expect(
      find.bySemanticsLabel(
        '15 Kasım – 14 Aralık: söz verilmiş ₺15.200, -₺200 eksik.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('past due in this period: "Paid" asks when, as on home', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await seed(db);
        // Klarna's first payment, due 6 Nov (before today), still unpaid.
        await seedPayIn4(db, first: LocalDate(2026, 11, 6), source: 'Zip');
      },
    );
    await scrollTo(tester, find.byKey(const ValueKey('coming-periods-strip')));
    await openStrip(tester);
    expect(find.text('Günü geçen 1 ödeme'), findsOneWidget);
    final paid = find.descendant(
      of: find.byKey(const ValueKey('coming-period-past-due')),
      matching: find.text('Ödendi'),
    );
    await tester.ensureVisible(paid);
    await tester.pumpAndSettle();
    await tester.tap(paid);
    await tester.pumpAndSettle();
    expect(find.text('Ne zaman ödedin?'), findsOneWidget);
  });

  testWidgets('every bar reads out its period and amounts', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, seed: seed);
    await openStrip(tester);
    expect(
      find.bySemanticsLabel(
        '15 Kasım – 14 Aralık: söz verilmiş ₺15.200, kalan ₺34.800.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        '15 Aralık – 14 Ocak: söz verilmiş ₺15.200, kalan ₺34.800.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('without income the bars read only spoken for', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, seed: (db) => seed(db, income: null));
    await openStrip(tester);
    expect(
      find.bySemanticsLabel('15 Kasım – 14 Aralık: söz verilmiş ₺15.200.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('bars are tappable at 48x48 or more', (tester) async {
    await pumpApp(tester, seed: seed);
    await openStrip(tester);
    for (var i = 0; i < comingPeriodCount; i++) {
      final size = tester.getSize(find.byKey(ValueKey('coming-period-$i')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('no payments: no strip on the home screen', (tester) async {
    await pumpApp(tester, seed: (db) => seedSettings(db, incomeMinor: 5000000));
    expect(find.byKey(const ValueKey('coming-periods-strip')), findsNothing);
  });

  testWidgets('no payments: the screen says so, no empty axes', (tester) async {
    await pumpApp(
      tester,
      seed: (db) => seedSettings(db, incomeMinor: 5000000),
      overrides: [initialRouteProvider.overrideWithValue('/periods')],
    );
    expect(find.text('Önümüzdeki 6 dönemde ödeme yok.'), findsOneWidget);
    expect(find.byType(ComingPeriodsChart), findsNothing);
  });

  testWidgets('the strip follows new data', (tester) async {
    final db = await pumpApp(tester, seed: seedSettings);
    expect(find.byKey(const ValueKey('coming-periods-strip')), findsNothing);
    await tester.runAsync(() => seedRent(db));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('coming-periods-strip')), findsOneWidget);
  });

  testWidgets('large text on a small phone does not overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, seed: (db) => seed(db, income: 1500000));
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.byKey(const ValueKey('coming-periods-strip')));
    expect(tester.takeException(), isNull);
    await openStrip(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('right to left: the first period is on the right', (
    tester,
  ) async {
    final periods = comingPeriods(
      plans: const [],
      recurring: const [],
      schedule: const PaySchedule.monthly(15),
      today: testToday,
      incomeMinor: 5000000,
    );
    Future<(double, double)> xs(TextDirection direction) async {
      await pumpLocalized(
        tester,
        ProviderScope(
          overrides: [
            currencyProvider.overrideWithValue(Currency.byCode('TRY')!),
          ],
          child: Directionality(
            textDirection: direction,
            child: ComingPeriodsChart(
              periods: periods,
              selected: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double x(int i) =>
          tester.getCenter(find.byKey(ValueKey('coming-period-$i'))).dx;
      return (x(0), x(5));
    }

    final (ltrFirst, ltrLast) = await xs(TextDirection.ltr);
    expect(ltrFirst, lessThan(ltrLast));
    final (rtlFirst, rtlLast) = await xs(TextDirection.rtl);
    expect(rtlFirst, greaterThan(rtlLast));
  });

  group('BarGeometry', () {
    test('one scale: the largest of spoken for and income', () {
      final periods = comingPeriods(
        plans: const [],
        recurring: const [],
        schedule: const PaySchedule.monthly(15),
        today: testToday,
        incomeMinor: 5000000,
      );
      expect(BarGeometry.scaleOf(periods), 5000000);
    });

    test('left sits above spoken for and fills to income', () {
      final g = BarGeometry.of(
        spokenForMinor: 2500,
        incomeMinor: 10000,
        scale: 10000,
        height: 100,
      );
      expect(g.spokenFor, 25);
      expect(g.left, 75);
      expect(g.incomeLine, isNull);
    });

    test('a tiny nonzero amount is still visible', () {
      final g = BarGeometry.of(
        spokenForMinor: 1,
        incomeMinor: null,
        scale: 1000000,
        height: 100,
      );
      expect(g.spokenFor, BarGeometry.minVisible);
      expect(g.left, 0);
    });

    test('short: whole bar spoken for, a line at the income level', () {
      final g = BarGeometry.of(
        spokenForMinor: 20300,
        incomeMinor: 20000,
        scale: 20300,
        height: 203,
        isShort: true,
      );
      expect(g.spokenFor, 203);
      expect(g.left, 0);
      expect(g.incomeLine, closeTo(200, 0.001));
    });

    test('nothing to draw on an empty scale', () {
      final g = BarGeometry.of(
        spokenForMinor: 0,
        incomeMinor: null,
        scale: 0,
        height: 100,
      );
      expect(g.spokenFor, 0);
      expect(g.left, 0);
    });
  });
}
