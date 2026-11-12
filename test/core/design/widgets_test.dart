import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/colors.dart';
import 'package:kalan/core/design/theme.dart';
import 'package:kalan/core/design/widgets.dart';
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

  testWidgets('PeriodBar shows coral only when negative', (tester) async {
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
    expect(excess.color, KalanColors.coral);
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

  test('themes are flat and use the brand palette', () {
    for (final theme in [KalanTheme.light(), KalanTheme.dark()]) {
      expect(theme.cardTheme.elevation, 0);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.colorScheme.shadow.a, 0);
      expect(theme.colorScheme.surfaceTint.a, 0);
      expect(theme.extension<KalanPalette>(), isNotNull);
      // Coral is reserved for negative periods, never for form errors.
      expect(theme.colorScheme.error, isNot(KalanColors.coral));
    }
    expect(KalanTheme.light().colorScheme.surface, KalanColors.paper);
    expect(KalanTheme.dark().colorScheme.surface, KalanColors.ink);
    expect(KalanPalette.light.leftAmount, KalanColors.darkGreen);
    expect(KalanPalette.dark.leftAmount, KalanColors.green);
  });

  test('text colors meet WCAG contrast on their grounds', () {
    double lum(Color c) {
      double ch(double v) => v <= 0.03928
          ? v / 12.92
          : ((v + 0.055) / 1.055) *
                ((v + 0.055) / 1.055) *
                // pow(x, 2.4) ~ x^2 * x^0.4; use dart:math-free approximation
                _pow04((v + 0.055) / 1.055);
      return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
    }

    double contrast(Color a, Color b) {
      final la = lum(a), lb = lum(b);
      final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    // Body text: 4.5:1.
    expect(contrast(KalanColors.ink, KalanColors.paper), greaterThan(4.5));
    expect(contrast(KalanColors.smoke, KalanColors.paper), greaterThan(4.5));
    expect(contrast(KalanColors.smokeLight, KalanColors.ink), greaterThan(4.5));
    expect(
      contrast(KalanColors.darkGreen, KalanColors.paper),
      greaterThan(4.5),
    );
    expect(contrast(KalanColors.green, KalanColors.ink), greaterThan(4.5));
    // Large amounts: 3:1.
    expect(contrast(KalanColors.coral, KalanColors.paper), greaterThan(3));
    expect(contrast(KalanColors.coral, KalanColors.ink), greaterThan(3));
    // Ink text on amber fills.
    expect(contrast(KalanColors.ink, KalanColors.amber), greaterThan(4.5));
  });
}

/// x^0.4 via Newton iterations on y^5 = x^2 (x in [0, 1]).
double _pow04(double x) {
  if (x <= 0) return 0;
  final target = x * x;
  var y = x;
  for (var i = 0; i < 40; i++) {
    final y4 = y * y * y * y;
    y = y - (y4 * y - target) / (5 * y4);
  }
  return y;
}
