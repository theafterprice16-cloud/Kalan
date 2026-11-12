import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.x relative luminance.
double luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const normalText = 4.5;
const largeOrIcon = 3.0;

void main() {
  group('dark theme', () {
    const c = KalanColors.dark;
    final pairs = <(String, Color, Color, double)>[
      ('text / bg', c.text, c.bg, normalText),
      ('text / surface', c.text, c.surface, normalText),
      ('text / surfaceRaised', c.text, c.surfaceRaised, normalText),
      ('textMuted / bg', c.textMuted, c.bg, normalText),
      ('textMuted / surface', c.textMuted, c.surface, normalText),
      ('textMuted / surfaceRaised', c.textMuted, c.surfaceRaised, normalText),
      ('mintText / bg', c.mintText, c.bg, normalText),
      ('mintText / surface', c.mintText, c.surface, normalText),
      ('amberText / bg', c.amberText, c.bg, normalText),
      ('amberText / surface', c.amberText, c.surface, normalText),
      ('coral / bg', c.coral, c.bg, normalText),
      ('coral / surface', c.coral, c.surface, normalText),
      ('onMint / mint', c.onMint, c.mint, normalText),
      ('bg / text (snackbar)', c.bg, c.text, normalText),
      ('mint bar / surface', c.mint, c.surface, largeOrIcon),
      ('amber bar / surface', c.amber, c.surface, largeOrIcon),
      ('chartCommitted / surface', c.chartCommitted, c.surface, largeOrIcon),
      (
        'field outline / surfaceRaised',
        c.textMuted,
        c.surfaceRaised,
        largeOrIcon,
      ),
    ];
    for (final (name, fg, bg, min) in pairs) {
      test('$name ≥ $min', () {
        expect(contrast(fg, bg), greaterThanOrEqualTo(min));
      });
    }
  });

  group('light theme', () {
    const c = KalanColors.light;
    final pairs = <(String, Color, Color, double)>[
      ('text / bg', c.text, c.bg, normalText),
      ('text / surface', c.text, c.surface, normalText),
      ('text / surfaceRaised', c.text, c.surfaceRaised, normalText),
      ('textMuted / bg', c.textMuted, c.bg, normalText),
      ('textMuted / surface', c.textMuted, c.surface, normalText),
      ('textMuted / surfaceRaised', c.textMuted, c.surfaceRaised, normalText),
      ('mintText / bg', c.mintText, c.bg, normalText),
      ('mintText / surface', c.mintText, c.surface, normalText),
      ('amberText / bg', c.amberText, c.bg, normalText),
      ('amberText / surface', c.amberText, c.surface, normalText),
      ('coral / bg', c.coral, c.bg, normalText),
      ('coral / surface', c.coral, c.surface, normalText),
      ('onMint / mint', c.onMint, c.mint, normalText),
      ('bg / text (snackbar)', c.bg, c.text, normalText),
      ('chartCommitted / surface', c.chartCommitted, c.surface, largeOrIcon),
      // Light mint and amber fills sit next to chartCommitted in the bar,
      // which also carries a text label for screen readers.
      ('mint / chartCommitted', c.mint, c.chartCommitted, largeOrIcon),
      ('amber / chartCommitted', c.amber, c.chartCommitted, largeOrIcon),
      (
        'field outline / surfaceRaised',
        c.textMuted,
        c.surfaceRaised,
        largeOrIcon,
      ),
    ];
    for (final (name, fg, bg, min) in pairs) {
      test('$name ≥ $min', () {
        expect(contrast(fg, bg), greaterThanOrEqualTo(min));
      });
    }

    test('mint is never readable as text on light grounds', () {
      expect(contrast(c.mint, c.surface), lessThan(normalText));
      expect(c.mintText, isNot(c.mint));
    });
  });

  test('reported ratios match docs/DESIGN_TOKENS.md', () {
    const d = KalanColors.dark;
    const l = KalanColors.light;
    expect(contrast(d.text, d.bg), closeTo(17.55, 0.01));
    expect(contrast(d.textMuted, d.surface), closeTo(6.92, 0.01));
    expect(contrast(d.onMint, d.mint), closeTo(10.87, 0.01));
    expect(contrast(d.coral, d.surface), closeTo(5.72, 0.01));
    expect(contrast(l.text, l.bg), closeTo(18.09, 0.01));
    expect(contrast(l.mintText, l.surface), closeTo(5.35, 0.01));
    expect(contrast(l.amberText, l.surface), closeTo(5.19, 0.01));
    expect(contrast(l.coral, l.surface), closeTo(5.46, 0.01));
    expect(contrast(l.mint, l.surface), closeTo(1.77, 0.01));
  });
}
