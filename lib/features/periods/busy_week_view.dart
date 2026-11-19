import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';

/// The one icon of a busy week, in the chart and on the calendar: payments
/// stacked on each other. Always in the text color, never late or
/// negative: a busy week is an observation, not a warning.
const IconData busyWeekIcon = Icons.layers_outlined;

/// "Busy week: Dec 17–21 · 4 payments · $5,200".
String busyWeekSummaryText(BuildContext context, WidgetRef ref, BusyWeek w) =>
    context.l10n.busyWeekSummary(
      context.dayRange(w.first, w.last),
      w.count,
      ref.money(context, w.totalMinor),
    );

/// The busy week's explanation: one line in a surfaceRaised box, the text
/// in the text color and its days in textMuted. The same box under the
/// chart's period summary and in the calendar's day section.
class BusyWeekNote extends ConsumerWidget {
  const BusyWeekNote({required this.week, super.key});

  final BusyWeek week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.text);
    final text = busyWeekSummaryText(context, ref, week);
    final range = context.dayRange(week.first, week.last);
    // The days in textMuted: found in the one translated sentence, so the
    // word order stays the translator's.
    final at = text.indexOf(range);
    final span = at < 0
        ? TextSpan(text: text)
        : TextSpan(
            children: [
              TextSpan(text: text.substring(0, at)),
              TextSpan(
                text: range,
                style: TextStyle(color: colors.textMuted),
              ),
              TextSpan(text: text.substring(at + range.length)),
            ],
          );
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('busy-week-note'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: KalanSpace.sm,
          vertical: KalanSpace.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.border, width: 0.5),
          borderRadius: BorderRadius.circular(KalanRadius.input),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(busyWeekIcon, size: 18, color: colors.text),
            const SizedBox(width: KalanSpace.xs),
            Expanded(child: Text.rich(span, style: style)),
          ],
        ),
      ),
    );
  }
}

/// Under a chart bar: the small icon and the word "busy". Never on the
/// bar itself.
class BusyWeekTag extends StatelessWidget {
  const BusyWeekTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(busyWeekIcon, size: 12, color: colors.text),
        const SizedBox(width: KalanSpace.xxs / 2),
        Flexible(
          child: Text(
            context.l10n.busyWeekTag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.text),
          ),
        ),
      ],
    );
  }
}
