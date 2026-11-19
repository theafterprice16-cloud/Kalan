import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/models.dart';
import 'refund_actions.dart';

/// "Adjust amount" (19): a lower total after a partial return. The new
/// payments are previewed before anything is saved; paid payments, dates
/// and the number of payments never change ([adjustPlanTotal]).
class AdjustAmountScreen extends ConsumerStatefulWidget {
  const AdjustAmountScreen({required this.planId, super.key});

  final int planId;

  @override
  ConsumerState<AdjustAmountScreen> createState() => _AdjustAmountScreenState();
}

class _AdjustAmountScreenState extends ConsumerState<AdjustAmountScreen> {
  final _total = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  Future<void> _save(PlanWithPayments plan, int newTotal) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    final rejected = await ref
        .read(planRepositoryProvider)
        .adjustTotal(plan.plan.id, newTotal);
    if (!mounted) return;
    if (rejected != null) {
      setState(() => _saving = false);
      return;
    }
    KalanHaptics.success();
    router.popWithMessage(
      SnackBar(content: Text(l10n.amountAdjustedDone)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  Future<void> _close(PlanWithPayments plan) async {
    final router = GoRouter.of(context);
    final reason = await showCloseDialog(context);
    if (reason == null || !mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    await ref
        .read(planRepositoryProvider)
        .close(plan.plan.id, reason: reason, today: ref.read(todayProvider));
    router.popWithMessage(
      SnackBar(content: Text(l10n.planClosedDone)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider);
    final plan = plans.value
        ?.where((p) => p.plan.id == widget.planId)
        .firstOrNull;
    if (plan == null || plan.isClosed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adjustOption)),
        body: plans.hasValue
            ? EmptyState(l10n.planNotFound)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final colors = context.colors;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final states = [for (final p in plan.allPayments) p.toState()];
    final paid = paidTotalOf(states);
    final unpaidCount = states.where((p) => !p.isPaid).length;
    final text = _total.text.trim();
    final typed = text.isEmpty ? null : ref.parseMoney(context, text);
    final result = typed == null ? null : adjustPlanTotal(states, typed);
    final applied = result is AdjustApplied ? result.payments : null;
    final rejection = result is AdjustRejected ? result.reason : null;
    final message = switch (rejection) {
      AdjustRejection.belowPaid => l10n.adjustBelowPaid(
        ref.money(context, paid),
      ),
      AdjustRejection.aboveTotal => l10n.adjustAboveTotal(
        ref.money(context, plan.totalMinor),
      ),
      AdjustRejection.unchanged => l10n.adjustUnchanged,
      AdjustRejection.cannotSplit => l10n.adjustCannotSplit(unpaidCount),
      AdjustRejection.nothingLeft => l10n.adjustNothingLeft,
      null =>
        text.isNotEmpty && typed == null
            ? ref.amountError(context, text)
            : null,
    };
    const gap = SizedBox(height: KalanSpace.md);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adjustOption)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.md,
          KalanSpace.xs,
          KalanSpace.md,
          KalanSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.planName(plan),
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.adjustCurrentTotal(ref.money(context, plan.totalMinor)),
              style: muted,
            ),
            Text(l10n.adjustPaidSoFar(ref.money(context, paid)), style: muted),
            gap,
            TextField(
              key: const ValueKey('adjust-total'),
              controller: _total,
              autofocus: true,
              keyboardType: ref.amountKeyboard,
              inputFormatters: ref.amountFormatters(context),
              decoration: InputDecoration(
                labelText: l10n.adjustNewTotal,
                // Not an error in red (19 uses no `late`): a calm note in
                // ink in place of the hint.
                helperText: message ?? l10n.adjustHint,
                helperMaxLines: 4,
                helperStyle: message == null
                    ? null
                    : TextStyle(color: colors.text),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (rejection == AdjustRejection.nothingLeft) ...[
              const SizedBox(height: KalanSpace.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  key: const ValueKey('adjust-close'),
                  onPressed: () => _close(plan),
                  child: Text(l10n.closeTitle),
                ),
              ),
            ],
            if (applied != null) ...[
              gap,
              Text(l10n.adjustPreviewTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: KalanSpace.xs),
              _Preview(plan: plan, payments: applied),
            ],
            gap,
            FilledButton(
              key: const ValueKey('adjust-save'),
              onPressed: applied == null || _saving
                  ? null
                  : () => _save(plan, typed!),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// The unpaid payments with their new amounts, in a surface card.
class _Preview extends ConsumerWidget {
  const _Preview({required this.plan, required this.payments});

  final PlanWithPayments plan;
  final List<PaymentState> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    return Card(
      key: const ValueKey('adjust-preview'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KalanSpace.md,
          vertical: KalanSpace.xs,
        ),
        child: Column(
          children: [
            for (final p in payments)
              if (!p.isPaid)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KalanSpace.xxs),
                  child: Row(
                    children: [
                      if (!plan.isPayLater)
                        SizedBox(
                          width: 56,
                          child: Text(
                            l10n.progressLabel(
                              p.seq,
                              plan.plan.installmentCount,
                            ),
                            style: muted?.copyWith(
                              fontFeatures: AmountText.tabular,
                            ),
                            semanticsLabel: l10n.progressSemantics(
                              p.seq,
                              plan.plan.installmentCount,
                            ),
                          ),
                        ),
                      Expanded(child: Text(context.longDate(p.date))),
                      AmountText(
                        ref.money(context, p.amountMinor),
                        size: AmountSize.small,
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
