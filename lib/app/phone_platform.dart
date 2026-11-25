import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Whether an iOS [version] (as `Platform.operatingSystemVersion` gives
/// it, "Version 17.2 (Build 21C62)") has Lock Screen widgets: iOS 16 and
/// later. An unreadable version counts as new enough.
bool lockScreenOsSupported(String version) {
  final major = RegExp(r'(\d+)\.\d+').firstMatch(version);
  return major == null || int.parse(major[1]!) >= 16;
}

/// Whether this phone has Kalan's Lock Screen widget (Roadmap 32): an
/// iPhone on iOS 16 or later (product owner's decision 1: iOS only).
/// Decided here, once, outside the screens; they read it from the widget
/// gateway.
bool get phoneHasLockScreenWidget =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.iOS &&
    lockScreenOsSupported(Platform.operatingSystemVersion);
