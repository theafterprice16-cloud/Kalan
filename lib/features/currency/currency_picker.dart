import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = foldForSearch(_query.text.trim());
    final names = {for (final c in Currency.all) c: currencyName(context, c)};
    final language = context.localeName.split(RegExp('[-_]')).first;
    final sorted = [...Currency.all]
      ..sort((a, b) => compareNames(names[a]!, names[b]!, language));

    Widget tile(Currency c, String section) {
      final selected = c == widget.selected;
      return Semantics(
        selected: selected,
        child: ListTile(
          key: ValueKey('$section-${c.code}'),
          minTileHeight: 64,
          leading: _SymbolBox(c.symbol),
          title: Text(names[c]!),
          subtitle: Text(
            c.pickerLabel,
            style: TextStyle(color: context.colors.textMuted),
          ),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop(c),
        ),
      );
    }

    final List<Widget> rows;
    if (q.isEmpty) {
      final suggested = Currency.suggested(
        region: ref.watch(deviceRegionProvider),
        languageCode: language,
      );
      rows = [
        SectionTitle(l10n.currencySuggested),
        for (final c in suggested) tile(c, 'suggested'),
        SectionTitle(l10n.currencyAll),
        for (final c in sorted) tile(c, 'currency'),
      ];
    } else {
      rows = [
        for (final c in sorted)
          if (matchesCurrency(c, names[c]!, q)) tile(c, 'currency'),
      ];
    }

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
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.currencyNoMatch,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  )
                : ListView(children: rows),
          ),
        ],
      ),
    );
  }
}

/// Lowercase without Turkish dotted/dotless i differences or accents that
/// matter for search ("İsrail", "israil" and "ISRAIL" all match).
String foldForSearch(String text) => text
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('\u0307', '')
    .replaceAll('ı', 'i');

/// Search by name, ISO code, symbol or distinctive symbol; [query] is
/// already folded.
bool matchesCurrency(Currency c, String name, String query) => [
  c.code,
  c.symbol,
  c.distinctiveSymbol,
  name,
].any((t) => foldForSearch(t).contains(query));

const _turkishOrder = 'abcçdefgğhıijklmnoöprsştuüvyz';

/// Sorts names in the app language; Turkish letters keep their place.
int compareNames(String a, String b, String language) {
  if (language != 'tr') return a.toLowerCase().compareTo(b.toLowerCase());
  String key(String s) => String.fromCharCodes(
    s
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('\u0307', '')
        .runes
        .map((r) {
          final i = _turkishOrder.indexOf(String.fromCharCode(r));
          return i < 0 ? r + 0x100 : 0x41 + i;
        }),
  );
  return key(a).compareTo(key(b));
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
    final label = '${value.pickerLabel} · ${currencyName(context, value)}';
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
        formatMoney(minor, c, localeName: context.localeName);
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
