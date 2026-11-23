import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/models.dart';
import '../home/payment_tile.dart' show PaymentTile;
import 'card_statements.dart';
import 'sources_screen.dart' show FittedAmount, StatementClosedNote;

/// One statement of a card: its dates, how many installments and their
/// total, and the installments one by one (decision 8). Installments paid
/// before Kalan count, but are shown as one line per plan.
class CardStatementScreen extends ConsumerWidget {
  const CardStatementScreen({
    required this.cardId,
    required this.statementDay,
    super.key,
  });

  final int cardId;

  /// The statement date as an epoch day.
  final int statementDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final date = LocalDate.fromEpochDay(statementDay);
    final loading =
        !ref.watch(sourcesProvider).hasValue ||
        !ref.watch(plansProvider).hasValue;
    final view = ref.watch(cardStatementsProvider(cardId));
    final statement = view?.statementOn(date);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cardStatementTitle(context.shortDate(date))),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : view == null || statement == null
          // Not one of the six coming statements (an old link, a removed
          // card): say so, never "no installments".
          ? Center(
              child: EmptyState(
                key: const ValueKey('statement-not-coming'),
                l10n.cardStatementNotComing,
              ),
            )
          : _body(context, ref, view, statement),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    CardStatementsView view,
    CardStatement statement,
  ) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );

    final listed = [
      for (final i in statement.installments)
        if (!i.paidBeforeKalan) i,
    ];
    // Paid before Kalan: counted in the total, never listed one by one or
    // dated; one line per plan.
    final before = <int, List<StatementInstallment>>{};
    for (final i in statement.installments) {
      if (i.paidBeforeKalan) before.putIfAbsent(i.planId, () => []).add(i);
    }

    final rows = <Widget>[
      for (final i in listed)
        _InstallmentRow(plan: view.plans[i.planId]!, installment: i),
      for (final MapEntry(key: planId, value: items) in before.entries)
        _PaidBeforeRow(plan: view.plans[planId]!, installments: items),
    ];

    return ListView(
      key: const ValueKey('card-statement'),
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.xs,
        KalanSpace.md,
        KalanSpace.xl,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(KalanSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LetterBadge(view.card.name),
                    const SizedBox(width: KalanSpace.sm),
                    Expanded(
                      child: Text(
                        view.card.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KalanSpace.md),
                context.spokenText(
                  statement.isEmpty
                      ? l10n.cardStatementEmpty
                      : l10n.cardStatementCountTotal(
                          statement.count,
                          ref.money(context, statement.totalMinor),
                        ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: AmountText.tabular,
                  ),
                ),
                const SizedBox(height: KalanSpace.xs),
                Wrap(
                  spacing: KalanSpace.md,
                  runSpacing: KalanSpace.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.cardStatementCutOn(
                        context.longDate(statement.statementDate),
                      ),
                      style: secondary,
                    ),
                    if (statement.isClosed)
                      StatementClosedNote(style: secondary),
                    Text(
                      l10n.cardStatementDueOn(
                        context.longDate(statement.dueDate),
                      ),
                      style: secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: KalanSpace.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (n, row) in rows.indexed) ...[
                  if (n > 0) const Divider(height: 1),
                  row,
                ],
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.xxs,
            KalanSpace.sm,
            KalanSpace.xxs,
            0,
          ),
          child: Text(
            l10n.cardStatementsNote,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Plan name, "3/10", amount and, when paid, "Paid". Opens the plan.
class _InstallmentRow extends ConsumerWidget {
  const _InstallmentRow({required this.plan, required this.installment});

  final PlanWithPayments plan;
  final StatementInstallment installment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );
    final name = context.planName(plan);
    final i = installment;
    return _Row(
      key: ValueKey('statement-installment-${i.paymentId}'),
      plan: plan,
      details: [
        Text(
          l10n.progressLabel(i.seq, i.installmentCount),
          style: secondary?.copyWith(fontFeatures: AmountText.tabular),
          semanticsLabel: l10n.progressSemantics(i.seq, i.installmentCount),
        ),
        if (i.isPaid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: colors.textMuted),
              const SizedBox(width: KalanSpace.xxs),
              Flexible(child: Text(l10n.paidLabel, style: secondary)),
            ],
          ),
      ],
      name: name,
      amount: ref.money(context, i.amountMinor),
      amountColor: i.isPaid ? colors.textMuted : null,
    );
  }
}

/// A plan's installments paid before Kalan on this statement: one line,
/// no dates.
class _PaidBeforeRow extends ConsumerWidget {
  const _PaidBeforeRow({required this.plan, required this.installments});

  final PlanWithPayments plan;
  final List<StatementInstallment> installments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = installments.fold(0, (sum, i) => sum + i.amountMinor);
    return _Row(
      plan: plan,
      name: context.planName(plan),
      details: [
        context.spokenText(
          context.l10n.paidBeforeSummary(
            installments.length,
            ref.money(context, total),
          ),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.colors.textMuted),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.plan,
    required this.name,
    required this.details,
    super.key,
    this.amount,
    this.amountColor,
  });

  final PlanWithPayments plan;
  final String name;
  final List<Widget> details;
  final String? amount;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => context.push(Routes.plan(plan.plan.id)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KalanSpace.md,
              vertical: KalanSpace.sm,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  LetterBadge(name),
                  const SizedBox(width: KalanSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  if (amount != null) ...[
                    const SizedBox(width: KalanSpace.xs),
                    FittedAmount(
                      amount!,
                      maxWidth: PaymentTile.maxAmountWidth(
                        constraints.maxWidth,
                      ),
                      color: amountColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
