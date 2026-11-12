import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/routing/router.dart';
import '../core/theme/kalan_theme.dart';
import '../core/theme/theme_mode.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// Turkish for Turkish devices, English otherwise.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

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
      themeMode: ref.watch(themeModeProvider),
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
