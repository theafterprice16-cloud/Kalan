import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/format.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import 'local_notifications.dart';
import 'reminder_providers.dart';
import 'reminder_settings_store.dart';
import 'repeat_mode_ui.dart';

/// "1 day before" … "7 days before", for dialogs.
List<(int, String)> leadDayOptions(BuildContext context) => [
  for (final days in leadDayChoices)
    (days, context.l10n.reminderLeadDaysValue(days)),
];

/// Settings > Reminders. With the master switch off the other rows are
/// inactive but keep their values.
class RemindersSection extends ConsumerWidget {
  const RemindersSection({required this.settings, super.key});

  final SettingsRow settings;

  Future<void> _setEnabled(WidgetRef ref, bool on) async {
    final store = ref.read(reminderSettingsStoreProvider);
    if (on) {
      await ref.read(notificationGatewayProvider).requestPermission();
      await store.markPromptShown();
      ref.invalidate(notificationPermissionProvider);
    }
    await store.setEnabled(on);
  }

  Future<void> _pickLeadDays(BuildContext context, WidgetRef ref) async {
    final picked = await showChoiceDialog<int>(
      context,
      title: context.l10n.reminderLeadDays,
      selected: settings.reminderLeadDays,
      options: leadDayOptions(context),
    );
    if (picked == null) return;
    await ref.read(reminderSettingsStoreProvider).setLeadDays(picked.value);
  }

  Future<void> _pickRepeat(BuildContext context, WidgetRef ref) async {
    final picked = await showChoiceDialog<ReminderRepeat>(
      context,
      title: context.l10n.repeatReminders,
      selected: settings.repeatMode,
      note: context.l10n.repeatRemindersHelp,
      options: repeatModeOptions(context),
    );
    if (picked == null) return;
    await ref.read(reminderSettingsStoreProvider).setRepeatMode(picked.value);
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final minute = settings.reminderMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null) return;
    await ref
        .read(reminderSettingsStoreProvider)
        .setMinuteOfDay(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final gateway = ref.watch(notificationGatewayProvider);
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.textMuted);

    if (!gateway.supported) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(l10n.settingsReminders),
          ListTile(
            key: const ValueKey('reminders-web-only'),
            title: Text(l10n.remindersEnabled),
            subtitle: Text(l10n.remindersWebOnly, style: muted),
          ),
        ],
      );
    }

    final reminders = settings.reminderSettings;
    final on = reminders.enabled;
    final permission = ref.watch(notificationPermissionProvider).value;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(
        hour: reminders.minuteOfDay ~/ 60,
        minute: reminders.minuteOfDay % 60,
      ),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final privacy = ref.read(privacySettingsProvider);
    final pickLeadDays = on ? () => _pickLeadDays(context, ref) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.settingsReminders),
        if (permission == false)
          ListTile(
            key: const ValueKey('permission-status'),
            leading: Icon(Icons.notifications_off_outlined, color: colors.text),
            title: Text(l10n.remindersPermissionOff),
            trailing: TextButton(
              key: const ValueKey('open-settings'),
              onPressed: gateway.openSystemSettings,
              child: Text(l10n.openPhoneSettings),
            ),
          ),
        SwitchListTile.adaptive(
          key: const ValueKey('reminders-enabled'),
          title: Text(l10n.remindersEnabled),
          subtitle: Text(l10n.remindersEnabledHint, style: muted),
          value: on,
          onChanged: (v) => unawaited(_setEnabled(ref, v)),
        ),
        Semantics(
          button: true,
          enabled: on,
          label: l10n.reminderLeadDaysSemantics(reminders.leadDays),
          onTap: pickLeadDays,
          excludeSemantics: true,
          child: ListTile(
            key: const ValueKey('reminder-lead-days'),
            enabled: on,
            title: Text(l10n.reminderLeadDays),
            subtitle: Text(
              l10n.reminderLeadDaysValue(reminders.leadDays),
              style: muted,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: pickLeadDays,
          ),
        ),
        ListTile(
          key: const ValueKey('reminder-time'),
          enabled: on,
          title: Text(l10n.reminderTime),
          subtitle: Text(time, style: muted),
          trailing: const Icon(Icons.schedule),
          onTap: on ? () => _pickTime(context, ref) : null,
        ),
        ListTile(
          key: const ValueKey('reminder-repeat'),
          enabled: on,
          title: Text(l10n.repeatReminders),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repeatModeLabel(context, reminders.repeatMode),
                style: muted,
              ),
              const SizedBox(height: 4),
              Text(l10n.repeatRemindersHelp, style: muted),
              if (reminders.repeatMode == ReminderRepeat.daily)
                Text(
                  l10n.repeatDailyHint(eveningTime(context)),
                  key: const ValueKey('repeat-daily-hint'),
                  style: muted,
                ),
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: on ? () => _pickRepeat(context, ref) : null,
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('payday-summary'),
          title: Text(l10n.reminderPaydayToggle),
          subtitle: Text(l10n.reminderPaydayToggleHint, style: muted),
          value: reminders.paydaySummary,
          onChanged: on
              ? (v) => unawaited(
                  ref.read(reminderSettingsStoreProvider).setPaydaySummary(v),
                )
              : null,
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('reminder-show-amount'),
          title: Text(l10n.reminderShowAmount),
          value: privacy.showAmountsInNotifications(settings),
          onChanged: on
              ? (v) => unawaited(privacy.setShowAmountsInNotifications(v))
              : null,
        ),
        ListTile(
          title: Text(l10n.remindersHelpLink),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.remindersHelp),
        ),
        // Debug builds only (kDebugMode is false in release builds, so the
        // row is not even compiled in).
        if (kDebugMode)
          ListTile(
            key: const ValueKey('test-notification'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.debugTestNotification),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await gateway.showTest(
                title: l10n.appTitle,
                body: l10n.testNotificationText,
                delay: const Duration(seconds: 10),
              );
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.testNotificationScheduled)),
              );
            },
          ),
        // Debug builds only: three repeat reminders a minute apart for the
        // nearest unpaid payment; "Paid" on the first cancels the others.
        // Real repeats are never minutes apart.
        if (kDebugMode)
          ListTile(
            key: const ValueKey('test-repeats'),
            leading: const Icon(Icons.repeat),
            title: Text(l10n.debugRepeatTest),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final start = tz.TZDateTime.now(tz.local);
              final repeats = await ref
                  .read(reminderSchedulerProvider)
                  .testRepeats(
                    firstId: ReminderIds.testRepeats,
                    times: [
                      for (var i = 1; i <= 3; i++)
                        start.add(Duration(minutes: i)),
                    ],
                  );
              for (final r in repeats) {
                await gateway.showTestReminder(r);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    repeats.isEmpty
                        ? l10n.testReminderNoPayment
                        : l10n.testNotificationScheduled,
                  ),
                ),
              );
            },
          ),
        // Debug builds only: the nearest unpaid payment's "on the day"
        // reminder with its buttons, so "Paid" can be tried at once.
        if (kDebugMode)
          ListTile(
            key: const ValueKey('test-reminder-actions'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.debugTestReminderActions),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final reminder = await ref
                  .read(reminderSchedulerProvider)
                  .testReminder(
                    id: ReminderIds.testReminder,
                    fireAt: tz.TZDateTime.now(tz.local)
                        .add(const Duration(seconds: 10)),
                  );
              if (reminder != null) {
                await gateway.showTestReminder(reminder);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    reminder == null
                        ? l10n.testReminderNoPayment
                        : l10n.testNotificationScheduled,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
