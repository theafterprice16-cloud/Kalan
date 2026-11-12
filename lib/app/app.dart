import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/theme.dart';
import '../core/routing/router.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// App languages in picker order. Portuguese is Brazilian, Chinese is
/// Simplified.
const appLanguageCodes = [
  'tr', 'en', 'es', 'fr', 'de', 'pt', 'ru', 'zh', 'it', 'id', //
];

/// A language's name in that language ("Deutsch", "中文").
String nativeLanguageName(String code) =>
    lookupAppLocalizations(Locale(code)).languageNativeName;

/// The device language when Kalan has it, English otherwise.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  final code = device?.languageCode;
  return appLanguageCodes.contains(code) ? Locale(code!) : const Locale('en');
}

class KalanApp extends ConsumerWidget {
  const KalanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(
      settingsProvider.select((s) => s.value?.localeCode),
    );
    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: KalanTheme.light(),
      darkTheme: KalanTheme.dark(),
      locale: localeCode == null ? null : Locale(localeCode),
      localeResolutionCallback: resolveLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
