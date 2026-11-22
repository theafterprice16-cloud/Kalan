// Writes the iOS and Android language lists from lib/l10n/app_locales.dart
// (Roadmap 24): the reviewed locales, in order. Run after changing a
// locale's status:
//   dart run tool/sync_locales.dart
// test/l10n/platform_locales_test.dart fails while the lists differ.
import 'dart:io';

import 'package:kalan/l10n/app_locales.dart';

const infoPlistPath = 'ios/Runner/Info.plist';
const localeConfigPath = 'android/app/src/main/res/xml/locales_config.xml';

/// The tags the phone may offer as the app's language: reviewed only, the
/// same locales the phone's language is matched to.
List<String> platformTags([List<AppLocaleInfo> locales = appLocales]) => [
  for (final l in locales)
    if (l.status == LocaleStatus.reviewed) l.platformTag,
];

final _plistArray = RegExp(
  r'(<key>CFBundleLocalizations</key>\s*<array>)[\s\S]*?(\s*</array>)',
);

/// [plist] with its CFBundleLocalizations array set to [tags].
String withPlistLocalizations(String plist, List<String> tags) {
  if (!_plistArray.hasMatch(plist)) {
    throw StateError('CFBundleLocalizations not found in $infoPlistPath');
  }
  return plist.replaceFirstMapped(
    _plistArray,
    (m) =>
        '${m[1]}${[for (final t in tags) '\n\t\t<string>$t</string>'].join()}'
        '${m[2]}',
  );
}

/// The tags in a plist's CFBundleLocalizations array.
List<String> plistLocalizations(String plist) {
  final m = _plistArray.firstMatch(plist);
  if (m == null) return const [];
  return [
    for (final s in RegExp(r'<string>([^<]*)</string>').allMatches(m[0]!))
      s[1]!,
  ];
}

/// Android's per-app language list (Android 13 and later).
String localeConfigXml(List<String> tags) =>
    '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Written by tool/sync_locales.dart from lib/l10n/app_locales.dart. -->
<locale-config xmlns:android="http://schemas.android.com/apk/res/android">
${[for (final t in tags) '    <locale android:name="$t" />'].join('\n')}
</locale-config>
''';

void main() {
  final tags = platformTags();
  final plist = File(infoPlistPath);
  plist.writeAsStringSync(
    withPlistLocalizations(plist.readAsStringSync(), tags),
  );
  File(localeConfigPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(localeConfigXml(tags));
  stdout.writeln('Languages on iOS and Android: ${tags.join(', ')}');
}
