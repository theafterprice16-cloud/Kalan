import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/date/local_date.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import '../home/past_due.dart';
import '../home/payment_tile.dart';
import '../settings/settings_screen.dart' show editNetIncome;
import 'coming_periods.dart';
import 'payment_calendar.dart';
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
  /// The selected period, by its first day: when the day turns and the
  /// periods move on, the same period stays selected (or, once it is in
  /// the past, the current one).
  LocalDate? _selectedStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final periods = ref.watch(comingPeriodsProvider);
    final view = ref.watch(comingViewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comingPeriodsTitle)),
      body: switch (periods) {
        null => const Center(child: CircularProgressIndicator()),
        final ps => () {
          // The choice scrolls with the content, as the screen's first row.
          final choice = _ViewChoice(
            view: view,
            onChanged: ref.read(comingViewProvider.notifier).set,
          );
          return switch (view) {
            ComingView.calendar => PaymentCalendar(header: choice),
            ComingView.chart when ps.every((p) => p.summary.itemCount == 0) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  choice,
                  Expanded(
                    child: EmptyState(
                      key: const ValueKey('coming-periods-empty'),
                      l10n.comingPeriodsEmpty(ps.length),
                    ),
                  ),
                ],
              ),
            ComingView.chart => _body(context, ps, choice),
          };
        }(),
      },
    );
  }

  Widget _body(
    BuildContext context,
    List<ComingPeriod> periods,
    Widget header,
  ) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    _selectedStart ??=
        periods[widget.initialSelected.clamp(0, periods.length - 1)]
            .period
            .start;
    final found = periods.indexWhere((p) => p.period.start == _selectedStart);
    final index = found < 0 ? 0 : found;
    final p = periods[index];
    final left = p.leftMinor;
    final total = ref.money(context, p.spokenForMinor);

    return ListView(
      padding: const EdgeInsets.only(bottom: KalanSpace.xl),
      children: [
        header,
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
                onSelect: (i) =>
                    setState(() => _selectedStart = periods[i].period.start),
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
                  // The same sentence as on the home screen.
                  text: l10n.homeNegative(ref.money(context, -left!)),
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
        // Past-due payments (current period only) as on the home screen:
        // "Paid" asks when, so the payment keeps counting where it should.
        if (p.pastDue.isNotEmpty) ...[
          SectionTitle(l10n.pastDueTitle(p.pastDue.length)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KalanSpace.md),
            child: Card(
              key: const ValueKey('coming-period-past-due'),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, e) in p.pastDue.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    PastDueRow(entry: e, today: ref.watch(todayProvider)),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (p.entries.isNotEmpty) ...[
          SectionTitle(l10n.homePaymentsTitle),
          for (final e in p.entries)
            PaymentTile(
              key: ValueKey('${e.paymentId}-${e.recurringId}-${e.date}'),
              entry: e,
            ),
        ],
      ],
    );
  }
}

/// "Chart | Calendar", with the app's own segmented control.
class _ViewChoice extends StatelessWidget {
  const _ViewChoice({required this.view, required this.onChanged});

  final ComingView view;
  final ValueChanged<ComingView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.xs,
        KalanSpace.md,
        KalanSpace.xs,
      ),
      child: Semantics(
        label: l10n.comingViewLabel,
        container: true,
        child: SegmentedButton<ComingView>(
          key: const ValueKey('coming-view'),
          segments: [
            ButtonSegment(
              value: ComingView.chart,
              label: Text(l10n.comingViewChart),
            ),
            ButtonSegment(
              value: ComingView.calendar,
              label: Text(l10n.comingViewCalendar),
            ),
          ],
          selected: {view},
          onSelectionChanged: (s) => onChanged(s.single),
        ),
      ),
    );
  }
}
