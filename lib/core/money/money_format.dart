import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';

import 'currency.dart';

/// The only place amounts are turned into text.
///
/// Layout (symbol position, separators, spacing) comes from the app
/// language through intl; symbol and digits come from [Currency]. Amounts
/// stay integers: intl formats the whole part, the minor part is added
/// from the integer remainder with exactly [Currency.decimals] digits.
/// Whole amounts drop their minor digits.
///
/// Amounts always carry the currency's own symbol, also when it is shared
/// ("$" for COP); the picker tells currencies apart. A right-to-left
/// symbol (ر.س) is isolated so the digits keep their order.
///
/// What every amount on screen shows while "Hide amounts" is on (Roadmap
/// 28): the same three dots whatever the amount, its sign or the
/// currency, so neither a symbol nor the length gives anything away.
const amountMask = '•••';

/// tr, TRY, 123456 → ₺1.234,56 · de, EUR → 1.234,56 € ·
/// id, IDR, 1234567 → Rp1.234.567.
String formatMoney(int minor, Currency currency, {required String localeName}) {
  final symbol = isolateRtl(currency.symbol);
  final format = _currencyFormat(localeName, currency.code, symbol);
  final symbols = format.symbols;
  final factor = currency.minorPerMajor;
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ factor;
  final fraction = abs % factor;

  var text = format.format(negative && whole > 0 ? -whole : whole);
  if (negative && whole == 0) text = '${symbols.MINUS_SIGN}$text';
  if (fraction == 0) return text;

  final digits = fraction.toString().padLeft(currency.decimals, '0');
  final lastDigit = text.lastIndexOf(RegExp('[0-9]'));
  return '${text.substring(0, lastDigit + 1)}'
      '${symbols.DECIMAL_SEP}$digits'
      '${text.substring(lastDigit + 1)}';
}

/// A short amount for narrow places (labels under chart bars): below 1,000
/// whole units exactly [formatMoney]; from 1,000 on, intl's compact form
/// in the app language, without minor digits.
///
/// tr, TRY, 1240000 → ₺12,4 B · en, USD, 123456789 → $1.23M ·
/// en, JPY, 999 → ¥999 · en, IDR, 120000000 → Rp120M.
String formatMoneyShort(
  int minor,
  Currency currency, {
  required String localeName,
}) {
  final whole = minor.abs() ~/ currency.minorPerMajor;
  if (whole < 1000) {
    return formatMoney(minor, currency, localeName: localeName);
  }
  final format = _compactFormats.putIfAbsent(
    '$localeName|${currency.code}',
    () => NumberFormat.compactCurrency(
      locale: localeName,
      name: currency.code,
      symbol: isolateRtl(currency.symbol),
    ),
  );
  return format.format(minor < 0 ? -whole : whole);
}

final _compactFormats = <String, NumberFormat>{};

final _formats = <String, NumberFormat>{};

NumberFormat _currencyFormat(String locale, String code, String symbol) =>
    _formats.putIfAbsent(
      '$locale|$code|$symbol',
      () => NumberFormat.currency(
        locale: locale,
        name: code,
        symbol: symbol,
        decimalDigits: 0,
      ),
    );

/// Wraps [text] in a first-strong isolate (U+2068 … U+2069) when it holds
/// right-to-left letters, so it shows intact inside left-to-right text.
String isolateRtl(String text) =>
    _rtl.hasMatch(text) ? '\u2068$text\u2069' : text;

final _rtl = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

NumberSymbols _symbols(String localeName) =>
    NumberFormat.decimalPattern(localeName).symbols;

/// The most digits an amount field takes before the decimal separator.
const maxWholeDigits = 13;

/// The largest amount an amount field takes in [currency], in minor units
/// ([maxWholeDigits] nines and a full fraction).
int maxTypedAmountMinor(Currency currency) {
  var whole = 1;
  for (var i = 0; i < maxWholeDigits; i++) {
    whole *= 10;
  }
  return whole * currency.minorPerMajor - 1;
}

/// Plain number for an input field: no grouping, the language's decimal
/// separator, minor digits only when non-zero.
String formatMinorForInput(
  int minor,
  Currency currency, {
  required String localeName,
}) {
  final factor = currency.minorPerMajor;
  final whole = minor ~/ factor;
  final fraction = minor % factor;
  if (fraction == 0) return '$whole';
  return '$whole${_symbols(localeName).DECIMAL_SEP}'
      '${fraction.toString().padLeft(currency.decimals, '0')}';
}

/// A sample input ("1250,50", "1250.50" or "1250") for hints and errors.
String amountInputExample(Currency currency, {required String localeName}) =>
    formatMinorForInput(
      1250 * currency.minorPerMajor + currency.minorPerMajor ~/ 2,
      currency,
      localeName: localeName,
    );

/// [text] with what Arabic and Persian keyboards type (٠-٩, ۰-۹, ٫, ٬)
/// as the app writes amounts: Western digits and [localeName]'s
/// separators (Roadmap 24). Same length, so a cursor stays in place.
String westernDigits(String text, {required String localeName}) {
  if (!_easternInput.hasMatch(text)) return text;
  final symbols = _symbols(localeName);
  return text.replaceAllMapped(_easternInput, (m) {
    final unit = m[0]!.codeUnitAt(0);
    if (unit == 0x066B) return symbols.DECIMAL_SEP;
    if (unit == 0x066C) return symbols.GROUP_SEP;
    final zero = unit >= 0x06F0 ? 0x06F0 : 0x0660;
    return '${unit - zero}';
  });
}

final _easternInput = RegExp('[\u0660-\u0669\u066B\u066C\u06F0-\u06F9]');

/// Whether an amount field may hold [text] while typing: digits, spaces
/// and separators only; no decimal separator for currencies without minor
/// digits (JPY) and at most [Currency.decimals] digits after it (three for
/// KWD). Anything else is kept out of the field; [parseAmount] still
/// checks the full value.
bool acceptsAmountInput(
  String text,
  Currency currency, {
  required String localeName,
}) {
  text = westernDigits(text, localeName: localeName);
  if (!RegExp(r'^[0-9., ]*$').hasMatch(text)) return false;
  final decimalSep = _symbols(localeName).DECIMAL_SEP;
  final parts = text.split(decimalSep);
  if (parts.length == 1) return true;
  if (currency.decimals == 0 || parts.length > 2) return false;
  return RegExp(r'^[0-9]*$').hasMatch(parts[1]) &&
      parts[1].length <= currency.decimals;
}

/// Parses typed text into minor units using the app language's separators.
///
/// Spaces and currency symbols are ignored. The decimal separator may
/// appear once, followed by at most [Currency.decimals] digits; currencies
/// without minor digits reject it. Grouping separators must split the
/// whole part into groups of three ("1.234.567"), so "62.5" in Turkish is
/// rejected rather than read as 625. Returns null when the text is not a
/// valid non-negative amount.
int? parseAmount(
  String input,
  Currency currency, {
  required String localeName,
}) => _parseAmount(input, currency, localeName, maxWholeDigits);

/// Whether [input] is a well-formed amount with more than
/// [maxWholeDigits] digits before the decimal separator: wrong only in
/// size, so it gets a "too large" message instead of an example.
bool amountTooLarge(
  String input,
  Currency currency, {
  required String localeName,
}) =>
    parseAmount(input, currency, localeName: localeName) == null &&
    _parseAmount(input, currency, localeName, 18) != null;

int? _parseAmount(
  String input,
  Currency currency,
  String localeName,
  int maxWhole,
) {
  if (input.contains('-')) return null;
  // Symbols may hold separators ("B/.", "د.ك"); drop them first.
  var text = westernDigits(input, localeName: localeName);
  for (final s in [
    currency.distinctiveSymbol,
    currency.symbol,
    currency.code,
  ]..sort((a, b) => b.length.compareTo(a.length))) {
    text = text.replaceAll(s, '');
  }
  final cleaned = text.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (cleaned.isEmpty) return null;

  final symbols = _symbols(localeName);
  final decimalSep = symbols.DECIMAL_SEP;
  final groupSep = symbols.GROUP_SEP;

  final parts = cleaned.split(decimalSep);
  if (parts.length > 2) return null;
  final wholeText = parts[0];
  final fractionText = parts.length == 2 ? parts[1] : '';

  if (parts.length == 2 && currency.decimals == 0) return null;
  if (fractionText.length > currency.decimals) return null;
  if (!RegExp(r'^[0-9]*$').hasMatch(fractionText)) return null;

  String wholeDigits;
  if (RegExp(r'^[0-9]*$').hasMatch(wholeText)) {
    wholeDigits = wholeText;
  } else {
    if (groupSep != '.' && groupSep != ',') return null;
    final groups = wholeText.split(groupSep);
    final valid =
        groups.first.isNotEmpty &&
        groups.first.length <= 3 &&
        groups.every((g) => RegExp(r'^[0-9]+$').hasMatch(g)) &&
        groups.skip(1).every((g) => g.length == 3);
    if (!valid) return null;
    wholeDigits = groups.join();
  }

  if (wholeDigits.isEmpty && fractionText.isEmpty) return null;
  if (wholeDigits.length > maxWhole) return null;
  final whole = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
  final fraction = fractionText.isEmpty
      ? 0
      : int.parse(fractionText.padRight(currency.decimals, '0'));
  return whole * currency.minorPerMajor + fraction;
}
