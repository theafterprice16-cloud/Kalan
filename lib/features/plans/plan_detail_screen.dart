import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/haptics.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../home/past_due.dart';
import '../onboarding/pay_form.dart';
import '../reminders/reminder_choice_tile.dart';
import '../reminders/reminder_settings_store.dart';
import '../reminders/repeat_mode_ui.dart';
import 'change_date_screen.dart';
import 'pay_later_form.dart';
import 'payment_method_ui.dart';
import 'plan_labels.dart';
import 'refund_actions.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, super.key});

  final int planId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final router = GoRouter.of(context);
    final ok = await showKalanDialog<bool>(
      context: context,
      builder: (context) => KalanAlertDialog(
        content: Text(l10n.planDeleteConfirm),
        actions: [
          KalanDialogAction(
            label: l10n.actionCancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          KalanDialogAction(
            label: l10n.actionDelete,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(planRepositoryProvider).deletePlan(planId);
    router.popWithMessage(
      SnackBar(content: Text(l10n.planDeleted)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider);
    if (!plans.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final plan = plans.value!.where((p) => p.plan.id == planId).firstOrNull;
    if (plan == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(l10n.planNotFound));
    }
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.textMuted,
    );
    // Plans added with only their remaining payments (before v4).
    final midwayCount = plan.allPayments.first.seq - 1;
    final today = ref.watch(todayProvider);
    final passedWhileHeld = plan.passedWhileHeld;
    // A closed plan shows what was paid; its other payments are out.
    final heroMinor = plan.isClosed ? plan.paidMinor : plan.remainingMinor;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.planName(plan)),
        actions: [
          // The one entry point for returns and cancellations (19); in
          // the bar, so the payments stay where they are.
          if (plan.isOpen)
            IconButton(
              key: const ValueKey('refund-action'),
              tooltip: l10n.refundAction,
              onPressed: () => openRefundActions(context, ref, plan),
              icon: const Icon(Icons.assignment_return_outlined),
            ),
          // A closed plan is read-only (19).
          if (plan.startsAtFirstPayment && !plan.isClosed)
            IconButton(
              key: const ValueKey('plan-edit'),
              tooltip: l10n.planEdit,
              onPressed: () => context.push(Routes.planEdit(plan.plan.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: l10n.planDelete,
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: KalanSpace.xl),
        children: [
          if (plan.holdCheckDueOn(today))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                KalanSpace.xs,
                KalanSpace.md,
                0,
              ),
              child: HoldCheckCard(plan: plan),
            ),
          Padding(
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
                    Row(
                      children: [
                        LetterBadge(
                          plan.source?.name ?? context.planName(plan),
                        ),
                        const SizedBox(width: KalanSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      plan.isPayLater
                                          ? context.planName(plan)
                                          : plan.source!.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  if (planRepeats(
                                    plan.plan,
                                    ref.watch(globalRepeatModeProvider),
                                  )) ...[
                                    const SizedBox(width: KalanSpace.xxs),
                                    const RepeatIcon(),
                                  ],
                                ],
                              ),
                              Text(
                                planKindLabel(context, plan.plan),
                                style: secondary,
                              ),
                              if (plan.isOnHold) const OnHoldTag(),
                              if (plan.plan.closeReason case final reason?)
                                Text(
                                  l10n.closedWithReason(reason.name),
                                  key: const ValueKey('closed-reason'),
                                  style: secondary,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KalanSpace.md),
                    AmountText(
                      ref.money(context, heroMinor),
                      size: AmountSize.medium,
                      // Held or closed: not part of any total.
                      color: plan.status == PlanStatus.open
                          ? null
                          : context.colors.textMuted,
                    ),
                    Text(
                      plan.isClosed
                          ? l10n.planPaidAmount(ref.money(context, heroMinor))
                          : l10n.planToPay(ref.money(context, heroMinor)),
                      style: secondary,
                    ),
                    if (plan.isOnHold && plan.setAside.isNotEmpty)
                      Text(
                        l10n.planOnHoldNote(plan.setAside.length),
                        key: const ValueKey('on-hold-note'),
                        style: secondary,
                      ),
                    const SizedBox(height: KalanSpace.xs),
                    Wrap(
                      spacing: KalanSpace.md,
                      runSpacing: KalanSpace.xxs,
                      children: [
                        // One payment: no "0/1"; the due date below.
                        if (!plan.isPayLater)
                          PlanProgress(
                            paid: plan.paidCount,
                            total: plan.plan.installmentCount,
                          ),
                        Text(
                          l10n.planTotal(ref.money(context, plan.totalMinor)),
                        ),
                        if (plan.plan.purchaseDay != null)
                          Text(
                            l10n.planPurchaseDate(
                              context.longDate(
                                LocalDate.fromEpochDay(plan.plan.purchaseDay!),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (plan.isPayLater) ...[
                      const SizedBox(height: KalanSpace.xs),
                      PayLaterSummary(plan: plan),
                    ],
                    if (passedWhileHeld > 0) ...[
                      const SizedBox(height: KalanSpace.xs),
                      Text(
                        l10n.passedWhileHeld(passedWhileHeld),
                        key: const ValueKey('passed-while-held'),
                      ),
                    ],
                    if (midwayCount > 0) ...[
                      const SizedBox(height: KalanSpace.xs),
                      Text(
                        l10n.planStartedMidway(midwayCount),
                        style: secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // A closed plan is read-only: nothing to remind or set (19).
          if (!plan.isClosed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.xxs,
                KalanSpace.xs,
                KalanSpace.xxs,
                0,
              ),
              child: ReminderChoiceTile(
                method: plan.plan.paymentMethod,
                value: reminderChoiceOf(
                  enabled: plan.plan.remindersEnabled,
                  leadDays: plan.plan.reminderLeadDays,
                ),
                onChanged: (choice) {
                  final (enabled, leadDays) = reminderColumnsOf(choice);
                  return unawaited(
                    ref
                        .read(planRepositoryProvider)
                        .setReminderChoice(
                          plan.plan.id,
                          enabled: enabled,
                          leadDays: leadDays,
                        ),
                  );
                },
              ),
            ),
          if (plan.paidBefore.isNotEmpty ||
              plan.listedPayments.any((p) => !plan.isClosed || p.isPaid))
            SectionTitle(l10n.planPaymentsTitle),
          // Paid before Kalan: one line, no dates, nothing to open.
          if (plan.paidBefore.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                0,
                KalanSpace.md,
                KalanSpace.xs,
              ),
              child: Text(
                l10n.paidBeforeSummary(
                  plan.paidBefore.length,
                  ref.money(context, plan.paidBeforeMinor),
                ),
                key: const ValueKey('paid-before-summary'),
                style: secondary,
              ),
            ),
          for (final p in plan.listedPayments)
            // A closed plan lists only what was paid.
            if (!plan.isClosed || p.isPaid) _PaymentRow(plan: plan, payment: p),
          // Below the payments, so they stay at the top of the screen.
          const Divider(height: KalanSpace.lg),
          if (!plan.isClosed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KalanSpace.xxs),
              child: PaymentMethodTile(plan: plan),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KalanSpace.xxs),
              child: RepeatChoiceTile(
                value: plan.plan.repeatMode,
                enabled: plan.plan.remindersEnabled,
                onChanged: (mode) => unawaited(
                  ref
                      .read(planRepositoryProvider)
                      .setRepeatMode(plan.plan.id, mode),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({required this.plan, required this.payment});

  final PlanWithPayments plan;
  final PaymentRow payment;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (payment.isPaid) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.editRejectedPaid)));
      return;
    }
    final amountError = ref.amountError(context);
    final result = await showKalanDialog<(LocalDate, int)>(
      context: context,
      builder: (_) => _EditPaymentDialog(payment: payment, ref: ref),
    );
    if (result == null) return;
    final rejection = await ref
        .read(planRepositoryProvider)
        .editPayment(
          planId: plan.plan.id,
          seq: payment.seq,
          date: result.$1,
          amountMinor: result.$2,
        );
    final message = switch (rejection) {
      null => l10n.paymentUpdated,
      EditRejection.alreadyPaid => l10n.editRejectedPaid,
      EditRejection.noAbsorbers => l10n.editRejectedNoAbsorbers,
      EditRejection.absorberWouldBeNonPositive => l10n.editRejectedAbsorber,
      EditRejection.nonPositiveAmount => amountError,
      EditRejection.notFound => l10n.planNotFound,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );
    final today = ref.watch(todayProvider);
    // On hold (19): never past due, shown muted with the pause icon.
    final held = plan.isOnHold && !payment.isPaid;
    // A closed plan is read-only; a held payment is marked after "Reopen",
    // where a passed date asks when it was paid, as everywhere else.
    final readOnly = plan.isClosed || held;
    final pastDue =
        !held &&
        isPastDue(dueDate: payment.date, isPaid: payment.isPaid, today: today);
    // "Pay later": amount and dates change together, on the edit screen.
    Future<void> edit() async => plan.isPayLater
        ? context.push(Routes.planEdit(plan.plan.id))
        : _edit(context, ref);
    // "Change date" (20): unpaid payments of open plans, not card ones.
    final canMove = canChangeDate(
      status: plan.status,
      kind: plan.plan.kind,
      isPaid: payment.isPaid,
    );
    return InkWell(
      onTap: readOnly
          ? null
          : canMove
          ? () async {
              final choice = await openPaymentActions(
                context,
                ref,
                plan,
                payment,
              );
              if (choice == PaymentChoice.edit && context.mounted) {
                await edit();
              }
            }
          : edit,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          KalanSpace.md,
          KalanSpace.xxs,
          KalanSpace.xxs,
          KalanSpace.xxs,
        ),
        child: Row(
          children: [
            if (!plan.isPayLater)
              SizedBox(
                width: 56,
                child: Text(
                  l10n.progressLabel(payment.seq, plan.plan.installmentCount),
                  style: secondary?.copyWith(fontFeatures: AmountText.tabular),
                  semanticsLabel: l10n.progressSemantics(
                    payment.seq,
                    plan.plan.installmentCount,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.longDate(payment.date),
                    style: held ? TextStyle(color: colors.textMuted) : null,
                  ),
                  Wrap(
                    spacing: KalanSpace.xs,
                    children: [
                      if (held) const OnHoldTag(),
                      if (payment.isPaid)
                        Text(l10n.paidLabel, style: secondary),
                      if (pastDue)
                        DaysAgoNote(
                          days: daysPastDue(
                            dueDate: payment.date,
                            today: today,
                          ),
                        ),
                      if (payment.isEdited)
                        Text(l10n.editedTag, style: secondary),
                    ],
                  ),
                  MoveNoteText(payment: payment),
                ],
              ),
            ),
            AmountText(
              ref.money(context, payment.amountMinor),
              size: AmountSize.small,
              color: payment.isPaid || held ? colors.textMuted : null,
            ),
            if (readOnly)
              // The button's place, so amounts and rows line up.
              const SizedBox.square(dimension: kMinInteractiveDimension)
            else
              IconButton(
                tooltip: payment.isPaid ? l10n.markAsUnpaid : l10n.markAsPaid,
                // A past-due payment asks when it was paid, as on home.
                onPressed: pastDue
                    ? () => markPastDuePaid(
                        context,
                        ref,
                        paymentId: payment.id,
                        dueDate: payment.date,
                      )
                    : () async {
                        final paid = !payment.isPaid;
                        await ref
                            .read(planRepositoryProvider)
                            .setPaid(payment.id, paid: paid);
                        if (paid) KalanHaptics.success();
                      },
                icon: Icon(
                  payment.isPaid
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: payment.isPaid ? colors.accentText : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditPaymentDialog extends StatefulWidget {
  const _EditPaymentDialog({required this.payment, required this.ref});

  final PaymentRow payment;
  final WidgetRef ref;

  @override
  State<_EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<_EditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_amount.text.isEmpty) {
      _amount.text = widget.ref.moneyInput(context, widget.payment.amountMinor);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KalanAlertDialog(
      title: Text(l10n.editPaymentTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The amount only: a date changes with "Change date" (20),
              // which previews the periods and keeps the original date.
              AmountField(
                fieldKey: const ValueKey('edit-amount'),
                controller: _amount,
                label: l10n.fieldAmount,
              ),
              const SizedBox(height: KalanSpace.sm),
              Text(l10n.editPaymentHelp),
            ],
          ),
        ),
      ),
      actions: [
        KalanDialogAction(
          label: l10n.actionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        KalanDialogAction(
          label: l10n.actionSave,
          primary: true,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              widget.payment.date,
              widget.ref.parseMoney(context, _amount.text)!,
            ));
          },
        ),
      ],
    );
  }
}
