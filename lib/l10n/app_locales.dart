/// The app's locales: one list, the only place a language is opened.
///
/// Pure Dart (no Flutter import), so `tool/sync_locales.dart` can write
/// the iOS and Android language lists from it. The language picker, the
/// match to the phone's language and both platform lists read it.
///
/// Opening a language after its translation (the "bulk translation" at
/// the end of the roadmap) only changes its [LocaleStatus] here, then
/// `dart run tool/sync_locales.dart`.
library;

/// Whether users can see a locale.
enum LocaleStatus {
  /// Not shown anywhere; its texts fall back to English.
  closed,

  /// Translated, not yet read by a native speaker: offered in the
  /// language picker with a "Draft" note, never picked from the phone's
  /// language and not in the iOS and Android lists.
  draft,

  /// Translated and read by a native speaker: picker, phone language
  /// match, iOS and Android lists.
  reviewed;

  /// Offered in the language picker.
  bool get isOpen => this != closed;
}

/// One locale the app has an ARB file for.
final class AppLocaleInfo {
  const AppLocaleInfo(
    this.code, {
    required this.name,
    required this.regionalName,
    this.status = LocaleStatus.closed,
    this.tag,
    this.intl,
  });

  /// The ARB suffix (`app_<code>.arb`), the generated `localeName` and
  /// the value saved in settings: 'tr', 'en', 'en_GB', 'es_419', 'zh_Hant'.
  final String code;

  /// The language in its own words: 'English', 'Português', 'العربية'.
  final String name;

  /// With the region or script, used when two open locales share a
  /// language: 'English (US)', 'Português (Brasil)', '繁體中文'.
  final String regionalName;

  final LocaleStatus status;

  /// A platform tag other than the code's ([platformTag]).
  final String? tag;

  /// An intl locale other than the code ([intlLocale]).
  final String? intl;

  /// The BCP 47 tag in iOS `CFBundleLocalizations` and Android
  /// `locales_config.xml`: 'en', 'en-GB', 'pt-BR', 'zh-Hans'.
  String get platformTag => tag ?? code.replaceAll('_', '-');

  /// The intl locale for dates and numbers. Differs from [code] only
  /// where intl has no data under the code (zh_Hant → zh_TW).
  String get intlLocale => intl ?? code;

  List<String> get _parts => code.split('_');

  String get languageCode => _parts.first;

  /// 'Hant' for zh_Hant; null otherwise.
  String? get scriptCode =>
      _parts.length > 1 && _parts[1].length == 4 ? _parts[1] : null;

  /// 'GB' for en_GB, '419' for es_419; null otherwise.
  String? get countryCode =>
      _parts.length > 1 && _parts[1].length != 4 ? _parts[1] : null;

  AppLocaleInfo withStatus(LocaleStatus status) => AppLocaleInfo(
    code,
    name: name,
    regionalName: regionalName,
    status: status,
    tag: tag,
    intl: intl,
  );

  @override
  String toString() => 'AppLocaleInfo($code, ${status.name})';
}

/// The 22 locales (Roadmap 24), in the picker's order. Base files carry
/// one region each: en = en-US, es = es-ES, de = de-DE, fr = fr-FR,
/// zh = zh-Hans; app_pt.arb is only gen-l10n's fallback for pt_BR and
/// pt_PT ([fallbackArbCodes]).
const appLocales = <AppLocaleInfo>[
  AppLocaleInfo(
    'tr',
    name: 'Türkçe',
    regionalName: 'Türkçe',
    status: LocaleStatus.reviewed,
  ),
  AppLocaleInfo(
    'en',
    name: 'English',
    regionalName: 'English (US)',
    status: LocaleStatus.reviewed,
  ),
  AppLocaleInfo('en_GB', name: 'English', regionalName: 'English (UK)'),
  AppLocaleInfo('es', name: 'Español', regionalName: 'Español (España)'),
  AppLocaleInfo(
    'es_419',
    name: 'Español',
    regionalName: 'Español (Latinoamérica)',
  ),
  AppLocaleInfo('pt_BR', name: 'Português', regionalName: 'Português (Brasil)'),
  AppLocaleInfo(
    'pt_PT',
    name: 'Português',
    regionalName: 'Português (Portugal)',
  ),
  AppLocaleInfo('de', name: 'Deutsch', regionalName: 'Deutsch (Deutschland)'),
  AppLocaleInfo('de_CH', name: 'Deutsch', regionalName: 'Deutsch (Schweiz)'),
  AppLocaleInfo('fr', name: 'Français', regionalName: 'Français (France)'),
  AppLocaleInfo('fr_CA', name: 'Français', regionalName: 'Français (Canada)'),
  AppLocaleInfo('it', name: 'Italiano', regionalName: 'Italiano'),
  AppLocaleInfo(
    'id',
    name: 'Bahasa Indonesia',
    regionalName: 'Bahasa Indonesia',
  ),
  AppLocaleInfo('ru', name: 'Русский', regionalName: 'Русский'),
  AppLocaleInfo('zh', name: '中文', regionalName: '简体中文', tag: 'zh-Hans'),
  AppLocaleInfo('zh_Hant', name: '中文', regionalName: '繁體中文', intl: 'zh_TW'),
  AppLocaleInfo('ar', name: 'العربية', regionalName: 'العربية'),
  AppLocaleInfo('pl', name: 'Polski', regionalName: 'Polski'),
  AppLocaleInfo('nl', name: 'Nederlands', regionalName: 'Nederlands'),
  AppLocaleInfo('sv', name: 'Svenska', regionalName: 'Svenska'),
  AppLocaleInfo('ja', name: '日本語', regionalName: '日本語'),
  AppLocaleInfo('vi', name: 'Tiếng Việt', regionalName: 'Tiếng Việt'),
];

/// ARB files that are not locales of their own: gen-l10n needs a
/// language file next to app_pt_BR.arb and app_pt_PT.arb.
const fallbackArbCodes = {'pt'};

/// The locale when nothing else matches: English (US).
const fallbackLocaleCode = 'en';

/// [locales] users can see, in order.
List<AppLocaleInfo> openLocales([List<AppLocaleInfo> locales = appLocales]) => [
  for (final l in locales)
    if (l.status.isOpen) l,
];

/// The entry for [code] ('en_GB'), or null.
AppLocaleInfo? localeInfoOf(
  String? code, [
  List<AppLocaleInfo> locales = appLocales,
]) {
  if (code == null) return null;
  for (final l in locales) {
    if (l.code == code) return l;
  }
  return null;
}

/// The name a locale goes by in the picker: the language alone, or with
/// its region when another open locale shares the language.
String pickerNameOf(
  AppLocaleInfo locale, [
  List<AppLocaleInfo> locales = appLocales,
]) {
  final shared = openLocales(locales)
      .where((l) => l.languageCode == locale.languageCode)
      .length;
  return shared > 1 ? locale.regionalName : locale.name;
}

/// The intl locale for a generated `localeName` ('zh_Hant' → 'zh_TW'):
/// every date and number goes through this.
String intlLocaleOf(String localeName) =>
    localeInfoOf(localeName)?.intlLocale ?? localeName;

/// Spanish of Latin America and the US (CLDR parent es_419).
const _es419Regions = {
  '419', 'AR', 'BO', 'BR', 'BZ', 'CL', 'CO', 'CR', 'CU', 'DO', 'EC', //
  'GT', 'HN', 'MX', 'NI', 'PA', 'PE', 'PR', 'PY', 'SV', 'US', 'UY', 'VE',
};

/// English that follows the US (CLDR: no en_001 parent).
const _enUsRegions = {'US', 'AS', 'GU', 'MH', 'MP', 'PR', 'UM', 'VI'};

/// Chinese written in Traditional characters by default.
const _hantRegions = {'TW', 'HK', 'MO'};

/// The nearest of the 22 locales for a phone language, whatever its
/// status: es-AR → es_419, pt-AO → pt_PT, de-AT → de, fr-BE → fr,
/// en-AU → en_GB, zh-HK → zh_Hant. Null for other languages.
String? nearestLocaleCode(String language, {String? script, String? region}) {
  final lang = language.toLowerCase();
  final r = region?.toUpperCase();
  switch (lang) {
    case 'en':
      return r == null || _enUsRegions.contains(r) ? 'en' : 'en_GB';
    case 'es':
      return r != null && _es419Regions.contains(r) ? 'es_419' : 'es';
    case 'pt':
      return r == null || r == 'BR' ? 'pt_BR' : 'pt_PT';
    case 'de':
      return r == 'CH' || r == 'LI' ? 'de_CH' : 'de';
    case 'fr':
      return r == 'CA' ? 'fr_CA' : 'fr';
    case 'zh':
      final s = script?.toLowerCase();
      final hant = s == 'hant' || (s == null && _hantRegions.contains(r));
      return hant ? 'zh_Hant' : 'zh';
  }
  return localeInfoOf(lang) != null ? lang : null;
}

/// The app locale for the phone's language: only reviewed locales are
/// picked. The nearest locale ([nearestLocaleCode]) when it is reviewed,
/// otherwise another reviewed locale of the same language, otherwise
/// English (US). Never null.
AppLocaleInfo matchLocale(
  String language, {
  String? script,
  String? region,
  List<AppLocaleInfo> locales = appLocales,
}) {
  bool picked(AppLocaleInfo l) => l.status == LocaleStatus.reviewed;
  final nearest = localeInfoOf(
    nearestLocaleCode(language, script: script, region: region),
    locales,
  );
  if (nearest != null && picked(nearest)) return nearest;
  final lang = language.toLowerCase();
  for (final l in locales) {
    if (picked(l) && l.languageCode == lang) return l;
  }
  return localeInfoOf(fallbackLocaleCode, locales) ??
      localeInfoOf(fallbackLocaleCode)!;
}
