import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import 'sources_screen.dart' show FittedAmount;

/// "Keep in account" / "Coming to this card" (18) on a source's card: the
/// next withdrawal, the period's total, the day-by-day list ("Details")
/// and the next period, closed. A preparation list, never a warning: text
/// and textMuted only, emphasis by size and weight.
class ChargeSection extends ConsumerStatefulWidget {
  const ChargeSection({required this.source, required this.charges, super.key});

  final SourceRow source;
  final SourceCharges charges;

  @override
  ConsumerState<ChargeSection> createState() => _ChargeSectionState();
}

class _ChargeSectionState extends ConsumerState<ChargeSection> {
  bool _details = false;
  bool _next = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final id = widget.source.id;
    final current = widget.charges.current;
    final next = widget.charges.next;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final title = switch (widget.source.kind) {
      SourceKind.account => l10n.chargeTitleAccount,
      SourceKind.card => l10n.chargeTitleCard,
      SourceKind.provider => l10n.chargeTitleProvider,
    };
    final nextCharge = current.nextCharge;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextCharge == null)
          Text(
            l10n.chargeEmpty,
            key: ValueKey('charge-empty-$id'),
            style: muted,
          )
        else ...[
          Text(
            l10n.chargeNext(
              context.shortDate(nextCharge.date),
              ref.money(context, nextCharge.amountMinor),
            ),
            key: ValueKey('charge-next-$id'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: KalanSpace.xxs),
          Text(
            l10n.chargeBy(
              context.shortDate(current.period.lastDay),
              ref.money(context, current.totalMinor),
            ),
            key: ValueKey('charge-total-$id'),
            style: muted,
          ),
        ],
      ],
    );

    return Column(
      key: ValueKey('charge-section-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.sm,
            KalanSpace.md,
            KalanSpace.xxs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: ValueKey('charge-title-$id'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (current.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KalanSpace.md,
              KalanSpace.xs,
              KalanSpace.md,
              KalanSpace.xs,
            ),
            child: summary,
          )
        else
          _Toggle(
            key: ValueKey('charge-details-$id'),
            expanded: _details,
            onTap: () => setState(() => _details = !_details),
            trailingLabel: l10n.chargeDetails,
            child: summary,
          ),
        if (_details)
          for (final (i, row) in current.rows.indexed)
            _ChargeRowTile(key: ValueKey('charge-row-$id-$i'), row: row),
        _Toggle(
          key: ValueKey('charge-next-period-$id'),
          expanded: _next,
          onTap: () => setState(() => _next = !_next),
          child: Wrap(
            spacing: KalanSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.chargeNextPeriod, style: theme.textTheme.bodyLarge),
              Text(
                l10n.periodRange(
                  context.shortDate(next.period.start),
                  context.shortDate(next.period.lastDay),
                ),
                style: muted,
              ),
            ],
          ),
        ),
        if (_next) ...[
          if (next.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                0,
                KalanSpace.md,
                KalanSpace.xs,
              ),
              child: Text(
                l10n.chargeNextEmpty,
                key: ValueKey('charge-next-empty-$id'),
                style: muted,
              ),
            )
          else
            for (final (i, row) in next.rows.indexed)
              _ChargeRowTile(key: ValueKey('charge-next-row-$id-$i'), row: row),
        ],
        const SizedBox(height: KalanSpace.xs),
      ],
    );
  }
}

/// A whole row that opens and closes a part below it: at least 48 high,
/// with a turning arrow; screen readers hear whether it is open.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.expanded,
    required this.onTap,
    required this.child,
    super.key,
    this.trailingLabel,
  });

  final bool expanded;
  final VoidCallback onTap;
  final Widget child;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        button: true,
        expanded: expanded,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                KalanSpace.md,
                KalanSpace.xs,
                KalanSpace.xs,
                KalanSpace.xs,
              ),
              child: Row(
                children: [
                  Expanded(child: child),
                  if (trailingLabel != null) ...[
                    const SizedBox(width: KalanSpace.xs),
                    Text(
                      trailingLabel!,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                  ExcludeSemantics(
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, color: colors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tick and clock size on a day row, and the square they sit in: the
/// height of the row's first line, so the icon is centred on it.
const double _rowIconSize = 18;
const double _rowIconSlot = 24;

/// One day: "By 25 Nov" with the names below and the running total on the
/// end; a paid day muted with a tick and its own sum; today's row with a clock when it holds a
/// payment past its due date. Icons in ink, never a warning colour.
class _ChargeRowTile extends ConsumerWidget {
  const _ChargeRowTile({required this.row, super.key});

  final ChargeRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final date = context.shortDate(row.date);
    final names = [
      for (final i in row.items) i.name ?? payLaterAutoName(l10n, i.dueDate),
    ].join(', ');
    final Widget icon;
    if (row.isPaid) {
      icon = ExcludeSemantics(
        child: Icon(Icons.check, size: _rowIconSize, color: colors.text),
      );
    } else if (row.includesPastDue) {
      icon = Semantics(
        label: l10n.chargePastDue,
        child: Icon(Icons.schedule, size: _rowIconSize, color: colors.text),
      );
    } else {
      icon = const SizedBox.shrink();
    }
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          KalanSpace.md,
          KalanSpace.xxs,
          KalanSpace.md,
          KalanSpace.xxs,
        ),
        // Amounts on the end, tabular, one under the other: like the
        // statement rows below.
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The icon sits on the first line's centre.
              SizedBox.square(
                dimension: _rowIconSlot,
                child: Center(child: icon),
              ),
              const SizedBox(width: KalanSpace.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.isPaid
                          ? l10n.chargePaidOn(date)
                          : l10n.chargeByDate(date),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: row.isPaid ? colors.textMuted : colors.text,
                      ),
                    ),
                    Text(
                      names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KalanSpace.xs),
              FittedAmount(
                ref.money(
                  context,
                  row.isPaid ? row.amountMinor : row.cumulativeMinor,
                ),
                maxWidth: constraints.maxWidth / 2,
                color: row.isPaid ? colors.textMuted : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Automatic payments without a source" (decision 10): its own card at
/// the end, one row per plan with its next payment; a row opens the plan,
/// where the source can be chosen.
class UnassignedChargesCard extends ConsumerWidget {
  const UnassignedChargesCard({
    required this.items,
    required this.canChoose,
    super.key,
  });

  final List<ChargeItem> items;

  /// Whether any source exists: the plan details offer a choice only then,
  /// so the note pointing there is shown only then.
  final bool canChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    return Card(
      key: const ValueKey('charge-unassigned'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KalanSpace.md,
              KalanSpace.md,
              KalanSpace.md,
              KalanSpace.xxs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                l10n.chargeUnassignedTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final item in items)
            MergeSemantics(
              child: InkWell(
                key: ValueKey('charge-unassigned-${item.planId}'),
                onTap: () => context.push(Routes.plan(item.planId)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kMinInteractiveDimension,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      KalanSpace.md,
                      KalanSpace.xs,
                      KalanSpace.xs,
                      KalanSpace.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name ??
                                    payLaterAutoName(l10n, item.dueDate),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                l10n.chargeUnassignedRow(
                                  context.shortDate(item.dueDate),
                                  ref.money(context, item.amountMinor),
                                ),
                                style: muted,
                              ),
                            ],
                          ),
                        ),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!canChoose)
            const SizedBox(height: KalanSpace.xs)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                KalanSpace.xxs,
                KalanSpace.md,
                KalanSpace.md,
              ),
              child: Text(
                l10n.chargeUnassignedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
