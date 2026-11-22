/// Provider templates (Roadmap 25): the common payment patterns of buy now,
/// pay later providers, shipped with the app in
/// `assets/provider_templates.json` and renewed only with an app update.
///
/// A template is a starting value, never a promise: it fills the plan kind,
/// the payment count, the interval and, when there is one, the first
/// payment day or the "Pay later" rule. The amount always comes from the
/// user, and the plan keeps no trace of the template. The file has no fee,
/// interest, rate, late rule or color field ([templateKeys] is the whole
/// schema; [parseProviderTemplates] refuses anything else).
///
/// Pure Dart: no Flutter import (the CI check runs it with `dart run`).
library;

import 'dart:convert';

import '../date/local_date.dart';
import '../engine/pay_later.dart';
import '../engine/plan_draft.dart';
import '../engine/schedule.dart';

/// The asset path, declared in pubspec.yaml.
const providerTemplatesAsset = 'assets/provider_templates.json';

/// At most this many providers per country (product owner decision 1).
const maxProvidersPerCountry = 5;

/// A template older than this many months is flagged by the CI check
/// (product owner decision 2).
const staleAfterMonths = 6;

/// Every key the file may use, by level. Anything else is refused, so a
/// fee, an interest rate or a brand color cannot slip in.
const templateKeys = (
  file: {'schemaVersion', 'templates'},
  template: {'country', 'id', 'name', 'sources', 'checked', 'variants'},
  variant: {
    'kind',
    'count',
    'interval',
    'intervalDays',
    'first',
    'firstDay',
    'payLater',
    'payLaterValue',
  },
);

/// The only schema version this build reads.
const providerTemplatesSchemaVersion = 1;

/// When the first payment of a template with several payments falls.
enum TemplateFirstPayment {
  /// On the purchase day (paid at checkout).
  purchase,

  /// One interval after the purchase day ([PaymentInterval.dateAt]).
  afterInterval,

  /// On the given day of the month after the purchase, then the same day
  /// every month: the engine's "Pay later" next-month rule
  /// ([payLaterDueDate]); only with the same day each month.
  nextMonthDay,
}

/// One pattern of a provider, expressed only with the plan kinds,
/// intervals and "Pay later" rules the app already has.
class TemplateVariant {
  const TemplateVariant.payIn4()
    : kind = PlanKind.payIn4,
      count = 4,
      interval = PaymentInterval.biweekly,
      first = TemplateFirstPayment.purchase,
      firstDay = null,
      payLaterRule = null;

  const TemplateVariant.monthly({
    required this.count,
    required PaymentInterval this.interval,
    this.first = TemplateFirstPayment.purchase,
    this.firstDay,
  }) : kind = PlanKind.monthly,
       payLaterRule = null;

  const TemplateVariant.payLater(PayLaterRule this.payLaterRule)
    : kind = PlanKind.payLater,
      count = 1,
      interval = null,
      first = TemplateFirstPayment.purchase,
      firstDay = null;

  /// [PlanKind.payIn4], [PlanKind.monthly] or [PlanKind.payLater]; never a
  /// card (card installments are not created from templates).
  final PlanKind kind;
  final int count;

  /// Null for "Pay later" (one payment).
  final PaymentInterval? interval;
  final TemplateFirstPayment first;

  /// The day of the month for [TemplateFirstPayment.nextMonthDay].
  final int? firstDay;

  /// Only for "Pay later".
  final PayLaterRule? payLaterRule;

  /// The first payment date for a purchase on [purchase]: the date the
  /// form's first date field starts with. Only existing engine rules.
  LocalDate firstDate(LocalDate purchase) => switch (first) {
    TemplateFirstPayment.purchase => purchase,
    TemplateFirstPayment.afterInterval => interval!.dateAt(purchase, 1),
    TemplateFirstPayment.nextMonthDay => payLaterDueDate(
      purchase: purchase,
      rule: PayLaterRule.nextMonthDay(firstDay!),
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is TemplateVariant &&
      other.kind == kind &&
      other.count == count &&
      other.interval == interval &&
      other.first == first &&
      other.firstDay == firstDay &&
      other.payLaterRule == payLaterRule;

  @override
  int get hashCode =>
      Object.hash(kind, count, interval, first, firstDay, payLaterRule);

  @override
  String toString() =>
      'TemplateVariant(${kind.name}, $count, $interval, ${first.name}, '
      '$firstDay, $payLaterRule)';
}

/// A provider's patterns in one country.
class ProviderTemplate {
  const ProviderTemplate({
    required this.country,
    required this.id,
    required this.name,
    required this.sources,
    required this.checked,
    required this.variants,
  });

  /// ISO 3166-1 alpha-2, upper case.
  final String country;

  /// A slug, the same for one provider in every country.
  final String id;

  /// The provider's name as plain text; never translated.
  final String name;

  /// The official pages the patterns were checked on (one or more: a
  /// provider may describe two patterns on two pages).
  final List<Uri> sources;

  /// The day the patterns were last checked.
  final LocalDate checked;

  /// The first one is the provider's main pattern.
  final List<TemplateVariant> variants;

  @override
  String toString() => 'ProviderTemplate($country, $id)';
}

/// The file could not be read: a schema error with the place it was found.
class ProviderTemplateFormatException implements Exception {
  ProviderTemplateFormatException(this.message);

  final String message;

  @override
  String toString() => 'ProviderTemplateFormatException: $message';
}

final _countryPattern = RegExp(r'^[A-Z]{2}$');
final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Reads the templates file. Throws [ProviderTemplateFormatException] on
/// any key outside [templateKeys], a missing or out-of-range value, a
/// variant the app cannot express, or more than [maxProvidersPerCountry]
/// providers in a country.
List<ProviderTemplate> parseProviderTemplates(String json) {
  final Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException catch (e) {
    throw ProviderTemplateFormatException('not JSON: ${e.message}');
  }
  final file = _map(root, 'file', templateKeys.file);
  if (file['schemaVersion'] != providerTemplatesSchemaVersion) {
    throw ProviderTemplateFormatException('unknown schemaVersion');
  }
  final list = file['templates'];
  if (list is! List) {
    throw ProviderTemplateFormatException('templates is not a list');
  }
  final templates = [
    for (final (i, t) in list.indexed) _template(t, 'templates[$i]'),
  ];
  final seen = <String>{};
  final perCountry = <String, int>{};
  for (final t in templates) {
    if (!seen.add('${t.country}/${t.id}')) {
      throw ProviderTemplateFormatException(
        'duplicate ${t.id} in ${t.country}',
      );
    }
    final n = perCountry[t.country] = (perCountry[t.country] ?? 0) + 1;
    if (n > maxProvidersPerCountry) {
      throw ProviderTemplateFormatException(
        'more than $maxProvidersPerCountry providers in ${t.country}',
      );
    }
  }
  return templates;
}

Map<String, Object?> _map(Object? value, String at, Set<String> allowed) {
  if (value is! Map<String, Object?>) {
    throw ProviderTemplateFormatException('$at is not an object');
  }
  for (final key in value.keys) {
    if (!allowed.contains(key)) {
      throw ProviderTemplateFormatException('$at has unknown key "$key"');
    }
  }
  return value;
}

String _string(Map<String, Object?> m, String key, String at) {
  final v = m[key];
  if (v is! String || v.trim().isEmpty) {
    throw ProviderTemplateFormatException('$at.$key is missing');
  }
  return v;
}

int _int(Map<String, Object?> m, String key, String at, int min, int max) {
  final v = m[key];
  if (v is! int || v < min || v > max) {
    throw ProviderTemplateFormatException('$at.$key must be $min-$max');
  }
  return v;
}

void _absent(Map<String, Object?> m, List<String> keys, String at) {
  for (final k in keys) {
    if (m.containsKey(k)) {
      throw ProviderTemplateFormatException('$at.$k does not fit its kind');
    }
  }
}

ProviderTemplate _template(Object? value, String at) {
  final m = _map(value, at, templateKeys.template);
  final country = _string(m, 'country', at);
  if (!_countryPattern.hasMatch(country)) {
    throw ProviderTemplateFormatException('$at.country is not ISO alpha-2');
  }
  final id = _string(m, 'id', at);
  if (!_idPattern.hasMatch(id)) {
    throw ProviderTemplateFormatException('$at.id is not a slug');
  }
  final links = m['sources'];
  if (links is! List || links.isEmpty) {
    throw ProviderTemplateFormatException('$at.sources is empty');
  }
  final sources = <Uri>[];
  for (final (i, link) in links.indexed) {
    final uri = link is String ? Uri.tryParse(link) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw ProviderTemplateFormatException(
        '$at.sources[$i] is not an https link',
      );
    }
    sources.add(uri);
  }
  final variants = m['variants'];
  if (variants is! List || variants.isEmpty) {
    throw ProviderTemplateFormatException('$at.variants is empty');
  }
  final parsed = [
    for (final (i, v) in variants.indexed) _variant(v, '$at.variants[$i]'),
  ];
  if (parsed.toSet().length != parsed.length) {
    throw ProviderTemplateFormatException('$at has a repeated variant');
  }
  return ProviderTemplate(
    country: country,
    id: id,
    name: _string(m, 'name', at).trim(),
    sources: List.unmodifiable(sources),
    checked: parseCheckedDate(_string(m, 'checked', at), at),
    variants: List.unmodifiable(parsed),
  );
}

/// "2026-11-22" → that day; throws on anything else.
LocalDate parseCheckedDate(String text, [String at = 'checked']) {
  final match = _datePattern.firstMatch(text);
  if (match != null) {
    final y = int.parse(match[1]!);
    final mo = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= LocalDate.daysInMonth(y, mo)) {
      return LocalDate(y, mo, d);
    }
  }
  throw ProviderTemplateFormatException('$at is not a YYYY-MM-DD date');
}

TemplateVariant _variant(Object? value, String at) {
  final m = _map(value, at, templateKeys.variant);
  final kind = _string(m, 'kind', at);
  switch (kind) {
    case 'payIn4':
      _absent(m, [
        'count',
        'interval',
        'intervalDays',
        'first',
        'firstDay',
        'payLater',
        'payLaterValue',
      ], at);
      return const TemplateVariant.payIn4();
    case 'monthly':
      _absent(m, ['payLater', 'payLaterValue'], at);
      // The same limits as the plan form ("Monthly installments").
      final count = _int(m, 'count', at, 2, 60);
      final interval = switch (_string(m, 'interval', at)) {
        'sameDay' when !m.containsKey('intervalDays') =>
          PaymentInterval.sameDay,
        'everyDays' => PaymentInterval.everyDays(
          _int(
            m,
            'intervalDays',
            at,
            PaymentInterval.minDays,
            PaymentInterval.maxDays,
          ),
        ),
        _ => throw ProviderTemplateFormatException('$at.interval is unknown'),
      };
      final first = switch (m['first'] ?? 'purchase') {
        'purchase' => TemplateFirstPayment.purchase,
        'afterInterval' => TemplateFirstPayment.afterInterval,
        'nextMonthDay' when interval == PaymentInterval.sameDay =>
          TemplateFirstPayment.nextMonthDay,
        _ => throw ProviderTemplateFormatException('$at.first is unknown'),
      };
      final int? firstDay;
      if (first == TemplateFirstPayment.nextMonthDay) {
        firstDay = _int(m, 'firstDay', at, 1, 31);
      } else {
        _absent(m, ['firstDay'], at);
        firstDay = null;
      }
      return TemplateVariant.monthly(
        count: count,
        interval: interval,
        first: first,
        firstDay: firstDay,
      );
    case 'payLater':
      _absent(m, [
        'count',
        'interval',
        'intervalDays',
        'first',
        'firstDay',
      ], at);
      final rule = switch (_string(m, 'payLater', at)) {
        'days' => PayLaterRule.days(
          _int(m, 'payLaterValue', at, 1, PayLaterRule.maxDays),
        ),
        'nextMonthDay' => PayLaterRule.nextMonthDay(
          _int(m, 'payLaterValue', at, 1, 31),
        ),
        _ => throw ProviderTemplateFormatException('$at.payLater is unknown'),
      };
      return TemplateVariant.payLater(rule);
    default:
      throw ProviderTemplateFormatException('$at.kind "$kind" is not offered');
  }
}

// Countries ------------------------------------------------------------------

/// The countries each of the 22 locales (Roadmap 24) is for, as in the
/// roadmap's country notes; es_419 lists the Latin American countries the
/// notes name. Templates exist only for these countries.
const templateCountriesByLocale = <String, List<String>>{
  'tr': ['TR'],
  'en': ['US'],
  'en_GB': ['GB'],
  'es': ['ES'],
  'es_419': ['MX', 'AR', 'CO', 'CL'],
  'pt_BR': ['BR'],
  'pt_PT': ['PT'],
  'de': ['DE'],
  'de_CH': ['CH'],
  'fr': ['FR'],
  'fr_CA': ['CA'],
  'it': ['IT'],
  'id': ['ID'],
  'ru': ['RU', 'KZ'],
  'zh': ['CN', 'SG', 'MY'],
  'zh_Hant': ['TW', 'HK'],
  'ar': ['SA', 'AE', 'EG'],
  'pl': ['PL'],
  'nl': ['NL', 'BE'],
  'sv': ['SE'],
  'ja': ['JP'],
  'vi': ['VN'],
};

/// Every country templates may be written for.
final Set<String> templateCountries = {
  for (final list in templateCountriesByLocale.values) ...list,
};

/// The templates to offer for the device region [region] (ISO 3166-1, as
/// the phone reports it; the app language plays no part, DECISIONS 30).
/// Empty for an unknown or missing region, or one without verified
/// templates: then the section is not shown at all.
///
/// Sorted by name, so the order says nothing about the providers.
List<ProviderTemplate> templatesForRegion(
  List<ProviderTemplate> all,
  String? region,
) {
  final country = region?.trim().toUpperCase();
  if (country == null || !templateCountries.contains(country)) return const [];
  final list = [
    for (final t in all)
      if (t.country == country) t,
  ]..sort((a, b) => foldName(a.name).compareTo(foldName(b.name)));
  return List.unmodifiable(list.take(maxProvidersPerCountry));
}

// Staleness ------------------------------------------------------------------

/// Whether [checked] is more than [staleAfterMonths] months before
/// [today]: 5 months ago is not, 7 months ago is. Month ends clamp
/// (31 Aug + 6 months = 28 Feb).
bool isTemplateStale(LocalDate checked, LocalDate today) =>
    checked.addMonths(staleAfterMonths) < today;

/// The CI warning for each stale template ("Şablon kontrol tarihi 6 aydan
/// eski: Scalapay, IT"), in file order. Empty when all are recent.
List<String> staleTemplateWarnings(
  List<ProviderTemplate> all,
  LocalDate today,
) => [
  for (final t in all)
    if (isTemplateStale(t.checked, today))
      'Şablon kontrol tarihi $staleAfterMonths aydan eski: '
          '${t.name}, ${t.country}',
];

// Names ----------------------------------------------------------------------

const _folds = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', //
  'ă': 'a', 'ą': 'a', 'ạ': 'a', 'ả': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', //
  'ẫ': 'a', 'ậ': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a', //
  'æ': 'ae', 'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c', 'ċ': 'c', //
  'ď': 'd', 'đ': 'd', 'ð': 'd', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e', //
  'ě': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', //
  'ễ': 'e', 'ệ': 'e', 'ğ': 'g', 'ĝ': 'g', 'ġ': 'g', 'ģ': 'g', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i', 'ı': 'i', //
  'ỉ': 'i', 'ĩ': 'i', 'ị': 'i', 'ķ': 'k', 'ł': 'l', 'ľ': 'l', 'ļ': 'l', //
  'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', //
  'ő': 'o', 'ơ': 'o', 'ọ': 'o', 'ỏ': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', //
  'ỗ': 'o', 'ộ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o', //
  'œ': 'oe', 'ŕ': 'r', 'ř': 'r', 'ś': 's', 'š': 's', 'ş': 's', 'ș': 's', //
  'ß': 'ss', 'ť': 't', 'ţ': 't', 'ț': 't', 'þ': 'th', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', //
  'ų': 'u', 'ư': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u', 'ứ': 'u', 'ừ': 'u', //
  'ử': 'u', 'ữ': 'u', 'ự': 'u', 'ý': 'y', 'ÿ': 'y', 'ỳ': 'y', 'ỵ': 'y', //
  'ỷ': 'y', 'ỹ': 'y', 'ź': 'z', 'ż': 'z', 'ž': 'z', //
};

/// [name] for matching: trimmed, inner spaces collapsed, lower case, and
/// Latin letters without their marks ("Scalapay", "scalapay" and
/// "SCALAPAY" match; "Płacę" matches "place"). Turkish İ and I fold to i.
String foldName(String name) {
  final lower = name
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    // Combining marks (a decomposed "é" is "e" + U+0301) are dropped.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    out.write(_folds[ch] ?? ch);
  }
  return out.toString();
}
