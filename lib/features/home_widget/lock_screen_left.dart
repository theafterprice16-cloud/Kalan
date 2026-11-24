import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_gateway.dart';
import 'widget_sync.dart' show widgetGatewayProvider;

/// Where "Show what's left" (Roadmap 32) is kept: on this device only,
/// outside the database, so it never travels in an export or a backup
/// file (as "Show amounts in widget", 31).
abstract interface class LockScreenLeftStore {
  bool read();
  Future<void> write(bool show);
}

const lockScreenLeftKey = 'lockWidget.showLeft';

/// On-device key-value storage. No network. Also read by the background
/// isolate that marks payments from a notification.
class PrefsLockScreenLeftStore implements LockScreenLeftStore {
  PrefsLockScreenLeftStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsLockScreenLeftStore> open() async =>
      PrefsLockScreenLeftStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {lockScreenLeftKey},
          ),
        ),
      );

  /// Off unless the user turned it on (product owner's decision 2).
  @override
  bool read() => _prefs.getBool(lockScreenLeftKey) ?? false;

  @override
  Future<void> write(bool show) async {
    try {
      await _prefs.setBool(lockScreenLeftKey, show);
    } on Object {
      // The cache took the new value first: back to what is stored.
      await _prefs.reloadCache();
      rethrow;
    }
  }
}

/// Used in tests and until the real store is provided: off.
class MemoryLockScreenLeftStore implements LockScreenLeftStore {
  MemoryLockScreenLeftStore([this._show = false]);

  bool _show;

  @override
  bool read() => _show;

  @override
  Future<void> write(bool show) async => _show = show;
}

/// Overridden in main() with [PrefsLockScreenLeftStore].
final lockScreenLeftStoreProvider = Provider<LockScreenLeftStore>(
  (ref) => MemoryLockScreenLeftStore(),
);

/// Whether this phone has Kalan's Lock Screen widget: iPhone only
/// (product owner's decision 1, Roadmap 32), iOS 16 and later
/// ([WidgetGateway.lockScreen]); elsewhere neither the Pro screen nor
/// Settings mention it.
final lockScreenWidgetSupportedProvider = Provider<bool>((ref) {
  final gateway = ref.watch(widgetGatewayProvider);
  return gateway.supported && gateway.lockScreen;
});

/// "Show what's left": what's left this period on the Lock Screen widget,
/// when no amount is masked there ([lockScreenLeftShown]).
final lockScreenLeftProvider = NotifierProvider<LockScreenLeftController, bool>(
  LockScreenLeftController.new,
);

class LockScreenLeftController extends Notifier<bool> {
  @override
  bool build() => ref.watch(lockScreenLeftStoreProvider).read();

  Future<void> set(bool show) async {
    if (state == show) return;
    state = show;
    final store = ref.read(lockScreenLeftStoreProvider);
    try {
      await store.write(show);
    } on Object {
      // Not saved: back to what is stored, the value the widget reads.
      if (ref.mounted) state = store.read();
    }
  }
}
