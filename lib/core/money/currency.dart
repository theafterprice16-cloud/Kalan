/// The single source of truth for currencies. Pure Dart.
///
/// To add a currency: add one row to [Currency.all] and its name to the
/// `currencyName` select message in the Turkish and English ARB files.
/// Nothing else.
class Currency {
  const Currency._(
    this.code, {
    required this.symbol,
    required this.decimals,
    required this.countries,
    required this.locales,
    this.alsoUsedIn = const {},
    String? distinctiveSymbol,
  }) : distinctiveSymbol = distinctiveSymbol ?? symbol;

  /// ISO 4217 code; also the stored value.
  final String code;

  /// The symbol amounts are shown with inside the app.
  final String symbol;

  /// Tells apart currencies that share a symbol ("COL$", "JP¥", "SAR");
  /// shown with the code in the currency picker and in exports.
  final String distinctiveSymbol;

  /// Minor-unit digits Kalan stores, shows and accepts (0, 2 or 3). Follows
  /// daily use (Unicode CLDR) where it differs from ISO 4217 (COP, IDR,
  /// IQD, …): 0 digits store 1 per unit, 2 store 100, 3 store 1000.
  final int decimals;

  /// ISO 3166-1 alpha-2 regions where this is the local currency.
  final Set<String> countries;

  /// Regions where it circulates next to the local one (USD in Panama).
  final Set<String> alsoUsedIn;

  /// The app's planned local versions (language tags) it belongs to.
  final Set<String> locales;

  /// Minor units per major unit: 10^[decimals].
  int get minorPerMajor => pow10(decimals);

  /// "COL$ · COP": how the picker and exports name the currency.
  String get pickerLabel =>
      distinctiveSymbol == code ? code : '$distinctiveSymbol · $code';

  static const _euroArea = {
    'AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT', //
    'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK', 'AD', 'MC', 'ME', 'SM',
    'VA', 'XK',
  };

  static const all = <Currency>[
    Currency._(
      'TRY',
      symbol: '₺',
      decimals: 2,
      countries: {'TR'},
      locales: {'tr'},
    ),
    Currency._(
      'USD',
      symbol: r'$',
      distinctiveSymbol: r'US$',
      decimals: 2,
      countries: {
        'US',
        'EC',
        'SV',
        'PR',
        'GU',
        'VI',
        'AS',
        'MP',
        'TL',
        'FM',
        'MH',
        'PW',
        'BQ',
        'TC',
        'VG',
      },
      alsoUsedIn: {'PA'},
      locales: {'en-US', 'es-419'},
    ),
    Currency._(
      'EUR',
      symbol: '€',
      decimals: 2,
      countries: _euroArea,
      locales: {'en-GB', 'es-ES', 'pt-PT', 'de-DE', 'fr-FR', 'it', 'nl', 'sv'},
    ),
    Currency._(
      'GBP',
      symbol: '£',
      decimals: 2,
      countries: {'GB', 'IM', 'JE', 'GG'},
      locales: {'en-GB'},
    ),
    Currency._(
      'BRL',
      symbol: r'R$',
      decimals: 2,
      countries: {'BR'},
      locales: {'pt-BR'},
    ),
    Currency._(
      'MXN',
      symbol: r'$',
      distinctiveSymbol: r'MX$',
      decimals: 2,
      countries: {'MX'},
      locales: {'es-419'},
    ),
    Currency._(
      'COP',
      symbol: r'$',
      distinctiveSymbol: r'COL$',
      decimals: 0,
      countries: {'CO'},
      locales: {'es-419'},
    ),
    Currency._(
      'CLP',
      symbol: r'$',
      distinctiveSymbol: r'CLP$',
      decimals: 0,
      countries: {'CL'},
      locales: {'es-419'},
    ),
    Currency._(
      'RUB',
      symbol: '₽',
      decimals: 2,
      countries: {'RU'},
      locales: {'ru'},
    ),
    Currency._(
      'KZT',
      symbol: '₸',
      decimals: 2,
      countries: {'KZ'},
      locales: {'ru'},
    ),
    Currency._(
      'CNY',
      symbol: '¥',
      distinctiveSymbol: 'CN¥',
      decimals: 2,
      countries: {'CN'},
      locales: {'zh-Hans'},
    ),
    Currency._(
      'SGD',
      symbol: r'$',
      distinctiveSymbol: r'S$',
      decimals: 2,
      countries: {'SG'},
      locales: {'zh-Hans'},
    ),
    Currency._(
      'MYR',
      symbol: 'RM',
      decimals: 2,
      countries: {'MY'},
      locales: {'zh-Hans'},
    ),
    Currency._(
      'IDR',
      symbol: 'Rp',
      decimals: 0,
      countries: {'ID'},
      locales: {'id'},
    ),
    Currency._(
      'CAD',
      symbol: r'$',
      distinctiveSymbol: r'CA$',
      decimals: 2,
      countries: {'CA'},
      locales: {'en-US', 'fr-CA'},
    ),
    Currency._(
      'AUD',
      symbol: r'$',
      distinctiveSymbol: r'A$',
      decimals: 2,
      countries: {'AU', 'CX', 'CC', 'NF', 'KI', 'NR', 'TV'},
      locales: {'en-GB'},
    ),
    Currency._(
      'CHF',
      symbol: 'CHF',
      decimals: 2,
      countries: {'CH', 'LI'},
      locales: {'de-CH', 'fr-FR', 'it'},
    ),
    Currency._(
      'NZD',
      symbol: r'$',
      distinctiveSymbol: r'NZ$',
      decimals: 2,
      countries: {'NZ', 'CK', 'NU', 'PN', 'TK'},
      locales: {'en-GB'},
    ),
    Currency._(
      'ZAR',
      symbol: 'R',
      decimals: 2,
      countries: {'ZA'},
      locales: {'en-GB'},
    ),
    Currency._(
      'ARS',
      symbol: r'$',
      distinctiveSymbol: r'AR$',
      decimals: 2,
      countries: {'AR'},
      locales: {'es-419'},
    ),
    Currency._(
      'PEN',
      symbol: 'S/',
      decimals: 2,
      countries: {'PE'},
      locales: {'es-419'},
    ),
    Currency._(
      'UYU',
      symbol: r'$',
      distinctiveSymbol: r'$U',
      decimals: 2,
      countries: {'UY'},
      locales: {'es-419'},
    ),
    Currency._(
      'PYG',
      symbol: '₲',
      decimals: 0,
      countries: {'PY'},
      locales: {'es-419'},
    ),
    Currency._(
      'BOB',
      symbol: 'Bs',
      decimals: 2,
      countries: {'BO'},
      locales: {'es-419'},
    ),
    Currency._(
      'VES',
      symbol: 'Bs.',
      distinctiveSymbol: 'Bs.S',
      decimals: 2,
      countries: {'VE'},
      locales: {'es-419'},
    ),
    Currency._(
      'CRC',
      symbol: '₡',
      decimals: 0,
      countries: {'CR'},
      locales: {'es-419'},
    ),
    Currency._(
      'GTQ',
      symbol: 'Q',
      decimals: 2,
      countries: {'GT'},
      locales: {'es-419'},
    ),
    Currency._(
      'HNL',
      symbol: 'L',
      decimals: 2,
      countries: {'HN'},
      locales: {'es-419'},
    ),
    Currency._(
      'NIO',
      symbol: r'C$',
      decimals: 2,
      countries: {'NI'},
      locales: {'es-419'},
    ),
    Currency._(
      'DOP',
      symbol: r'$',
      distinctiveSymbol: r'RD$',
      decimals: 2,
      countries: {'DO'},
      locales: {'es-419'},
    ),
    Currency._(
      'PAB',
      symbol: 'B/.',
      decimals: 2,
      countries: {'PA'},
      locales: {'es-419'},
    ),
    Currency._(
      'AOA',
      symbol: 'Kz',
      decimals: 2,
      countries: {'AO'},
      locales: {'pt-PT'},
    ),
    Currency._(
      'MZN',
      symbol: 'MT',
      decimals: 2,
      countries: {'MZ'},
      locales: {'pt-PT'},
    ),
    Currency._(
      'XOF',
      symbol: 'CFA',
      distinctiveSymbol: 'F CFA',
      decimals: 0,
      countries: {'BJ', 'BF', 'CI', 'GW', 'ML', 'NE', 'SN', 'TG'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'XAF',
      symbol: 'FCFA',
      decimals: 0,
      countries: {'CM', 'CF', 'TD', 'CG', 'GQ', 'GA'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'BYN',
      symbol: 'Br',
      decimals: 2,
      countries: {'BY'},
      locales: {'ru'},
    ),
    Currency._(
      'KGS',
      symbol: 'с',
      distinctiveSymbol: 'сом',
      decimals: 2,
      countries: {'KG'},
      locales: {'ru'},
    ),
    Currency._(
      'UZS',
      symbol: 'soʻm',
      decimals: 0,
      countries: {'UZ'},
      locales: {'ru'},
    ),
    Currency._(
      'TWD',
      symbol: r'$',
      distinctiveSymbol: r'NT$',
      decimals: 0,
      countries: {'TW'},
      locales: {'zh-Hant'},
    ),
    Currency._(
      'HKD',
      symbol: r'$',
      distinctiveSymbol: r'HK$',
      decimals: 2,
      countries: {'HK'},
      locales: {'zh-Hant'},
    ),
    Currency._(
      'MOP',
      symbol: r'MOP$',
      decimals: 2,
      countries: {'MO'},
      locales: {'zh-Hant'},
    ),
    Currency._(
      'SAR',
      symbol: 'ر.س',
      distinctiveSymbol: 'SAR',
      decimals: 2,
      countries: {'SA'},
      locales: {'ar'},
    ),
    Currency._(
      'AED',
      symbol: 'د.إ',
      distinctiveSymbol: 'AED',
      decimals: 2,
      countries: {'AE'},
      locales: {'ar'},
    ),
    Currency._(
      'QAR',
      symbol: 'ر.ق',
      distinctiveSymbol: 'QAR',
      decimals: 2,
      countries: {'QA'},
      locales: {'ar'},
    ),
    Currency._(
      'KWD',
      symbol: 'د.ك',
      distinctiveSymbol: 'KWD',
      decimals: 3,
      countries: {'KW'},
      locales: {'ar'},
    ),
    Currency._(
      'BHD',
      symbol: 'د.ب',
      distinctiveSymbol: 'BHD',
      decimals: 3,
      countries: {'BH'},
      locales: {'ar'},
    ),
    Currency._(
      'OMR',
      symbol: 'ر.ع.',
      distinctiveSymbol: 'OMR',
      decimals: 3,
      countries: {'OM'},
      locales: {'ar'},
    ),
    Currency._(
      'EGP',
      symbol: 'ج.م',
      distinctiveSymbol: 'E£',
      decimals: 2,
      countries: {'EG'},
      locales: {'ar'},
    ),
    Currency._(
      'JOD',
      symbol: 'د.أ',
      distinctiveSymbol: 'JOD',
      decimals: 3,
      countries: {'JO'},
      alsoUsedIn: {'PS'},
      locales: {'ar'},
    ),
    Currency._(
      'IQD',
      symbol: 'د.ع',
      distinctiveSymbol: 'IQD',
      decimals: 0,
      countries: {'IQ'},
      locales: {'ar'},
    ),
    Currency._(
      'MAD',
      symbol: 'د.م.',
      distinctiveSymbol: 'DH',
      decimals: 2,
      countries: {'MA'},
      locales: {'ar'},
    ),
    Currency._(
      'DZD',
      symbol: 'د.ج',
      distinctiveSymbol: 'DA',
      decimals: 2,
      countries: {'DZ'},
      locales: {'ar'},
    ),
    Currency._(
      'TND',
      symbol: 'د.ت',
      distinctiveSymbol: 'DT',
      decimals: 3,
      countries: {'TN'},
      locales: {'ar'},
    ),
    Currency._(
      'LBP',
      symbol: 'ل.ل',
      distinctiveSymbol: 'LL',
      decimals: 0,
      countries: {'LB'},
      locales: {'ar'},
    ),
    Currency._(
      'LYD',
      symbol: 'د.ل',
      distinctiveSymbol: 'LD',
      decimals: 3,
      countries: {'LY'},
      locales: {'ar'},
    ),
    Currency._(
      'INR',
      symbol: '₹',
      decimals: 2,
      countries: {'IN'},
      locales: {'en-GB'},
    ),
    Currency._(
      'PKR',
      symbol: 'Rs',
      distinctiveSymbol: 'PKR',
      decimals: 0,
      countries: {'PK'},
      locales: {'en-GB'},
    ),
    Currency._(
      'NGN',
      symbol: '₦',
      decimals: 2,
      countries: {'NG'},
      locales: {'en-GB'},
    ),
    Currency._(
      'PHP',
      symbol: '₱',
      decimals: 2,
      countries: {'PH'},
      locales: {'en-US'},
    ),
    Currency._(
      'KES',
      symbol: 'KSh',
      decimals: 2,
      countries: {'KE'},
      locales: {'en-GB'},
    ),
    Currency._(
      'CDF',
      symbol: 'FC',
      decimals: 2,
      countries: {'CD'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'GNF',
      symbol: 'FG',
      decimals: 0,
      countries: {'GN'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'HTG',
      symbol: 'G',
      decimals: 2,
      countries: {'HT'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'MGA',
      symbol: 'Ar',
      decimals: 0,
      countries: {'MG'},
      locales: {'fr-FR'},
    ),
    Currency._(
      'SRD',
      symbol: r'$',
      distinctiveSymbol: r'Sr$',
      decimals: 2,
      countries: {'SR'},
      locales: {'nl'},
    ),
    Currency._(
      'TJS',
      symbol: 'SM',
      decimals: 2,
      countries: {'TJ'},
      locales: {'ru'},
    ),
    Currency._(
      'SDG',
      symbol: 'ج.س.',
      distinctiveSymbol: 'SDG',
      decimals: 2,
      countries: {'SD'},
      locales: {'ar'},
    ),
    Currency._(
      'YER',
      symbol: 'ر.ي.',
      distinctiveSymbol: 'YER',
      decimals: 0,
      countries: {'YE'},
      locales: {'ar'},
    ),
    Currency._(
      'SYP',
      symbol: 'ل.س',
      distinctiveSymbol: 'SYP',
      decimals: 0,
      countries: {'SY'},
      locales: {'ar'},
    ),
    Currency._(
      'MRU',
      symbol: 'UM',
      decimals: 2,
      countries: {'MR'},
      locales: {'ar'},
    ),
    Currency._(
      'ILS',
      symbol: '₪',
      decimals: 2,
      countries: {'IL'},
      alsoUsedIn: {'PS'},
      locales: {'ar'},
    ),
    Currency._(
      'PLN',
      symbol: 'zł',
      decimals: 2,
      countries: {'PL'},
      locales: {'pl'},
    ),
    Currency._(
      'SEK',
      symbol: 'kr',
      decimals: 2,
      countries: {'SE'},
      locales: {'sv'},
    ),
    Currency._(
      'JPY',
      symbol: '¥',
      distinctiveSymbol: 'JP¥',
      decimals: 0,
      countries: {'JP'},
      locales: {'ja'},
    ),
    Currency._(
      'VND',
      symbol: '₫',
      decimals: 0,
      countries: {'VN'},
      locales: {'vi'},
    ),
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

  /// The default currency for a device region; USD when none matches.
  static Currency forRegion(String? region) {
    if (region == null) return fallback;
    final upper = region.toUpperCase();
    for (final c in all) {
      if (c.countries.contains(upper)) return c;
    }
    return fallback;
  }

  /// The "Suggested" list: the region's own currencies, then those that
  /// circulate there. Without a known region, the currencies of the app
  /// language's local version ("tr" → TRY), else USD.
  static List<Currency> suggested({
    required String? region,
    required String languageCode,
  }) {
    final r = region?.toUpperCase();
    if (r != null) {
      final list = [
        ...all.where((c) => c.countries.contains(r)),
        ...all.where((c) => c.alsoUsedIn.contains(r)),
      ];
      if (list.isNotEmpty) return list;
    }
    final byLanguage = all.where((c) => c.locales.contains(languageCode));
    return byLanguage.isEmpty ? [fallback] : byLanguage.toList();
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
