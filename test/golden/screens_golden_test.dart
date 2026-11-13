// Golden screenshots of every main screen in light and dark themes.
// Images live in screenshots/. Update with:
//   flutter test test/golden --update-goldens
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/roadmap/roadmap.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/app_harness.dart';
import '../helpers/fake_notifications.dart';

/// Real fonts from the Flutter SDK so screenshots are readable.
Future<void> loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  Directory? fonts;
  for (var i = 0; i < 8 && fonts == null; i++) {
    final candidate = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) fonts = candidate;
    final env = Platform.environment['FLUTTER_ROOT'];
    if (fonts == null && env != null) {
      final fromEnv = Directory('$env/bin/cache/artifacts/material_fonts');
      if (fromEnv.existsSync()) fonts = fromEnv;
    }
    dir = dir.parent;
  }
  if (fonts == null) return;
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('${fonts!.path}/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await family('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await family('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// A plan with a past unpaid payment (overdue), a card plan, rent.
Future<void> seedRich(AppDatabase db, {required int incomeMinor}) async {
  await seedSettings(db, incomeMinor: incomeMinor, thresholdMinor: 500000);
  await seedPayIn4(db, totalMinor: 240000, title: 'Kulaklık');
  await seedPayIn4(
    db,
    first: LocalDate(2026, 10, 30),
    totalMinor: 180000,
    source: 'Afterpay',
    title: 'Mont',
  );
  final card = await seedCard(db);
  final draft = PlanCalculator.card(
    purchaseDate: LocalDate(2026, 10, 10),
    totalMinor: 1200000,
    count: 6,
    terms: const CardTerms(statementDay: 25, dueDay: 5),
  );
  final planId = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          sourceId: card,
          title: const Value('Telefon'),
          kind: PlanKind.card,
          installmentCount: 6,
          origin: PlanOrigin.template,
        ),
      );
  for (final p in draft.payments) {
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            planId: planId,
            seq: p.seq,
            dueDay: p.date.epochDay,
            amountMinor: p.amountMinor,
            paidAt: Value(p.seq == 1 ? DateTime(2026, 11, 5) : null),
          ),
        );
  }
  await seedRent(db);
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
    await loadFonts();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme = mode.name;

    Future<void> start(
      WidgetTester tester, {
      int income = 4500000,
      bool onboarded = true,
      List<Override> extra = const [],
      String? route,
    }) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        seed: onboarded ? (db) => seedRich(db, incomeMinor: income) : null,
        overrides: [
          themeModeStoreProvider.overrideWithValue(MemoryThemeModeStore(mode)),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 20, 5)),
          if (route != null) initialRouteProvider.overrideWithValue(route),
          ...extra,
        ],
      );
    }

    group(theme, () {
      testWidgets('onboarding', (tester) async {
        await start(tester, onboarded: false);
        await shoot(tester, '01-onboarding-$theme');
      });

      testWidgets('home, left positive', (tester) async {
        await start(tester);
        await shoot(tester, '02-home-positive-$theme');
      });

      testWidgets('home, left negative', (tester) async {
        await start(tester, income: 1500000);
        await shoot(tester, '03-home-negative-$theme');
      });

      testWidgets('add plan', (tester) async {
        await start(tester);
        await tester.tap(find.text('Plan ekle'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Aylık taksit'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
        await tester.enterText(find.byKey(const ValueKey('total')), '6000');
        await tester.enterText(find.byKey(const ValueKey('count')), '3');
        FocusManager.instance.primaryFocus?.unfocus();
        await shoot(tester, '04-add-plan-$theme');
      });

      testWidgets('plans', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await shoot(tester, '05-plans-$theme');
      });

      testWidgets('plan detail', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Mont'));
        await shoot(tester, '06-plan-detail-$theme');
      });

      testWidgets('recurring payment', (tester) async {
        await start(tester);
        await openTab(tester, 'Planlar');
        await tester.tap(find.text('Sabit'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kira'));
        await shoot(tester, '07-recurring-$theme');
      });

      testWidgets('settings', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await shoot(tester, '08-settings-$theme');
      });

      testWidgets('roadmap', (tester) async {
        // The documented example, read synchronously for a stable shot.
        final doc = File('docs/ROADMAP_CONTENT.md').readAsStringSync();
        final example = RegExp(
          r'```json\n(.*?)```',
          dotAll: true,
        ).firstMatch(doc)!.group(1)!;
        await start(
          tester,
          extra: [roadmapSourceProvider.overrideWith((ref) async => example)],
        );
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Yol Haritası'));
        await tester.tap(find.text('Yol Haritası'));
        await shoot(tester, '09-roadmap-$theme');
      });

      testWidgets('currency change', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('currency-search')),
          'IDR',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('currency-IDR')));
        await shoot(tester, '10-currency-change-$theme');
      });

      testWidgets('currency picker', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await shoot(tester, '15-currency-picker-$theme');
      });

      testWidgets('currency search, right-to-left symbols', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        await scrollTo(tester, find.text('Para birimi'));
        await tester.tap(find.text('Para birimi'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('currency-search')),
          'dinar',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await shoot(tester, '16-currency-search-$theme');
      });

      testWidgets('settings, reminders section', (tester) async {
        await start(tester);
        await openTab(tester, 'Ayarlar');
        // Put the section title near the top of the screen.
        await scrollTo(tester, find.text('Hatırlatmalar'));
        final top = tester.getTopLeft(find.text('Hatırlatmalar')).dy;
        await tester.drag(find.byType(Scrollable).first, Offset(0, 80 - top));
        await shoot(tester, '11-settings-reminders-$theme');
      });

      testWidgets('payments of the day', (tester) async {
        await start(tester, route: '/day/2026-11-20');
        await shoot(tester, '12-day-payments-$theme');
      });

      testWidgets('reminders help', (tester) async {
        await start(tester, route: Routes.remindersHelp);
        await shoot(tester, '13-reminders-help-$theme');
      });

      testWidgets('reminder prompt', (tester) async {
        await start(tester);
        await tester.tap(find.text('Plan ekle'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
        await tester.enterText(find.byKey(const ValueKey('total')), '400');
        await tester.pumpAndSettle();
        await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
        await tester.tap(find.byKey(const ValueKey('save-plan')));
        await shoot(tester, '14-reminder-prompt-$theme');
      });
    });
  }
}
