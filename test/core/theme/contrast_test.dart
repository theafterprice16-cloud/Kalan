import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.2 relative luminance.
double luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Normal text.
const normalText = 4.5;

/// Large text, fills, charts, borders and focus.
const nonText = 3.0;

typedef Pair = (
  String name,
  Color Function(KalanColors) fg,
  Color Function(KalanColors) bg,
  double min,
);

Color _bg(KalanColors c) => c.bg;
Color _surface(KalanColors c) => c.surface;
Color _raised(KalanColors c) => c.surfaceRaised;

/// Every pair in docs/DESIGN_TOKENS.md, with the ratio it reports for the
/// light and the dark theme.
final pairs = <(Pair, double light, double dark)>[
  for (final (ground, g, l, d) in [
    ('bg', _bg, 13.93, 15.02),
    ('surface', _surface, 15.05, 13.43),
    ('surfaceRaised', _raised, 15.82, 11.69),
  ])
    (('text / $ground', (c) => c.text, g, normalText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 5.60, 8.30),
    ('surface', _surface, 6.05, 7.41),
    ('surfaceRaised', _raised, 6.36, 6.46),
  ])
    (('textMuted / $ground', (c) => c.textMuted, g, normalText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 7.39, 9.82),
    ('surface', _surface, 7.98, 8.78),
    ('surfaceRaised', _raised, 8.39, 7.65),
  ])
    (('accentText / $ground', (c) => c.accentText, g, normalText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 6.01, 11.11),
    ('surface', _surface, 6.49, 9.93),
    ('surfaceRaised', _raised, 6.82, 8.65),
  ])
    (('negativeText / $ground', (c) => c.negativeText, g, normalText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 6.68, 6.26),
    ('surface', _surface, 7.21, 5.59),
    ('surfaceRaised', _raised, 7.59, 4.87),
  ])
    (('late / $ground', (c) => c.late, g, normalText), l, d),
  (
    ('onAccent / accent', (c) => c.onAccent, (c) => c.accent, normalText),
    7.98,
    8.49,
  ),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 7.39, 8.91),
    ('surface', _surface, 7.98, 7.97),
    ('surfaceRaised', _raised, 8.39, 6.94),
  ])
    (('accent / $ground', (c) => c.accent, g, nonText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 5.22, 11.11),
    ('surface', _surface, 5.64, 9.93),
    ('surfaceRaised', _raised, 5.93, 8.65),
  ])
    (('negative / $ground', (c) => c.negative, g, nonText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 3.17, 6.43),
    ('surface', _surface, 3.43, 5.75),
    ('surfaceRaised', _raised, 3.60, 5.01),
  ])
    (('chartCommitted / $ground', (c) => c.chartCommitted, g, nonText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 3.21, 4.04),
    ('surface', _surface, 3.46, 3.61),
    ('surfaceRaised', _raised, 3.64, 3.14),
  ])
    (('border / $ground', (c) => c.border, g, nonText), l, d),
  for (final (ground, g, l, d) in [
    ('bg', _bg, 4.52, 12.24),
    ('surface', _surface, 4.88, 10.94),
    ('surfaceRaised', _raised, 5.13, 9.53),
  ])
    (('focus / $ground', (c) => c.focus, g, nonText), l, d),
];

void main() {
  for (final (theme, c, light) in [
    ('light', KalanColors.light, true),
    ('dark', KalanColors.dark, false),
  ]) {
    group('$theme theme', () {
      for (final ((name, fg, bg, min), l, d) in pairs) {
        test('$name ≥ $min', () {
          final ratio = contrast(fg(c), bg(c));
          expect(ratio, greaterThanOrEqualTo(min));
          // Matches the table in docs/DESIGN_TOKENS.md.
          expect(ratio, closeTo(light ? l : d, 0.01));
        });
      }

      // Pairs the theme uses that the table does not list.
      test('bg on text (snackbar, selected controls) ≥ $normalText', () {
        expect(contrast(c.bg, c.text), greaterThanOrEqualTo(normalText));
      });
      test('scheme onError on error ≥ $normalText', () {
        final scheme =
            (light ? KalanTheme.light() : KalanTheme.dark()).colorScheme;
        expect(
          contrast(scheme.onError, scheme.error),
          greaterThanOrEqualTo(normalText),
        );
      });
    });
  }

  test('the table covers 31 pairs', () => expect(pairs, hasLength(31)));
}
