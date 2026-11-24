import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/backup/backup_file.dart';
import '../../core/date/local_date.dart';

/// How long "Go back to previous data" stays (Roadmap 30, decision 1).
const undoCopyDays = 30;

/// Whether a safety copy made on [copiedOn] is still offered on [today]:
/// on the day it was made and the 29 days after; gone from the 30th day
/// on. Calendar days, so the clock and summer time play no part; a copy
/// dated in the future (the phone's clock moved back) stays.
bool undoCopyKept({required LocalDate copiedOn, required LocalDate today}) =>
    copiedOn.daysUntil(today) < undoCopyDays;

/// The one safety copy: when it was made and the "Last backup" day the
/// phone showed then (put back when the user goes back to it).
class UndoCopy {
  const UndoCopy({required this.copiedOn, required this.lastFullBackup});

  /// The local day it was made: its file's `createdAt`.
  final LocalDate copiedOn;
  final LocalDate? lastFullBackup;
}

/// Where the safety copy lives: the app's own support folder (Library/
/// Application Support on iPhone, the app's private files on Android),
/// never shown in the Files app or shared. Overridden in tests.
final undoDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getApplicationSupportDirectory,
);

/// The safety copy taken before a restore overwrites the data on this
/// phone (Roadmap 30, decision 1): a full backup file without a password,
/// written by Roadmap 29's writer, plus one field of this phone's own
/// (the "Last backup" day then; readers ignore unknown fields).
///
/// One copy at a time, replaced in two steps so a failure at any point
/// never loses the copy there was:
///
/// 1. [stage]: the new copy goes to `previous.next.json` (written to a
///    temporary name, flushed, then renamed);
/// 2. the restore's database transaction runs;
/// 3. [commit] renames it over `previous.json`; should the transaction
///    fail, [discard] deletes it and `previous.json` stays as it was.
///
/// Should the app stop between 2 and 3, [tidy] on the next start finishes
/// the job (see there).
class UndoCopyStore {
  UndoCopyStore(this._directory);

  final Future<Directory> Function() _directory;

  static const _folder = 'kalan-restore';
  static const _current = 'previous.json';
  static const _next = 'previous.next.json';
  static const _partial = 'previous.next.json.part';
  static const _deviceField = 'thisDevice';

  Future<File> _file(String name) async {
    final dir = Directory('${(await _directory()).path}/$_folder');
    await dir.create(recursive: true);
    return File('${dir.path}/$name');
  }

  /// The copy's file text with this phone's [lastFullBackup] added.
  static String withDevice(String backupText, LocalDate? lastFullBackup) {
    final json = jsonDecode(backupText) as Map<String, Object?>;
    json[_deviceField] = {'lastFullBackup': lastFullBackup?.toString()};
    return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
  }

  /// Writes [text] as the copy waiting for its restore. Throws when it
  /// cannot be written in full; then the restore must not go on.
  Future<void> stage(String text) async {
    final partial = await _file(_partial);
    await partial.writeAsString(text, flush: true);
    await partial.rename((await _file(_next)).path);
  }

  /// The restore went through: the staged copy becomes the copy.
  Future<void> commit() async {
    final next = await _file(_next);
    await next.rename((await _file(_current)).path);
  }

  /// The restore did not go through: the staged copy goes, the copy
  /// there was stays.
  Future<void> discard() async {
    await _delete(await _file(_next));
    await _delete(await _file(_partial));
  }

  /// The copy's file text, or null when there is none.
  Future<String?> read() => _readText(_current);

  /// What [read] holds, or null when there is none or it does not read.
  Future<UndoCopy?> info() async {
    final text = await read();
    return text == null ? null : _info(text);
  }

  /// Once per start, before the copy is offered:
  ///
  /// - a staged copy left by a restore that stopped halfway: if the data
  ///   on the phone is still what it copied ([currentData], the data
  ///   object of a backup of the phone now), the restore never happened
  ///   and the staged copy goes; otherwise the restore went through and
  ///   it becomes the copy;
  /// - a copy older than [undoCopyDays] days on [today] is deleted, and
  ///   so is one that does not read.
  Future<void> tidy({
    required LocalDate today,
    required Future<Object?> Function() currentData,
  }) async {
    await _delete(await _file(_partial));
    final staged = await _readText(_next);
    if (staged != null) {
      Object? stagedData;
      try {
        stagedData = (jsonDecode(staged) as Map<String, Object?>)['data'];
      } on Object {
        stagedData = null;
      }
      final now = await currentData();
      if (stagedData != null &&
          now != null &&
          jsonEncode(stagedData) == jsonEncode(now)) {
        await discard();
      } else {
        await commit();
      }
    }
    final copy = await info();
    if (copy == null || !undoCopyKept(copiedOn: copy.copiedOn, today: today)) {
      await _delete(await _file(_current));
    }
  }

  static UndoCopy? _info(String text) {
    try {
      final header = readBackupHeader(text);
      final json = jsonDecode(text) as Map<String, Object?>;
      final device = json[_deviceField];
      final last = device is Map<String, Object?>
          ? device['lastFullBackup']
          : null;
      return UndoCopy(
        copiedOn: LocalDate.fromDateTime(header.createdAt.toLocal()),
        lastFullBackup: last is String ? _parseDay(last) : null,
      );
    } on Object {
      return null;
    }
  }

  Future<String?> _readText(String name) async {
    final file = await _file(name);
    try {
      if (!file.existsSync()) return null;
      return await file.readAsString();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static Future<void> _delete(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Gone already.
    }
  }
}

/// "2026-11-19"; null for anything else.
LocalDate? _parseDay(String text) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (m == null) return null;
  final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  if (mo < 1 || mo > 12 || d < 1 || d > LocalDate.daysInMonth(y, mo)) {
    return null;
  }
  return LocalDate(y, mo, d);
}

final undoCopyStoreProvider = Provider(
  (ref) => UndoCopyStore(ref.watch(undoDirectoryProvider)),
);
