import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/theme/kalan_theme.dart';
import 'reminder_providers.dart';

/// Right after the first plan is saved: Kalan's short explanation, then
/// (only on "Turn on reminders") the system permission dialog. Shown once;
/// "Not now", a dismissed sheet or a refusal are never asked about again.
/// Skipped when the system already allows notifications (Android 12 and
/// older have no dialog).
Future<void> askForRemindersIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final gateway = ref.read(notificationGatewayProvider);
  if (!gateway.supported) return;
  final settings = await ref.read(settingsRepositoryProvider).get();
  if (settings == null || settings.reminderPromptShown) return;
  final store = ref.read(reminderSettingsStoreProvider);
  if (await gateway.permissionGranted()) {
    await store.markPromptShown();
    return;
  }
  await store.markPromptShown();
  if (!context.mounted) return;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    // Grows with large text and scrolls instead of overflowing.
    isScrollControlled: true,
    builder: (_) => const ReminderPermissionSheet(),
  );
  if (accepted ?? false) await gateway.requestPermission();
  ref.invalidate(notificationPermissionProvider);
}

class ReminderPermissionSheet extends StatelessWidget {
  const ReminderPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('reminder-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.notifications_none,
                size: 32,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                l10n.reminderPromptTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reminderPromptBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('reminder-sheet-accept'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.reminderPromptAccept),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('reminder-sheet-later'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.reminderPromptLater),
            ),
          ],
        ),
      ),
    );
  }
}
