import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/theme/kalan_theme.dart';
import 'reminders_section.dart';

enum _Mode { general, off, custom }

/// "Reminder" row on a plan or recurring payment: General setting (the
/// default), Off, or a different "days before" (1, 2, 3, 5 or 7). The
/// time always comes from Settings.
class ReminderChoiceTile extends ConsumerWidget {
  const ReminderChoiceTile({
    required this.value,
    required this.onChanged,
    super.key,
    this.method,
  });

  final ReminderChoice value;
  final ValueChanged<ReminderChoice> onChanged;

  /// The plan's payment method: "General setting" shows the days it means
  /// for this plan ([defaultLeadDaysFor]). Null for recurring payments.
  final PaymentMethod? method;

  String _label(BuildContext context, int generalDays) {
    final l10n = context.l10n;
    if (value.off) return l10n.planReminderOff;
    final days = value.leadDays;
    return days == null
        ? l10n.planReminderGeneral(generalDays)
        : l10n.reminderLeadDaysValue(days);
  }

  Future<void> _pick(BuildContext context, int generalDays) async {
    final l10n = context.l10n;
    final mode = await showChoiceDialog<_Mode>(
      context,
      title: l10n.planReminder,
      selected: value.off
          ? _Mode.off
          : value.leadDays == null
          ? _Mode.general
          : _Mode.custom,
      options: [
        (_Mode.general, l10n.planReminderGeneral(generalDays)),
        (_Mode.off, l10n.planReminderOff),
        (_Mode.custom, l10n.planReminderCustom),
      ],
    );
    if (mode == null || !context.mounted) return;
    switch (mode.value) {
      case _Mode.general:
        onChanged(ReminderChoice.general);
      case _Mode.off:
        onChanged(ReminderChoice.disabled);
      case _Mode.custom:
        final days = await showChoiceDialog<int>(
          context,
          title: l10n.planReminderCustom,
          // A manual plan's general day (the global one + 1) may not be one
          // of the choices; then the global one is marked.
          selected:
              value.leadDays ??
              (leadDayChoices.contains(generalDays)
                  ? generalDays
                  : generalDays - 1),
          options: leadDayOptions(context),
        );
        if (days != null) onChanged(ReminderChoice.days(days.value));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalDays = defaultLeadDaysFor(
      method,
      ReminderSettings(
        leadDays:
            ref.watch(settingsProvider).value?.reminderLeadDays ??
            initialLeadDays,
      ),
    );
    return ListTile(
      key: const ValueKey('item-reminders'),
      leading: Icon(
        value.off ? Icons.notifications_off_outlined : Icons.notifications_none,
        color: context.colors.textMuted,
      ),
      title: Text(context.l10n.planReminder),
      subtitle: Text(
        _label(context, generalDays),
        style: TextStyle(color: context.colors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pick(context, generalDays),
    );
  }
}
