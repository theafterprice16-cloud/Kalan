// Right to left (Roadmap 24, decision 10, Example 3): the app in Arabic,
// opened here for the test only (no Arabic texts yet, so the words are
// English, but the layout, dates and numbers are Arabic).
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/locale.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/design/widgets.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/periods/period_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// The registry with Arabic open, as after the bulk translation.
final arabicOpen = [
  for (final l in appLocales)
    l.code == 'ar' ? l.withStatus(LocaleStatus.reviewed) : l,
];

/// Income, a plan due today and one with a payment 3 weeks late.
Future<void> seedArabic(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 4500000);
  await seedPayIn4(db, totalMinor: 240000, title: 'Kulaklık');
  await seedPayIn4(
    db,
    first: LocalDate(2026, 10, 30),
    totalMinor: 180000,
    source: 'Afterpay',
    title: 'Mont',
  );
}

Future<void> pumpArabic(WidgetTester tester) => pumpApp(
  tester,
  locale: const Locale('ar', 'EG'),
  seed: seedArabic,
  overrides: [appLocalesProvider.overrideWithValue(arabicOpen)],
);

/// Whether [icon] is drawn mirrored (Icon flips matchTextDirection icons).
bool mirrored(WidgetTester tester, Finder icon) {
  final flips = find.descendant(of: icon, matching: find.byType(Transform));
  return flips.evaluate().any(
    (e) => (e.widget as Transform).transform.storage[0] < 0,
  );
}

void main() {
  testWidgets('a closed Arabic stays closed: an Arabic phone gets English', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('ar', 'EG'), seed: seedArabic);
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Localizations.localeOf(context), const Locale('en'));
  });

  testWidgets('home reads from the right; the bar fills from the right', (
    tester,
  ) async {
    await pumpArabic(tester);
    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('ar'));
    expect(Directionality.of(context), TextDirection.rtl);

    // Spoken for starts at the bar's right edge; left follows it.
    final bar = tester.getRect(find.byType(PeriodBar));
    final spokenFor = tester.getRect(
      find.byKey(const ValueKey('bar-spoken-for')),
    );
    final left = tester.getRect(find.byKey(const ValueKey('bar-left')));
    expect(spokenFor.right, moreOrLessEquals(bar.right, epsilon: 0.5));
    expect(left.left, moreOrLessEquals(bar.left, epsilon: 0.5));
    expect(spokenFor.left, greaterThan(left.left));

    // The six small bars: this period is the rightmost.
    final mini = find.descendant(
      of: find.byType(ComingPeriodsMiniBars),
      matching: find.byType(ComingBar),
    );
    final first = tester.getRect(mini.at(0));
    final second = tester.getRect(mini.at(1));
    expect(first.left, greaterThan(second.left));

    // The clock of a late payment is not mirrored; the chevron is.
    final clock = find.descendant(
      of: find.byKey(const ValueKey('overdue-badge')),
      matching: find.byIcon(Icons.schedule),
    );
    expect(clock, findsWidgets);
    expect(mirrored(tester, clock.first), isFalse);
  });

  testWidgets('amounts keep their digits: Western, in order', (tester) async {
    await pumpArabic(tester);
    final tryCurrency = Currency.fromCode('TRY');
    // Mont: ₺1.800 in four, ₺450 each, the first one late.
    final amount = formatMoney(45000, tryCurrency, localeName: 'ar');
    expect(amount.replaceAll(RegExp(r'[^0-9]'), ''), '450');
    expect(find.text(amount), findsWidgets);
    final arabicDigits = RegExp('[٠-٩۰-۹]');
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data ?? text.textSpan?.toPlainText() ?? '';
      expect(arabicDigits.hasMatch(data), isFalse, reason: data);
    }
  });

  testWidgets('coming periods: the first period on the right, back arrow '
      'points right', (tester) async {
    await pumpArabic(tester);
    await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byKey(const ValueKey('coming-period-0')));
    final second = tester.getRect(
      find.byKey(const ValueKey('coming-period-1')),
    );
    expect(first.left, greaterThan(second.left));
    // Each amount under a bar stays on one line ("26.8 ألف ₺" is wider
    // than English "₺26.8K"; the column grows, the row may scroll).
    final amounts = find.descendant(
      of: find.byKey(const ValueKey('coming-period-1')),
      matching: find.textContaining('₺'),
    );
    expect(amounts, findsOneWidget);
    final paragraph =
        amounts.evaluate().single.renderObject! as RenderParagraph;
    final text = paragraph.text.toPlainText();
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: text);
    // Colors keep their roles: spoken for and left as in left to right.
    expect(find.byKey(const ValueKey('coming-bar-spoken-for')), findsWidgets);

    // The back arrow is mirrored (points to the right, where it came from).
    final back = find.descendant(
      of: find.byType(BackButton),
      matching: find.byType(Icon),
    );
    expect(back, findsOneWidget);
    expect(mirrored(tester, back), isTrue);
    final appBar = tester.getRect(find.byType(AppBar));
    expect(tester.getCenter(back).dx, greaterThan(appBar.center.dx));
  });

  // The system date picker reads Arabic dates as well: 0-9 there too.
  testWidgets('the date picker writes 0-9', (tester) async {
    await pumpArabic(tester);
    await tester.tap(find.text('Add plan'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('first-date'));
    await scrollTo(tester, field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    final texts = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(RichText),
    );
    expect(texts, findsWidgets);
    final eastern = RegExp('[\u0660-\u0669\u06F0-\u06F9]');
    var digits = 0;
    for (final e in texts.evaluate()) {
      final text = (e.widget as RichText).text.toPlainText();
      expect(eastern.hasMatch(text), isFalse, reason: text);
      if (RegExp('[0-9]').hasMatch(text)) digits++;
    }
    expect(digits, greaterThan(20), reason: 'the month\'s days');
  });

  testWidgets('calendar: the week starts on the right', (tester) async {
    await pumpArabic(tester);
    await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    // 2 and 3 November 2026 share a week: 2 is to the right of 3.
    final two = tester.getRect(find.byKey(const ValueKey('calendar-cell-2')));
    final three = tester.getRect(find.byKey(const ValueKey('calendar-cell-3')));
    expect(two.top, three.top);
    expect(two.left, greaterThan(three.left));
    // Previous month: the chevron next to the month name points right.
    final previous = find.descendant(
      of: find.byKey(const ValueKey('calendar-previous')),
      matching: find.byType(Icon),
    );
    expect(mirrored(tester, previous), isTrue);
  });
}
