import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/engine/engine.dart';

/// The product price (23) as typed: null while empty, zero or not a valid
/// amount ("not entered", [normalizeProductPrice]).
int? typedProductPrice(BuildContext context, WidgetRef ref, String text) {
  if (text.trim().isEmpty) return null;
  return normalizeProductPrice(ref.parseMoney(context, text));
}

/// "Product price" with its helper (23). Lives under the collapsed "More
/// details" (add) and "More options" (edit) sections, after the fee per
/// payment, so the default form keeps its fields. Only for kinds that
/// [canHaveProductPrice]. Empty and zero are "not entered"; a price above
/// the total is kept without a word. The amount uses the app's one money
/// path.
class ProductPriceField extends ConsumerWidget {
  const ProductPriceField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return TextFormField(
      key: const ValueKey('product-price'),
      controller: controller,
      keyboardType: ref.amountKeyboard,
      inputFormatters: ref.amountFormatters(context),
      decoration: InputDecoration(
        labelText: l10n.productPriceLabel,
        helperText: l10n.productPriceHelper,
        helperMaxLines: 3,
      ),
      onChanged: (_) => onChanged(),
      validator: (text) {
        // Empty and zero are "not entered"; only an amount that cannot be
        // kept is refused.
        if (text == null || text.trim().isEmpty) return null;
        final v = ref.parseMoney(context, text);
        if (v == null || v < 0) return ref.amountError(context, text);
        return null;
      },
    );
  }
}
