import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemException;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_version.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_csv.dart';
import '../../core/backup/backup_data.dart';
import '../../core/backup/backup_file.dart';
import '../../core/date/local_date.dart';
import '../../data/backup/backup_collector.dart';
import '../../l10n/generated/app_localizations.dart';
import '../reminders/reminder_providers.dart' show clockProvider;
import 'backup_prefs.dart';
import 'export_texts.dart';

/// What to export (Roadmap 29).
enum ExportKind { spreadsheet, backup }

/// How the share sheet ended.
enum ShareOutcome {
  /// Saved or sent somewhere.
  shared,

  /// Closed without choosing anything.
  dismissed,

  /// Shown, but the platform cannot tell what happened.
  unknown,
}

/// Opens the system share sheet for one file. Kalan sends nothing
/// itself: the user picks where the file goes (Files, Drive, mail…).
abstract interface class FileShareGateway {
  Future<ShareOutcome> shareFile(
    String path, {
    required String mimeType,
    Rect? origin,
  });
}

class SharePlusGateway implements FileShareGateway {
  const SharePlusGateway();

  @override
  Future<ShareOutcome> shareFile(
    String path, {
    required String mimeType,
    Rect? origin,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        // iPad shows the sheet next to the button (and needs a place).
        sharePositionOrigin: origin,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}

final fileShareGatewayProvider = Provider<FileShareGateway>(
  (ref) => const SharePlusGateway(),
);

/// The app's temporary folder (the cache on Android): files are written
/// there just for the share sheet. Overridden in tests.
final exportTempDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

/// Encrypts away from the UI isolate (key derivation takes about a
/// second by design). Overridden in tests that need it on the spot.
final backupWriterProvider =
    Provider<Future<String> Function(BackupWriteRequest)>(
      (ref) =>
          (request) => compute(writeBackupRequest, request),
    );

/// What the background isolate needs to write a backup file.
class BackupWriteRequest {
  const BackupWriteRequest({
    required this.data,
    required this.createdAt,
    this.password,
  });

  final BackupData data;
  final DateTime createdAt;

  /// Never stored or logged; dropped once the file is written.
  final String? password;
}

/// [writeBackup] for [compute].
Future<String> writeBackupRequest(BackupWriteRequest request) => writeBackup(
  request.data,
  appVersion: appVersion,
  createdAt: request.createdAt,
  password: request.password,
);

/// Where export files wait for the share sheet, in the temporary folder.
const _folder = 'kalan-export';

/// "kalan-yedek-2026-11-19.json": the app language's name, always ASCII
/// (letters, digits and hyphens) and starting with "kalan-".
String exportFileName(AppLocalizations l10n, ExportKind kind, LocalDate day) {
  final date = day.toString();
  final base = switch (kind) {
    ExportKind.spreadsheet => l10n.exportFileSpreadsheet(date),
    ExportKind.backup => l10n.exportFileBackup(date),
  };
  var ascii = base
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9-]+'), '-')
      .replaceAll(RegExp('-+'), '-');
  if (!ascii.startsWith('kalan-')) ascii = 'kalan-$ascii';
  if (!ascii.contains(date)) ascii = '$ascii-$date';
  return '$ascii.${kind == ExportKind.backup ? 'json' : 'csv'}';
}

/// Writes the chosen file, opens the share sheet and deletes the file
/// afterwards. A full backup that was saved or shared (or whose outcome
/// the platform cannot tell) becomes the "last backup"; a closed sheet
/// and a spreadsheet never do.
class ExportService {
  ExportService(this._ref);

  final Ref _ref;

  Future<ShareOutcome> export({
    required ExportKind kind,
    required AppLocalizations l10n,
    String? password,
    Rect? origin,
  }) async {
    final today = _ref.read(todayProvider);
    final data = await collectBackup(_ref.read(databaseProvider));
    if (data == null) throw StateError('No settings yet');
    final temp = await _ref.read(exportTempDirectoryProvider)();
    await cleanUpExportFiles(temp);
    final directory = Directory('${temp.path}/$_folder');
    await directory.create(recursive: true);
    final List<int> bytes;
    if (kind == ExportKind.spreadsheet) {
      bytes = utf8.encode(buildCsv(data, ExportTexts(l10n), today: today));
    } else {
      final text = await _ref.read(backupWriterProvider)(
        BackupWriteRequest(
          data: data,
          createdAt: _ref.read(clockProvider)(),
          password: password,
        ),
      );
      bytes = utf8.encode(text);
    }
    final file = File('${directory.path}/${exportFileName(l10n, kind, today)}');
    final ShareOutcome outcome;
    try {
      await file.writeAsBytes(bytes, flush: true);
      outcome = await _ref
          .read(fileShareGatewayProvider)
          .shareFile(
            file.path,
            mimeType: kind == ExportKind.backup
                ? 'application/json'
                : 'text/csv',
            origin: origin,
          );
    } finally {
      await _delete(file);
    }
    if (kind == ExportKind.backup && outcome != ShareOutcome.dismissed) {
      await _ref.read(backupPrefsProvider.notifier).backedUpOn(today);
    }
    return outcome;
  }
}

/// Deletes what an export left in the temporary folder [temp]: its own
/// files, and the copy Android's share sheet plugin keeps until its next
/// share. Run before every export and when the app starts (a receiving
/// app has long read the file by then).
Future<void> cleanUpExportFiles(Directory temp) async {
  await _deleteAll(Directory('${temp.path}/$_folder'), (_) => true);
  await _deleteAll(
    Directory('${temp.path}/share_plus'),
    (name) => name.startsWith('kalan-'),
  );
}

Future<void> _delete(File file) async {
  try {
    if (file.existsSync()) await file.delete();
  } on FileSystemException {
    // Gone already, or the folder went with the cache.
  }
}

Future<void> _deleteAll(Directory dir, bool Function(String name) which) async {
  try {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is File && which(name)) await _delete(entity);
    }
  } on FileSystemException {
    // The system may clear the cache at any time.
  }
}

final exportServiceProvider = Provider(ExportService.new);
