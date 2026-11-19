import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/models.dart';

/// What the "Return or cancellation" sheet offers (19): three actions,
/// with "Reopen" in place of "Put on hold" on a plan on hold.
enum RefundChoice { hold, reopen, adjust, close }

/// The pause icon that goes with every "On hold": the color is never the
/// only sign.
const onHoldIcon = Icons.pause_circle_outline;

/// The one entry point on the plan: opens the sheet and carries out the
/// choice.
Future<void> openRefundActions(
  BuildContext context,
  WidgetRef ref,
  PlanWithPayments plan,
) async {
  final choice = await showModalBottomSheet<RefundChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => RefundSheet(onHold: plan.isOnHold),
  );
  if (choice == null || !context.mounted) return;
  await runRefundChoice(context, ref, plan, choice);
}

Future<void> runRefundChoice(
  BuildContext context,
  WidgetRef ref,
  PlanWithPayments plan,
  RefundChoice choice,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(planRepositoryProvider);
  final today = ref.read(todayProvider);
  final id = plan.plan.id;
  void done(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  switch (choice) {
    case RefundChoice.hold:
      await repo.hold(id, today: today);
      done(l10n.planHeldDone);
    case RefundChoice.reopen:
      await repo.reopen(id, today: today);
      done(l10n.planReopenedDone);
    case RefundChoice.adjust:
      await context.push(Routes.planAdjust(id));
    case RefundChoice.close:
      final reason = await showCloseDialog(context);
      if (reason == null) return;
      await repo.close(id, reason: reason, today: today);
      done(l10n.planClosedDone);
  }
}

/// "Close plan": the reason (return or cancellation) and a calm
/// confirmation. Closing is not deleting, so no `late` color. Null when
/// dismissed.
Future<CloseReason?> showCloseDialog(BuildContext context) =>
    showKalanDialog<CloseReason>(
      context: context,
      builder: (_) => const CloseDialog(),
    );

class RefundSheet extends StatelessWidget {
  const RefundSheet({required this.onHold, super.key});

  final bool onHold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('refund-sheet'),
        padding: const EdgeInsets.only(bottom: KalanSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.lg,
                0,
                KalanSpace.lg,
                KalanSpace.xs,
              ),
              child: Text(
                l10n.refundAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onHold)
              _Option(
                choice: RefundChoice.reopen,
                icon: Icons.play_circle_outline,
                title: l10n.reopenOption,
                hint: l10n.reopenOptionHint,
              )
            else
              _Option(
                choice: RefundChoice.hold,
                icon: onHoldIcon,
                title: l10n.holdOption,
                hint: l10n.holdOptionHint,
              ),
            _Option(
              choice: RefundChoice.adjust,
              icon: Icons.edit_outlined,
              title: l10n.adjustOption,
              hint: l10n.adjustOptionHint,
            ),
            _Option(
              choice: RefundChoice.close,
              icon: Icons.archive_outlined,
              title: l10n.closeOption,
              hint: l10n.closeOptionHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final RefundChoice choice;
  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      key: ValueKey('refund-${choice.name}'),
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: KalanSpace.lg),
      leading: Icon(icon, color: colors.text),
      title: Text(title),
      subtitle: Text(hint, style: TextStyle(color: colors.textMuted)),
      onTap: () => Navigator.pop(context, choice),
    );
  }
}

class CloseDialog extends StatefulWidget {
  const CloseDialog({super.key});

  @override
  State<CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends State<CloseDialog> {
  CloseReason? _reason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return KalanAlertDialog(
      title: Text(l10n.closeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.closeBody),
            const SizedBox(height: KalanSpace.md),
            Text(l10n.closeReasonTitle, style: theme.textTheme.titleSmall),
            for (final (reason, label) in [
              (CloseReason.refund, l10n.closeReasonRefund),
              (CloseReason.cancel, l10n.closeReasonCancel),
            ])
              Semantics(
                selected: _reason == reason,
                inMutuallyExclusiveGroup: true,
                child: ListTile(
                  key: ValueKey('close-reason-${reason.name}'),
                  minTileHeight: 48,
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  trailing: _reason == reason
                      ? Icon(Icons.check, color: context.colors.text)
                      : null,
                  onTap: () => setState(() => _reason = reason),
                ),
              ),
          ],
        ),
      ),
      actions: [
        KalanDialogAction(
          label: l10n.actionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        KalanDialogAction(
          key: const ValueKey('close-confirm'),
          label: l10n.closeOption,
          primary: true,
          // A reason is chosen first.
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(context, _reason),
        ),
      ],
    );
  }
}

/// "On hold" with its pause icon, in textMuted (never `late`).
class OnHoldTag extends StatelessWidget {
  const OnHoldTag({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle =
        style ??
        Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.textMuted);
    return Row(
      key: const ValueKey('on-hold-tag'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(onHoldIcon, size: 16, color: colors.textMuted),
        ),
        const SizedBox(width: KalanSpace.xxs),
        Flexible(child: Text(context.l10n.planOnHold, style: textStyle)),
      ],
    );
  }
}

/// "Still waiting on the return?" on a plan held for 30 days (Decision
/// 2): Close / Reopen / Keep on hold. Shown only when the plan is opened.
class HoldCheckCard extends ConsumerWidget {
  const HoldCheckCard({required this.plan, super.key});

  final PlanWithPayments plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final since = plan.plan.heldSinceDay;
    final ink = TextButton.styleFrom(foregroundColor: colors.text);
    return Card(
      key: const ValueKey('hold-check'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.md,
          KalanSpace.md,
          KalanSpace.md,
          KalanSpace.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.holdCheckTitle, style: theme.textTheme.titleMedium),
            if (since != null)
              Text(
                l10n.holdCheckSince(
                  context.shortDate(LocalDate.fromEpochDay(since)),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            const SizedBox(height: KalanSpace.xs),
            Wrap(
              spacing: KalanSpace.xs,
              children: [
                TextButton(
                  key: const ValueKey('hold-check-close'),
                  style: ink,
                  onPressed: () =>
                      runRefundChoice(context, ref, plan, RefundChoice.close),
                  child: Text(l10n.closeOption),
                ),
                TextButton(
                  key: const ValueKey('hold-check-reopen'),
                  style: ink,
                  onPressed: () =>
                      runRefundChoice(context, ref, plan, RefundChoice.reopen),
                  child: Text(l10n.reopenOption),
                ),
                TextButton(
                  key: const ValueKey('hold-check-keep'),
                  style: ink,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref
                        .read(planRepositoryProvider)
                        .keepOnHold(
                          plan.plan.id,
                          today: ref.read(todayProvider),
                        );
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.planKeptOnHold)),
                      );
                  },
                  child: Text(l10n.keepOnHold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
