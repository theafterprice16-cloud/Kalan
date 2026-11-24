import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/period_summary.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../export/data_section.dart';
import '../periods/coming_periods_strip.dart';
import '../privacy/hide_amounts_ui.dart';
import '../restore/restore_notice.dart';
import 'home_view.dart';
import 'past_due.dart';
import 'payment_tile.dart';

/// "What's left?" for the current pay period.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeViewProvider);
    final l10n = context.l10n;
    if (view == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final period = view.summary.period;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.periodRange(
            context.shortDate(period.start),
            context.shortDate(period.lastDay),
          ),
        ),
        actions: const [HideAmountsButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(Routes.addPlan),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddPlan),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: KalanSpace.fabClearance),
        children: [
          _Header(view: view),
          // Once after a restore (30): a short message, or the Pro line.
          const RestoreNotice(),
          const ComingPeriodsStrip(),
          PastDueSection(view: view),
          if (view.entries.isNotEmpty) ...[
            SectionTitle(l10n.homePaymentsTitle),
            for (final e in view.entries) PaymentTile(entry: e),
          ],
          // "Last backup was 3 months ago." (29): one calm line, last.
          const BackupNote(),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final s = view.summary;
    final spokenFor = ref.money(context, s.spokenForMinor);
    final left = s.leftMinor;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );

    final number = left == null ? spokenFor : ref.money(context, left);
    // A hidden amount (28) reads as "Amount hidden".
    Text spokenText(String text, TextStyle? style) =>
        Text(text, style: style, semanticsLabel: context.spoken(text));

    final tight = s.status == PeriodStatus.tight
        ? l10n.homeTight(ref.money(context, view.tightThresholdMinor!))
        : '';
    final negative = s.status == PeriodStatus.negative
        ? l10n.homeNegative(ref.money(context, -left!))
        : '';

    final Color numberColor;
    if (left == null) {
      numberColor = theme.colorScheme.onSurface;
    } else if (s.status == PeriodStatus.negative) {
      numberColor = colors.negative;
    } else {
      numberColor = colors.accent;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.xs,
        KalanSpace.md,
        0,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KalanSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      left == null
                          ? l10n.homeSpokenForLabel
                          : l10n.homeLeftLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: KalanSpace.xxs),
                    AmountText(
                      key: const ValueKey('home-number'),
                      number,
                      color: numberColor,
                      semanticsLabel: context.spoken(number),
                    ),
                  ],
                ),
              ),
              if (left != null) ...[
                const SizedBox(height: KalanSpace.sm),
                PeriodBar(
                  spokenForMinor: s.spokenForMinor,
                  incomeMinor: s.incomeMinor!,
                  semanticsLabel: context.spokenLabel(
                    l10n.homeBarLabel(
                      spokenFor,
                      ref.money(context, s.incomeMinor!),
                    ),
                  ),
                ),
                const SizedBox(height: KalanSpace.sm),
                Wrap(
                  spacing: KalanSpace.md,
                  runSpacing: KalanSpace.xxs,
                  children: [
                    spokenText(
                      '${l10n.homeSpokenForLabel} $spokenFor',
                      secondary,
                    ),
                    spokenText(
                      '${l10n.homeIncomeLabel} ${ref.money(context, s.incomeMinor!)}',
                      secondary,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: KalanSpace.sm),
              spokenText(
                l10n.homeSummary(s.itemCount, spokenFor),
                theme.textTheme.bodyLarge,
              ),
              if (s.status == PeriodStatus.tight) ...[
                const SizedBox(height: KalanSpace.sm),
                StatusNote(
                  key: const ValueKey('status-tight'),
                  icon: Icons.hourglass_bottom,
                  color: colors.text,
                  text: tight,
                  semanticsLabel: context.spoken(tight),
                ),
              ],
              if (s.status == PeriodStatus.negative) ...[
                const SizedBox(height: KalanSpace.sm),
                StatusNote(
                  key: const ValueKey('status-negative'),
                  icon: Icons.remove_circle_outline,
                  color: colors.negative,
                  textColor: colors.negativeText,
                  text: negative,
                  semanticsLabel: context.spoken(negative),
                ),
              ],
              if (s.status == PeriodStatus.noIncome) ...[
                const SizedBox(height: KalanSpace.sm),
                Text(l10n.homeNoIncomeHint, style: secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
