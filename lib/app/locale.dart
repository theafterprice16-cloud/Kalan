import 'dart:ui' show Locale, PlatformDispatcher;

/// Turkish for Turkish devices, English otherwise.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

/// The app language: the setting if chosen, otherwise from the device.
Locale appLocale(String? localeCode) => localeCode != null
    ? Locale(localeCode)
    : resolveLocale(PlatformDispatcher.instance.locale, const []);
