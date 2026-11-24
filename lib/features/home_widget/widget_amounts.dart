import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where "Show amounts in widget" (Roadmap 31) is kept: on this device
/// only, outside the database, so it never travels in an export or a
/// backup file (product owner's decision 13).
abstract interface class WidgetAmountsStore {
  bool read();
  Future<void> write(bool show);
}

const widgetAmountsKey = 'widget.showAmounts';

/// On-device key-value storage. No network. Also read by the background
/// isolate that marks payments from a notification.
class PrefsWidgetAmountsStore implements WidgetAmountsStore {
  PrefsWidgetAmountsStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsWidgetAmountsStore> open() async =>
      PrefsWidgetAmountsStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {widgetAmountsKey},
          ),
        ),
      );

  /// Off unless the user turned it on.
  @override
  bool read() => _prefs.getBool(widgetAmountsKey) ?? false;

  @override
  Future<void> write(bool show) async {
    try {
      await _prefs.setBool(widgetAmountsKey, show);
    } on Object {
      // The cache took the new value first: back to what is stored.
      await _prefs.reloadCache();
      rethrow;
    }
  }
}

/// Used in tests and until the real store is provided: off.
class MemoryWidgetAmountsStore implements WidgetAmountsStore {
  MemoryWidgetAmountsStore([this._show = false]);

  bool _show;

  @override
  bool read() => _show;

  @override
  Future<void> write(bool show) async => _show = show;
}

/// Overridden in main() with [PrefsWidgetAmountsStore].
final widgetAmountsStoreProvider = Provider<WidgetAmountsStore>(
  (ref) => MemoryWidgetAmountsStore(),
);

/// "Show amounts in widget": whether the widget shows amounts while the
/// app lock is on. Has no effect while the lock is off ("Hide amounts"
/// alone decides then) and never shows an amount "Hide amounts" hides.
final widgetAmountsProvider = NotifierProvider<WidgetAmountsController, bool>(
  WidgetAmountsController.new,
);

class WidgetAmountsController extends Notifier<bool> {
  @override
  bool build() => ref.watch(widgetAmountsStoreProvider).read();

  Future<void> set(bool show) async {
    if (state == show) return;
    state = show;
    final store = ref.read(widgetAmountsStoreProvider);
    try {
      await store.write(show);
    } on Object {
      // Not saved: back to what is stored, the value the widget reads.
      if (ref.mounted) state = store.read();
    }
  }
}
