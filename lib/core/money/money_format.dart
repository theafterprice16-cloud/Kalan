import 'package:intl/intl.dart';

import 'currency.dart';

bool _isTurkish(String localeName) => localeName.startsWith('tr');

String _symbol(Currency currency, String localeName) {
  final tr = _isTurkish(localeName);
  return switch (currency) {
    Currency.lira => tr ? 'TL' : '₺',
    Currency.dollar => r'$',
    Currency.pound => '£',
    Currency.euro => '€',
  };
}

/// Formats minor units for display.
///
/// Whole amounts drop the decimals ("3.250 TL", "$62"); amounts with cents
/// show two digits ("3.250,50 TL", "$62.05"). Turkish puts the symbol after
/// the number, English before it.
String formatMoney(int minor, Currency currency, String localeName) {
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ currency.minorPerMajor;
  final cents = abs % currency.minorPerMajor;
  final grouped = NumberFormat.decimalPattern(localeName).format(whole);
  final decimalSep = NumberFormat.decimalPattern(localeName)
      .symbols
      .DECIMAL_SEP;
  final number = cents == 0
      ? grouped
      : '$grouped$decimalSep${cents.toString().padLeft(2, '0')}';
  final symbol = _symbol(currency, localeName);
  final body = _isTurkish(localeName) ? '$number $symbol' : '$symbol$number';
  return negative ? '−$body' : body;
}

/// Plain number for an input field: no grouping, locale decimal separator.
String formatMinorForInput(int minor, String localeName) {
  final whole = minor ~/ 100;
  final cents = minor % 100;
  if (cents == 0) return '$whole';
  final sep = _isTurkish(localeName) ? ',' : '.';
  return '$whole$sep${cents.toString().padLeft(2, '0')}';
}

/// Parses user input into minor units without floating point.
///
/// Accepts both "1.234,56" and "1,234.56": the last `.` or `,` followed by
/// one or two digits is the decimal separator; other separators are
/// grouping. Currency symbols and spaces are ignored. Returns null for
/// anything else.
int? parseMinorUnits(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(
        RegExp(r'(TL|TRY|USD|GBP|EUR|[₺$£€])', caseSensitive: false),
        '',
      );
  if (cleaned.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(cleaned)) {
    return null;
  }
  final lastSep = cleaned.lastIndexOf(RegExp('[.,]'));
  var wholePart = cleaned;
  var fraction = '';
  if (lastSep >= 0) {
    final after = cleaned.substring(lastSep + 1);
    if (after.length <= 2) {
      wholePart = cleaned.substring(0, lastSep);
      fraction = after;
    } else if (after.length != 3) {
      return null;
    }
  }
  final digits = wholePart.replaceAll(RegExp('[.,]'), '');
  if (digits.isEmpty && fraction.isEmpty) return null;
  if (digits.length > 12) return null;
  final whole = digits.isEmpty ? 0 : int.parse(digits);
  final cents = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  return whole * 100 + cents;
}
