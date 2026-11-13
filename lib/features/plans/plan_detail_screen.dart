import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../onboarding/pay_form.dart';
import '../reminders/reminder_choice_tile.dart';
import '../reminders/reminder_settings_store.dart';
import 'plan_labels.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, super.key});

  final int planId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.planDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.late),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(planRepositoryProvider).deletePlan(planId);
    messenger.showSnackBar(SnackBar(content: Text(l10n.planDeleted)));
    router.pop();
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
    final midwayCount = plan.payments.first.seq - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.displayName),
        actions: [
          IconButton(
            tooltip: l10n.planDelete,
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LetterBadge(plan.source.name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.source.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                planKindLabel(context, plan.plan),
                                style: secondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AmountText(
                      ref.money(context, plan.remainingMinor),
                      size: AmountSize.medium,
                    ),
                    Text(
                      l10n.planToPay(ref.money(context, plan.remainingMinor)),
                      style: secondary,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text(
                          l10n.planPaidOf(
                            plan.paidCount,
                            plan.plan.installmentCount,
                          ),
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
                    if (midwayCount > 0) ...[
                      const SizedBox(height: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: ReminderChoiceTile(
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
          SectionTitle(l10n.planPaymentsTitle),
          for (final p in plan.payments) _PaymentRow(plan: plan, payment: p),
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
    final result = await showDialog<(LocalDate, int)>(
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
    return InkWell(
      onTap: () => _edit(context, ref),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
        child: Row(
          children: [
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
                  Text(context.longDate(payment.date)),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (payment.isPaid)
                        Text(l10n.paidLabel, style: secondary),
                      if (!payment.isPaid &&
                          payment.dueDay < ref.watch(todayProvider).epochDay)
                        OverdueBadge(label: l10n.overdueBadge),
                      if (payment.isEdited)
                        Text(l10n.editedTag, style: secondary),
                    ],
                  ),
                ],
              ),
            ),
            AmountText(
              ref.money(context, payment.amountMinor),
              size: AmountSize.small,
              color: payment.isPaid ? colors.textMuted : null,
            ),
            IconButton(
              tooltip: payment.isPaid ? l10n.markAsUnpaid : l10n.markAsPaid,
              onPressed: () => ref
                  .read(planRepositoryProvider)
                  .setPaid(payment.id, paid: !payment.isPaid),
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
  late LocalDate _date;

  @override
  void initState() {
    super.initState();
    _date = widget.payment.date;
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
    return AlertDialog(
      title: Text(l10n.editPaymentTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateField(
                label: l10n.fieldPaymentDate,
                value: _date,
                format: context.longDate,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 16),
              AmountField(
                fieldKey: const ValueKey('edit-amount'),
                controller: _amount,
                label: l10n.fieldAmount,
              ),
              const SizedBox(height: 12),
              Text(l10n.editPaymentHelp),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              _date,
              widget.ref.parseMoney(context, _amount.text)!,
            ));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
