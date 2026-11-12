import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';

import 'currency.dart';

/// The only place amounts are turned into text.
///
/// Layout (symbol position, separators, spacing) comes from the app
/// language through intl; symbol and digits come from [Currency]. Amounts
/// stay integers: intl formats the whole part, the minor part is added
/// from the integer remainder. Whole amounts drop their minor digits.
///
/// tr, TRY, 123456 → ₺1.234,56 · de, EUR → 1.234,56 € ·
/// id, IDR, 1234567 → Rp1.234.567.
String formatMoney(
  int minor,
  Currency currency, {
  required String localeName,
  String? region,
}) {
  final symbol = currency.symbolFor(region);
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

NumberSymbols _symbols(String localeName) =>
    NumberFormat.decimalPattern(localeName).symbols;

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
}) {
  if (input.contains('-')) return null;
  final cleaned = input.replaceAll(RegExp(r'[^0-9.,]'), '');
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
  if (wholeDigits.length > 13) return null;
  final whole = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
  final fraction = fractionText.isEmpty
      ? 0
      : int.parse(fractionText.padRight(currency.decimals, '0'));
  return whole * currency.minorPerMajor + fraction;
}
