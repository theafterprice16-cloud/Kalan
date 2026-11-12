import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the System / Light / Dark choice is kept. Kept out of the
/// database on purpose: it is a display preference, not user data.
abstract interface class ThemeModeStore {
  ThemeMode read();
  Future<void> write(ThemeMode mode);
}

const _key = 'themeMode';

/// On-device key-value storage. No network.
class PrefsThemeModeStore implements ThemeModeStore {
  PrefsThemeModeStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsThemeModeStore> open() async => PrefsThemeModeStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {_key}),
    ),
  );

  @override
  ThemeMode read() => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_key),
    orElse: () => ThemeMode.system,
  );

  @override
  Future<void> write(ThemeMode mode) => _prefs.setString(_key, mode.name);
}

/// Used in tests and until the real store is provided.
class MemoryThemeModeStore implements ThemeModeStore {
  MemoryThemeModeStore([this._mode = ThemeMode.system]);

  ThemeMode _mode;

  @override
  ThemeMode read() => _mode;

  @override
  Future<void> write(ThemeMode mode) async => _mode = mode;
}

/// Overridden in main() with [PrefsThemeModeStore].
final themeModeStoreProvider = Provider<ThemeModeStore>(
  (ref) => MemoryThemeModeStore(),
);

/// The chosen theme; follows the system by default.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeStoreProvider).read();

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeStoreProvider).write(mode);
  }
}
