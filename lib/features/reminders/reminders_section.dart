import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import 'reminder_providers.dart';
import 'reminder_settings_store.dart';

/// Settings > Reminders.
class RemindersSection extends ConsumerWidget {
  const RemindersSection({required this.settings, super.key});

  final SettingsRow settings;

  Future<void> _setEnabled(WidgetRef ref, bool on) async {
    if (on) {
      await ref.read(notificationGatewayProvider).requestPermission();
      ref.invalidate(notificationPermissionProvider);
    }
    await ref.read(reminderSettingsStoreProvider).setEnabled(on);
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
    final store = ref.read(reminderSettingsStoreProvider);

    Widget offset(ReminderOffset o, String label) => SwitchListTile(
      key: ValueKey('reminder-${o.name}'),
      title: Text(label),
      value: reminders.offsets.contains(o),
      onChanged: on ? (v) => unawaited(store.setOffset(o, v)) : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.settingsReminders),
        if (on && permission == false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              key: const ValueKey('permission-banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusNote(
                    icon: Icons.notifications_off_outlined,
                    color: colors.text,
                    text: l10n.remindersPermissionOff,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: gateway.openSystemSettings,
                      child: Text(l10n.openPhoneSettings),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SwitchListTile(
          key: const ValueKey('reminders-enabled'),
          title: Text(l10n.remindersEnabled),
          value: on,
          onChanged: (v) => unawaited(_setEnabled(ref, v)),
        ),
        offset(ReminderOffset.days7, l10n.reminderDays7),
        offset(ReminderOffset.days3, l10n.reminderDays3),
        offset(ReminderOffset.days1, l10n.reminderDays1),
        offset(ReminderOffset.sameDay, l10n.reminderSameDay),
        ListTile(
          key: const ValueKey('reminder-time'),
          enabled: on,
          title: Text(l10n.reminderTime),
          subtitle: Text(time, style: muted),
          trailing: const Icon(Icons.schedule),
          onTap: on ? () => _pickTime(context, ref) : null,
        ),
        SwitchListTile(
          key: const ValueKey('reminder-hide-amounts'),
          title: Text(l10n.reminderHideAmounts),
          value: ref
              .read(privacySettingsProvider)
              .hideAmountsInNotifications(settings),
          onChanged: (v) => unawaited(
            ref.read(privacySettingsProvider).setHideAmountsInNotifications(v),
          ),
        ),
        ListTile(
          title: Text(l10n.remindersHelpLink),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.remindersHelp),
        ),
        if (kDebugMode)
          ListTile(
            key: const ValueKey('test-notification'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.debugTestNotification),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await gateway.showTest(
                l10n.testNotificationText,
                const Duration(seconds: 10),
              );
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.testNotificationScheduled)),
              );
            },
          ),
      ],
    );
  }
}
