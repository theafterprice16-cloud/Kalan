import 'package:shared_preferences/shared_preferences.dart';

import 'pro_rules.dart';

/// Where the last known Pro state is kept. Outside the database on
/// purpose: a store event can arrive before onboarding (reinstall, Ask to
/// Buy, family sharing), when there is no settings row yet; and Pro is not
/// user data, so it never goes into an export or a backup.
abstract interface class ProStatusStore {
  ProStatus read();
  Future<void> write(ProStatus status);
}

const _key = 'pro.status';

/// On-device key-value storage, read once at start. No network.
class PrefsProStatusStore implements ProStatusStore {
  PrefsProStatusStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsProStatusStore> open() async => PrefsProStatusStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {_key}),
    ),
  );

  @override
  ProStatus read() => proStatusFromName(_prefs.getString(_key));

  @override
  Future<void> write(ProStatus status) => _prefs.setString(_key, status.name);
}

/// Anything unreadable counts as free; the store check at start fixes it.
ProStatus proStatusFromName(String? name) => ProStatus.values.firstWhere(
  (s) => s.name == name,
  orElse: () => ProStatus.notPro,
);

/// Used in tests and until the real store is provided.
class MemoryProStatusStore implements ProStatusStore {
  MemoryProStatusStore([this._status = ProStatus.notPro]);

  ProStatus _status;

  @override
  ProStatus read() => _status;

  @override
  Future<void> write(ProStatus status) async => _status = status;
}
