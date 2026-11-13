import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/period_summary.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(Routes.addPlan),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddPlan),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _Header(view: view),
          PastDueSection(view: view),
          if (view.entries.isNotEmpty) ...[
            SectionTitle(l10n.homePaymentsTitle),
            for (final e in view.entries) PaymentTile(entry: e),
          ],
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

    final Color numberColor;
    if (left == null) {
      numberColor = theme.colorScheme.onSurface;
    } else if (s.status == PeriodStatus.negative) {
      numberColor = colors.negative;
    } else {
      numberColor = colors.accent;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 4),
                    AmountText(
                      key: const ValueKey('home-number'),
                      left == null ? spokenFor : ref.money(context, left),
                      color: numberColor,
                    ),
                  ],
                ),
              ),
              if (left != null) ...[
                const SizedBox(height: 12),
                PeriodBar(
                  spokenForMinor: s.spokenForMinor,
                  incomeMinor: s.incomeMinor!,
                  semanticsLabel: l10n.homeBarLabel(
                    spokenFor,
                    ref.money(context, s.incomeMinor!),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${l10n.homeSpokenForLabel} $spokenFor',
                      style: secondary,
                    ),
                    Text(
                      '${l10n.homeIncomeLabel} ${ref.money(context, s.incomeMinor!)}',
                      style: secondary,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.homeSummary(s.itemCount, spokenFor),
                style: theme.textTheme.bodyLarge,
              ),
              if (s.status == PeriodStatus.tight) ...[
                const SizedBox(height: 12),
                StatusNote(
                  key: const ValueKey('status-tight'),
                  icon: Icons.hourglass_bottom,
                  color: colors.text,
                  text: l10n.homeTight(
                    ref.money(context, view.tightThresholdMinor!),
                  ),
                ),
              ],
              if (s.status == PeriodStatus.negative) ...[
                const SizedBox(height: 12),
                StatusNote(
                  key: const ValueKey('status-negative'),
                  icon: Icons.remove_circle_outline,
                  color: colors.negative,
                  textColor: colors.negativeText,
                  text: l10n.homeNegative(ref.money(context, -left!)),
                ),
              ],
              if (s.status == PeriodStatus.noIncome) ...[
                const SizedBox(height: 12),
                Text(l10n.homeNoIncomeHint, style: secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
