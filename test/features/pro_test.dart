import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/store_gateway.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_store.dart';

const limitText =
    'Ücretsiz sürümde 4 açık plan var. Bir planı bitirdiğinde ya da Pro ile '
    'yenisini ekleyebilirsin.';

/// Four open pay-in-4 plans and rent (recurring payments do not count).
Future<void> seedFour(AppDatabase db) async {
  await seedSettings(db);
  for (final name in ['A', 'B', 'C', 'D']) {
    await seedPayIn4(db, source: name);
  }
  await seedRent(db);
}

Future<AppDatabase> startWithFour(
  WidgetTester tester, {
  FakeStoreGateway? store,
  ProStatus stored = ProStatus.notPro,
  String? route,
}) => pumpApp(
  tester,
  seed: seedFour,
  overrides: [
    storeGatewayProvider.overrideWithValue(store ?? FakeStoreGateway()),
    proStatusStoreProvider.overrideWithValue(LoggingProStatusStore([], stored)),
    if (route != null) initialRouteProvider.overrideWithValue(route),
  ],
);

/// Opens "Add plan" and fills a fifth pay-in-4 plan, then taps Save.
Future<void> fillFifthAndSave(WidgetTester tester) async {
  await tester.tap(find.text('Plan ekle'));
  await tester.pumpAndSettle();
  expect(find.text('Plan türü'), findsOneWidget);
  await tester.enterText(find.byKey(const ValueKey('source')), 'Zip');
  await tester.enterText(find.byKey(const ValueKey('total')), '400');
  await tester.pumpAndSettle();
  await tapSave(tester);
}

Future<void> tapSave(WidgetTester tester) async {
  await scrollTo(tester, find.byKey(const ValueKey('save-plan')));
  await tester.tap(find.byKey(const ValueKey('save-plan')));
  await tester.pumpAndSettle();
}

Future<void> scrollUpTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<int> planCount(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.plans).get()))!.length;

void main() {
  testWidgets('fifth plan: a calm sheet, nothing saved', (tester) async {
    final db = await startWithFour(tester);
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsOneWidget);
    expect(find.text("Pro'ya bak"), findsOneWidget);
    expect(find.text('Şimdi değil'), findsOneWidget);
    expect(await planCount(tester, db), 4);
  });

  testWidgets('"Not now" keeps every typed field', (tester) async {
    final db = await startWithFour(tester);
    await fillFifthAndSave(tester);
    await tester.tap(find.byKey(const ValueKey('pro-limit-not-now')));
    await tester.pumpAndSettle();
    expect(find.text(limitText), findsNothing);
    expect(find.byType(Form), findsOneWidget);
    await scrollUpTo(tester, find.byKey(const ValueKey('total')));
    expect(find.text('400'), findsOneWidget);
    await scrollUpTo(tester, find.byKey(const ValueKey('source')));
    expect(find.text('Zip'), findsOneWidget);
    expect(await planCount(tester, db), 4);
  });

  testWidgets('buying Pro returns to the plan, which then saves', (
    tester,
  ) async {
    final store = FakeStoreGateway();
    final db = await startWithFour(tester, store: store);
    await fillFifthAndSave(tester);
    await tester.tap(find.byKey(const ValueKey('pro-limit-see-pro')));
    await tester.pumpAndSettle();
    expect(
      find.text('249,99 ₺ · bir kez ödenir. Abonelik yok, yenileme yok.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('pro-buy')));
    await tester.pumpAndSettle();

    // The save carries on with the typed fields: back home, plan added.
    expect(find.byKey(const ValueKey('pro-screen')), findsNothing);
    expect(find.text('Plan eklendi.'), findsOneWidget);
    expect(await planCount(tester, db), 5);
    final names = await tester.runAsync(() => db.select(db.sources).get());
    expect(names!.map((s) => s.name), contains('Zip'));
  });

  testWidgets('a canceled purchase stays on the Pro screen, quietly', (
    tester,
  ) async {
    final store = FakeStoreGateway()..afterBuy = [const StoreCanceled()];
    await startWithFour(tester, store: store, route: Routes.pro());
    await tester.tap(find.byKey(const ValueKey('pro-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pro-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('pro-failed')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed purchase shows one calm line', (tester) async {
    final store = FakeStoreGateway()..afterBuy = [const StoreFailed()];
    await startWithFour(tester, store: store, route: Routes.pro());
    await tester.tap(find.byKey(const ValueKey('pro-buy')));
    await tester.pumpAndSettle();
    expect(
      find.text('Satın alma tamamlanamadı. Sonra yeniden dene.'),
      findsOneWidget,
    );
  });

  testWidgets('price not loaded: a note, try again, no buying', (tester) async {
    final store = FakeStoreGateway()..price = const PriceUnavailable();
    await startWithFour(tester, store: store, route: Routes.pro());
    expect(find.text('Fiyat şu an alınamadı.'), findsOneWidget);
    final buy = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pro-buy')),
    );
    expect(buy.onPressed, isNull);

    store.price = const PriceLoaded('249,99 ₺');
    await tester.tap(find.byKey(const ValueKey('pro-price-retry')));
    await tester.pumpAndSettle();
    expect(find.textContaining('249,99 ₺ · bir kez ödenir.'), findsOneWidget);
  });

  testWidgets('Pro user: no limit, one calm line on the Pro screen', (
    tester,
  ) async {
    final db = await startWithFour(tester, stored: ProStatus.pro);
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsNothing);
    expect(await planCount(tester, db), 5);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('settings-pro')));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('settings-pro')),
        matching: find.text('Pro'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('settings-pro')));
    await tester.pumpAndSettle();
    expect(find.text('Pro açık. Teşekkürler.'), findsOneWidget);
    expect(find.byKey(const ValueKey('pro-buy')), findsNothing);
  });

  testWidgets('refunded: plans stay and open, a new one is stopped', (
    tester,
  ) async {
    final store = FakeStoreGateway()..ownership = const Revoked();
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedFour(db);
        await seedPayIn4(db, source: 'E');
        await seedPayIn4(db, source: 'F');
      },
      overrides: [
        storeGatewayProvider.overrideWithValue(store),
        proStatusStoreProvider.overrideWithValue(
          LoggingProStatusStore([], ProStatus.pro),
        ),
      ],
    );
    await tester.tap(find.text('Planlar'));
    await tester.pumpAndSettle();
    for (final name in ['A', 'F']) {
      await scrollTo(tester, find.text(name).first);
      expect(find.text(name), findsWidgets);
    }
    await tester.tap(find.text('F').first);
    await tester.pumpAndSettle();
    // Still editable: the edit button is there and opens the form.
    await tester.tap(find.byTooltip('Planı düzenle'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Planı düzenle'), findsOneWidget);
    ProviderScope.containerOf(tester.element(find.byType(KalanApp)))
        .read(routerProvider)
        .go(Routes.home);
    await tester.pumpAndSettle();
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsOneWidget);
    expect(await planCount(tester, db), 6);
  });

  group('restore from Settings', () {
    Future<void> restoreWith(
      WidgetTester tester,
      OwnershipQuery answer,
      String message,
    ) async {
      final store = FakeStoreGateway()..restoreAnswer = answer;
      await startWithFour(tester, store: store, route: Routes.settings);
      await scrollTo(tester, find.byKey(const ValueKey('settings-restore')));
      await tester.tap(find.byKey(const ValueKey('settings-restore')));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
    }

    testWidgets('found', (tester) async {
      await restoreWith(tester, const Owned(), 'Pro açıldı.');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-pro')),
          matching: find.text('Pro'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('not found', (tester) async {
      await restoreWith(
        tester,
        const NotOwned(),
        'Bu mağaza hesabında Pro bulunamadı.',
      );
      expect(find.text('Ücretsiz'), findsOneWidget);
    });

    testWidgets('store unreachable', (tester) async {
      await restoreWith(
        tester,
        const QueryFailed(FailureKind.network),
        'Mağazaya şu an ulaşılamadı. Sonra yeniden dene.',
      );
    });
  });

  testWidgets('debug Pro switch still lifts the limit in debug builds', (
    tester,
  ) async {
    final db = await startWithFour(tester);
    await tester.runAsync(
      () => db
          .update(db.appSettings)
          .write(const AppSettingsCompanion(debugPro: Value(true))),
    );
    await tester.pumpAndSettle();
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsNothing);
  });

  testWidgets('large text: Pro screen and sheet do not overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = FakeStoreGateway()..afterBuy = null;
    await startWithFour(tester, store: store);
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pro-limit-see-pro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pro-buy')));
    await tester.pump();
    // Buying: the button waits and cannot be tapped again.
    final buy = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pro-buy')),
    );
    expect(buy.onPressed, isNull);
    expect(store.buyCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
