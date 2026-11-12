/// The single source of truth for currencies. Pure Dart.
///
/// To add a currency: add one row to [Currency.all] and its name to the
/// `currencyName` select message in every ARB file. Nothing else.
class Currency {
  const Currency._(
    this.code, {
    required this.symbol,
    required this.decimals,
    required this.countries,
    String? distinctiveSymbol,
  }) : distinctiveSymbol = distinctiveSymbol ?? symbol;

  /// ISO 4217 code; also the stored value.
  final String code;

  /// Symbol used inside the currency's own countries.
  final String symbol;

  /// Symbol used elsewhere, for currencies that share "$".
  final String distinctiveSymbol;

  /// Minor-unit digits Kalan stores and shows. May differ from ISO 4217
  /// where cents are not used in daily life (IDR, COP).
  final int decimals;

  /// ISO 3166-1 alpha-2 regions where this is the local currency.
  final Set<String> countries;

  /// Minor units per major unit: 10^[decimals].
  int get minorPerMajor => pow10(decimals);

  /// "$" inside the currency's own region, the distinctive symbol
  /// ("MX$", "CA$", …) everywhere else.
  String symbolFor(String? region) =>
      region != null && countries.contains(region.toUpperCase())
      ? symbol
      : distinctiveSymbol;

  static const _euroArea = {
    'AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT', //
    'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK', 'AD', 'MC', 'ME', 'SM',
    'VA', 'XK',
  };

  static const all = <Currency>[
    Currency._('TRY', symbol: '₺', decimals: 2, countries: {'TR'}),
    Currency._('USD', symbol: r'$', decimals: 2, countries: {'US'}),
    Currency._('EUR', symbol: '€', decimals: 2, countries: _euroArea),
    Currency._('GBP', symbol: '£', decimals: 2, countries: {'GB'}),
    Currency._('BRL', symbol: r'R$', decimals: 2, countries: {'BR'}),
    Currency._(
      'MXN',
      symbol: r'$',
      distinctiveSymbol: r'MX$',
      decimals: 2,
      countries: {'MX'},
    ),
    Currency._(
      'COP',
      symbol: r'$',
      distinctiveSymbol: r'COL$',
      decimals: 0,
      countries: {'CO'},
    ),
    Currency._(
      'CLP',
      symbol: r'$',
      distinctiveSymbol: r'CLP$',
      decimals: 0,
      countries: {'CL'},
    ),
    Currency._('RUB', symbol: '₽', decimals: 2, countries: {'RU'}),
    Currency._('KZT', symbol: '₸', decimals: 2, countries: {'KZ'}),
    Currency._('CNY', symbol: '¥', decimals: 2, countries: {'CN'}),
    Currency._(
      'SGD',
      symbol: r'$',
      distinctiveSymbol: r'S$',
      decimals: 2,
      countries: {'SG'},
    ),
    Currency._('MYR', symbol: 'RM', decimals: 2, countries: {'MY'}),
    Currency._('IDR', symbol: 'Rp', decimals: 0, countries: {'ID'}),
    Currency._(
      'CAD',
      symbol: r'$',
      distinctiveSymbol: r'CA$',
      decimals: 2,
      countries: {'CA'},
    ),
    Currency._(
      'AUD',
      symbol: r'$',
      distinctiveSymbol: r'A$',
      decimals: 2,
      countries: {'AU'},
    ),
    Currency._('CHF', symbol: 'CHF', decimals: 2, countries: {'CH', 'LI'}),
  ];

  /// Fallback for unknown codes and regions.
  static Currency get fallback => byCode('USD')!;

  static Currency? byCode(String code) {
    final upper = code.toUpperCase();
    for (final c in all) {
      if (c.code == upper) return c;
    }
    return null;
  }

  /// Stored codes always exist; unknown ones fall back to USD.
  static Currency fromCode(String code) => byCode(code) ?? fallback;

  /// Suggested currency for a device region; USD when none matches.
  static Currency forRegion(String? region) {
    if (region == null) return fallback;
    final upper = region.toUpperCase();
    for (final c in all) {
      if (c.countries.contains(upper)) return c;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Currency($code)';
}

/// 10^[n] for small non-negative [n].
int pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

/// Moves a stored amount between minor-unit bases without conversion.
///
/// More digits multiply; fewer digits round half up (amounts are never
/// negative). 123456 (2 digits) → 1235 (0 digits); 1235 → 123500.
int scaleMinor(
  int value, {
  required int fromDecimals,
  required int toDecimals,
}) {
  if (value < 0) throw ArgumentError.value(value, 'value', 'negative');
  if (toDecimals >= fromDecimals) {
    return value * pow10(toDecimals - fromDecimals);
  }
  final factor = pow10(fromDecimals - toDecimals);
  final q = value ~/ factor;
  final r = value % factor;
  return r * 2 >= factor ? q + 1 : q;
}
