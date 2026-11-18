import 'dart:async';

import 'package:flutter/services.dart';

/// The only way screens make the phone vibrate. Light and rare: never on
/// errors, warnings or ordinary taps. Fire and forget: a phone without a
/// vibration motor simply ignores it.
abstract final class KalanHaptics {
  /// A choice changed (picker, segmented choice).
  static void selection() => unawaited(HapticFeedback.selectionClick());

  /// A payment was marked paid, or a plan or recurring payment was saved.
  static void success() => unawaited(HapticFeedback.lightImpact());
}
