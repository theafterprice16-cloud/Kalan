import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import 'home_view.dart';
import 'past_due.dart';

/// A payment row with a one-tap "paid" toggle.
class PaymentTile extends ConsumerWidget {
  const PaymentTile({required this.entry, super.key});

  final HomeEntry entry;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final paid = !entry.isPaid;
    // Read now: undo can run after this row has left the tree.
    final plans = ref.read(planRepositoryProvider);
    final recurring = ref.read(recurringRepositoryProvider);
    Future<void> set({required bool paid}) => entry.isRecurring
        ? recurring.setPaid(entry.recurringId!, entry.date.epochDay, paid: paid)
        : plans.setPaid(entry.paymentId!, paid: paid);
    await set(paid: paid);
    if (paid) {
      showMarkedPaid(messenger, l10n, onUndo: () => set(paid: false));
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.markedUnpaid)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final amount = ref.money(context, entry.amountMinor);
    final date = context.shortDate(entry.date);
    final days = ref.watch(todayProvider).daysUntil(entry.date);
    final soon = !entry.isPaid && days >= 0 && days <= 1;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );

    final details = <Widget>[
      Text(date, style: secondary),
      if (entry.isRecurring)
        Text(l10n.recurringTag, style: secondary)
      else
        Text(
          l10n.progressLabel(entry.seq!, entry.installmentCount!),
          style: secondary?.copyWith(fontFeatures: AmountText.tabular),
          semanticsLabel: l10n.progressSemantics(
            entry.seq!,
            entry.installmentCount!,
          ),
        ),
      if (!entry.isPaid && days < 0) DaysAgoNote(days: -days),
      if (soon)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: colors.text),
            const SizedBox(width: 4),
            Text(
              days == 0 ? l10n.dueToday : l10n.dueTomorrow,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      if (entry.isPaid)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: colors.textMuted),
            const SizedBox(width: 2),
            Text(l10n.paidLabel, style: secondary),
          ],
        ),
    ];

    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: InkWell(
              onTap: entry.planId == null
                  ? () => context.push(Routes.recurring(entry.recurringId!))
                  : () => context.push(Routes.plan(entry.planId!)),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                child: Row(
                  children: [
                    LetterBadge(entry.label(l10n)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label(l10n),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Wrap(spacing: 12, runSpacing: 2, children: details),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AmountText(
                      amount,
                      size: AmountSize.small,
                      color: entry.isPaid ? colors.textMuted : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: IconButton(
            tooltip: entry.isPaid ? l10n.markAsUnpaid : l10n.markAsPaid,
            onPressed: () => _toggle(context, ref),
            icon: Icon(
              entry.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
              color: entry.isPaid ? colors.accentText : null,
            ),
          ),
        ),
      ],
    );
  }
}
