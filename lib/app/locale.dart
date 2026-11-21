import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../l10n/app_locales.dart';

export '../l10n/app_locales.dart';

/// The locale list the app reads ([appLocales]); tests open a closed
/// locale (Arabic, right to left) by overriding it.
final appLocalesProvider = Provider<List<AppLocaleInfo>>((ref) => appLocales);

/// The Flutter locale of [info]: language, script and region kept apart
/// (zh_Hant is Chinese in Traditional script, not a language "zh_Hant").
Locale localeOf(AppLocaleInfo info) => Locale.fromSubtags(
  languageCode: info.languageCode,
  scriptCode: info.scriptCode,
  countryCode: info.countryCode,
);

/// The saved language setting when it names a locale users can see;
/// null means the phone's language.
AppLocaleInfo? chosenLocale(
  String? localeCode, [
  List<AppLocaleInfo> locales = appLocales,
]) {
  final info = localeInfoOf(localeCode, locales);
  return info != null && info.status.isOpen ? info : null;
}

/// The app locale for the phone's language ([matchLocale]): Turkish for
/// Turkish phones, English otherwise while only those two are reviewed.
Locale resolveLocale(
  Locale? device, [
  List<AppLocaleInfo> locales = appLocales,
]) => localeOf(
  matchLocale(
    device?.languageCode ?? fallbackLocaleCode,
    script: device?.scriptCode,
    region: device?.countryCode,
    locales: locales,
  ),
);

/// The app language: the setting if it is open, otherwise from the
/// phone. Works in background isolates once the binding is initialized.
Locale appLocale(
  String? localeCode, [
  List<AppLocaleInfo> locales = appLocales,
]) {
  final chosen = chosenLocale(localeCode, locales);
  return chosen != null
      ? localeOf(chosen)
      : resolveLocale(
          WidgetsBinding.instance.platformDispatcher.locale,
          locales,
        );
}

/// Loads intl's date data for every locale (Roadmap 24), before the
/// first frame and in background isolates. Numbers need no loading.
Future<void> loadLocaleData() => initializeDateFormatting();
