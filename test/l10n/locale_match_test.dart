// The phone's language → the app locale (Roadmap 24, decision 8).
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/locale.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Every locale reviewed, as after the bulk translation.
final allReviewed = [
  for (final l in appLocales) l.withStatus(LocaleStatus.reviewed),
];

String match(String tag, [List<AppLocaleInfo> locales = appLocales]) {
  final parts = tag.split('-');
  String? script;
  String? region;
  for (final p in parts.skip(1)) {
    if (p.length == 4) {
      script = p;
    } else {
      region = p;
    }
  }
  return matchLocale(
    parts.first,
    script: script,
    region: region,
    locales: locales,
  ).code;
}

void main() {
  group('today: only Turkish and English are open', () {
    // Example 1 (and DECISIONS 18: Turkish for Turkish phones, else English).
    for (final (device, expected) in [
      ('de-DE', 'en'),
      ('tr-TR', 'tr'),
      ('tr', 'tr'),
      ('es-MX', 'en'),
      ('en-US', 'en'),
      ('en-AU', 'en'),
      ('en-GB', 'en'),
      ('ar-EG', 'en'),
      ('zh-Hant-TW', 'en'),
      ('pt-BR', 'en'),
      ('ko-KR', 'en'),
      ('und', 'en'),
    ]) {
      test('$device → $expected', () => expect(match(device), expected));
    }
  });

  group('after the bulk translation: nearest region', () {
    for (final (device, expected) in [
      ('es-MX', 'es_419'),
      ('es-AR', 'es_419'),
      ('es-US', 'es_419'),
      ('es-ES', 'es'),
      ('es', 'es'),
      ('pt-AO', 'pt_PT'),
      ('pt-PT', 'pt_PT'),
      ('pt-BR', 'pt_BR'),
      ('pt', 'pt_BR'),
      ('de-AT', 'de'),
      ('de-CH', 'de_CH'),
      ('de-LI', 'de_CH'),
      ('fr-BE', 'fr'),
      ('fr-CA', 'fr_CA'),
      ('en-AU', 'en_GB'),
      ('en-IN', 'en_GB'),
      ('en-GB', 'en_GB'),
      ('en-US', 'en'),
      ('en-PR', 'en'),
      ('en', 'en'),
      ('zh-HK', 'zh_Hant'),
      ('zh-TW', 'zh_Hant'),
      ('zh-Hant', 'zh_Hant'),
      ('zh-CN', 'zh'),
      ('zh-Hans-HK', 'zh'),
      ('zh', 'zh'),
      ('ar-EG', 'ar'),
      ('ar-SA', 'ar'),
      ('ja-JP', 'ja'),
      ('ru-KZ', 'ru'),
      ('tr-CY', 'tr'),
      ('ko-KR', 'en'),
    ]) {
      test(
        '$device → $expected',
        () => expect(match(device, allReviewed), expected),
      );
    }
  });

  test('a closed nearest region falls back to the open one', () {
    // Only es-ES is open: a Mexican phone gets Spanish (Spain), not English.
    final locales = [
      for (final l in appLocales)
        l.code == 'es' ? l.withStatus(LocaleStatus.reviewed) : l,
    ];
    expect(match('es-MX', locales), 'es');
    // English (UK) closed (today): an Australian phone gets English (US).
    expect(match('en-AU'), 'en');
  });

  test('a draft locale is never picked from the phone', () {
    final locales = [
      for (final l in appLocales)
        l.code == 'de' ? l.withStatus(LocaleStatus.draft) : l,
    ];
    expect(match('de-DE', locales), 'en');
    // But it is offered in the picker.
    expect(openLocales(locales).map((l) => l.code), contains('de'));
  });

  test('a saved language is used only while it is open', () {
    expect(chosenLocale('tr')?.code, 'tr');
    expect(chosenLocale('en')?.code, 'en');
    expect(chosenLocale(null), isNull);
    expect(chosenLocale('de'), isNull, reason: 'closed today');
    expect(chosenLocale('xx'), isNull);
  });

  test('every locale turns into a Flutter locale with its own texts', () {
    for (final info in appLocales) {
      final locale = localeOf(info);
      expect(locale.languageCode, isNot(contains('_')), reason: info.code);
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.localeName, info.code, reason: info.code);
    }
    expect(
      localeOf(localeInfoOf('zh_Hant')!),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(localeOf(localeInfoOf('es_419')!), const Locale('es', '419'));
  });

  test('resolveLocale keeps today\'s results', () {
    expect(resolveLocale(const Locale('tr', 'TR')), const Locale('tr'));
    expect(resolveLocale(const Locale('de', 'DE')), const Locale('en'));
    expect(resolveLocale(null), const Locale('en'));
  });

  test('picker names: the language alone unless two of it are open', () {
    expect(pickerNameOf(localeInfoOf('tr')!), 'Türkçe');
    expect(pickerNameOf(localeInfoOf('en')!), 'English');
    expect(
      pickerNameOf(localeInfoOf('pt_BR')!, allReviewed),
      'Português (Brasil)',
    );
    expect(pickerNameOf(localeInfoOf('ar')!, allReviewed), 'العربية');
    expect(pickerNameOf(localeInfoOf('en')!, allReviewed), 'English (US)');
  });

  test('intl locales: zh_Hant reads Taiwan\'s data, others their own', () {
    expect(intlLocaleOf('zh_Hant'), 'zh_TW');
    expect(intlLocaleOf('tr'), 'tr');
    expect(intlLocaleOf('en'), 'en');
    expect(intlLocaleOf('es_419'), 'es_419');
    expect(intlLocaleOf('pt'), 'pt');
  });
}
