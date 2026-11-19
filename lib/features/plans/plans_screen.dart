import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/models.dart';
import '../reminders/repeat_mode_ui.dart';
import 'pay_later_form.dart';
import 'plan_labels.dart';

/// Open plans, recurring payments and the archive of finished plans.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider).value;
    final recurring = ref.watch(recurringProvider).value;
    final onRecurringTab = _tabs.index == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlans),
        actions: [
          IconButton(
            tooltip: l10n.sourcesTitle,
            onPressed: () => context.push(Routes.sources),
            icon: const Icon(Icons.credit_card),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.plansTabOpen),
            Tab(text: l10n.plansTabRecurring),
            Tab(text: l10n.plansTabFinished),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () =>
            context.push(onRecurringTab ? Routes.newRecurring : Routes.addPlan),
        icon: const Icon(Icons.add),
        label: Text(onRecurringTab ? l10n.addRecurring : l10n.actionAddPlan),
      ),
      body: plans == null || recurring == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _PlanList(
                  plans: plans.where((p) => p.isOpen).toList(),
                  empty: l10n.plansEmptyOpen,
                ),
                _RecurringList(items: recurring),
                _PlanList(
                  plans: plans.where((p) => !p.isOpen).toList(),
                  empty: l10n.plansEmptyFinished,
                ),
              ],
            ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.plans, required this.empty});

  final List<PlanWithPayments> plans;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) return Center(child: EmptyState(empty));
    final l10n = context.l10n;
    final global = ref.watch(globalRepeatModeProvider);
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    return ListView(
      padding: const EdgeInsets.only(
        bottom: KalanSpace.fabClearance,
        top: KalanSpace.xs,
      ),
      children: [
        for (final p in plans)
          InkWell(
            onTap: () => context.push(Routes.plan(p.plan.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KalanSpace.md,
                vertical: KalanSpace.xs,
              ),
              child: Row(
                children: [
                  LetterBadge(context.planName(p)),
                  const SizedBox(width: KalanSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.planName(p),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (p.isOpen && planRepeats(p.plan, global)) ...[
                              const SizedBox(width: KalanSpace.xxs),
                              const RepeatIcon(),
                            ],
                          ],
                        ),
                        Wrap(
                          spacing: KalanSpace.sm,
                          children: [
                            Text(
                              planKindLabel(context, p.plan),
                              style: secondary,
                            ),
                            if (p.isPayLater)
                              // One payment: the due date and days left,
                              // never "0/1".
                              PayLaterDueLine(
                                due: p.allPayments.first.date,
                                showDaysLeft: p.isOpen,
                                short: true,
                              )
                            else
                              PlanProgress(
                                paid: p.paidCount,
                                total: p.plan.installmentCount,
                                style: secondary,
                              ),
                            if (p.nextUnpaid != null && !p.isPayLater)
                              Text(
                                l10n.planNext(
                                  context.shortDate(p.nextUnpaid!.date),
                                ),
                                style: secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KalanSpace.xs),
                  AmountText(
                    ref.money(
                      context,
                      p.isOpen ? p.remainingMinor : p.totalMinor,
                    ),
                    size: AmountSize.small,
                    semanticsLabel: p.isOpen
                        ? l10n.planToPay(ref.money(context, p.remainingMinor))
                        : l10n.planTotal(ref.money(context, p.totalMinor)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecurringList extends ConsumerWidget {
  const _RecurringList({required this.items});

  final List<RecurringWithMarks> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (items.isEmpty) return Center(child: EmptyState(l10n.recurringEmpty));
    final today = ref.watch(todayProvider);
    final global = ref.watch(globalRepeatModeProvider);
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    return ListView(
      padding: const EdgeInsets.only(
        bottom: KalanSpace.fabClearance,
        top: KalanSpace.xs,
      ),
      children: [
        for (final r in items)
          Builder(
            builder: (context) {
              final next = r.occurrences(today, today.addDays(400)).firstOrNull;
              return InkWell(
                onTap: () => context.push(Routes.recurring(r.item.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KalanSpace.md,
                    vertical: KalanSpace.xs,
                  ),
                  child: Row(
                    children: [
                      LetterBadge(r.item.name),
                      const SizedBox(width: KalanSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    r.item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                if (recurringRepeats(r.item, global)) ...[
                                  const SizedBox(width: KalanSpace.xxs),
                                  const RepeatIcon(),
                                ],
                              ],
                            ),
                            Wrap(
                              spacing: KalanSpace.sm,
                              children: [
                                Text(
                                  recurrenceLabel(context, r.item.recurrence),
                                  style: secondary,
                                ),
                                Text(
                                  next == null
                                      ? l10n.recurringEnded
                                      : l10n.recurringNext(
                                          context.shortDate(next),
                                        ),
                                  style: secondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AmountText(
                        ref.money(context, r.item.amountMinor),
                        size: AmountSize.small,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
