import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import 'reminder_providers.dart';

/// "Not getting reminders?": Focus on iPhone, battery saving on Android.
class RemindersHelpScreen extends ConsumerWidget {
  const RemindersHelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersHelpLink)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.remindersHelpIntro,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
          section(
            l10n.remindersHelpPermissionTitle,
            l10n.remindersHelpPermissionBody,
          ),
          section(l10n.remindersHelpIosTitle, l10n.remindersHelpIosBody),
          section(
            l10n.remindersHelpAndroidTitle,
            l10n.remindersHelpAndroidBody,
          ),
          if (ref.watch(notificationGatewayProvider).supported)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: ref
                    .read(notificationGatewayProvider)
                    .openSystemSettings,
                child: Text(l10n.openPhoneSettings),
              ),
            )
          else
            EmptyState(l10n.remindersWebOnly),
        ],
      ),
    );
  }
}
