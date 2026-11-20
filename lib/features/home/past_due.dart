import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../plans/extra_fee_sheet.dart';
import 'home_view.dart';

/// Rows shown before "Show all".
const pastDueVisibleRows = 3;

/// When a past-due payment was paid.
enum PaidWhen { today, onDueDate }

/// How long "Marked as paid." with "Undo" stays on screen.
const markedPaidDuration = Duration(seconds: 6);

/// "Marked as paid." with a calm "Undo". It leaves on its own: an action
/// would otherwise keep it on screen.
void showMarkedPaid(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n, {
  required VoidCallback onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.markedPaid),
        duration: markedPaidDuration,
        persist: false,
        action: SnackBarAction(label: l10n.actionUndo, onPressed: onUndo),
      ),
    );
}

/// "When did you pay?" for a past-due payment. "Today" keeps it in this
/// period; "on the due date" moves it back to its own. Returns null when
/// cancelled; otherwise the payment is already marked, and "Undo" puts it
/// back in the list as it was.
Future<PaidWhen?> markPastDuePaid(
  BuildContext context,
  WidgetRef ref, {
  required int paymentId,
  required LocalDate dueDate,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  // Read now: the row leaves the tree once the payment is paid.
  final repo = ref.read(planRepositoryProvider);
  final today = ref.read(todayProvider);
  final choice = await showModalBottomSheet<PaidWhen>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PaidWhenSheet(dueDate: dueDate),
  );
  if (choice == null) return null;
  await repo.setPaidOn(paymentId, choice == PaidWhen.today ? today : dueDate);
  KalanHaptics.success();
  showMarkedPaid(
    messenger,
    l10n,
    onUndo: () => repo.setPaid(paymentId, paid: false),
  );
  return choice;
}

class PaidWhenSheet extends StatelessWidget {
  const PaidWhenSheet({required this.dueDate, super.key});

  final LocalDate dueDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.textMuted,
    );
    Widget option(PaidWhen value, String title, String hint, Key key) =>
        ListTile(
          key: key,
          minTileHeight: 64,
          title: Text(title),
          subtitle: Text(hint, style: muted),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, value),
        );
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('paid-when-sheet'),
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.xs,
          0,
          KalanSpace.xs,
          KalanSpace.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                0,
                KalanSpace.md,
                KalanSpace.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.paidWhenTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            option(
              PaidWhen.today,
              l10n.paidWhenToday,
              l10n.paidWhenTodayHint,
              const ValueKey('paid-when-today'),
            ),
            const Divider(),
            option(
              PaidWhen.onDueDate,
              l10n.paidWhenOnDue(context.dayMonth(dueDate)),
              l10n.paidWhenOnDueHint,
              const ValueKey('paid-when-due'),
            ),
            const SizedBox(height: KalanSpace.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const ValueKey('paid-when-cancel'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Past-due payments": under the big number, above this period's list.
/// Hidden when empty. Rows leave only when paid, or when their plan is
/// deleted or edited.
class PastDueSection extends StatefulWidget {
  const PastDueSection({required this.view, super.key});

  final HomeView view;

  @override
  State<PastDueSection> createState() => _PastDueSectionState();
}

class _PastDueSectionState extends State<PastDueSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = widget.view.pastDue;
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = _expanded || items.length <= pastDueVisibleRows
        ? items
        : items.take(pastDueVisibleRows).toList();
    return Padding(
      key: const ValueKey('past-due'),
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.md,
        KalanSpace.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.pastDueTitle(items.length),
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.view.pastDueFromEarlier)
            Padding(
              padding: const EdgeInsets.only(top: KalanSpace.xxs),
              child: Text(
                l10n.pastDueDeducted,
                key: const ValueKey('past-due-deducted'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ),
          const SizedBox(height: KalanSpace.xs),
          Card(
            clipBehavior: Clip.antiAlias,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  for (final (i, e) in visible.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    PastDueRow(entry: e, today: widget.view.today),
                  ],
                ],
              ),
            ),
          ),
          if (!_expanded && items.length > pastDueVisibleRows)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('past-due-show-all'),
                onPressed: () => setState(() => _expanded = true),
                child: Text(l10n.pastDueShowAll(items.length)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Plan name, amount, "x days ago" with a clock (late), and "Paid".
class PastDueRow extends ConsumerWidget {
  const PastDueRow({required this.entry, required this.today, super.key});

  final HomeEntry entry;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amount = ref.money(context, entry.amountMinor);
    final days = daysPastDue(dueDate: entry.date, today: today);
    final fee = entry.extraFeeMinor == null
        ? null
        : ref.money(context, entry.extraFeeMinor!);
    final row = Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: fee == null
                ? l10n.pastDueRowSemantics(entry.label(l10n), amount, days)
                : l10n.pastDueRowFeeSemantics(
                    entry.label(l10n),
                    amount,
                    fee,
                    days,
                  ),
            // The tap is read out with the label (the InkWell's own is
            // excluded), so screen readers can open the plan too.
            onTap: () => context.push(Routes.plan(entry.planId!)),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => context.push(Routes.plan(entry.planId!)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    KalanSpace.md,
                    KalanSpace.xs,
                    KalanSpace.xs,
                    KalanSpace.xs,
                  ),
                  child: Row(
                    children: [
                      LetterBadge(entry.label(l10n)),
                      const SizedBox(width: KalanSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: KalanSpace.xxs),
                            DaysAgoNote(days: days),
                            // The amount stays the payment's own; the
                            // fee is a note under it (21).
                            if (fee != null)
                              Text(
                                l10n.extraFeeRowNote(fee),
                                key: ValueKey(
                                  'past-due-fee-${entry.paymentId}',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KalanSpace.xs),
                      AmountText(amount, size: AmountSize.small),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: KalanSpace.xxs),
          child: TextButton(
            key: ValueKey('past-due-paid-${entry.paymentId}'),
            onPressed: () => markPastDuePaid(
              context,
              ref,
              paymentId: entry.paymentId!,
              dueDate: entry.date,
            ),
            child: Text(l10n.pastDueMarkPaid),
          ),
        ),
      ],
    );
    return Column(
      key: ValueKey('past-due-${entry.paymentId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        // "Add extra fee" in ink (21), under the name: outside the row's
        // own label so screen readers reach it too.
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: KalanSpace.md + LetterBadge.defaultSize,
            bottom: KalanSpace.xxs,
          ),
          child: TextButton(
            key: ValueKey('past-due-fee-action-${entry.paymentId}'),
            onPressed: () => openExtraFee(
              context,
              ref,
              paymentId: entry.paymentId!,
              planName: entry.label(l10n),
              paymentLabel: paymentLabelOf(
                context,
                seq: entry.seq!,
                installmentCount: entry.installmentCount!,
                isPayLater: entry.isPayLater,
                date: entry.date,
              ),
              feeMinor: entry.extraFeeMinor,
              note: entry.extraFeeNote,
            ),
            child: Text(fee == null ? l10n.extraFeeAdd : l10n.extraFeeEdit),
          ),
        ),
      ],
    );
  }
}

/// "4 days ago" with a small clock, in late: never the color alone.
class DaysAgoNote extends StatelessWidget {
  const DaysAgoNote({required this.days, super.key});

  final int days;

  @override
  Widget build(BuildContext context) =>
      OverdueBadge(label: context.l10n.pastDueDaysAgo(days));
}
