import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/reminders/reminder_models.dart';
import '../../l10n/generated/app_localizations.dart';

/// Notification text for a planned reminder, in the app language and the
/// user's currency, through the shared money formatter.
///
/// One payment: "Tomorrow: Klarna 3/4 · AMOUNT". Several: "Tomorrow you
/// have 3 payments · TOTAL in total". With amounts hidden: "Tomorrow you
/// have 1 payment".
String reminderText(
  PlannedReminder reminder, {
  required AppLocalizations l10n,
  required Currency currency,
  required bool hideAmounts,
}) {
  final when = l10n.reminderWhen(reminder.offset.name);
  final count = reminder.payments.length;
  if (hideAmounts) return l10n.reminderCountOnly(when, count);
  String money(int minor) =>
      formatMoney(minor, currency, localeName: l10n.localeName);
  if (count > 1) {
    return l10n.reminderSummary(when, count, money(reminder.totalMinor));
  }
  final p = reminder.payments.single;
  final name = p.seq != null && p.count != null
      ? '${p.name} ${l10n.progressLabel(p.seq!, p.count!)}'
      : p.name;
  return l10n.reminderSingle(when, name, money(p.amountMinor));
}
