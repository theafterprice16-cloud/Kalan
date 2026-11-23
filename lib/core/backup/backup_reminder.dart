/// The calm backup note (Roadmap 29): Settings and the bottom of the home
/// screen say when the last full backup is getting old. Never a
/// notification. Pure Dart.
library;

import '../date/local_date.dart';

/// Days after the first plan was saved before the first note, when there
/// is no backup yet.
const firstBackupNoteAfterDays = 30;

/// Days after the last full backup before the note.
const backupNoteAfterDays = 90;

/// Whether the note shows on [today]: the switch is on, and either the
/// last full backup was [backupNoteAfterDays] or more days ago, or there
/// is none and the first plan was saved [firstBackupNoteAfterDays] or
/// more days ago. Whole calendar days (no clock, no daylight saving); a
/// date after [today] (a clock set back) shows nothing.
bool backupNoteDue({
  required bool enabled,
  required LocalDate today,
  required LocalDate? lastBackup,
  required LocalDate? firstPlanSaved,
}) {
  if (!enabled) return false;
  if (lastBackup != null) {
    return lastBackup.daysUntil(today) >= backupNoteAfterDays;
  }
  return firstPlanSaved != null &&
      firstPlanSaved.daysUntil(today) >= firstBackupNoteAfterDays;
}

/// "Last backup was 3 months ago": whole months of 30 days since
/// [lastBackup] (91 days → 3).
int monthsSince(LocalDate lastBackup, LocalDate today) =>
    lastBackup.daysUntil(today) ~/ 30;
