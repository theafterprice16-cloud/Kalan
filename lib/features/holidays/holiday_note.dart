import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/business_days.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import 'holiday_providers.dart';

/// Whether [payment]'s date is a card due date moved past a public holiday
/// (decision 7): the card's own installment, not edited or moved, on the
/// date the card's rule gives its statement with at least one holiday
/// skipped. A move only off a weekend shows nothing, as before.
bool movedForHoliday(
  PlanWithPayments plan,
  PaymentRow payment,
  HolidayCalendar? holidays,
) {
  if (payment.isEdited ||
      payment.originalDay != null ||
      plan.ownCardId == null) {
    return false;
  }
  final terms = plan.source?.cardTermsIn(holidays);
  return terms != null && terms.movedForHoliday(payment.date);
}

/// "Moved for a public holiday" under a payment's date: textMuted and a
/// small calendar icon, no color or warning; the holiday is never named.
class HolidayMovedNote extends ConsumerWidget {
  const HolidayMovedNote({
    required this.plan,
    required this.payment,
    super.key,
  });

  final PlanWithPayments plan;
  final PaymentRow payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!movedForHoliday(plan, payment, ref.watch(appliedHolidaysProvider))) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Row(
      key: ValueKey('holiday-note-${payment.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, size: 16, color: colors.textMuted),
        const SizedBox(width: KalanSpace.xxs),
        Flexible(
          child: Text(
            context.l10n.holidayMovedNote,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}
