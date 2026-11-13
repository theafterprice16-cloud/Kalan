import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import 'reminder_providers.dart';

/// After the first plan or recurring payment is saved: Kalan's own short
/// explanation first, then the system permission dialog. "Not now" is
/// final; reminders can be turned on later in Settings.
Future<void> askForRemindersIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final gateway = ref.read(notificationGatewayProvider);
  if (!gateway.supported) return;
  final settings = await ref.read(settingsRepositoryProvider).get();
  if (settings == null || settings.reminderPromptShown || !context.mounted) {
    return;
  }
  final remind = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ReminderPromptDialog(),
  );
  final store = ref.read(reminderSettingsStoreProvider);
  if (remind ?? false) {
    await gateway.requestPermission();
    await store.markPromptAnswered(remind: true);
  } else {
    await store.markPromptAnswered(remind: false);
  }
  ref.invalidate(notificationPermissionProvider);
}

class ReminderPromptDialog extends StatelessWidget {
  const ReminderPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const ValueKey('reminder-prompt'),
      icon: const Icon(Icons.notifications_none),
      title: Text(l10n.reminderPromptTitle),
      content: Text(l10n.reminderPromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.reminderPromptLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.reminderPromptAccept),
        ),
      ],
    );
  }
}
