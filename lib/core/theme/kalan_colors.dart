import 'package:material_ui/material_ui.dart';

/// The "Gece & Nane" palette (docs/DESIGN_TOKENS.md). The only place in the
/// app where colors are defined. Adding a color, tone or gradient needs the
/// product owner's approval first.
@immutable
class KalanColors extends ThemeExtension<KalanColors> {
  const KalanColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.mint,
    required this.onMint,
    required this.mintText,
    required this.amber,
    required this.amberText,
    required this.coral,
    required this.chartCommitted,
  });

  static const dark = KalanColors(
    bg: Color(0xFF0B0F14),
    surface: Color(0xFF151B23),
    surfaceRaised: Color(0xFF1E2630),
    border: Color(0xFF2A3441),
    text: Color(0xFFF2F5F7),
    textMuted: Color(0xFF9AA5B1),
    mint: Color(0xFF3DDC97),
    onMint: Color(0xFF0B0F14),
    mintText: Color(0xFF3DDC97),
    amber: Color(0xFFFFB547),
    amberText: Color(0xFFFFB547),
    coral: Color(0xFFFF5C5C),
    chartCommitted: Color(0xFF6B7684),
  );

  static const light = KalanColors(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEEF1F4),
    border: Color(0xFFDDE2E8),
    text: Color(0xFF0B0F14),
    textMuted: Color(0xFF5B6673),
    // Never text on light grounds (1.66:1); fills with onMint text only.
    mint: Color(0xFF3DDC97),
    onMint: Color(0xFF0B0F14),
    mintText: Color(0xFF0E7A53),
    amber: Color(0xFFFFB547),
    amberText: Color(0xFFA15C00),
    coral: Color(0xFFC62F2F),
    chartCommitted: Color(0xFF5B6673),
  );

  /// Screen ground.
  final Color bg;

  /// Cards, lists, sheets.
  final Color surface;

  /// Selected rows, input fields, letter badges.
  final Color surfaceRaised;

  /// Thin dividers and card outlines; decoration only.
  final Color border;
  final Color text;

  /// Secondary text: dates, descriptions.
  final Color textMuted;

  /// "Left" accent fills, primary buttons, the ring's bright segment.
  final Color mint;

  /// Text and icons on [mint] fills.
  final Color onMint;

  /// Mint as text: the big "left" number, links.
  final Color mintText;

  /// Fill when "left" goes negative; warning badges.
  final Color amber;

  /// Amber as text: a negative "left", warning text.
  final Color amberText;

  /// Only overdue payments, errors and irreversible deletes.
  final Color coral;

  /// The "spoken for" part of the period bar.
  final Color chartCommitted;

  /// Modal barrier: the ground at partial opacity (not a new tone).
  Color get scrim => bg.withValues(alpha: 0.6);

  @override
  KalanColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? mint,
    Color? onMint,
    Color? mintText,
    Color? amber,
    Color? amberText,
    Color? coral,
    Color? chartCommitted,
  }) => KalanColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    border: border ?? this.border,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    mint: mint ?? this.mint,
    onMint: onMint ?? this.onMint,
    mintText: mintText ?? this.mintText,
    amber: amber ?? this.amber,
    amberText: amberText ?? this.amberText,
    coral: coral ?? this.coral,
    chartCommitted: chartCommitted ?? this.chartCommitted,
  );

  @override
  KalanColors lerp(KalanColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension KalanColorsX on BuildContext {
  KalanColors get colors => Theme.of(this).extension<KalanColors>()!;
}
