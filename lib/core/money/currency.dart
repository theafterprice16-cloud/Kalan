/// The four currencies Kalan supports. One per install; no conversion.
enum Currency {
  lira('TRY'),
  dollar('USD'),
  pound('GBP'),
  euro('EUR');

  const Currency(this.code);

  /// ISO 4217 code, also the stored value.
  final String code;

  /// Minor units per major unit. All supported currencies use cents.
  int get minorPerMajor => 100;

  static Currency fromCode(String code) =>
      values.firstWhere((c) => c.code == code, orElse: () => Currency.lira);
}
