import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/theme/kalan_theme.dart';

/// The currency's name in the app language.
String currencyName(BuildContext context, Currency currency) =>
    context.l10n.currencyName(currency.code);

/// Opens the searchable list; returns the picked currency or null.
Future<Currency?> showCurrencyPicker(
  BuildContext context, {
  required Currency selected,
}) => Navigator.of(context).push<Currency>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => CurrencyPickerScreen(selected: selected),
  ),
);

class CurrencyPickerScreen extends ConsumerStatefulWidget {
  const CurrencyPickerScreen({required this.selected, super.key});

  final Currency selected;

  @override
  ConsumerState<CurrencyPickerScreen> createState() =>
      _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends ConsumerState<CurrencyPickerScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Currency c, String q) {
    if (q.isEmpty) return true;
    return [
      c.code,
      c.symbol,
      c.distinctiveSymbol,
      currencyName(context, c),
    ].any((t) => t.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final region = ref.watch(deviceRegionProvider);
    final q = _query.text.trim().toLowerCase();
    final items = Currency.all.where((c) => _matches(c, q)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fieldCurrency)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const ValueKey('currency-search'),
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.currencySearch,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.currencyNoMatch,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final selected = c == widget.selected;
                      return Semantics(
                        selected: selected,
                        child: ListTile(
                          key: ValueKey('currency-${c.code}'),
                          minTileHeight: 64,
                          leading: _SymbolBox(c.symbolFor(region)),
                          title: Text(currencyName(context, c)),
                          subtitle: Text(
                            c.code,
                            style: TextStyle(color: context.colors.textMuted),
                          ),
                          trailing: selected ? const Icon(Icons.check) : null,
                          onTap: () => Navigator.of(context).pop(c),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SymbolBox extends StatelessWidget {
  const _SymbolBox(this.symbol);

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              symbol,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A form field showing the chosen currency; tapping opens the picker.
class CurrencyField extends ConsumerWidget {
  const CurrencyField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final region = ref.watch(deviceRegionProvider);
    final label =
        '${value.symbolFor(region)} · ${value.code} · '
        '${currencyName(context, value)}';
    return Semantics(
      button: true,
      label: l10n.fieldCurrency,
      value: label,
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('currency-field'),
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showCurrencyPicker(context, selected: value);
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.fieldCurrency,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Confirms a currency change: no conversion, only the label changes;
/// shows an example of what an amount will look like.
class CurrencyChangeDialog extends ConsumerWidget {
  const CurrencyChangeDialog({required this.from, required this.to, super.key});

  final Currency from;
  final Currency to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final region = ref.watch(deviceRegionProvider);
    final sample = scaleMinor(
      123456,
      fromDecimals: 2,
      toDecimals: from.decimals,
    );
    final after = scaleMinor(
      sample,
      fromDecimals: from.decimals,
      toDecimals: to.decimals,
    );
    String show(int minor, Currency c) =>
        formatMoney(minor, c, localeName: context.localeName, region: region);
    return AlertDialog(
      title: Text(l10n.currencyChangeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsCurrencyNote),
          const SizedBox(height: 12),
          Text(
            l10n.currencyChangePreview(show(sample, from), show(after, to)),
            key: const ValueKey('currency-preview'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (from.decimals != to.decimals) ...[
            const SizedBox(height: 12),
            Text(l10n.currencyChangeRounding),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          key: const ValueKey('currency-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.currencyChangeConfirm),
        ),
      ],
    );
  }
}
