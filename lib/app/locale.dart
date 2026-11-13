import 'package:flutter/widgets.dart';

/// Turkish for Turkish devices, English otherwise.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

/// The app language: the setting if chosen, otherwise from the device.
/// Works in background isolates once the binding is initialized.
Locale appLocale(String? localeCode) => localeCode != null
    ? Locale(localeCode)
    : resolveLocale(
        WidgetsBinding.instance.platformDispatcher.locale,
        const [],
      );
