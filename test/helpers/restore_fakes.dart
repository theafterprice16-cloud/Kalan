import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/features/restore/restore_service.dart';
import 'package:kalan/features/restore/restore_undo.dart';

/// The version 1 fixtures (test/fixtures, Roadmap 30).
const plainFixture = 'test/fixtures/backup_v1.json';
const encryptedFixture = 'test/fixtures/backup_v1_encrypted.json';
const fixturePasswordText = 'Pelin-şifre 1';

/// The file the picker hands over next (null: the picker was closed).
class FakePicker implements BackupFilePicker {
  FakePicker([this.file]);

  XFile? file;

  @override
  Future<XFile?> pick() async => file;

  void pickPath(String path) => file = XFile.fromData(
    File(path).readAsBytesSync(),
    name: path.split('/').last,
  );

  void pickBytes(List<int> bytes) =>
      file = XFile.fromData(Uint8List.fromList(bytes), name: 'file');
}

/// Reads like the real reader but on the spot, and opens the encrypted
/// fixture without deriving its key (a widget test's clock does not wait
/// for Argon2id): the password is compared, then the plain fixture with
/// the same content is read. Key derivation itself is tested in
/// test/features/restore_service_test.dart.
Future<BackupContents> fakeRead(BackupReadRequest request) async {
  final encrypted = File(encryptedFixture).readAsBytesSync();
  if (_same(request.bytes, encrypted)) {
    if (request.password == null) {
      throw const BackupReadException(BackupReadError.passwordNeeded);
    }
    if (request.password != fixturePasswordText) {
      throw const BackupReadException(BackupReadError.wrongPasswordOrChanged);
    }
    return readBackupBytes(File(plainFixture).readAsBytesSync());
  }
  return readBackupBytes(request.bytes);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The restore's providers for widget tests: [picker], the on-the-spot
/// reader, the safety copy in [undoDir] written on the spot.
List<Override> restoreOverrides(FakePicker picker, Directory undoDir) => [
  backupFilePickerProvider.overrideWithValue(picker),
  backupReaderProvider.overrideWithValue(fakeRead),
  undoDirectoryProvider.overrideWithValue(() async => undoDir),
  // A folder of its own: deleting a picked copy can never reach the
  // safety copy.
  pickedCopyDirectoriesProvider.overrideWithValue(
    () async => [Directory('${undoDir.path}-picked')],
  ),
  undoCopyWriterProvider.overrideWithValue(
    (data) => writeBackup(
      data,
      appVersion: '1.0.0+1',
      createdAt: DateTime.utc(2026, 11, 20, 9),
    ),
  ),
];
