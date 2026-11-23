import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/date/local_date.dart';

/// The last full backup's day and the "Backup reminder" switch (Roadmap
/// 29): this device's own, outside the database, so they never travel in
/// a backup. Note: the phone's own backup (iCloud, Android auto backup)
/// may bring them to a new phone with the rest of the app's settings.
class BackupPrefs {
  const BackupPrefs({this.lastFullBackup, this.reminderEnabled = true});

  /// The local day of the last full backup that was saved or shared.
  final LocalDate? lastFullBackup;

  /// On unless turned off.
  final bool reminderEnabled;
}

abstract interface class BackupPrefsStore {
  BackupPrefs read();
  Future<void> write(BackupPrefs prefs);
}

const _lastKey = 'backup.lastFull';
const _reminderKey = 'backup.reminder';

/// On-device key-value storage. No network.
class SharedBackupPrefsStore implements BackupPrefsStore {
  SharedBackupPrefsStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedBackupPrefsStore> open() async => SharedBackupPrefsStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_lastKey, _reminderKey},
      ),
    ),
  );

  @override
  BackupPrefs read() => BackupPrefs(
    lastFullBackup: _parseDay(_prefs.getString(_lastKey)),
    reminderEnabled: _prefs.getBool(_reminderKey) ?? true,
  );

  @override
  Future<void> write(BackupPrefs prefs) async {
    try {
      final last = prefs.lastFullBackup;
      if (last == null) {
        await _prefs.remove(_lastKey);
      } else {
        await _prefs.setString(_lastKey, last.toString());
      }
      await _prefs.setBool(_reminderKey, prefs.reminderEnabled);
    } on Object {
      await _prefs.reloadCache();
      rethrow;
    }
  }
}

/// "2026-11-19"; null for anything else.
LocalDate? _parseDay(String? text) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text ?? '');
  if (m == null) return null;
  final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  if (mo < 1 || mo > 12 || d < 1 || d > LocalDate.daysInMonth(y, mo)) {
    return null;
  }
  return LocalDate(y, mo, d);
}

/// Used in tests and until the real store is provided.
class MemoryBackupPrefsStore implements BackupPrefsStore {
  MemoryBackupPrefsStore([this._prefs = const BackupPrefs()]);

  BackupPrefs _prefs;

  @override
  BackupPrefs read() => _prefs;

  @override
  Future<void> write(BackupPrefs prefs) async => _prefs = prefs;
}

/// Overridden in main() with [SharedBackupPrefsStore].
final backupPrefsStoreProvider = Provider<BackupPrefsStore>(
  (ref) => MemoryBackupPrefsStore(),
);

final backupPrefsProvider =
    NotifierProvider<BackupPrefsController, BackupPrefs>(
      BackupPrefsController.new,
    );

class BackupPrefsController extends Notifier<BackupPrefs> {
  @override
  BackupPrefs build() => ref.watch(backupPrefsStoreProvider).read();

  Future<void> _save(BackupPrefs next) async {
    state = next;
    try {
      await ref.read(backupPrefsStoreProvider).write(next);
    } on Object {
      if (ref.mounted) state = ref.read(backupPrefsStoreProvider).read();
    }
  }

  /// A full backup was saved or shared on [day].
  Future<void> backedUpOn(LocalDate day) => _save(
    BackupPrefs(lastFullBackup: day, reminderEnabled: state.reminderEnabled),
  );

  Future<void> setReminder(bool enabled) => _save(
    BackupPrefs(lastFullBackup: state.lastFullBackup, reminderEnabled: enabled),
  );
}
