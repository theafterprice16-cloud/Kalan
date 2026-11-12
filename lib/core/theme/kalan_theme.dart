import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'kalan_colors.dart';

export 'kalan_colors.dart';

/// Flat themes derived from [KalanColors]: no gradients, no shadows. In the
/// dark theme depth comes from bg → surface → surfaceRaised.
abstract final class KalanTheme {
  static ThemeData light() => _build(KalanColors.light, Brightness.light);
  static ThemeData dark() => _build(KalanColors.dark, Brightness.dark);

  static ColorScheme scheme(KalanColors c, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: c.mint,
        onPrimary: c.onMint,
        primaryContainer: c.surfaceRaised,
        onPrimaryContainer: c.text,
        secondary: c.text,
        onSecondary: c.bg,
        secondaryContainer: c.surfaceRaised,
        onSecondaryContainer: c.text,
        error: c.coral,
        onError: brightness == Brightness.light ? c.surface : c.bg,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.textMuted,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surfaceRaised,
        surfaceContainerHighest: c.surfaceRaised,
        outline: c.textMuted,
        outlineVariant: c.border,
        shadow: Colors.transparent,
        scrim: c.scrim,
        surfaceTint: Colors.transparent,
        inverseSurface: c.text,
        onInverseSurface: c.bg,
        inversePrimary: brightness == Brightness.light ? c.mint : c.mintText,
      );

  /// Status and navigation bars follow the theme.
  static SystemUiOverlayStyle overlay(KalanColors c, Brightness brightness) {
    final icons = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: brightness,
      systemNavigationBarColor: c.surface,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarDividerColor: c.border,
    );
  }

  static ThemeData _build(KalanColors c, Brightness brightness) {
    final scheme = KalanTheme.scheme(c, brightness);
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],
    );
    final outline = BorderSide(color: c.border);
    // Derive from the theme's text styles so font, size and weight stay.
    final text = base.textTheme;
    final mintTextStyle = text.bodyLarge?.copyWith(color: c.mintText);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay(c, brightness),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outline,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        indicatorColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.mintText,
        unselectedLabelColor: c.textMuted,
        indicatorColor: c.mintText,
        dividerColor: c.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        barrierColor: c.scrim,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBarrierColor: c.scrim,
        elevation: 0,
        modalElevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.mint,
        foregroundColor: c.onMint,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.mint,
          foregroundColor: c.onMint,
          minimumSize: const Size(64, 48),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.mintText,
          side: BorderSide(color: c.textMuted),
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.mintText,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.text),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.surfaceRaised,
        checkmarkColor: c.mintText,
        side: outline,
        labelStyle: text.labelLarge?.copyWith(color: c.text),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onMint : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.mint : c.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.all(c.textMuted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.mintText),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.mintText,
        selectionHandleColor: c.mintText,
        selectionColor: c.mint.withValues(alpha: 0.4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
        actionTextColor: brightness == Brightness.light ? c.mint : c.mintText,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.textMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.mintText, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.coral, width: 2),
        ),
        floatingLabelStyle: mintTextStyle,
        errorStyle: text.bodySmall?.copyWith(color: c.coral),
        filled: true,
        fillColor: c.surfaceRaised,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        headerBackgroundColor: c.surface,
        headerForegroundColor: c.text,
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onMint : c.mintText,
        ),
        todayBorder: BorderSide(color: c.mintText),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(elevation: 0, color: c.surface),
      listTileTheme: ListTileThemeData(iconColor: c.textMuted),
    );
  }
}
