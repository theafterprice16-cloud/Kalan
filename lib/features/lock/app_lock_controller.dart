import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/locale.dart';
import '../../app/providers.dart';
import '../../core/lock/app_lock_machine.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_lock_store.dart';
import 'device_lock_gateway.dart';

/// What the screen needs to know about the app lock.
@immutable
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.delay,
    required this.locked,
    required this.covered,
    required this.authenticating,
    required this.notice,
  });

  /// "App lock" is on.
  final bool enabled;
  final RelockDelay delay;

  /// The lock screen is up; nothing else shows.
  final bool locked;

  /// Kalan is not in front (app switcher, notification shade): the
  /// content is covered with the ground and the logo.
  final bool covered;

  /// The phone's own authentication dialog is open.
  final bool authenticating;

  /// Kalan turned its own lock off (Settings says why, once).
  final AppLockNotice? notice;
}

/// Turning the lock on.
enum AppLockEnableResult {
  /// On: the phone said yes.
  enabled,

  /// Cancelled or failed: the switch stays off.
  cancelled,

  /// The phone has no screen lock: the switch cannot be turned on.
  needsScreenLock,
}

/// The clock the lock counts with; tests move a fake one.
final lockClockProvider = Provider<LockClock>((ref) => SystemLockClock());

/// Whether Kalan is in front and active right now; tests override it.
final appIsActiveProvider = Provider<bool Function()>(
  (ref) =>
      () => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
);

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

/// The app lock (Roadmap 27). Fed by KalanApp's lifecycle listener; asks
/// the phone through [DeviceLockGateway]. The lock never shuts the user
/// out: with no screen lock on the phone it turns itself off.
class AppLockController extends Notifier<AppLockState> {
  late AppLockMachine _machine;
  late AppLockStore _store;
  late DeviceLockGateway _gateway;
  bool _covered = false;
  AppLockNotice? _notice;

  /// The lock screen asks by itself once each time it comes up (a cold
  /// start, a new lock, a return to it from the background).
  bool _promptPending = false;
  bool _started = false;

  @override
  AppLockState build() {
    _store = ref.watch(appLockStoreProvider);
    _gateway = ref.watch(deviceLockGatewayProvider);
    final saved = _store.read();
    final enabled = saved.enabled && _gateway.supported;
    _machine = AppLockMachine(
      clock: ref.watch(lockClockProvider),
      enabled: enabled,
      delay: saved.delay,
    );
    _notice = saved.notice;
    _promptPending = enabled;
    return _snapshot();
  }

  AppLockState _snapshot() => AppLockState(
    enabled: _machine.enabled,
    delay: _machine.delay,
    locked: _machine.locked,
    covered: _covered,
    authenticating: _machine.authenticating,
    notice: _notice,
  );

  void _emit() => state = _snapshot();

  /// After the first frame: a locked cold start checks that the phone
  /// still has a screen lock, then asks.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!_machine.enabled) return;
    unawaited(_gateway.setAppSwitcherCover(on: true));
    if (!await _gateway.hasScreenLock()) {
      await _turnOff(AppLockNotice.noScreenLock);
      return;
    }
    if (ref.read(appIsActiveProvider)()) await _autoPrompt();
  }

  // Lifecycle (KalanApp's AppLifecycleListener).

  /// Kalan lost focus (app switcher, notification shade, a call).
  void appInactive() {
    if (!_machine.enabled || _machine.authenticating || _covered) return;
    _covered = true;
    _emit();
  }

  /// Kalan left the screen.
  void appHidden() {
    _machine.hidden();
    appInactive();
  }

  /// Kalan is back on screen (not yet active).
  void appShown() {
    if (_machine.shown()) {
      _promptPending = true;
      // A field focused before the lock keeps no keyboard over it.
      FocusManager.instance.primaryFocus?.unfocus();
      _emit();
    }
  }

  /// Kalan is in front and active again.
  Future<void> appResumed() async {
    if (_covered) {
      _covered = false;
      _emit();
    }
    if (_started) await _autoPrompt();
  }

  Future<void> _autoPrompt() async {
    if (!_promptPending || !_machine.locked) return;
    _promptPending = false;
    await unlock();
  }

  /// "Unlock" (and the lock screen's own first ask). Never shuts the
  /// user out: with no screen lock, or a check the phone cannot show,
  /// Kalan opens and turns its lock off.
  Future<void> unlock() async {
    if (!_machine.locked || _machine.authenticating) return;
    _promptPending = false;
    // The screen lock may have gone while Kalan was in the background.
    _machine.beginAuth();
    final hasLock = await _gateway.hasScreenLock();
    _machine.endAuth(success: false);
    if (!hasLock) {
      await _turnOff(AppLockNotice.noScreenLock);
      return;
    }
    final result = await _ask(_texts().unlock);
    _machine.endAuth(success: result == DeviceAuthResult.success);
    switch (result) {
      case DeviceAuthResult.noScreenLock:
        await _turnOff(AppLockNotice.noScreenLock);
      case DeviceAuthResult.unavailable:
        await _turnOff(AppLockNotice.unavailable);
      case DeviceAuthResult.success || DeviceAuthResult.failed:
        _emit();
    }
  }

  /// The switch in Settings: on only after the phone says yes.
  Future<AppLockEnableResult> enable() async {
    if (_machine.enabled || _machine.authenticating) {
      return _machine.enabled
          ? AppLockEnableResult.enabled
          : AppLockEnableResult.cancelled;
    }
    if (!await _gateway.hasScreenLock()) {
      return AppLockEnableResult.needsScreenLock;
    }
    final result = await _ask(_texts().enable);
    _machine.endAuth(success: false);
    switch (result) {
      case DeviceAuthResult.success:
        _machine.enable(_machine.delay);
        _notice = null;
        await _save();
        unawaited(_gateway.setAppSwitcherCover(on: true));
        _emit();
        return AppLockEnableResult.enabled;
      case DeviceAuthResult.noScreenLock:
        _emit();
        return AppLockEnableResult.needsScreenLock;
      case DeviceAuthResult.failed || DeviceAuthResult.unavailable:
        _emit();
        return AppLockEnableResult.cancelled;
    }
  }

  /// The switch in Settings, off.
  Future<void> disable() async {
    if (!_machine.enabled) return;
    _machine.disable();
    _covered = false;
    await _save();
    unawaited(_gateway.setAppSwitcherCover(on: false));
    _emit();
  }

  Future<void> setDelay(RelockDelay delay) async {
    _machine.delay = delay;
    await _save();
    _emit();
  }

  /// Settings shows the "turned off" note once: reading it clears it.
  AppLockNotice? takeNotice() {
    final notice = _notice;
    if (notice == null) return null;
    _notice = null;
    unawaited(_save());
    _emit();
    return notice;
  }

  Future<DeviceAuthResult> _ask(DeviceAuthTexts texts) async {
    _machine.beginAuth();
    _emit();
    try {
      return await _gateway.authenticate(texts);
    } on Object {
      return DeviceAuthResult.failed;
    }
  }

  Future<void> _turnOff(AppLockNotice why) async {
    _machine.disable();
    _covered = false;
    _promptPending = false;
    _notice = why;
    await _save();
    unawaited(_gateway.setAppSwitcherCover(on: false));
    _emit();
  }

  Future<void> _save() => _store.write(
    AppLockSettings(
      enabled: _machine.enabled,
      delay: _machine.delay,
      notice: _notice,
    ),
  );

  /// The system dialog's words in the app's language.
  ({DeviceAuthTexts unlock, DeviceAuthTexts enable}) _texts() {
    final l10n = lookupAppLocalizations(
      appLocale(
        ref.read(settingsProvider).value?.localeCode,
        ref.read(appLocalesProvider),
      ),
    );
    DeviceAuthTexts texts(String reason, String title) => DeviceAuthTexts(
      reason: reason,
      title: title,
      hint: l10n.appLockPromptHint,
      cancel: l10n.actionCancel,
    );
    return (
      unlock: texts(l10n.appLockReason, l10n.appLockPromptTitle),
      enable: texts(l10n.appLockEnableReason, l10n.appLockEnablePromptTitle),
    );
  }
}
