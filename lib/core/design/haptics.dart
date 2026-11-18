import 'package:flutter/services.dart';

/// The only way screens make the phone vibrate. Light and rare: never on
/// errors, warnings or ordinary taps.
abstract final class KalanHaptics {
  /// A choice changed (picker, segmented choice).
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// A payment was marked paid, or a plan or recurring payment was saved.
  static Future<void> success() => HapticFeedback.lightImpact();
}
