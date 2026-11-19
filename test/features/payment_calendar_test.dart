import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/periods/period_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/calendar_seed.dart';

/// iPhone-sized screen.
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<AppDatabase> openCalendar(
  WidgetTester tester, {
  Locale locale = const Locale('tr', 'TR'),
  LocalDate? today,
}) async {
  final db = await pumpApp(
    tester,
    locale: locale,
    today: today ?? calendarToday,
    seed: seedCalendar,
  );
  await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(locale.languageCode == 'tr' ? 'Takvim' : 'Calendar'),
  );
  await tester.pumpAndSettle();
  return db;
}

Finder cell(int day) => find.byKey(ValueKey('calendar-cell-$day'));

Finder markIn(int day, String mark) =>
    find.descendant(of: cell(day), matching: find.byKey(ValueKey(mark)));

void main() {
  testWidgets('"Chart" first; "Calendar" is remembered in the app', (
    tester,
  ) async {
    await pumpApp(tester, today: calendarToday, seed: seedCalendar);
    await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
    await tester.pumpAndSettle();
    expect(find.byType(ComingPeriodsChart), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-calendar')), findsNothing);

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-calendar')), findsOneWidget);
    expect(find.text('Kasım 2026'), findsOneWidget);

    // Back home and in again: still the calendar.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-calendar')), findsOneWidget);
  });

  testWidgets('Examples 1 and 3: marks and the payday ring', (tester) async {
    await openCalendar(tester);
    expect(markIn(5, 'mark-paid'), findsOneWidget);
    expect(markIn(10, 'mark-late'), findsOneWidget);
    expect(markIn(14, 'mark-pending'), findsOneWidget);
    expect(markIn(28, 'mark-pending'), findsOneWidget);
    expect(
      find.descendant(
        of: cell(15),
        matching: find.byKey(const ValueKey('calendar-payday-15')),
      ),
      findsOneWidget,
    );
    // Shapes, not only colors: a clock for late, a check for paid.
    expect(
      find.descendant(of: cell(10), matching: find.byIcon(Icons.schedule)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cell(5), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    for (final day in [1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 15, 16, 30]) {
      expect(
        find.descendant(
          of: cell(day),
          matching: find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('mark-'),
          ),
        ),
        findsNothing,
        reason: 'day $day',
      );
    }
  });

  testWidgets('screen reader labels count every state', (tester) async {
    final semantics = tester.ensureSemantics();
    await openCalendar(tester);
    expect(
      find.bySemanticsLabel('10 Kasım, 1 ödeme, gecikmiş'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('14 Kasım, 2 ödeme'), findsOneWidget);
    expect(find.bySemanticsLabel('5 Kasım, 1 ödeme, ödendi'), findsOneWidget);
    expect(
      find.bySemanticsLabel('15 Kasım, Ödeme yok, maaş günü'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('13 Kasım, Ödeme yok, bugün'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Example 3: today 19 Nov, 10 Nov unpaid', (tester) async {
    final semantics = tester.ensureSemantics();
    await openCalendar(tester, today: LocalDate(2026, 11, 19));
    expect(markIn(10, 'mark-late'), findsOneWidget);
    expect(
      find.bySemanticsLabel('10 Kasım, 1 ödeme, gecikmiş'),
      findsOneWidget,
    );
    // Never moved to today.
    expect(find.bySemanticsLabel('19 Kasım, Ödeme yok, bugün'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('day cells are at least 48x48', (tester) async {
    await openCalendar(tester);
    // iPhone width, set here: test text (Ahem) is wider than real fonts.
    phone(tester);
    await tester.pumpAndSettle();
    for (final day in [1, 14, 30]) {
      final size = tester.getSize(cell(day));
      expect(size.width, greaterThanOrEqualTo(48), reason: 'day $day');
      expect(size.height, greaterThanOrEqualTo(48), reason: 'day $day');
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('336 dp wide: cells still 48 wide', (tester) async {
    await openCalendar(tester);
    tester.view.physicalSize = const Size(672, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    expect(tester.getSize(cell(14)).width, greaterThanOrEqualTo(48));
  });

  testWidgets('screen readers can tap a day', (tester) async {
    final semantics = tester.ensureSemantics();
    await openCalendar(tester);
    tester.semantics.tap(find.semantics.byLabel('14 Kasım, 2 ödeme'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-day-section')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Example 2: a day\'s payments, total and one-tap paid', (
    tester,
  ) async {
    final db = await openCalendar(tester);
    await tester.tap(cell(14));
    await tester.pumpAndSettle();
    final section = find.byKey(const ValueKey('calendar-day-section'));
    await scrollTo(tester, find.byKey(const ValueKey('calendar-day-total')));
    expect(
      find.descendant(of: section, matching: find.text('Telefon taksiti')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('Laptop taksiti')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('₺1.400')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('₺1.500')),
      findsOneWidget,
    );
    expect(find.text('Toplam ₺2.900'), findsOneWidget);

    // The home screen's row and its repository "paid".
    await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
    await tester.pumpAndSettle();
    final paid = await (db.select(
      db.payments,
    )..where((p) => p.paidAt.isNotNull())).get();
    expect(paid, hasLength(2)); // Saat, and the one just marked.
    expect(find.text('Ödendi olarak işaretlendi.'), findsOneWidget);
    // One paid, one pending: the day keeps the pending mark.
    expect(markIn(14, 'mark-pending'), findsOneWidget);

    await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
    await tester.pumpAndSettle();
    expect(markIn(14, 'mark-paid'), findsOneWidget);
  });

  testWidgets('a late payment asks "when did you pay?" as on home', (
    tester,
  ) async {
    await openCalendar(tester);
    await tester.tap(cell(10));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Kulaklık').last);
    await tester.tap(find.byKey(const ValueKey('past-due-paid-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paid-when-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paid-when-today')));
    await tester.pumpAndSettle();
    expect(markIn(10, 'mark-paid'), findsOneWidget);
  });

  testWidgets('Example 5: a day without payments', (tester) async {
    await openCalendar(tester);
    await tester.tap(cell(3));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('calendar-day-empty')));
    expect(find.text('Bu gün ödeme yok.'), findsOneWidget);

    // Payday: its own row.
    await tester.tap(cell(15));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('calendar-day-payday')));
    expect(find.text('Maaş günü'), findsOneWidget);
    expect(find.text('Bu gün ödeme yok.'), findsOneWidget);
  });

  testWidgets('Example 4: the week starts with the device region', (
    tester,
  ) async {
    // Turkey: Monday first, so Sunday 1 Nov 2026 is the last column.
    await openCalendar(tester);
    expect(
      tester.getCenter(cell(1)).dx,
      greaterThan(tester.getCenter(cell(2)).dx),
    );
    expect(
      tester.getCenter(cell(1)).dy,
      lessThan(tester.getCenter(cell(2)).dy),
    );
  });

  testWidgets('Example 4: United States, Sunday first', (tester) async {
    await openCalendar(tester, locale: const Locale('en', 'US'));
    expect(find.text('November 2026'), findsOneWidget);
    // 1 Nov is a Sunday: the first column, the same row as the 2nd.
    expect(
      tester.getCenter(cell(1)).dx,
      lessThan(tester.getCenter(cell(2)).dx),
    );
    expect(tester.getCenter(cell(1)).dy, tester.getCenter(cell(2)).dy);
  });

  testWidgets('English phone in Turkey: Monday first', (tester) async {
    await openCalendar(tester, locale: const Locale('en', 'TR'));
    expect(find.text('November 2026'), findsOneWidget);
    expect(
      tester.getCenter(cell(1)).dx,
      greaterThan(tester.getCenter(cell(2)).dx),
    );
  });

  testWidgets('months: 12 back, forward to the last payment, "Today"', (
    tester,
  ) async {
    await openCalendar(tester);
    final previous = find.byKey(const ValueKey('calendar-previous'));
    final next = find.byKey(const ValueKey('calendar-next'));
    bool enabled(Finder f) => tester.widget<IconButton>(f).onPressed != null;
    final today = find.byKey(const ValueKey('calendar-today'));
    expect(tester.widget<TextButton>(today).onPressed, isNull);

    for (var i = 0; i < 12; i++) {
      await tester.tap(previous);
      await tester.pumpAndSettle();
    }
    expect(find.text('Kasım 2025'), findsOneWidget);
    expect(enabled(previous), isFalse);

    await tester.tap(today);
    await tester.pumpAndSettle();
    expect(find.text('Kasım 2026'), findsOneWidget);

    // No payment after this month: six months ahead, May 2027.
    for (var i = 0; i < 6; i++) {
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Mayıs 2027'), findsOneWidget);
    expect(enabled(next), isFalse);

    // A swipe goes back a month.
    await tester.fling(
      find.byKey(const ValueKey('calendar-cell-14')),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nisan 2027'), findsOneWidget);
  });

  test('color guard: no accent or chartCommitted in the calendar', () {
    for (final path in [
      'lib/features/periods/payment_calendar.dart',
      'lib/features/periods/calendar_month.dart',
    ]) {
      final code = File(path)
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        RegExp(r'\.(accent|accentText|onAccent|chartCommitted)\b')
            .hasMatch(code),
        isFalse,
        reason: path,
      );
    }
  });
}
