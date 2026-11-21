import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';

/// The fee per payment (22) as typed: null while empty or not a valid
/// amount; zero is "no fee" ([normalizeInstallmentFee]).
int? typedInstallmentFee(BuildContext context, WidgetRef ref, String text) {
  if (text.trim().isEmpty) return null;
  return normalizeInstallmentFee(ref.parseMoney(context, text));
}

/// "Fee per payment" and, once a fee is typed, which payments take it
/// (22). Lives under the collapsed "More details" section of the add and
/// edit plan screens, so the default form keeps its fields. Never shown
/// for card installments. Empty and zero are "no fee"; the amount uses the
/// app's one money path. [notes] are calm lines under the choice (the
/// edit screen's "This changes … unpaid payments.").
class InstallmentFeeFields extends ConsumerWidget {
  const InstallmentFeeFields({
    required this.controller,
    required this.scope,
    required this.onScopeChanged,
    required this.onChanged,
    this.showScope = true,
    this.enabled = true,
    this.notes = const [],
    super.key,
  });

  final TextEditingController controller;
  final InstallmentFeeScope scope;
  final ValueChanged<InstallmentFeeScope> onScopeChanged;
  final VoidCallback onChanged;

  /// False for "Pay later": one payment, no choice.
  final bool showScope;

  /// False when nothing could change: a paid "Pay later" plan, whose one
  /// payment keeps its own fee.
  final bool enabled;

  /// (key, text) of each calm line.
  final List<(String, String)> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    final hasFee = typedInstallmentFee(context, ref, controller.text) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('installment-fee'),
          controller: controller,
          enabled: enabled,
          keyboardType: ref.amountKeyboard,
          inputFormatters: ref.amountFormatters(context),
          decoration: InputDecoration(
            labelText: l10n.installmentFeeLabel,
            helperText: l10n.installmentFeeHelper,
            helperMaxLines: 3,
          ),
          onChanged: (_) => onChanged(),
          validator: (text) {
            // Empty and zero are "no fee"; only an amount that cannot be
            // kept is refused.
            if (text == null || text.trim().isEmpty) return null;
            final v = ref.parseMoney(context, text);
            if (v == null || v < 0) return ref.amountError(context, text);
            return null;
          },
        ),
        if (hasFee && showScope) ...[
          const SizedBox(height: KalanSpace.sm),
          ChoiceField<InstallmentFeeScope>(
            key: const ValueKey('installment-fee-scope'),
            label: l10n.installmentFeeScopeLabel,
            selected: scope,
            options: [
              (InstallmentFeeScope.everyPayment, l10n.installmentFeeScopeEvery),
              (
                InstallmentFeeScope.firstPaymentOnly,
                l10n.installmentFeeScopeFirst,
              ),
            ],
            onSelected: onScopeChanged,
          ),
        ],
        for (final (id, note) in notes)
          Padding(
            padding: const EdgeInsets.only(top: KalanSpace.xs),
            child: Text(note, key: ValueKey(id), style: muted),
          ),
      ],
    );
  }
}

/// The plan summary rows: "Plan amount / Payment fees" when the plan has
/// fees per payment (22), the one "Total you repay" row, and "Product
/// price / Difference" when [price] is shown (23). Shown only when there
/// is a fee or a price to show; otherwise screens keep their plain "Total"
/// line. Labels textMuted, amounts text; no accent, no warning, no
/// judgement (the fee and the price are known parts of the plan).
class InstallmentFeeSummary extends ConsumerWidget {
  const InstallmentFeeSummary({
    required this.planMinor,
    required this.feesMinor,
    this.price,
    super.key,
  });

  final int planMinor;
  final int feesMinor;

  /// "Product price" and "Difference" (23); null hides both rows.
  final PriceDifference? price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final style = Theme.of(context).textTheme.bodyMedium;
    Widget row(String id, String label, int minor) => Padding(
      padding: const EdgeInsets.only(top: KalanSpace.xxs),
      child: Row(
        key: ValueKey(id),
        children: [
          Expanded(
            child: Text(label, style: style?.copyWith(color: colors.textMuted)),
          ),
          Text(
            ref.money(context, minor),
            style: style?.copyWith(
              color: colors.text,
              fontFeatures: AmountText.tabular,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feesMinor > 0) ...[
          row('fee-summary-plan', l10n.planAmountLabel, planMinor),
          row('fee-summary-fees', l10n.installmentFeesLabel, feesMinor),
        ],
        row('fee-summary-total', l10n.planTotalLabel, planMinor + feesMinor),
        if (price case final price?) ...[
          row(
            'price-summary-price',
            l10n.productPriceLabel,
            price.productPriceMinor,
          ),
          row(
            'price-summary-difference',
            l10n.priceDifferenceLabel,
            price.differenceMinor,
          ),
        ],
      ],
    );
  }
}
