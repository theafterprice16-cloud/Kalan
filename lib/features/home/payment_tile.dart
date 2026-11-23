import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../plans/payment_method_ui.dart';
import 'home_view.dart';
import 'past_due.dart';

/// A payment row with a one-tap "paid" toggle.
class PaymentTile extends ConsumerWidget {
  const PaymentTile({required this.entry, super.key, this.showDaysAgo = true});

  /// The name column never gets narrower than this because of the amount.
  static const double _minNameWidth = KalanSpace.xl * 3;

  /// Room the amount may take in a row of [rowWidth]: its natural width
  /// unless that would squeeze the name below [_minNameWidth] (very large
  /// text, very long amounts on a narrow phone); then it shrinks.
  static double maxAmountWidth(double rowWidth) {
    final room =
        rowWidth -
        LetterBadge.defaultSize -
        KalanSpace.sm -
        KalanSpace.xs -
        _minNameWidth;
    return room > 0 ? room : 0;
  }

  final HomeEntry entry;

  /// "x days ago" on an unpaid payment whose day has passed. Off on the
  /// calendar for earlier periods' unmarked recurring payments, which are
  /// never late (decision 24a).
  final bool showDaysAgo;

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
      KalanHaptics.success();
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

    // A hidden amount (28) reads as "Amount hidden".
    Text feeNote(String text, Key key) => Text(
      text,
      key: key,
      style: secondary,
      semanticsLabel: context.spoken(text),
    );

    final method = entry.paymentMethod;
    final details = <Widget>[
      // The payment method's icon before the date, read out as its word.
      if (method == null)
        Text(date, style: secondary)
      else
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaymentMethodIcon(method),
            const SizedBox(width: KalanSpace.xxs),
            Text(date, style: secondary),
          ],
        ),
      if (entry.isRecurring)
        Text(l10n.recurringTag, style: secondary)
      else if (entry.isPayLater)
        Text(l10n.kindPayLater, style: secondary)
      else
        Text(
          l10n.progressLabel(entry.seq!, entry.installmentCount!),
          style: secondary?.copyWith(fontFeatures: AmountText.tabular),
          semanticsLabel: l10n.progressSemantics(
            entry.seq!,
            entry.installmentCount!,
          ),
        ),
      if (showDaysAgo && !entry.isPaid && days < 0) DaysAgoNote(days: -days),
      // The fee per payment inside the amount on the right (22).
      if (entry.installmentFeeMinor case final fee?)
        feeNote(
          l10n.installmentFeeIncluded(ref.money(context, fee)),
          ValueKey('installment-fee-note-${entry.paymentId}'),
        ),
      // The fee on top of the amount on the right (21), never in it.
      if (entry.extraFeeMinor case final fee?)
        feeNote(
          l10n.extraFeeRowNote(ref.money(context, fee)),
          ValueKey('fee-note-${entry.paymentId}'),
        ),
      if (soon)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: colors.text),
            const SizedBox(width: KalanSpace.xxs),
            // Flexible: at large text sizes the note wraps, never overflows.
            Flexible(
              child: Text(
                days == 0 ? l10n.dueToday : l10n.dueTomorrow,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      if (entry.isPaid)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: colors.textMuted),
            const SizedBox(width: KalanSpace.xxs),
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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  KalanSpace.md,
                  KalanSpace.xs,
                  KalanSpace.xs,
                  KalanSpace.xs,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      LetterBadge(entry.label(l10n)),
                      const SizedBox(width: KalanSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label(l10n),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: KalanSpace.xxs),
                            Wrap(
                              spacing: KalanSpace.sm,
                              runSpacing: KalanSpace.xxs,
                              children: details,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KalanSpace.xs),
                      // A long amount shrinks only when the name would get
                      // too narrow, never pushing the row past the screen.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxAmountWidth(constraints.maxWidth),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: AmountText(
                            amount,
                            semanticsLabel: context.spoken(amount),
                            size: AmountSize.small,
                            color: entry.isPaid ? colors.textMuted : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: KalanSpace.xxs),
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
