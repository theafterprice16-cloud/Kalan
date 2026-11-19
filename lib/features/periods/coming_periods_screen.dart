import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import '../home/payment_tile.dart';
import '../settings/settings_screen.dart' show editNetIncome;
import 'coming_periods.dart';
import 'period_chart.dart';

/// "Coming pay periods": six bars on one scale, the selected period's
/// summary and its payments. Opens with [initialSelected] (the current
/// period by default).
class ComingPeriodsScreen extends ConsumerStatefulWidget {
  const ComingPeriodsScreen({super.key, this.initialSelected = 0});

  final int initialSelected;

  @override
  ConsumerState<ComingPeriodsScreen> createState() =>
      _ComingPeriodsScreenState();
}

class _ComingPeriodsScreenState extends ConsumerState<ComingPeriodsScreen> {
  late int _selected = widget.initialSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final periods = ref.watch(comingPeriodsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comingPeriodsTitle)),
      body: switch (periods) {
        null => const Center(child: CircularProgressIndicator()),
        final ps when ps.every((p) => p.summary.itemCount == 0) => EmptyState(
          key: const ValueKey('coming-periods-empty'),
          l10n.comingPeriodsEmpty(ps.length),
        ),
        final ps => _body(context, ps),
      },
    );
  }

  Widget _body(BuildContext context, List<ComingPeriod> periods) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final index = _selected.clamp(0, periods.length - 1);
    final p = periods[index];
    final left = p.leftMinor;
    final total = ref.money(context, p.spokenForMinor);
    final rows = p.rows;

    return ListView(
      padding: const EdgeInsets.only(bottom: KalanSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.xs,
            KalanSpace.md,
            0,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(KalanSpace.xs),
              child: ComingPeriodsChart(
                periods: periods,
                selected: index,
                onSelect: (i) => setState(() => _selected = i),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.lg,
            KalanSpace.md,
            0,
          ),
          child: Column(
            key: const ValueKey('coming-period-summary'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.periodRange(
                    context.shortDate(p.period.start),
                    context.shortDate(p.period.lastDay),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: KalanSpace.xxs),
              Text(
                left == null || p.isNegative
                    ? l10n.comingPeriodsSummaryNoLeft(
                        p.summary.itemCount,
                        total,
                      )
                    : l10n.comingPeriodsSummary(
                        p.summary.itemCount,
                        total,
                        ref.money(context, left),
                      ),
                style: theme.textTheme.bodyLarge,
              ),
              if (p.isNegative) ...[
                const SizedBox(height: KalanSpace.xs),
                StatusNote(
                  key: const ValueKey('coming-period-short'),
                  icon: Icons.remove_circle_outline,
                  color: colors.negative,
                  textColor: colors.negativeText,
                  text: l10n.comingPeriodsShort(ref.money(context, left!)),
                ),
              ],
            ],
          ),
        ),
        if (left == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KalanSpace.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('coming-periods-income-invite'),
                onPressed: () => editNetIncome(context, ref),
                child: Text(l10n.comingPeriodsIncomeInvite),
              ),
            ),
          ),
        if (rows.isNotEmpty) ...[
          SectionTitle(l10n.homePaymentsTitle),
          for (final e in rows)
            PaymentTile(
              key: ValueKey('${e.paymentId}-${e.recurringId}-${e.date}'),
              entry: e,
            ),
        ],
      ],
    );
  }
}
