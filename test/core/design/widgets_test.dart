import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/widgets.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump.dart';

void main() {
  group('PeriodBar.weights', () {
    final cases = <(int, int, (int, int, int))>[
      (250, 1000, (250, 750, 0)),
      (0, 1000, (0, 1000, 0)),
      (1000, 1000, (1000, 0, 0)),
      (1500, 1000, (666, 0, 334)),
      (1, 1000000, (1, 999, 0)),
      (0, 0, (0, 0, 0)),
    ];
    for (final (spent, income, expected) in cases) {
      test('$spent of $income -> $expected', () {
        expect(PeriodBar.weights(spent, income), expected);
      });
    }
  });

  testWidgets('PeriodBar shows amber only when negative', (tester) async {
    await pumpLocalized(
      tester,
      const PeriodBar(
        spokenForMinor: 400,
        incomeMinor: 1000,
        semanticsLabel: 'bar',
      ),
    );
    expect(find.byKey(const ValueKey('bar-spoken-for')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-excess')), findsNothing);
    expect(find.bySemanticsLabel('bar'), findsOneWidget);
    // Segments must actually be drawn at the bar's height.
    expect(
      tester.getSize(find.byKey(const ValueKey('bar-spoken-for'))).height,
      12,
    );
    expect(tester.getSize(find.byKey(const ValueKey('bar-left'))).height, 12);

    await pumpLocalized(
      tester,
      const PeriodBar(
        spokenForMinor: 1400,
        incomeMinor: 1000,
        semanticsLabel: 'bar',
      ),
    );
    final excess = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('bar-excess')),
    );
    expect(excess.color, KalanColors.light.amber);
    expect(find.byKey(const ValueKey('bar-left')), findsNothing);
  });

  test('LetterBadge handles Turkish i and empty names', () {
    expect(LetterBadge.letterOf('işbank', localeName: 'tr'), 'İ');
    expect(LetterBadge.letterOf('ısparta', localeName: 'tr'), 'I');
    expect(LetterBadge.letterOf('klarna'), 'K');
    expect(LetterBadge.letterOf('  '), '?');
  });

  testWidgets('LetterBadge is hidden from screen readers', (tester) async {
    await pumpLocalized(tester, const LetterBadge('Klarna'));
    expect(find.text('K'), findsOneWidget);
    expect(find.bySemanticsLabel('K'), findsNothing);
  });

  testWidgets('AmountText uses tabular figures', (tester) async {
    await pumpLocalized(tester, const AmountText('3.250 TL'));
    final text = tester.widget<Text>(find.text('3.250 TL'));
    expect(text.style!.fontFeatures, AmountText.tabular);
  });

  test('themes are flat and derived from KalanColors', () {
    for (final (theme, c) in [
      (KalanTheme.light(), KalanColors.light),
      (KalanTheme.dark(), KalanColors.dark),
    ]) {
      expect(theme.extension<KalanColors>(), c);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.colorScheme.shadow.a, 0);
      expect(theme.colorScheme.surfaceTint.a, 0);
      expect(theme.scaffoldBackgroundColor, c.bg);
      expect(theme.colorScheme.surface, c.surface);
      expect(theme.colorScheme.primary, c.mint);
      expect(theme.colorScheme.onPrimary, c.onMint);
      expect(theme.colorScheme.error, c.coral);
      expect(
        theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        c.mintText,
      );
      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarColor,
        c.surface,
      );
    }
  });
}
