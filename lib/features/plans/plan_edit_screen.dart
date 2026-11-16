import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import 'add_plan_screen.dart' show findSourceByName;
import 'interval_field.dart';
import 'pay_later_form.dart';

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

  @override
  void dispose() {
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
    PlanKind.card => switch (plan.source?.cardTerms) {
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
      for (final p in plan.payments) p.toState(),
    ]);
    if (n < min) return l10n.errorCountMin(min);
    return _countError;
  }

  /// The payment the "next payment date" belongs to, when it may move.
  PaymentRow? _nextPayment(PlanWithPayments plan) {
    final n = _paidCount(plan);
    if (n == null || n < 0 || n >= plan.payments.length) return null;
    final p = plan.payments[n];
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
    final run = leadingRunOf(plan.payments);
    final max = run == plan.payments.length
        ? count - 1
        : maxPaidBeforeOf(plan.payments);
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
    final count = _underway ? _paidCount(plan) ?? 0 : 0;
    final back = plan.paidBefore.length - count;
    if (back > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('underway-revert'),
          content: Text(l10n.underwayRevert(back)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              key: const ValueKey('underway-revert-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.underwayRevertConfirm),
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
    final max = maxPaidBeforeOf(plan.payments);
    final payIn4 = _isPayIn4(plan);
    final next = _nextPayment(plan);
    final showDate = _pattern(plan) != null && next != null;
    final nextDate = _nextDateTouched ? _nextDate : next?.date;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planEdit)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                  SwitchListTile(
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
                    const SizedBox(height: 8),
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
              IntervalField(input: interval, onChanged: () => setState(() {})),
              const SizedBox(height: 8),
              Text(
                l10n.intervalEditHint,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.colors.textMuted),
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

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final payment = plan.payments.first;
    _input = PayLaterInput(
      purchaseDate: plan.purchaseDate ?? payment.date,
      rule: plan.payLaterRule ?? const PayLaterRule.chosenDate(),
      chosenDate: payment.date,
    );
    _input.store.text = plan.plan.title ?? '';
    _input.source.text = plan.source?.name ?? '';
    for (final c in _input.controllers) {
      c.addListener(_refresh);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _input.amount.text = ref.moneyInput(context, payment.amountMinor);
    });
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final plan = widget.plan;
    final paid = plan.payments.first.isPaid;
    final amount = paid
        ? plan.payments.first.amountMinor
        : ref.parseMoney(context, _input.amount.text);
    final rule = _input.rule;
    if (amount == null || rule == null) return;
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
        );
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PayLaterFields(
              input: _input,
              onChanged: _refresh,
              locked: widget.plan.payments.first.isPaid,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('save-plan-edit'),
              onPressed: _saving ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
