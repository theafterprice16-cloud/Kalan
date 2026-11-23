import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/recurring.dart';
import '../../data/db/app_database.dart';
import '../../l10n/generated/app_localizations.dart';

String planKindLabel(BuildContext context, PlanRow plan) =>
    planKindLabelIn(context.l10n, plan.kind, cashAdvance: plan.isCashAdvance);

/// A plan's type in [l10n]'s language (also the exported spreadsheet's
/// "Type", 29).
String planKindLabelIn(
  AppLocalizations l10n,
  PlanKind kind, {
  required bool cashAdvance,
}) => cashAdvance
    ? l10n.kindCashAdvance
    : switch (kind) {
        PlanKind.payIn4 => l10n.kindPayIn4,
        PlanKind.monthly => l10n.kindMonthly,
        PlanKind.card => l10n.kindCard,
        PlanKind.manual => l10n.kindManual,
        PlanKind.payLater => l10n.kindPayLater,
      };

String recurrenceLabel(BuildContext context, Recurrence r) {
  final l10n = context.l10n;
  return switch (r) {
    Recurrence.weekly => l10n.recurrenceWeekly,
    Recurrence.biweekly => l10n.recurrenceBiweekly,
    Recurrence.monthly => l10n.recurrenceMonthly,
    Recurrence.yearly => l10n.recurrenceYearly,
  };
}

/// Plan progress as card statements show it ("3/10 paid"), with a spoken
/// label ("3 of 10 installments paid"). Numbers come from intl.
class PlanProgress extends StatelessWidget {
  const PlanProgress({
    required this.paid,
    required this.total,
    super.key,
    this.style,
  });

  final int paid;
  final int total;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      l10n.planPaidOf(paid, total),
      key: const ValueKey('plan-progress'),
      style: style,
      semanticsLabel: l10n.progressPaidOfSemantics(paid, total),
    );
  }
}
