import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/design/theme.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [child] inside a themed, localized MaterialApp.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('tr'),
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    theme: brightness == Brightness.light
        ? KalanTheme.light()
        : KalanTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);
