// iOS and Android language lists follow lib/l10n/app_locales.dart
// (Roadmap 24, decision 7). Fix with: dart run tool/sync_locales.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/l10n/app_locales.dart';

import '../../tool/sync_locales.dart';

void main() {
  test('reviewed locales only: Turkish and English today', () {
    expect(platformTags(), ['tr', 'en']);
  });

  test('iOS CFBundleLocalizations is the reviewed list', () {
    final plist = File(infoPlistPath).readAsStringSync();
    expect(plistLocalizations(plist), platformTags());
  });

  test('Android locales_config.xml is the reviewed list', () {
    expect(
      File(localeConfigPath).readAsStringSync(),
      localeConfigXml(platformTags()),
    );
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
  });

  test('opening a locale adds its platform tag', () {
    final locales = [
      for (final l in appLocales)
        switch (l.code) {
          'zh' || 'pt_BR' || 'es_419' => l.withStatus(LocaleStatus.reviewed),
          'ar' => l.withStatus(LocaleStatus.draft),
          _ => l,
        },
    ];
    expect(platformTags(locales), ['tr', 'en', 'es-419', 'pt-BR', 'zh-Hans']);
    final plist = withPlistLocalizations(
      File(infoPlistPath).readAsStringSync(),
      platformTags(locales),
    );
    expect(plistLocalizations(plist), [
      'tr',
      'en',
      'es-419',
      'pt-BR',
      'zh-Hans',
    ]);
    expect(plist, contains('<key>CFBundleDisplayName</key>'));
  });
}
