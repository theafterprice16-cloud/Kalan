import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import 'coming_periods.dart';
import 'period_chart.dart';

/// The home screen's small "Coming pay periods" strip under the big
/// number: a title and six small bars, one tap target that opens the
/// screen with the current period selected. Hidden while no coming period
/// has a payment.
class ComingPeriodsStrip extends ConsumerWidget {
  const ComingPeriodsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(comingPeriodsProvider);
    if (periods == null || periods.every((p) => p.summary.itemCount == 0)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.xs,
        KalanSpace.md,
        0,
      ),
      child: Card(
        key: const ValueKey('coming-periods-strip'),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: () => context.push(Routes.comingPeriods()),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                KalanSpace.md,
                KalanSpace.xs,
                KalanSpace.xs,
                KalanSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.comingPeriodsTitle,
                          style: Theme.of(context).textTheme.titleSmall,
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
                  const SizedBox(height: KalanSpace.xs),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: KalanSpace.xs,
                    ),
                    child: ComingPeriodsMiniBars(periods: periods),
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
