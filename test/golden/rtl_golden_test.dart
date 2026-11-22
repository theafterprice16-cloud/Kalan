// Right-to-left screenshots (Roadmap 24): the app in Arabic, opened for
// the test only. There are no Arabic texts yet, so the words are English;
// the layout reads from the right and dates are Arabic, with 0-9.
// DejaVu Sans (test/fonts, test only) draws Arabic letters; phones use
// their own fonts. Update with:
//   flutter test test/golden --update-goldens
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';
import 'screens_golden_test.dart' show seedRich;

/// DejaVu Sans for every text style (Latin and Arabic), Material icons
/// from the Flutter SDK.
Future<void> loadArabicFonts() async {
  Future<void> family(String name, List<String> paths) async {
    final loader = FontLoader(name);
    for (final p in paths) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const dejaVu = [
    'test/fonts/DejaVuSans.ttf',
    'test/fonts/DejaVuSans-Bold.ttf',
  ];
  for (final name in [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
  ]) {
    await family(name, dejaVu);
  }
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final icons = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await family('MaterialIcons', [icons.path]);
      return;
    }
    dir = dir.parent;
  }
}

Future<void> shoot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(KalanApp),
    matchesGoldenFile('../../screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await loadArabicFonts();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme = mode.name;

    Future<void> start(WidgetTester tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        locale: const Locale('ar', 'EG'),
        seed: (db) => seedRich(db, incomeMinor: 4500000),
        overrides: [
          appLocalesProvider.overrideWithValue([
            for (final l in appLocales)
              l.code == 'ar' ? l.withStatus(LocaleStatus.reviewed) : l,
          ]),
          themeModeStoreProvider.overrideWithValue(MemoryThemeModeStore(mode)),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 20, 5)),
        ],
      );
    }

    group(theme, () {
      testWidgets('home, Arabic', (tester) async {
        await start(tester);
        await shoot(tester, '93-home-ar-$theme');
      });

      testWidgets('coming periods, Arabic', (tester) async {
        await start(tester);
        await tester.tap(find.byKey(const ValueKey('coming-periods-strip')));
        await shoot(tester, '94-coming-periods-ar-$theme');
      });
    });
  }
}
