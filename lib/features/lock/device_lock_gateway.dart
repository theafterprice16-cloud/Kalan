import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// How the phone's own authentication ended.
enum DeviceAuthResult {
  /// Face, fingerprint or the phone's passcode matched.
  success,

  /// Cancelled, failed, timed out or interrupted: Kalan stays as it is.
  failed,

  /// The phone has no screen lock (no passcode, so nothing to ask).
  noScreenLock,

  /// The phone could not show its check at all (no window for it, broken
  /// sensor and no passcode fallback, an unknown error).
  unavailable,
}

/// The words the system dialog shows (from the ARB files).
class DeviceAuthTexts {
  const DeviceAuthTexts({
    required this.reason,
    required this.title,
    required this.hint,
    required this.cancel,
  });

  /// Why Kalan asks: iOS Touch ID and the Android dialog's description.
  final String reason;

  /// Android dialog title.
  final String title;

  /// Android dialog subtitle.
  final String hint;

  /// Android cancel button (shown only if the phone offers no passcode).
  final String cancel;
}

/// The phone's own authentication (Face ID, Touch ID, fingerprint or the
/// phone's passcode) behind an interface, so the lock's rules are tested
/// without a device. Kalan never sees biometric data: it only learns
/// whether the phone said yes.
abstract interface class DeviceLockGateway {
  /// Whether this platform offers the app lock at all (phones only).
  bool get supported;

  /// Whether the phone has a screen lock (a passcode, PIN or pattern;
  /// biometrics need one too).
  Future<bool> hasScreenLock();

  /// Asks the phone: biometrics first, the phone's passcode as fallback.
  Future<DeviceAuthResult> authenticate(DeviceAuthTexts texts);

  /// Hides Kalan in the app switcher (iOS: before the snapshot; Android
  /// 13+: no recents screenshot). Screenshots stay allowed.
  Future<void> setAppSwitcherCover({required bool on});
}

/// Web, desktop and tests: no app lock.
class UnsupportedDeviceLock implements DeviceLockGateway {
  const UnsupportedDeviceLock();

  @override
  bool get supported => false;

  @override
  Future<bool> hasScreenLock() async => false;

  @override
  Future<DeviceAuthResult> authenticate(DeviceAuthTexts texts) async =>
      DeviceAuthResult.noScreenLock;

  @override
  Future<void> setAppSwitcherCover({required bool on}) async {}
}

/// Flutter's official local_auth plugin. No network, no stored data.
class LocalAuthDeviceLock implements DeviceLockGateway {
  LocalAuthDeviceLock([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  static const _system = MethodChannel('kalan/system');

  /// Codes after which asking again can work: the user cancelled, looked
  /// away, or the system interrupted. Kalan stays locked; "Unlock" asks
  /// again. Every other code means the check cannot be shown.
  static const _tryAgain = {
    LocalAuthExceptionCode.userCanceled,
    LocalAuthExceptionCode.systemCanceled,
    LocalAuthExceptionCode.timeout,
    LocalAuthExceptionCode.authInProgress,
    LocalAuthExceptionCode.temporaryLockout,
    LocalAuthExceptionCode.biometricLockout,
    LocalAuthExceptionCode.userRequestedFallback,
  };

  @override
  bool get supported => true;

  @override
  Future<bool> hasScreenLock() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<DeviceAuthResult> authenticate(DeviceAuthTexts texts) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: texts.reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: texts.title,
            signInHint: texts.hint,
            cancelButton: texts.cancel,
          ),
        ],
        // Face or fingerprint first; the phone's passcode when they fail
        // or are not set up.
        biometricOnly: false,
        // Opening an app is not a payment: no extra confirm tap.
        sensitiveTransaction: false,
      );
      return ok ? DeviceAuthResult.success : DeviceAuthResult.failed;
    } on LocalAuthException catch (e) {
      if (!await hasScreenLock()) return DeviceAuthResult.noScreenLock;
      return _tryAgain.contains(e.code)
          ? DeviceAuthResult.failed
          : DeviceAuthResult.unavailable;
    } on PlatformException {
      if (!await hasScreenLock()) return DeviceAuthResult.noScreenLock;
      return DeviceAuthResult.unavailable;
    }
  }

  @override
  Future<void> setAppSwitcherCover({required bool on}) async {
    try {
      await _system.invokeMethod<void>('setAppSwitcherCover', on);
    } on MissingPluginException {
      // An older native side: the Flutter cover still hides the content.
    } on PlatformException {
      // Same.
    }
  }
}

/// Overridden in main() on phones with [LocalAuthDeviceLock].
final deviceLockGatewayProvider = Provider<DeviceLockGateway>(
  (ref) => const UnsupportedDeviceLock(),
);
