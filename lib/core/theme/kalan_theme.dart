import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'kalan_colors.dart';

export 'kalan_colors.dart';

/// Flat themes derived from [KalanColors]: no gradients, no shadows, no
/// surface tint. Depth comes from bg → surface → surfaceRaised and thin
/// borders.
///
/// [KalanColors.accent] belongs to "left" only (the big number, the primary
/// button, the bar's left part), so selection controls (switches, pickers)
/// use ink ([KalanColors.text]) instead of the scheme's primary.
abstract final class KalanTheme {
  static ThemeData light() => _build(KalanColors.light, Brightness.light);
  static ThemeData dark() => _build(KalanColors.dark, Brightness.dark);

  static ColorScheme scheme(KalanColors c, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        primaryContainer: c.surfaceRaised,
        onPrimaryContainer: c.text,
        secondary: c.text,
        onSecondary: c.bg,
        secondaryContainer: c.surfaceRaised,
        onSecondaryContainer: c.text,
        tertiary: c.text,
        onTertiary: c.bg,
        error: c.late,
        // late on surfaceRaised (light, 7.59:1) and on bg (dark, 6.26:1).
        onError: brightness == Brightness.light ? c.surfaceRaised : c.bg,
        errorContainer: c.surfaceRaised,
        onErrorContainer: c.late,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.textMuted,
        surfaceDim: c.bg,
        surfaceBright: c.surfaceRaised,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surfaceRaised,
        surfaceContainerHighest: c.surfaceRaised,
        outline: c.border,
        outlineVariant: c.border,
        shadow: Colors.transparent,
        scrim: Colors.transparent,
        surfaceTint: Colors.transparent,
        inverseSurface: c.text,
        onInverseSurface: c.bg,
        inversePrimary: c.accentText,
      );

  /// Keyboard focus ring: 2 px of [KalanColors.focus], 2 px away from the
  /// control. (strokeAlign 3 puts the stroke 2–4 px outside the shape.)
  static BorderSide focusRing(KalanColors c) =>
      BorderSide(color: c.focus, width: 2, strokeAlign: 3);

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
      canvasColor: c.bg,
      cardColor: c.surface,
      dividerColor: c.border,
      shadowColor: Colors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],
    );
    final outline = BorderSide(color: c.border);
    final ring = focusRing(c);
    // A focus ring on every button; [rest] is the side when not focused.
    WidgetStateProperty<BorderSide?> sideWithRing([BorderSide? rest]) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused) ? ring : rest,
        );
    // Ink selection: filled with text, labelled with bg.
    Color selectedOr(Set<WidgetState> s, Color selected, Color rest) =>
        s.contains(WidgetState.selected) ? selected : rest;
    final raised = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: outline,
    );
    // Derive from the theme's text styles so font, size and weight stay.
    final text = base.textTheme;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: overlay(c, brightness),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
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
        indicatorShape: StadiumBorder(side: outline),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: selectedOr(s, c.text, c.textMuted)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: selectedOr(s, c.text, c.textMuted),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.text,
        unselectedLabelColor: c.textMuted,
        indicatorColor: c.text,
        dividerColor: c.border,
      ),
      // No dimming tone behind modals: raised ground and a border instead.
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        barrierColor: Colors.transparent,
        elevation: 0,
        shape: raised,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceRaised,
        modalBarrierColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          side: outline,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        focusColor: c.focus,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.textMuted,
          minimumSize: const Size(64, 48),
          elevation: 0,
        ).copyWith(side: sideWithRing()),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.surfaceRaised,
          foregroundColor: c.accentText,
          minimumSize: const Size(64, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(side: sideWithRing(outline)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accentText,
          minimumSize: const Size(64, 48),
        ).copyWith(side: sideWithRing(outline)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentText,
          minimumSize: const Size(48, 48),
        ).copyWith(side: sideWithRing()),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.text)
            .copyWith(side: sideWithRing()),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.surfaceRaised,
        checkmarkColor: c.text,
        side: outline,
        labelStyle: text.labelLarge?.copyWith(color: c.text),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.bg, c.textMuted),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, c.surfaceRaised),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, c.border),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, Colors.transparent),
        ),
        checkColor: WidgetStateProperty.all(c.bg),
        side: BorderSide(color: c.border, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, c.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.text,
        linearTrackColor: c.surfaceRaised,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.text,
        selectionHandleColor: c.text,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
        actionTextColor: c.bg,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: outline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.focus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.late),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.late, width: 2),
        ),
        floatingLabelStyle: text.bodyLarge?.copyWith(color: c.text),
        errorStyle: text.bodySmall?.copyWith(color: c.late),
        filled: true,
        fillColor: c.surfaceRaised,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.surfaceRaised,
        headerForegroundColor: c.text,
        shape: raised,
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, Colors.transparent),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? c.textMuted
              : selectedOr(s, c.bg, c.text),
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, Colors.transparent),
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.bg, c.text),
        ),
        todayBorder: BorderSide(color: c.text),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.text, Colors.transparent),
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (s) => selectedOr(s, c.bg, c.text),
        ),
        dividerColor: c.border,
        elevation: 0,
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surfaceRaised,
        shape: raised,
        elevation: 0,
        dialBackgroundColor: c.surface,
        dialHandColor: c.text,
        dialTextColor: WidgetStateColor.resolveWith(
          (s) => selectedOr(s, c.bg, c.text),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (s) => selectedOr(s, c.text, c.surface),
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (s) => selectedOr(s, c.bg, c.text),
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (s) => selectedOr(s, c.text, c.surface),
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (s) => selectedOr(s, c.bg, c.text),
        ),
        dayPeriodBorderSide: outline,
        entryModeIconColor: c.text,
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: raised,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(c.surfaceRaised),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          side: WidgetStateProperty.all(outline),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.textMuted),
    );
  }
}
