/// Spacing and corner scale. Screens use these names, never bare numbers
/// (`test/app/ui_guard_test.dart` checks `lib/features`).
library;

/// Spacing steps: multiples of 4 only.
abstract final class KalanSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Room left under a list so the floating add button never covers the
  /// last row (three [xl] steps).
  static const double fabClearance = xl * 3;
}

/// Corner radii: input fields 8, cards 12, dialogs and sheets 16. Buttons
/// and indicators are stadium shaped and need no radius.
abstract final class KalanRadius {
  static const double input = 8;
  static const double card = 12;
  static const double sheet = 16;
}
