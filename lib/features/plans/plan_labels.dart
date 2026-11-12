import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/recurring.dart';
import '../../data/db/app_database.dart';

String planKindLabel(BuildContext context, PlanRow plan) {
  final l10n = context.l10n;
  if (plan.isCashAdvance) return l10n.kindCashAdvance;
  return switch (plan.kind) {
    PlanKind.payIn4 => l10n.kindPayIn4,
    PlanKind.monthly => l10n.kindMonthly,
    PlanKind.card => l10n.kindCard,
    PlanKind.manual => l10n.kindManual,
  };
}

String recurrenceLabel(BuildContext context, Recurrence r) {
  final l10n = context.l10n;
  return switch (r) {
    Recurrence.weekly => l10n.recurrenceWeekly,
    Recurrence.biweekly => l10n.recurrenceBiweekly,
    Recurrence.monthly => l10n.recurrenceMonthly,
    Recurrence.yearly => l10n.recurrenceYearly,
  };
}
