import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/reminders/reminder_models.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';

/// "Off", "Once more in the evening", "Every day".
String repeatModeLabel(BuildContext context, ReminderRepeat mode) {
  final l10n = context.l10n;
  return switch (mode) {
    ReminderRepeat.off => l10n.repeatModeOff,
    ReminderRepeat.evening => l10n.repeatModeEvening,
    ReminderRepeat.daily => l10n.repeatModeDaily,
  };
}

List<(ReminderRepeat, String)> repeatModeOptions(BuildContext context) => [
  for (final mode in ReminderRepeat.values)
    (mode, repeatModeLabel(context, mode)),
];

/// The global repeat mode (off until onboarding has stored settings).
final globalRepeatModeProvider = Provider<ReminderRepeat>(
  (ref) =>
      ref.watch(settingsProvider.select((s) => s.value?.repeatMode)) ??
      ReminderRepeat.off,
);

/// Whether [plan] is set to repeat: its reminders on and its own or the
/// global repeat mode not off.
bool planRepeats(PlanRow plan, ReminderRepeat global) =>
    plan.remindersEnabled && (plan.repeatMode ?? global) != ReminderRepeat.off;

/// The same for a recurring payment.
bool recurringRepeats(RecurringPaymentRow item, ReminderRepeat global) =>
    item.remindersEnabled && (item.repeatMode ?? global) != ReminderRepeat.off;

/// "20:00" (or "8:00 PM") in the language's clock.
String eveningTime(BuildContext context) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      const TimeOfDay(hour: remindTonightMinute ~/ 60, minute: 0),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// The small repeat sign on a plan, in textMuted; read out as "Repeat
/// reminders on" (color is never the only sign).
class RepeatIcon extends StatelessWidget {
  const RepeatIcon({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.repeatRemindersOn,
    excludeSemantics: true,
    child: Icon(Icons.repeat, size: 18, color: context.colors.textMuted),
  );
}

/// "Repeat reminders" on a plan: Default (the global choice), Off, Once
/// more in the evening or Every day. Inactive, value kept, when the
/// plan's reminders are off.
class RepeatChoiceTile extends ConsumerWidget {
  const RepeatChoiceTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// Null follows the global setting.
  final ReminderRepeat? value;
  final bool enabled;
  final ValueChanged<ReminderRepeat?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final global = ref.watch(globalRepeatModeProvider);
    String label(ReminderRepeat? mode) => mode == null
        ? l10n.repeatModeGeneral(repeatModeLabel(context, global))
        : repeatModeLabel(context, mode);
    final muted = TextStyle(color: context.colors.textMuted);
    return ListTile(
      key: const ValueKey('item-repeat'),
      enabled: enabled,
      leading: Icon(Icons.repeat, color: context.colors.textMuted),
      title: Text(l10n.repeatReminders),
      subtitle: Text(label(value), style: muted),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showChoiceDialog<ReminderRepeat?>(
          context,
          title: l10n.repeatReminders,
          selected: value,
          note: l10n.repeatRemindersHelp,
          options: [
            (null, label(null)),
            for (final mode in ReminderRepeat.values)
              (mode, repeatModeLabel(context, mode)),
          ],
        );
        if (picked != null) onChanged(picked.value);
      },
    );
  }
}
