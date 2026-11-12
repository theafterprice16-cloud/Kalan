import 'package:material_ui/material_ui.dart';

import 'colors.dart';

/// Semantic colors that Material's scheme does not cover.
@immutable
class KalanPalette extends ThemeExtension<KalanPalette> {
  const KalanPalette({
    required this.leftAmount,
    required this.spokenForBar,
    required this.leftBar,
    required this.negative,
    required this.attention,
    required this.onAttention,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.secondaryText,
  });

  static const light = KalanPalette(
    leftAmount: KalanColors.darkGreen,
    spokenForBar: KalanColors.ink,
    leftBar: KalanColors.green,
    negative: KalanColors.coral,
    attention: KalanColors.amber,
    onAttention: KalanColors.ink,
    badgeBackground: KalanColors.badgeLight,
    badgeForeground: KalanColors.ink,
    secondaryText: KalanColors.smoke,
  );

  static const dark = KalanPalette(
    leftAmount: KalanColors.green,
    spokenForBar: KalanColors.smokeLight,
    leftBar: KalanColors.green,
    negative: KalanColors.coral,
    attention: KalanColors.amber,
    onAttention: KalanColors.ink,
    badgeBackground: KalanColors.inkHigh,
    badgeForeground: KalanColors.paper,
    secondaryText: KalanColors.smokeLight,
  );

  final Color leftAmount;
  final Color spokenForBar;
  final Color leftBar;
  final Color negative;
  final Color attention;
  final Color onAttention;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color secondaryText;

  @override
  KalanPalette copyWith({
    Color? leftAmount,
    Color? spokenForBar,
    Color? leftBar,
    Color? negative,
    Color? attention,
    Color? onAttention,
    Color? badgeBackground,
    Color? badgeForeground,
    Color? secondaryText,
  }) => KalanPalette(
    leftAmount: leftAmount ?? this.leftAmount,
    spokenForBar: spokenForBar ?? this.spokenForBar,
    leftBar: leftBar ?? this.leftBar,
    negative: negative ?? this.negative,
    attention: attention ?? this.attention,
    onAttention: onAttention ?? this.onAttention,
    badgeBackground: badgeBackground ?? this.badgeBackground,
    badgeForeground: badgeForeground ?? this.badgeForeground,
    secondaryText: secondaryText ?? this.secondaryText,
  );

  @override
  KalanPalette lerp(KalanPalette? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension KalanThemeX on BuildContext {
  KalanPalette get palette => Theme.of(this).extension<KalanPalette>()!;
}

/// Flat themes: no shadows, no gradients, no surface tint.
abstract final class KalanTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: KalanColors.darkGreen,
      onPrimary: KalanColors.white,
      secondary: KalanColors.ink,
      onSecondary: KalanColors.paper,
      // Form errors use ink plus a message; coral is reserved for a
      // negative period.
      error: KalanColors.ink,
      onError: KalanColors.paper,
      surface: KalanColors.paper,
      onSurface: KalanColors.ink,
      onSurfaceVariant: KalanColors.smoke,
      surfaceContainerLowest: KalanColors.white,
      surfaceContainerLow: KalanColors.white,
      surfaceContainer: KalanColors.white,
      surfaceContainerHigh: KalanColors.badgeLight,
      surfaceContainerHighest: KalanColors.badgeLight,
      outline: KalanColors.smoke,
      outlineVariant: KalanColors.lineLight,
      shadow: Color(0x00000000),
      scrim: Color(0x66000000),
      surfaceTint: Color(0x00000000),
      inverseSurface: KalanColors.ink,
      onInverseSurface: KalanColors.paper,
      inversePrimary: KalanColors.green,
      secondaryContainer: KalanColors.badgeLight,
      onSecondaryContainer: KalanColors.ink,
      primaryContainer: KalanColors.badgeLight,
      onPrimaryContainer: KalanColors.ink,
    ),
    KalanPalette.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: KalanColors.green,
      onPrimary: KalanColors.ink,
      secondary: KalanColors.paper,
      onSecondary: KalanColors.ink,
      error: KalanColors.paper,
      onError: KalanColors.ink,
      surface: KalanColors.ink,
      onSurface: KalanColors.paper,
      onSurfaceVariant: KalanColors.smokeLight,
      surfaceContainerLowest: KalanColors.inkRaised,
      surfaceContainerLow: KalanColors.inkRaised,
      surfaceContainer: KalanColors.inkRaised,
      surfaceContainerHigh: KalanColors.inkHigh,
      surfaceContainerHighest: KalanColors.inkHigh,
      outline: KalanColors.smokeLight,
      outlineVariant: KalanColors.lineDark,
      shadow: Color(0x00000000),
      scrim: Color(0x99000000),
      surfaceTint: Color(0x00000000),
      inverseSurface: KalanColors.paper,
      onInverseSurface: KalanColors.ink,
      inversePrimary: KalanColors.darkGreen,
      secondaryContainer: KalanColors.inkHigh,
      onSecondaryContainer: KalanColors.paper,
      primaryContainer: KalanColors.inkHigh,
      onPrimaryContainer: KalanColors.paper,
    ),
    KalanPalette.dark,
  );

  static ThemeData _build(ColorScheme scheme, KalanPalette palette) {
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [palette],
    );
    final outline = BorderSide(color: scheme.outlineVariant);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outline,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.surfaceContainerHigh,
        surfaceTintColor: const Color(0x00000000),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
        modalElevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: scheme.surfaceContainer,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
      ),
    );
  }
}
