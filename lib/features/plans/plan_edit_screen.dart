import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/haptics.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../holidays/holiday_providers.dart';
import 'add_plan_screen.dart' show findSourceByName;
import 'installment_fee_fields.dart';
import 'interval_field.dart';
import 'pay_later_form.dart';
import 'payment_method_ui.dart';
import 'product_price_field.dart';

/// "This plan is already underway", changed after the plan was added: the
/// same switch and fields as on the add screen, filled in. Payments marked
/// paid in Kalan are never changed here.
class PlanEditScreen extends ConsumerStatefulWidget {
  const PlanEditScreen({required this.planId, super.key});

  final int planId;

  @override
  ConsumerState<PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends ConsumerState<PlanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paid = TextEditingController();
  final _count = TextEditingController();
  String? _countError;
  bool _loaded = false;
  bool _underway = false;
  int _paidPayIn4 = 1;
  LocalDate? _nextDate;
  bool _nextDateTouched = false;
  bool _saving = false;

  /// "Monthly installments" and "Pay in 4": the payment interval.
  IntervalInput? _interval;

  /// Payment method and where an automatic one is taken from.
  PaymentMethod? _method;
  int? _chargeSourceId;

  /// Fee per payment (22); empty is no fee.
  final _fee = TextEditingController();
  InstallmentFeeScope _feeScope = InstallmentFeeScope.everyPayment;

  /// Product price (23); empty is not entered.
  final _price = TextEditingController();

  @override
  void dispose() {
    _fee.dispose();
    _price.dispose();
    _paid.dispose();
    _count.dispose();
    _interval?.dispose();
    super.dispose();
  }

  void _load(PlanWithPayments plan) {
    if (_loaded) return;
    _loaded = true;
    final before = plan.paidBefore.length;
    _underway = before > 0;
    final initial = before > 0 ? before : 1;
    _paid.text = '$initial';
    _count.text = '${plan.plan.installmentCount}';
    _paidPayIn4 = initial.clamp(1, 3);
    if (plan.interval case final interval?) _interval = IntervalInput(interval);
    _method = plan.plan.paymentMethod;
    _chargeSourceId = plan.chargeSourceId;
    _feeScope = plan.plan.installmentFeeScope;
    if (plan.installmentFee case final fee?) {
      _fee.text = ref.moneyInput(context, fee);
    }
    if (plan.productPrice case final price?) {
      _price.text = ref.moneyInput(context, price);
    }
  }

  bool _isPayIn4(PlanWithPayments plan) => plan.plan.kind == PlanKind.payIn4;

  int? _paidCount(PlanWithPayments plan) =>
      _isPayIn4(plan) ? _paidPayIn4 : int.tryParse(_paid.text.trim());

  /// How the dates repeat, or null when the plan has no fixed pattern
  /// (manual entry, a card without its days): no next date field then.
  /// Monthly and Pay in 4 follow the interval as chosen on this screen.
  UnderwayPattern? _pattern(PlanWithPayments plan) => switch (plan.plan.kind) {
    PlanKind.monthly || PlanKind.payIn4 => switch (_interval?.interval ??
        plan.interval) {
      final interval? => IntervalPattern(interval),
      null => null,
    },
    PlanKind.card => switch (plan.source?.cardTermsIn(
      ref.read(appliedHolidaysProvider),
    )) {
      final terms? => CardPattern(terms),
      null => null,
    },
    PlanKind.manual || PlanKind.payLater => null,
  };

  /// The count can change where new payments have a date rule: monthly
  /// and card plans. Pay in 4 is always 4; manual entry has no rule.
  bool _countEditable(PlanWithPayments plan) =>
      plan.plan.kind != PlanKind.payIn4 && _pattern(plan) != null;

  int _newCount(PlanWithPayments plan) =>
      int.tryParse(_count.text.trim()) ?? plan.plan.installmentCount;

  String? _validateCount(PlanWithPayments plan, String? v) {
    final l10n = context.l10n;
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 1 || n > PlanCalculator.maxInstallments) {
      return l10n.errorCountInvalid;
    }
    final min = minInstallmentCount([
      for (final p in plan.allPayments) p.toState(),
    ]);
    if (n < min) return l10n.errorCountMin(min);
    return _countError;
  }

  /// The payment the "next payment date" belongs to, when it may move.
  PaymentRow? _nextPayment(PlanWithPayments plan) {
    final n = _paidCount(plan);
    if (n == null || n < 0 || n >= plan.allPayments.length) return null;
    final p = plan.allPayments[n];
    return p.isPaid && !p.paidBeforeKalan ? null : p;
  }

  String? _validate(PlanWithPayments plan, String? v) {
    final l10n = context.l10n;
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 1) return l10n.errorPaidMin;
    final count = _newCount(plan);
    if (n >= count) return l10n.errorPaidAll;
    // New payments at the end are unpaid too, so a plan with nothing
    // marked in Kalan can count up to the new total.
    final run = leadingRunOf(plan.allPayments);
    final max = run == plan.allPayments.length
        ? count - 1
        : maxPaidBeforeOf(plan.allPayments);
    if (n > max) return l10n.errorPaidMax(max);
    return null;
  }

  Future<void> _save(PlanWithPayments plan) async {
    setState(() => _countError = null);
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final fee = typedInstallmentFee(context, ref, _fee.text);
    // A price the section cannot read (closed with text the validator
    // never saw) leaves the stored price as it is.
    final priceText = _price.text.trim();
    final priceReadable =
        priceText.isEmpty || ref.parseMoney(context, priceText) != null;
    final price = typedProductPrice(context, ref, _price.text);
    final count = _underway ? _paidCount(plan) ?? 0 : 0;
    final back = plan.paidBefore.length - count;
    if (back > 0) {
      final ok = await showKalanDialog<bool>(
        context: context,
        builder: (context) => KalanAlertDialog(
          key: const ValueKey('underway-revert'),
          content: Text(l10n.underwayRevert(back)),
          actions: [
            KalanDialogAction(
              label: l10n.actionCancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            KalanDialogAction(
              key: const ValueKey('underway-revert-confirm'),
              label: l10n.underwayRevertConfirm,
              primary: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    final pattern = _pattern(plan);
    final moveDates =
        _underway && _nextDateTouched && pattern != null && _nextDate != null;
    final rejected = await ref
        .read(planRepositoryProvider)
        .editPlan(
          plan.plan.id,
          count: _newCount(plan),
          paidBefore: count,
          nextDate: moveDates ? _nextDate : null,
          pattern: pattern,
          interval: _interval?.interval,
          installmentFee: canHaveInstallmentFee(plan.plan.kind)
              ? (feeMinor: fee, scope: _feeScope)
              : null,
          productPrice: canHaveProductPrice(plan.plan.kind) && priceReadable
              ? (priceMinor: price)
              : null,
        );
    if (rejected != null) {
      // What is left cannot be split that finely; say so under the field.
      setState(() {
        _saving = false;
        _countError = l10n.errorTotalTooSmall;
      });
      _formKey.currentState!.validate();
      return;
    }
    await ref
        .read(planRepositoryProvider)
        .setPaymentMethod(
          plan.plan.id,
          _method,
          chargeSourceId: storedChargeSourceId(_chargeSourceId, plan.ownCardId),
        );
    KalanHaptics.success();
    router.popWithMessage(
      SnackBar(content: Text(l10n.planUpdated)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider);
    final plan = plans.value
        ?.where((p) => p.plan.id == widget.planId)
        .firstOrNull;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.planEdit)),
        body: plans.hasValue
            ? EmptyState(l10n.planNotFound)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    // "Pay later": its own short form, no "underway".
    if (plan.isPayLater) return _PayLaterEdit(plan: plan);
    _load(plan);
    final max = maxPaidBeforeOf(plan.allPayments);
    final payIn4 = _isPayIn4(plan);
    final next = _nextPayment(plan);
    final showDate = _pattern(plan) != null && next != null;
    final nextDate = _nextDateTouched ? _nextDate : next?.date;
    const gap = SizedBox(height: KalanSpace.md);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planEdit)),
      body: Form(
        key: _formKey,
        // Built in full, so the save button is always there to reach.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.xs,
            KalanSpace.md,
            KalanSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!payIn4) ...[
                TextFormField(
                  key: const ValueKey('total-installments'),
                  controller: _count,
                  enabled: _countEditable(plan),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.fieldTotalInstallments,
                    helperText: _countEditable(plan) ? l10n.resizeHint : null,
                    helperMaxLines: 3,
                  ),
                  onChanged: (_) => setState(() => _countError = null),
                  validator: (v) => _validateCount(plan, v),
                ),
                gap,
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      key: const ValueKey('underway'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.underwayToggle),
                      subtitle: Text(
                        l10n.underwayHint,
                        style: TextStyle(color: context.colors.textMuted),
                      ),
                      value: _underway,
                      // A plan with its first payment marked paid in Kalan
                      // has nothing the switch could cover.
                      onChanged: max < 1 && !_underway
                          ? null
                          : (v) => setState(() => _underway = v),
                    ),
                    if (_underway) ...[
                      const SizedBox(height: KalanSpace.xs),
                      if (!payIn4) ...[
                        TextFormField(
                          key: const ValueKey('paid-count'),
                          controller: _paid,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.fieldPaidInstallments,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => _validate(plan, v),
                        ),
                      ] else
                        ChoiceField<int>(
                          key: const ValueKey('paid-payin4'),
                          label: l10n.fieldPaidInstallments,
                          selected: _paidPayIn4,
                          options: [
                            for (var n = 1; n <= (max < 3 ? max : 3); n++)
                              (n, l10n.numberValue(n)),
                          ],
                          onSelected: (n) => setState(() => _paidPayIn4 = n),
                        ),
                      if (showDate) ...[
                        gap,
                        DateField(
                          key: const ValueKey('next-date'),
                          label: l10n.fieldNextPaymentDate,
                          value: nextDate,
                          format: context.longDate,
                          onChanged: (d) => setState(() {
                            _nextDate = d;
                            _nextDateTouched = true;
                          }),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_interval case final interval?) ...[
                gap,
                IntervalField(
                  input: interval,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: KalanSpace.xs),
                Text(
                  l10n.intervalEditHint,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.colors.textMuted),
                ),
              ],
              gap,
              PaymentMethodFields(
                method: _method,
                chargeSourceId: _chargeSourceId,
                ownCardId: plan.ownCardId,
                onMethodChanged: (m) => setState(() => _method = m),
                onChargeSourceChanged: (id) =>
                    setState(() => _chargeSourceId = id),
              ),
              // Fee per payment (22, never for card installments) and
              // product price (23, monthly, card and manual).
              if (canHaveInstallmentFee(plan.plan.kind) ||
                  canHaveProductPrice(plan.plan.kind)) ...[
                const SizedBox(height: KalanSpace.xs),
                _FeeSection(
                  plan: plan,
                  controller: _fee,
                  scope: _feeScope,
                  onScopeChanged: (v) => setState(() => _feeScope = v),
                  onChanged: () => setState(() {}),
                  priceController: canHaveProductPrice(plan.plan.kind)
                      ? _price
                      : null,
                ),
              ],
              gap,
              FilledButton(
                key: const ValueKey('save-plan-edit'),
                onPressed: _saving ? null : () => _save(plan),
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editing a "Pay later" plan: amount, name, purchase date, rule and
/// source. The due date follows the rule from the purchase date; a picked
/// date stays. A paid plan changes only its name and source.
class _PayLaterEdit extends ConsumerStatefulWidget {
  const _PayLaterEdit({required this.plan});

  final PlanWithPayments plan;

  @override
  ConsumerState<_PayLaterEdit> createState() => _PayLaterEditState();
}

class _PayLaterEditState extends ConsumerState<_PayLaterEdit> {
  final _formKey = GlobalKey<FormState>();
  late final PayLaterInput _input;
  bool _saving = false;
  PaymentMethod? _method;
  int? _chargeSourceId;

  /// Fee per payment (22); empty is no fee.
  final _fee = TextEditingController();

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final payment = plan.allPayments.first;
    _input = PayLaterInput(
      purchaseDate: plan.purchaseDate ?? payment.date,
      rule: plan.payLaterRule ?? const PayLaterRule.chosenDate(),
      chosenDate: payment.date,
    );
    if (payment.originalDay != null && !payment.isPaid) {
      _input.moved = (
        date: payment.date,
        purchase: plan.purchaseDate,
        rule: plan.payLaterRule,
      );
    }
    _input.store.text = plan.plan.title ?? '';
    _input.source.text = plan.source?.name ?? '';
    _method = plan.plan.paymentMethod;
    _chargeSourceId = plan.chargeSourceId;
    for (final c in _input.controllers) {
      c.addListener(_refresh);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _input.amount.text = ref.moneyInput(context, payment.amountMinor);
      if (plan.installmentFee case final fee?) {
        _fee.text = ref.moneyInput(context, fee);
      }
    });
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _input.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final plan = widget.plan;
    final paid = plan.allPayments.first.isPaid;
    final amount = paid
        ? plan.allPayments.first.amountMinor
        : ref.parseMoney(context, _input.amount.text);
    final rule = _input.rule;
    if (amount == null || rule == null) return;
    final fee = typedInstallmentFee(context, ref, _fee.text);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final l10n = context.l10n;
    setState(() => _saving = true);
    final name = _input.source.text.trim();
    final sources = ref.read(sourcesProvider).value ?? const <SourceRow>[];
    final sourceId = name.isEmpty
        ? null
        : findSourceByName(sources, name)?.id ??
              await ref
                  .read(sourceRepositoryProvider)
                  .findOrCreateProvider(name);
    await ref
        .read(planRepositoryProvider)
        .editPayLater(
          plan.plan.id,
          title: _input.store.text,
          sourceId: sourceId,
          amountMinor: amount,
          purchaseDate: _input.purchaseDate,
          rule: rule,
          chosenDate: _input.chosenDate,
          installmentFee: (
            feeMinor: fee,
            scope: InstallmentFeeScope.everyPayment,
          ),
        );
    await ref
        .read(planRepositoryProvider)
        .setPaymentMethod(
          plan.plan.id,
          _method,
          chargeSourceId: storedChargeSourceId(
            _chargeSourceId,
            widget.plan.ownCardId,
          ),
        );
    KalanHaptics.success();
    router.popWithMessage(
      SnackBar(content: Text(l10n.planUpdated)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planEdit)),
      body: Form(
        key: _formKey,
        // Built in full, so the save button is always there to reach.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KalanSpace.md,
            KalanSpace.xs,
            KalanSpace.md,
            KalanSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PayLaterFields(
                input: _input,
                onChanged: _refresh,
                locked: widget.plan.allPayments.first.isPaid,
              ),
              const SizedBox(height: KalanSpace.md),
              PaymentMethodFields(
                method: _method,
                chargeSourceId: _chargeSourceId,
                onMethodChanged: (m) => setState(() => _method = m),
                onChargeSourceChanged: (id) =>
                    setState(() => _chargeSourceId = id),
              ),
              const SizedBox(height: KalanSpace.xs),
              _FeeSection(
                plan: widget.plan,
                controller: _fee,
                scope: InstallmentFeeScope.everyPayment,
                onScopeChanged: (_) {},
                onChanged: _refresh,
              ),
              const SizedBox(height: KalanSpace.md),
              FilledButton(
                key: const ValueKey('save-plan-edit'),
                onPressed: _saving ? null : _save,
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "More options" on the edit screens: the fee per payment (22) where the
/// kind has one, then the product price (23) when [priceController] is
/// given. Closed unless the plan has a fee or a price. Says calmly how many
/// unpaid payments the fee change touches, or that "first payment only"
/// adds nothing because the first payment is paid. Paid payments never
/// change; the price changes no payment at all.
class _FeeSection extends ConsumerWidget {
  const _FeeSection({
    required this.plan,
    required this.controller,
    required this.scope,
    required this.onScopeChanged,
    required this.onChanged,
    this.priceController,
  });

  /// Product price (23); null where the kind has none.
  final TextEditingController? priceController;

  final PlanWithPayments plan;
  final TextEditingController controller;
  final InstallmentFeeScope scope;
  final ValueChanged<InstallmentFeeScope> onScopeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fee = typedInstallmentFee(context, ref, controller.text);
    final payments = [for (final p in plan.allPayments) p.toFeePayment()];
    final scopeNow = plan.isPayLater ? InstallmentFeeScope.everyPayment : scope;
    final changes = unpaidFeeChanges(
      payments: payments,
      feeMinor: fee,
      scope: scopeNow,
    );
    final addsNothing = firstPaymentFeeAddsNothing(
      payments: payments,
      feeMinor: fee,
      scope: scopeNow,
    );
    return ExpansionTile(
      key: const ValueKey('more-options'),
      title: Text(l10n.moreOptions),
      initiallyExpanded:
          plan.installmentFee != null ||
          (priceController != null && plan.productPrice != null),
      tilePadding: EdgeInsets.zero,
      // Room above the field, so its floating label is never cut off.
      childrenPadding: const EdgeInsets.only(
        top: KalanSpace.xs,
        bottom: KalanSpace.xs,
      ),
      children: [
        if (canHaveInstallmentFee(plan.plan.kind))
          InstallmentFeeFields(
            controller: controller,
            scope: scope,
            showScope: !plan.isPayLater,
            // A paid "Pay later" keeps its fee, like its amount and date.
            enabled: !(plan.isPayLater && plan.allPayments.first.isPaid),
            onScopeChanged: onScopeChanged,
            onChanged: onChanged,
            notes: [
              if (addsNothing)
                ('installment-fee-first-paid', l10n.installmentFeeFirstPaid)
              else if (changes > 0)
                (
                  'installment-fee-affects',
                  l10n.installmentFeeAffects(changes),
                ),
            ],
          ),
        if (priceController case final price?) ...[
          if (canHaveInstallmentFee(plan.plan.kind))
            const SizedBox(height: KalanSpace.md),
          ProductPriceField(controller: price, onChanged: onChanged),
        ],
      ],
    );
  }
}
