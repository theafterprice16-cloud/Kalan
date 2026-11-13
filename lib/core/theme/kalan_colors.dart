import 'package:material_ui/material_ui.dart';

/// The "Mürekkep ve Safran" palette (docs/DESIGN_TOKENS.md). The only place
/// in the app where colors are defined. Adding a color, tone or gradient
/// needs the product owner's approval first.
@immutable
class KalanColors extends ThemeExtension<KalanColors> {
  const KalanColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.negative,
    required this.negativeText,
    required this.late,
    required this.chartCommitted,
    required this.focus,
  });

  static const light = KalanColors(
    bg: Color(0xFFF5F0E6),
    surface: Color(0xFFFCF9F2),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFF8E8576),
    text: Color(0xFF1A2330),
    textMuted: Color(0xFF566070),
    accent: Color(0xFF1D4E89),
    onAccent: Color(0xFFFCF9F2),
    accentText: Color(0xFF1D4E89),
    negative: Color(0xFF8A5A00),
    negativeText: Color(0xFF7D5200),
    late: Color(0xFFA3193F),
    chartCommitted: Color(0xFFB87A0A),
    focus: Color(0xFF2D6CC8),
  );

  static const dark = KalanColors(
    bg: Color(0xFF11161D),
    surface: Color(0xFF19212B),
    surfaceRaised: Color(0xFF222C38),
    border: Color(0xFF6B7888),
    text: Color(0xFFEFE9DD),
    textMuted: Color(0xFFA8B0BB),
    accent: Color(0xFF8FB8F2),
    onAccent: Color(0xFF0D1B2E),
    accentText: Color(0xFF9CC1F5),
    negative: Color(0xFFEEC56E),
    negativeText: Color(0xFFEEC56E),
    late: Color(0xFFF7668C),
    chartCommitted: Color(0xFFC98F24),
    focus: Color(0xFFBCD6FB),
  );

  /// Screen ground (paper).
  final Color bg;

  /// Cards and lists.
  final Color surface;

  /// Dialogs, bottom sheets, raised cards, input fields, letter badges.
  final Color surfaceRaised;

  /// Dividers, input and card outlines.
  final Color border;

  /// Main text (ink).
  final Color text;

  /// Secondary text: descriptions, dates.
  final Color textMuted;

  /// Only "left": the big number, the primary button fill, the bar's left
  /// part.
  final Color accent;

  /// Text and icons on [accent] fills.
  final Color onAccent;

  /// Accent as text: links, secondary button labels.
  final Color accentText;

  /// Only when "left" is negative: the big number and the period mark,
  /// always with a minus sign and a word.
  final Color negative;

  /// The text that explains a negative period.
  final Color negativeText;

  /// Only overdue payments, errors and deletes; always with an icon or word.
  final Color late;

  /// The "spoken for" part of the bar; never text on top.
  final Color chartCommitted;

  /// Keyboard focus ring (2 px wide, 2 px gap).
  final Color focus;

  @override
  KalanColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? negative,
    Color? negativeText,
    Color? late,
    Color? chartCommitted,
    Color? focus,
  }) => KalanColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    border: border ?? this.border,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentText: accentText ?? this.accentText,
    negative: negative ?? this.negative,
    negativeText: negativeText ?? this.negativeText,
    late: late ?? this.late,
    chartCommitted: chartCommitted ?? this.chartCommitted,
    focus: focus ?? this.focus,
  );

  @override
  KalanColors lerp(KalanColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension KalanColorsX on BuildContext {
  KalanColors get colors => Theme.of(this).extension<KalanColors>()!;
}
