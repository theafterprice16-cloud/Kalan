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
  bool _loaded = false;
  bool _underway = false;
  int _paidPayIn4 = 1;
  LocalDate? _nextDate;
  bool _nextDateTouched = false;
  bool _saving = false;

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  void _load(PlanWithPayments plan) {
    if (_loaded) return;
    _loaded = true;
    final before = plan.paidBefore.length;
    _underway = before > 0;
    final initial = before > 0 ? before : 1;
    _paid.text = '$initial';
    _paidPayIn4 = initial.clamp(1, 3);
  }

  bool _isPayIn4(PlanWithPayments plan) => plan.plan.kind == PlanKind.payIn4;

  int? _paidCount(PlanWithPayments plan) =>
      _isPayIn4(plan) ? _paidPayIn4 : int.tryParse(_paid.text.trim());

  /// How the dates repeat, or null when the plan has no fixed pattern
  /// (manual entry, a card without its days): no next date field then.
  UnderwayPattern? _pattern(PlanWithPayments plan) => switch (plan.plan.kind) {
    PlanKind.monthly => const MonthlyPattern(),
    PlanKind.payIn4 => const PayIn4Pattern(),
    PlanKind.card => switch (plan.source.cardTerms) {
      final terms? => CardPattern(terms),
      null => null,
    },
    PlanKind.manual => null,
  };

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
    if (n >= plan.plan.installmentCount) return l10n.errorPaidAll;
    final max = maxPaidBeforeOf(plan.payments);
    if (n > max) return l10n.errorPaidMax(max);
    return null;
  }

  Future<void> _save(PlanWithPayments plan) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
    await ref
        .read(planRepositoryProvider)
        .setPaidBefore(
          plan.plan.id,
          count: count,
          nextDate: moveDates ? _nextDate : null,
          pattern: moveDates ? pattern : null,
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.planUpdated)));
    router.pop();
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
                        key: const ValueKey('total-installments'),
                        initialValue: context.l10n.numberValue(
                          plan.plan.installmentCount,
                        ),
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: l10n.fieldTotalInstallments,
                        ),
                      ),
                      gap,
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
