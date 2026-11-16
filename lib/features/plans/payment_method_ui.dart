import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/design/form_fields.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';

/// The icon of a payment method; always shown with its word (on screen or
/// as the screen reader label), never alone.
IconData paymentMethodIcon(PaymentMethod method) => switch (method) {
  PaymentMethod.automatic => Icons.autorenew,
  PaymentMethod.manual => Icons.front_hand_outlined,
};

/// "Taken automatically", "Paid manually" or "Not set".
String paymentMethodName(AppLocalizations l10n, PaymentMethod? method) =>
    switch (method) {
      PaymentMethod.automatic => l10n.paymentMethodAutomatic,
      PaymentMethod.manual => l10n.paymentMethodManual,
      null => l10n.paymentMethodNotSet,
    };

/// The small payment method icon in textMuted, read out as its word.
class PaymentMethodIcon extends StatelessWidget {
  const PaymentMethodIcon(this.method, {super.key, this.size = 16});

  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    paymentMethodIcon(method),
    key: ValueKey('payment-method-icon-${method.name}'),
    size: size,
    color: context.colors.textMuted,
    semanticLabel: paymentMethodName(context.l10n, method),
  );
}

/// The payment method choice (Taken automatically / Paid manually / Not
/// set) and, for an automatic one, where it is taken from. Optional: "Not
/// set" keeps the reminders as before. A card plan ([ownCardId]) starts
/// with its own card as the source and has no "Not chosen".
class PaymentMethodFields extends ConsumerWidget {
  const PaymentMethodFields({
    required this.method,
    required this.chargeSourceId,
    required this.onMethodChanged,
    required this.onChargeSourceChanged,
    super.key,
    this.ownCardId,
  });

  final PaymentMethod? method;

  /// The chosen source; null is "not chosen" (or the plan's own card).
  final int? chargeSourceId;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final ValueChanged<int?> onChargeSourceChanged;
  final int? ownCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sources = ref.watch(sourcesProvider).value ?? const <SourceRow>[];
    final hint = switch (method) {
      PaymentMethod.automatic => l10n.paymentMethodAutomaticHint,
      PaymentMethod.manual => l10n.paymentMethodManualHint,
      null => null,
    };
    final selected = chargeSourceId ?? ownCardId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceField<PaymentMethod?>(
          key: const ValueKey('payment-method'),
          label: l10n.paymentMethodLabel,
          selected: method,
          options: [
            (PaymentMethod.automatic, l10n.paymentMethodAutomatic),
            (PaymentMethod.manual, l10n.paymentMethodManual),
            (null, l10n.paymentMethodNotSet),
          ],
          onSelected: onMethodChanged,
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            key: const ValueKey('payment-method-hint'),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.colors.textMuted),
          ),
        ],
        if (method == PaymentMethod.automatic && sources.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            // A different card on the add screen starts it again.
            key: ValueKey('charge-source-$ownCardId'),
            initialValue: sources.any((s) => s.id == selected)
                ? selected
                : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.chargeSourceLabel),
            items: [
              if (ownCardId == null)
                DropdownMenuItem(child: Text(l10n.chargeSourceNone)),
              for (final s in sources)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChargeSourceChanged,
          ),
        ],
      ],
    );
  }
}

/// The value to store for [selected]: a card plan's own card is stored
/// as "not chosen" (it follows the plan's card).
int? storedChargeSourceId(int? selected, int? ownCardId) =>
    selected == ownCardId ? null : selected;

/// "Payment method" row on the plan details: icon and word together, and
/// where an automatic payment is taken from. Tapping changes it.
class PaymentMethodTile extends ConsumerWidget {
  const PaymentMethodTile({required this.plan, super.key});

  final PlanWithPayments plan;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(planRepositoryProvider);
    final sources = ref.read(sourcesProvider).value ?? const <SourceRow>[];
    final picked = await showChoiceDialog<PaymentMethod?>(
      context,
      title: l10n.paymentMethodLabel,
      selected: plan.plan.paymentMethod,
      options: [
        (PaymentMethod.automatic, l10n.paymentMethodAutomatic),
        (PaymentMethod.manual, l10n.paymentMethodManual),
        (null, l10n.paymentMethodNotSet),
      ],
    );
    if (picked == null || !context.mounted) return;
    final method = picked.value;
    var source = plan.chargeSourceId ?? plan.ownCardId;
    if (method == PaymentMethod.automatic && sources.isNotEmpty) {
      final where = await showChoiceDialog<int?>(
        context,
        title: l10n.chargeSourceLabel,
        selected: source,
        options: [
          if (plan.ownCardId == null) (null, l10n.chargeSourceNone),
          for (final s in sources) (s.id, s.name),
        ],
      );
      // Dismissed: the method still changes, the source stays.
      if (where != null) source = where.value;
    }
    await repo.setPaymentMethod(
      plan.plan.id,
      method,
      chargeSourceId: storedChargeSourceId(source, plan.ownCardId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final method = plan.plan.paymentMethod;
    final sources = ref.watch(sourcesProvider).value ?? const <SourceRow>[];
    final from = sources
        .where((s) => s.id == plan.chargeSourceId)
        .firstOrNull
        ?.name;
    final name = paymentMethodName(l10n, method);
    return ListTile(
      key: const ValueKey('item-payment-method'),
      leading: method == null
          ? Icon(Icons.payments_outlined, color: context.colors.textMuted)
          : Icon(paymentMethodIcon(method), color: context.colors.textMuted),
      title: Text(l10n.paymentMethodLabel),
      subtitle: Text(
        from == null ? name : l10n.paymentMethodFrom(name, from),
        style: TextStyle(color: context.colors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pick(context, ref),
    );
  }
}
