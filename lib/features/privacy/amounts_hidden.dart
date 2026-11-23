import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminders/reminder_providers.dart';

/// Where "Hide amounts" (Roadmap 28) is kept: on this device only,
/// outside the database, so it never travels in an export or a backup
/// file. A display preference: nothing it touches is stored differently.
abstract interface class AmountsHiddenStore {
  bool read();
  Future<void> write(bool hidden);
}

const amountsHiddenKey = 'privacy.hideAmounts';

/// On-device key-value storage. No network. Also opened by the
/// background isolate that reschedules reminders.
class PrefsAmountsHiddenStore implements AmountsHiddenStore {
  PrefsAmountsHiddenStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsAmountsHiddenStore> open() async =>
      PrefsAmountsHiddenStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {amountsHiddenKey},
          ),
        ),
      );

  @override
  bool read() => _prefs.getBool(amountsHiddenKey) ?? false;

  @override
  Future<void> write(bool hidden) => _prefs.setBool(amountsHiddenKey, hidden);
}

/// Used in tests and until the real store is provided: amounts show.
class MemoryAmountsHiddenStore implements AmountsHiddenStore {
  MemoryAmountsHiddenStore([this._hidden = false]);

  bool _hidden;

  @override
  bool read() => _hidden;

  @override
  Future<void> write(bool hidden) async => _hidden = hidden;
}

/// Overridden in main() with [PrefsAmountsHiddenStore].
final amountsHiddenStoreProvider = Provider<AmountsHiddenStore>(
  (ref) => MemoryAmountsHiddenStore(),
);

/// Whether every amount the app shows is masked. The eye on the home
/// screen and the switch in Settings > Privacy change the same value;
/// the app remembers it (product owner's choice).
final amountsHiddenProvider = NotifierProvider<AmountsHiddenController, bool>(
  AmountsHiddenController.new,
);

class AmountsHiddenController extends Notifier<bool> {
  @override
  bool build() => ref.watch(privacySettingsProvider).amountsHidden;

  Future<void> set(bool hidden) async {
    if (state == hidden) return;
    state = hidden;
    try {
      await ref.read(privacySettingsProvider).setAmountsHidden(hidden);
    } on Object {
      // Not saved: the screen goes back to what is stored.
      if (ref.mounted) state = !hidden;
    }
  }

  Future<void> toggle() => set(!state);
}
