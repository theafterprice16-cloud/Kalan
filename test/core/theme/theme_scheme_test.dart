import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/theme/kalan_theme.dart';
import 'package:material_ui/material_ui.dart';

/// The Material scheme is derived from the tokens, never from a seed.
void main() {
  for (final (name, theme, c) in [
    ('light', KalanTheme.light(), KalanColors.light),
    ('dark', KalanTheme.dark(), KalanColors.dark),
  ]) {
    group('$name scheme', () {
      final s = theme.colorScheme;

      test('maps to tokens', () {
        expect(s.primary, c.accent);
        expect(s.onPrimary, c.onAccent);
        expect(s.surface, c.surface);
        expect(s.onSurface, c.text);
        expect(s.onSurfaceVariant, c.textMuted);
        expect(s.outline, c.border);
        expect(s.error, c.late);
        expect(s.onError, name == 'light' ? c.surfaceRaised : c.bg);
        expect(theme.scaffoldBackgroundColor, c.bg);
        expect(theme.extension<KalanColors>(), c);
      });

      test('flat: no shadow, no tint, no dimming tone', () {
        expect(s.shadow.a, 0);
        expect(s.surfaceTint.a, 0);
        expect(s.scrim.a, 0);
        expect(theme.dialogTheme.barrierColor!.a, 0);
        expect(theme.bottomSheetTheme.modalBarrierColor!.a, 0);
        expect(theme.dialogTheme.elevation, 0);
        expect(theme.floatingActionButtonTheme.elevation, 0);
      });

      test('every color the theme uses is a token or transparent', () {
        final tokens = {
          c.bg,
          c.surface,
          c.surfaceRaised,
          c.border,
          c.text,
          c.textMuted,
          c.accent,
          c.onAccent,
          c.accentText,
          c.negative,
          c.negativeText,
          c.late,
          c.chartCommitted,
          c.focus,
          Colors.transparent,
        };
        final used = [
          s.primary,
          s.onPrimary,
          s.primaryContainer,
          s.onPrimaryContainer,
          s.secondary,
          s.onSecondary,
          s.secondaryContainer,
          s.onSecondaryContainer,
          s.tertiary,
          s.onTertiary,
          s.error,
          s.onError,
          s.errorContainer,
          s.onErrorContainer,
          s.surface,
          s.onSurface,
          s.onSurfaceVariant,
          s.surfaceDim,
          s.surfaceBright,
          s.surfaceContainerLowest,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
          s.outline,
          s.outlineVariant,
          s.inverseSurface,
          s.onInverseSurface,
          s.inversePrimary,
        ];
        for (final color in used) {
          expect(tokens, contains(color));
        }
      });

      test('focus ring: focus color, 2 px wide, 2 px away', () {
        final ring = KalanTheme.focusRing(c);
        expect(ring.color, c.focus);
        expect(ring.width, 2);
        expect(ring.strokeInset, -2); // starts 2 px outside the shape
        expect(ring.strokeOutset, 4); // ends 4 px outside
        final side = theme.filledButtonTheme.style!.side!;
        expect(side.resolve({WidgetState.focused}), ring);
        expect(side.resolve({}), isNull);
      });

      test('accent only on the primary button and FAB', () {
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          c.accent,
        );
        expect(theme.floatingActionButtonTheme.backgroundColor, c.accent);
        // Selection controls use ink, not the accent.
        expect(
          theme.switchTheme.trackColor!.resolve({WidgetState.selected}),
          c.text,
        );
      });
    });
  }
}
