import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_reminder.dart';
import '../../core/date/local_date.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import 'backup_prefs.dart';

/// The calm backup note (Roadmap 29), or null when it does not show:
/// [backupNoteDue] with today, this device's last full backup and the
/// first plan saved. Never a notification.
final backupNoteProvider = Provider<({LocalDate? lastBackup})?>((ref) {
  final prefs = ref.watch(backupPrefsProvider);
  final today = ref.watch(todayProvider);
  final plans = ref.watch(plansProvider).value ?? const [];
  LocalDate? first;
  for (final p in plans) {
    final day = LocalDate.fromDateTime(p.plan.createdAt.toLocal());
    if (first == null || day.compareTo(first) < 0) first = day;
  }
  final due = backupNoteDue(
    enabled: prefs.reminderEnabled,
    today: today,
    lastBackup: prefs.lastFullBackup,
    firstPlanSaved: first,
  );
  return due ? (lastBackup: prefs.lastFullBackup) : null;
});

/// "Last backup was 3 months ago." or "No backup yet."
String backupNoteText(
  BuildContext context,
  LocalDate? lastBackup,
  LocalDate today,
) => lastBackup == null
    ? context.l10n.lastBackupNone
    : context.l10n.backupNoteMonths(monthsSince(lastBackup, today));

/// The note as one tappable line: opens the full backup.
class BackupNote extends ConsumerWidget {
  const BackupNote({super.key, this.withoutBackup = true});

  /// Whether "No backup yet." shows too (Settings already says it on the
  /// "Last backup" row).
  final bool withoutBackup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(backupNoteProvider);
    if (note == null || (note.lastBackup == null && !withoutBackup)) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.textMuted);
    return ListTile(
      key: const ValueKey('backup-note'),
      leading: Icon(Icons.info_outline, color: colors.textMuted),
      title: Text(
        backupNoteText(context, note.lastBackup, ref.watch(todayProvider)),
        style: muted,
      ),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: () => unawaited(context.push(Routes.export(backup: true))),
    );
  }
}

/// Settings > Data: "Export", "Last backup" and "Backup reminder".
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.textMuted);
    final prefs = ref.watch(backupPrefsProvider);
    final last = prefs.lastFullBackup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.settingsDataSection),
        ListTile(
          key: const ValueKey('settings-export'),
          title: Text(l10n.exportTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(context.push(Routes.export())),
        ),
        ListTile(
          key: const ValueKey('settings-last-backup'),
          title: Text(l10n.settingsLastBackup),
          subtitle: Text(
            last == null ? l10n.lastBackupNone : context.longDate(last),
            style: muted,
          ),
          onTap: () => unawaited(context.push(Routes.export(backup: true))),
        ),
        const BackupNote(
          key: ValueKey('settings-backup-note'),
          withoutBackup: false,
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('settings-backup-reminder'),
          title: Text(l10n.backupReminder),
          subtitle: Text(
            l10n.backupReminderHint,
            style: muted,
          ),
          value: prefs.reminderEnabled,
          onChanged: (v) =>
              unawaited(ref.read(backupPrefsProvider.notifier).setReminder(v)),
        ),
      ],
    );
  }
}
