import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/theme/kalan_colors.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/recurring_repository.dart';
import 'package:kalan/features/periods/busy_week_view.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/calendar_seed.dart';

/// Example 3: two plan payments and three recurring payments in one week.
Future<void> seedExample3(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 4500000);
  await seedSingle(db, 'Saat', LocalDate(2026, 12, 17), 100000);
  await seedSingle(db, 'Kulaklık', LocalDate(2026, 12, 18), 150000);
  for (final (name, day) in [('Spor', 17), ('İnternet', 18), ('Kira', 19)]) {
    await RecurringRepository(db).create(
      RecurringPaymentsCompanion.insert(
        name: name,
        amountMinor: 50000,
        recurrence: Recurrence.monthly,
        startDay: LocalDate(2026, 11, day).epochDay,
      ),
    );
  }
}

Future<void> openChart(
  WidgetTester tester,
  Future<void> Function(AppDatabase) seed, {
  Locale locale = const Locale('tr', 'TR'),
}) async {
  await pumpApp(tester, today: busyWeekToday, seed: seed, locale: locale);
  await scrollTo(tester, find.byKey(const ValueKey('coming-periods-strip')));
  await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
  await tester.pumpAndSettle();
}

Finder column(int i) => find.byKey(ValueKey('coming-period-$i'));
Finder tagIn(int i) => find.descendant(
  of: column(i),
  matching: find.byKey(const ValueKey('coming-busy-week')),
);
final note = find.byKey(const ValueKey('busy-week-note'));

Finder calendarCell(int day) => find.byKey(ValueKey('calendar-cell-$day'));
Finder lineIn(int day) => find.descendant(
  of: calendarCell(day),
  matching: find.byKey(const ValueKey('calendar-busy-line')),
);
Finder busyIconIn(int day) => find.descendant(
  of: calendarCell(day),
  matching: find.byKey(const ValueKey('calendar-busy-icon')),
);

Future<void> openCalendar(WidgetTester tester) async {
  await pumpApp(tester, today: calendarToday, seed: seedCalendar);
  await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Takvim'));
  await tester.pumpAndSettle();
}

String noteText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: note, matching: find.byType(Text)))
    .textSpan!
    .toPlainText();

void main() {
  group('chart', () {
    testWidgets('Example 1: a tag beside the December bar only', (
      tester,
    ) async {
      await openChart(tester, seedBusyWeek);
      expect(tagIn(1), findsOneWidget);
      for (final i in [0, 2, 3, 4, 5]) {
        expect(tagIn(i), findsNothing, reason: 'period $i');
      }
      // The tag is "yoğun" with the icon, under the bar, not on it.
      expect(
        find.descendant(of: tagIn(1), matching: find.text('yoğun')),
        findsOneWidget,
      );
      expect(note, findsNothing);
    });

    testWidgets('Example 1: tapping the bar shows the one line', (
      tester,
    ) async {
      await openChart(tester, seedBusyWeek);
      await tester.tap(column(1));
      await tester.pumpAndSettle();
      expect(note, findsOneWidget);
      expect(noteText(tester), 'Yoğun hafta: 17–21 Ara · 4 ödeme · ₺5.200');
    });

    testWidgets('tapping the tag opens the same explanation', (tester) async {
      await openChart(tester, seedBusyWeek);
      await tester.tap(tagIn(1));
      await tester.pumpAndSettle();
      expect(noteText(tester), 'Yoğun hafta: 17–21 Ara · 4 ödeme · ₺5.200');
    });

    testWidgets('English: "Busy week: Dec 17–21 · 4 payments"', (tester) async {
      await openChart(tester, seedBusyWeek, locale: const Locale('en', 'US'));
      expect(
        find.descendant(of: tagIn(1), matching: find.text('busy')),
        findsOneWidget,
      );
      await tester.tap(column(1));
      await tester.pumpAndSettle();
      expect(
        noteText(tester),
        startsWith('Busy week: Dec 17–21 · 4 payments · '),
      );
    });

    testWidgets('the bar reads the busy week out', (tester) async {
      final semantics = tester.ensureSemantics();
      await openChart(tester, seedBusyWeek);
      final label = tester.getSemantics(column(1)).label;
      expect(label, contains('Yoğun hafta: 17–21 Ara · 4 ödeme · ₺5.200'));
      expect(tester.getSemantics(column(2)).label, isNot(contains('Yoğun')));
      semantics.dispose();
    });

    testWidgets('Example 3: recurring payments never count', (tester) async {
      await openChart(tester, seedExample3);
      expect(find.byKey(const ValueKey('coming-busy-week')), findsNothing);
      await tester.tap(column(1));
      await tester.pumpAndSettle();
      expect(note, findsNothing);
    });

    testWidgets('the busy week is in the text color, never late or negative', (
      tester,
    ) async {
      await openChart(tester, seedBusyWeek);
      await tester.tap(column(1));
      await tester.pumpAndSettle();
      const colors = KalanColors.light;
      for (final icon in tester.widgetList<Icon>(find.byIcon(busyWeekIcon))) {
        expect(icon.color, colors.text);
      }
      final box = tester.widget<Container>(note);
      expect((box.decoration! as BoxDecoration).color, colors.surfaceRaised);
      final colorsUsed = [
        for (final icon in tester.widgetList<Icon>(find.byIcon(busyWeekIcon)))
          icon.color,
      ];
      expect(colorsUsed, isNot(contains(colors.late)));
      expect(colorsUsed, isNot(contains(colors.negative)));
    });
  });

  group('calendar', () {
    // seedCalendar, period 15 Oct - 14 Nov: plan payments on 5, 10, 14
    // and 14 Nov; 10-14 Nov holds three of four (the 28 Oct recurring
    // payment never counts).
    testWidgets('a thin line joins the busy days, the icon on the first', (
      tester,
    ) async {
      await openCalendar(tester);
      for (final day in [10, 11, 12, 13, 14]) {
        expect(lineIn(day), findsOneWidget, reason: 'day $day');
      }
      for (final day in [5, 9, 15, 28]) {
        expect(lineIn(day), findsNothing, reason: 'day $day');
      }
      expect(busyIconIn(10), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-busy-icon')), findsOneWidget);
    });

    testWidgets('screen readers hear "yoğun hafta"', (tester) async {
      final semantics = tester.ensureSemantics();
      await openCalendar(tester);
      expect(
        find.bySemanticsLabel('10 Kasım, 1 ödeme, gecikmiş, yoğun hafta'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('13 Kasım, Ödeme yok, yoğun hafta, bugün'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('5 Kasım, 1 ödeme, ödendi'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('tapping a busy day shows the same explanation', (
      tester,
    ) async {
      await openCalendar(tester);
      await tester.tap(calendarCell(10));
      await tester.pumpAndSettle();
      expect(noteText(tester), 'Yoğun hafta: 10–14 Kas · 3 ödeme · ₺3.500');

      await tester.tap(calendarCell(5));
      await tester.pumpAndSettle();
      expect(note, findsNothing);
    });
  });

  testWidgets('large text on a small phone: the tag and line fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openChart(tester, seedBusyWeek);
    expect(tester.takeException(), isNull);
    await scrollTo(tester, tagIn(1));
    await tester.tap(tagIn(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await scrollTo(tester, note);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(lineIn(17), findsOneWidget);
  });

  testWidgets('the home screen shows no busy week', (tester) async {
    // This period (15 Nov - 14 Dec) is busy too: 3 payments in a week.
    await pumpApp(
      tester,
      today: busyWeekToday,
      seed: (db) async {
        await seedBusyWeek(db);
        await seedSingle(db, 'A', LocalDate(2026, 11, 24), 10000);
        await seedSingle(db, 'B', LocalDate(2026, 11, 25), 10000);
        await seedSingle(db, 'C', LocalDate(2026, 11, 26), 10000);
      },
    );
    expect(find.byKey(const ValueKey('coming-busy-week')), findsNothing);
    expect(note, findsNothing);
    expect(find.byIcon(busyWeekIcon), findsNothing);
    expect(find.textContaining('oğun'), findsNothing);
  });
}
