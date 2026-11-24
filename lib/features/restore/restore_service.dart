import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_version.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_data.dart';
import '../../core/backup/backup_file.dart';
import '../../core/backup/backup_summary.dart';
import '../../core/date/local_date.dart';
import '../../data/backup/backup_collector.dart';
import '../../data/backup/backup_restorer.dart';
import '../../data/db/app_database.dart';
import '../export/backup_prefs.dart';
import '../reminders/reminder_providers.dart';
import 'restore_undo.dart';

/// Why a restore (Roadmap 30) stopped. In every case nothing on the
/// phone changed.
enum RestoreFailure {
  /// Not a Kalan backup (a photo, another app's file).
  notABackup,

  /// From a newer Kalan: update the app first.
  newerVersion,

  /// Encrypted: the password is asked for (no message).
  passwordNeeded,

  /// Encrypted, and it does not open with this password (or the file
  /// was changed: the two cannot be told apart).
  wrongPassword,

  /// Could not be read, is larger than 50 MB, is damaged or did not go
  /// into the database.
  unreadable,

  /// The copy of the data on the phone could not be saved, so the
  /// restore did not start.
  copyFailed,
}

class RestoreException implements Exception {
  const RestoreException(this.failure);

  final RestoreFailure failure;

  @override
  String toString() => 'RestoreException(${failure.name})';
}

/// Opens the phone's own file picker for any kind of file: whether it is
/// a backup is told from its content (decision 7). Kalan reads only the
/// file the user picks.
abstract interface class BackupFilePicker {
  Future<XFile?> pick();
}

class FileSelectorPicker implements BackupFilePicker {
  const FileSelectorPicker();

  @override
  Future<XFile?> pick() => openFile();
}

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => const FileSelectorPicker(),
);

/// What the background isolate needs to read a picked file.
class BackupReadRequest {
  const BackupReadRequest(this.bytes, {this.password});

  final Uint8List bytes;

  /// Never stored or logged; dropped once the file is read.
  final String? password;
}

/// [readBackupBytes] for [compute].
Future<BackupContents> readBackupRequest(BackupReadRequest request) =>
    readBackupBytes(request.bytes, password: request.password);

/// Reads and decrypts away from the UI isolate (deriving the key takes
/// about a second by design). Overridden in tests that need it on the
/// spot.
final backupReaderProvider =
    Provider<Future<BackupContents> Function(BackupReadRequest)>(
      (ref) =>
          (request) => compute(readBackupRequest, request),
    );

/// Writes the safety copy away from the UI isolate too.
final undoCopyWriterProvider = Provider<Future<String> Function(BackupData)>((
  ref,
) {
  final clock = ref.watch(clockProvider);
  return (data) => compute(_writePlain, (data, clock()));
});

Future<String> _writePlain((BackupData, DateTime) args) =>
    writeBackup(args.$1, appVersion: appVersion, createdAt: args.$2);

/// The safety copy still offered ("Go back to previous data"), or null.
/// Waits for the start's [UndoCopyStore.tidy] first.
final undoCopyProvider = FutureProvider<UndoCopy?>((ref) async {
  final today = ref.watch(todayProvider);
  await ref.watch(undoTidyProvider.future);
  final copy = await ref.watch(undoCopyStoreProvider).info();
  if (copy == null) return null;
  return undoCopyKept(copiedOn: copy.copiedOn, today: today) ? copy : null;
});

/// Once per start: finishes a restore that stopped halfway and deletes a
/// copy older than 30 days (decision 1). Best effort: should it fail, a
/// staged copy stays and no restore starts until a later start tidies it.
final undoTidyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  try {
    await ref
        .read(undoCopyStoreProvider)
        .tidy(today: ref.read(todayProvider), sequences: () => idSequences(db));
  } on Object {
    // The next start tries again; nothing is offered meanwhile.
  }
});

/// The database's AUTOINCREMENT counters (table → last id). A restore
/// that went through counts them up (it never resets them), so the
/// safety copy records them (see [UndoCopyStore.tidy]).
Future<Map<String, int>> idSequences(AppDatabase db) async {
  try {
    final rows = await db
        .customSelect('SELECT name, seq FROM sqlite_sequence')
        .get();
    return {for (final r in rows) r.read<String>('name'): r.read<int>('seq')};
  } on Object {
    // No table has had a row yet.
    return const {};
  }
}

/// Writes a backup's data over the phone's in one transaction
/// ([restoreBackup]). Overridden in tests that force a failure halfway.
final restoreWriterProvider =
    Provider<Future<void> Function(AppDatabase, BackupData)>(
      (ref) => restoreBackup,
    );

/// Picks, reads and restores a backup (Roadmap 30), and goes back to the
/// data from before it.
class RestoreService {
  RestoreService(this._ref);

  final Ref _ref;

  /// The picked file's bytes, or null when the picker was closed (on
  /// iPhone also for a file the system could not hand over, which the
  /// picker does not tell apart). More than 50 MB is refused before Kalan
  /// reads it (on Android the system picker has already copied it by
  /// then). The copy the picker leaves in the temporary folder is deleted.
  Future<Uint8List?> pick() async {
    final XFile? file;
    try {
      file = await _ref.read(backupFilePickerProvider).pick();
    } on Object {
      throw const RestoreException(RestoreFailure.unreadable);
    }
    if (file == null) return null;
    try {
      if (await file.length() > backupMaxBytes) {
        throw const RestoreException(RestoreFailure.unreadable);
      }
      return await file.readAsBytes();
    } on RestoreException {
      rethrow;
    } on Object {
      throw const RestoreException(RestoreFailure.unreadable);
    } finally {
      try {
        if (file.path.isNotEmpty) {
          await deletePickedCopy(
            file.path,
            await _ref.read(pickedCopyDirectoryProvider)(),
          );
        }
      } on Object {
        // The system clears its cache too.
      }
    }
  }

  /// Reads and fully checks [bytes]; nothing is written.
  Future<BackupContents> read(Uint8List bytes, {String? password}) async {
    try {
      return await _ref.read(backupReaderProvider)(
        BackupReadRequest(bytes, password: password),
      );
    } on BackupReadException catch (e) {
      throw RestoreException(switch (e.error) {
        BackupReadError.notABackup => RestoreFailure.notABackup,
        BackupReadError.newerVersion => RestoreFailure.newerVersion,
        BackupReadError.passwordNeeded => RestoreFailure.passwordNeeded,
        BackupReadError.wrongPasswordOrChanged => RestoreFailure.wrongPassword,
        BackupReadError.damaged => RestoreFailure.unreadable,
      });
    } on Object {
      throw const RestoreException(RestoreFailure.unreadable);
    }
  }

  /// Whether a restore replaces data on this phone (onboarding is done):
  /// then it asks first and keeps a copy (decision 1). The pay settings
  /// alone are data the user typed.
  Future<bool> hasData() async {
    final db = _ref.read(databaseProvider);
    return await db.select(db.appSettings).getSingleOrNull() != null;
  }

  /// Puts [contents] in place of the data on this phone. "Last backup"
  /// becomes the backup's day. Returns what came back.
  Future<BackupSummary> restore(BackupContents contents) async {
    await _replace(
      contents.data,
      lastBackupAfter: LocalDate.fromDateTime(
        contents.header.createdAt.toLocal(),
      ),
    );
    return BackupSummary.of(contents.data);
  }

  /// "Go back to previous data": the safety copy goes in the same way,
  /// and the data on the phone now becomes the new copy (its 30 days
  /// start again). "Last backup" goes back to what it was then.
  Future<void> goBack() async {
    final store = _ref.read(undoCopyStoreProvider);
    final text = await store.read();
    final copy = await store.info();
    if (text == null || copy == null) {
      throw const RestoreException(RestoreFailure.unreadable);
    }
    final contents = await read(utf8.encode(text));
    await _replace(contents.data, lastBackupAfter: copy.lastFullBackup);
  }

  Future<void> _replace(
    BackupData data, {
    required LocalDate? lastBackupAfter,
  }) async {
    final db = _ref.read(databaseProvider);
    final store = _ref.read(undoCopyStoreProvider);
    final prefs = _ref.read(backupPrefsProvider);
    // A restore that stopped halfway is finished first; while its staged
    // copy is still there (it may be the only copy of the data from
    // before), no restore starts over it.
    await _ref.read(undoTidyProvider.future);
    try {
      if (await store.hasStaged()) throw StateError('staged copy');
    } on Object {
      throw const RestoreException(RestoreFailure.copyFailed);
    }
    var staged = false;
    try {
      // One transaction from the copy to the last row written, so a
      // payment marked paid from a notification meanwhile is in the copy.
      await db.transaction(() async {
        final current = await collectBackup(db);
        if (current != null) {
          // The copy first, on disk in full and able to come back;
          // without it nothing goes on.
          try {
            current.validate();
            final sequences = await idSequences(db);
            final text = await _ref.read(undoCopyWriterProvider)(current);
            await store.stage(
              UndoCopyStore.withDevice(
                text,
                prefs.lastFullBackup,
                sequences: sequences,
              ),
            );
            staged = true;
          } on Object {
            throw const RestoreException(RestoreFailure.copyFailed);
          }
        }
        await _ref.read(restoreWriterProvider)(db, data);
      });
    } on Object catch (e) {
      await _quietly(store.discard);
      throw e is RestoreException
          ? e
          : const RestoreException(RestoreFailure.unreadable);
    }
    // Should this fail, the next start finds the staged copy and keeps it.
    if (staged) await _quietly(store.commit);
    _ref.invalidate(undoCopyProvider);
    await _ref
        .read(backupPrefsProvider.notifier)
        .putBackLastBackup(lastBackupAfter);
    // Reminders follow the new payments (the database streams ask too).
    _ref.read(reminderSyncProvider).request();
  }
}

Future<void> _quietly(Future<void> Function() step) async {
  try {
    await step();
  } on Object {
    // Best effort; see UndoCopyStore.tidy.
  }
}

final restoreServiceProvider = Provider(RestoreService.new);
