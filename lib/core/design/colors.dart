import 'dart:ui';

/// Brand palette from the identity file (B · Görsel yön).
abstract final class KalanColors {
  /// Mürekkep: primary dark, text, icon ground.
  static const ink = Color(0xFF14213D);

  /// Kalan yeşili: the "left" number on dark, accent fills.
  static const green = Color(0xFF23B58E);

  /// Koyu yeşil: green text and buttons on light grounds.
  static const darkGreen = Color(0xFF127A5F);

  /// Kehribar: upcoming payment, attention.
  static const amber = Color(0xFFF2A541);

  /// Mercan: only for a period that goes negative.
  static const coral = Color(0xFFE4572E);

  /// Kâğıt: light ground.
  static const paper = Color(0xFFF7F5F0);

  /// Duman: secondary text on light.
  static const smoke = Color(0xFF5F6880);

  // Derived neutrals (not brand colors).
  static const white = Color(0xFFFFFFFF);
  static const lineLight = Color(0xFFDDD9CF);
  static const badgeLight = Color(0xFFE9E6DE);

  /// Dark mode: cards one tone lighter than ink.
  static const inkRaised = Color(0xFF1E2C4D);
  static const inkHigh = Color(0xFF283862);
  static const lineDark = Color(0xFF3A4A6B);

  /// Secondary text on ink (smoke is unreadable there).
  static const smokeLight = Color(0xFFA3ABBF);
}
