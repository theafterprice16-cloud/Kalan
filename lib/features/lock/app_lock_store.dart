import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/lock/app_lock_machine.dart';

/// Why Kalan turned its own lock off; Settings says so once.
enum AppLockNotice {
  /// The phone has no screen lock any more.
  noScreenLock,

  /// The phone could not show its check at all (never a cancel or a
  /// wrong face): open rather than shut the user out.
  unavailable;

  static AppLockNotice? parse(String? name) =>
      values.where((n) => n.name == name).firstOrNull;
}

/// The app lock's stored choices (Roadmap 27).
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.delay = RelockDelay.standard,
    this.notice,
  });

  final bool enabled;
  final RelockDelay delay;
  final AppLockNotice? notice;
}

/// Where the app lock's choices are kept: on this device only, outside
/// the database, so they never travel in an export or a backup file.
abstract interface class AppLockStore {
  AppLockSettings read();
  Future<void> write(AppLockSettings settings);
}

const _enabledKey = 'appLock.enabled';
const _delayKey = 'appLock.delay';
const _noticeKey = 'appLock.notice';

/// On-device key-value storage. No network.
class PrefsAppLockStore implements AppLockStore {
  PrefsAppLockStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsAppLockStore> open() async => PrefsAppLockStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_enabledKey, _delayKey, _noticeKey},
      ),
    ),
  );

  @override
  AppLockSettings read() => AppLockSettings(
    enabled: _prefs.getBool(_enabledKey) ?? false,
    delay: RelockDelay.parse(_prefs.getString(_delayKey)),
    notice: AppLockNotice.parse(_prefs.getString(_noticeKey)),
  );

  @override
  Future<void> write(AppLockSettings settings) async {
    await _prefs.setBool(_enabledKey, settings.enabled);
    await _prefs.setString(_delayKey, settings.delay.name);
    final notice = settings.notice;
    if (notice == null) {
      await _prefs.remove(_noticeKey);
    } else {
      await _prefs.setString(_noticeKey, notice.name);
    }
  }
}

/// Used in tests and until the real store is provided: the lock is off.
class MemoryAppLockStore implements AppLockStore {
  MemoryAppLockStore([this._settings = const AppLockSettings()]);

  AppLockSettings _settings;

  @override
  AppLockSettings read() => _settings;

  @override
  Future<void> write(AppLockSettings settings) async => _settings = settings;
}

/// Overridden in main() with [PrefsAppLockStore].
final appLockStoreProvider = Provider<AppLockStore>(
  (ref) => MemoryAppLockStore(),
);
