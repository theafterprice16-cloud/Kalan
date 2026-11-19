import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import 'busy_week_view.dart';
import 'coming_periods.dart';

/// Pixel heights of one bar, from the bottom: spoken for, left above it,
/// and (short periods only) the part over income above spoken for, with
/// the income level between them.
class BarGeometry {
  const BarGeometry({
    required this.spokenFor,
    required this.left,
    this.over = 0,
    this.incomeLine,
  });

  /// Spoken for up to income (the whole of it when not short).
  final double spokenFor;
  final double left;

  /// Short periods only: spoken for above income.
  final double over;

  /// Short periods only: the income level, where [spokenFor] meets [over].
  final double? incomeLine;

  /// The shortest a bar part with a nonzero amount is drawn.
  static const double minVisible = 4;

  /// The amount the full [height] stands for: the largest spoken for or
  /// income among [periods], so every bar shares one scale.
  static int scaleOf(List<ComingPeriod> periods) => periods.fold(
    0,
    (top, p) => math.max(top, math.max(p.spokenForMinor, p.incomeMinor ?? 0)),
  );

  /// Heights in a bar of [height] on [scale]. Nonzero parts are at least
  /// [minVisible]; left is never drawn when spoken for exceeds income.
  /// [isShort]: the period's status is negative ([ComingPeriod.isNegative],
  /// the engine's rule): spoken for up to income, the part over income
  /// above it and the income line between them.
  static BarGeometry of({
    required int spokenForMinor,
    required int? incomeMinor,
    required int scale,
    required double height,
    bool isShort = false,
  }) {
    if (scale <= 0) return const BarGeometry(spokenFor: 0, left: 0);
    double part(int minor) =>
        minor <= 0 ? 0 : math.max(minVisible, minor / scale * height);
    final spent = math.min(height, part(spokenForMinor));
    if (incomeMinor == null) return BarGeometry(spokenFor: spent, left: 0);
    if (isShort) {
      // The part over income is never hidden, even one minor unit; the
      // part up to income gives way when the bar is short of room.
      final over = math.min(height, part(spokenForMinor - incomeMinor));
      final upToIncome = math.min(height - over, part(incomeMinor));
      return BarGeometry(
        spokenFor: upToIncome,
        left: 0,
        over: over,
        incomeLine: upToIncome,
      );
    }
    final left = math.min(height - spent, part(incomeMinor - spokenForMinor));
    return BarGeometry(spokenFor: spent, left: math.max(0, left));
  }
}

/// One bar: spoken for in chartCommitted at the bottom, left in accent
/// above it. In a short period the part over income is negative above
/// spoken for, with a thin text line at the income level between them.
/// No text is ever drawn on it.
class ComingBar extends StatelessWidget {
  const ComingBar({
    required this.geometry,
    required this.height,
    required this.barWidth,
    super.key,
  });

  final BarGeometry geometry;
  final double height;
  final double barWidth;

  static const double _line = 2;
  static const double _lineOverhang = KalanSpace.xxs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final g = geometry;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(KalanRadius.input),
              ),
              child: SizedBox(
                width: barWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Stretch so the colored parts take the bar's width.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (g.over > 0)
                      SizedBox(
                        key: const ValueKey('coming-bar-over'),
                        height: g.over,
                        child: ColoredBox(color: colors.negative),
                      ),
                    if (g.left > 0)
                      SizedBox(
                        key: const ValueKey('coming-bar-left'),
                        height: g.left,
                        child: ColoredBox(color: colors.accent),
                      ),
                    if (g.spokenFor > 0)
                      SizedBox(
                        key: const ValueKey('coming-bar-spoken-for'),
                        height: g.spokenFor,
                        child: ColoredBox(color: colors.chartCommitted),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // A little wider than the bar, so it reads on the background
          // too, but clear of the column's selection frame.
          if (g.incomeLine != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: math.max(0, g.incomeLine! - _line / 2),
              height: _line,
              child: Center(
                child: SizedBox(
                  key: const ValueKey('coming-bar-income-line'),
                  width: barWidth + 2 * _lineOverhang,
                  height: _line,
                  child: ColoredBox(color: colors.text),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The six small bars on the home screen: no labels, no own semantics
/// (the strip around them is one button).
class ComingPeriodsMiniBars extends StatelessWidget {
  const ComingPeriodsMiniBars({required this.periods, super.key});

  final List<ComingPeriod> periods;

  static const double height = KalanSpace.xl;

  @override
  Widget build(BuildContext context) {
    final scale = BarGeometry.scaleOf(periods);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (i, p) in periods.indexed) ...[
            if (i > 0) const SizedBox(width: KalanSpace.xs),
            Expanded(
              child: ComingBar(
                height: height,
                barWidth: KalanSpace.lg,
                geometry: BarGeometry.of(
                  spokenForMinor: p.spokenForMinor,
                  incomeMinor: p.incomeMinor,
                  scale: scale,
                  height: height,
                  isShort: p.isNegative,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The chart on the coming pay periods screen: one tappable column per
/// period with its payday and amount below the bar. Columns follow the
/// reading direction; on narrow screens the row scrolls.
class ComingPeriodsChart extends ConsumerWidget {
  const ComingPeriodsChart({
    required this.periods,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<ComingPeriod> periods;
  final int selected;
  final ValueChanged<int> onSelect;

  static const double barHeight = 144;
  static const double minColumnWidth = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = BarGeometry.scaleOf(periods);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = constraints.maxWidth / periods.length >= minColumnWidth;
        final width = fits
            ? constraints.maxWidth / periods.length
            : minColumnWidth;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, p) in periods.indexed)
              SizedBox(
                width: width,
                child: _Column(
                  key: ValueKey('coming-period-$i'),
                  period: p,
                  scale: scale,
                  selected: i == selected,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        );
        return fits
            ? row
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: row,
              );
      },
    );
  }
}

class _Column extends ConsumerStatefulWidget {
  const _Column({
    required this.period,
    required this.scale,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ComingPeriod period;
  final int scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  ConsumerState<_Column> createState() => _ColumnState();
}

class _ColumnState extends ConsumerState<_Column> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final p = widget.period;
    final left = p.leftMinor;
    final spokenFor = ref.money(context, p.spokenForMinor);
    final range = l10n.periodRange(
      context.dayMonth(p.period.start),
      context.dayMonth(p.period.lastDay),
    );
    final String label;
    if (left == null) {
      label = l10n.comingPeriodsBarLabelNoIncome(range, spokenFor);
    } else if (p.shortMinor case final short?) {
      // "Short" and the amount in words, never the color alone: certain
      // this period, "looks short" for one still to come.
      final amount = ref.money(context, short);
      label = p.isCurrent
          ? l10n.comingPeriodsBarLabelShortNow(range, spokenFor, amount)
          : l10n.comingPeriodsBarLabelShortAhead(range, spokenFor, amount);
    } else {
      label = l10n.comingPeriodsBarLabel(
        range,
        spokenFor,
        ref.money(context, left),
      );
    }
    final busy = p.busyWeek;
    final fullLabel = busy == null
        ? label
        : '$label ${busyWeekSummaryText(context, ref, busy)}';
    // The period's main number, as on the home screen: left when income
    // is set (negative when short), otherwise spoken for.
    final amount = ref.moneyShort(context, left ?? p.spokenForMinor);
    final small = theme.textTheme.bodySmall;

    final border = _focused
        ? Border.fromBorderSide(KalanTheme.focusRing(colors))
        : widget.selected
        ? Border.all(color: colors.text)
        : null;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: fullLabel,
      // The tap is read out with the label (the InkWell's own is excluded).
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KalanSpace.xxs),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(KalanRadius.input),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (f) => setState(() => _focused = f),
            borderRadius: BorderRadius.circular(KalanRadius.input),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KalanSpace.xs),
                child: Column(
                  children: [
                    ComingBar(
                      height: ComingPeriodsChart.barHeight,
                      barWidth: KalanSpace.lg,
                      geometry: BarGeometry.of(
                        spokenForMinor: p.spokenForMinor,
                        incomeMinor: p.incomeMinor,
                        scale: widget.scale,
                        height: ComingPeriodsChart.barHeight,
                        isShort: p.isNegative,
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.textMuted),
                    const SizedBox(height: KalanSpace.xs),
                    Text(
                      context.shortDate(p.period.start),
                      textAlign: TextAlign.center,
                      style: small?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: KalanSpace.xxs),
                    Text(
                      p.isNegative ? l10n.comingPeriodsShort(amount) : amount,
                      textAlign: TextAlign.center,
                      style: small?.copyWith(
                        color: p.isNegative ? colors.negativeText : colors.text,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AmountText.tabular,
                      ),
                    ),
                    // Beside the bar, never on it: a small icon and
                    // "busy". Tapping the column opens the explanation.
                    if (busy != null) ...[
                      const SizedBox(height: KalanSpace.xxs),
                      const BusyWeekTag(key: ValueKey('coming-busy-week')),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
