/// Older backup files brought up to the current content model (Roadmap
/// 30). A file of format version v is read by running the steps
/// v → v+1 → … → [backupFormatVersion] on its raw `data` object, then
/// [BackupData.fromJson] reads it like a new file. Each step changes only
/// what its version changed (docs/YEDEK_BICIMI.md, "Sürüm değişikliği")
/// and leaves every other field as it is, unknown ones included.
///
/// Today there is one version, so there are no steps. When version 2
/// comes: bump [backupFormatVersion], add `1: _from1To2` below, keep the
/// committed version 1 fixtures (test/fixtures) loading, and add version
/// 2 fixtures written by the new app.
///
/// Pure Dart.
library;

import 'backup_json.dart';

/// Turns the raw content of one format version into the next one's.
/// Gets its own copy to change; throws [BackupFormatException] when the
/// content cannot be read as that version.
typedef BackupUpgradeStep = Map<String, Object?> Function(
  Map<String, Object?> data,
);

/// The step from each version to the next, by the version it reads.
const Map<int, BackupUpgradeStep> backupUpgradeSteps = {};

/// [data] (a file's raw content, format version [from]) as format
/// version [to]. A missing step, a version outside 1…[to] or content that
/// is not an object is a [BackupFormatException]: the file reads as
/// damaged and nothing is written from it.
Map<String, Object?> upgradeBackupContent(
  Object? data, {
  required int from,
  required int to,
  Map<int, BackupUpgradeStep> steps = backupUpgradeSteps,
}) {
  if (data is! Map<String, Object?>) throw const BackupFormatException('data');
  if (from < 1 || from > to) {
    throw const BackupFormatException('formatVersion');
  }
  var content = data;
  for (var v = from; v < to; v++) {
    final step = steps[v];
    if (step == null) throw const BackupFormatException('formatVersion');
    content = step(_copy(content));
  }
  return content;
}

/// A deep copy, so a step never changes what it was given.
Map<String, Object?> _copy(Map<String, Object?> map) => {
  for (final MapEntry(:key, :value) in map.entries) key: _copyValue(value),
};

Object? _copyValue(Object? value) => switch (value) {
  final Map<String, Object?> m => _copy(m),
  final List<Object?> l => [for (final v in l) _copyValue(v)],
  _ => value,
};
