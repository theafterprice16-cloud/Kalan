import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:kalan/data/backup/backup_collector.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/features/export/backup_prefs.dart';
import 'package:kalan/features/home/home_screen.dart';
import 'package:kalan/features/lock/app_lock_controller.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';
import 'package:kalan/features/onboarding/onboarding_screen.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_device_lock.dart';
import '../helpers/fake_notifications.dart';
import '../helpers/fake_store.dart';
import '../helpers/restore_fakes.dart';
import 'pro_test.dart' show fillFifthAndSave, limitText;

/// Roadmap 30 on screen: "I have a backup" in setup, "Restore from
/// backup" in Settings, the summary, the calm errors, "Go back to
/// previous data" and the line for Pro.
void main() {
  late Directory undoDir;
  late FakePicker picker;
  late MemoryBackupPrefsStore prefs;
  late FakeNotificationGateway notifications;
  late FakeStoreGateway store;

  setUp(() {
    undoDir = Directory.systemTemp.createTempSync('kalan-restore-ui');
    picker = FakePicker();
    prefs = MemoryBackupPrefsStore();
    notifications = FakeNotificationGateway();
    store = FakeStoreGateway();
  });
  tearDown(() => undoDir.deleteSync(recursive: true));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<AppDatabase> start(
    WidgetTester tester, {
    String? route,
    Future<void> Function(AppDatabase db)? seed,
    Locale locale = const Locale('tr', 'TR'),
  }) => pumpApp(
    tester,
    locale: locale,
    seed: seed,
    overrides: [
      if (route != null) initialRouteProvider.overrideWithValue(route),
      ...restoreOverrides(picker, undoDir),
      backupPrefsStoreProvider.overrideWithValue(prefs),
      notificationGatewayProvider.overrideWithValue(notifications),
      reminderDebounceProvider.overrideWithValue(Duration.zero),
      storeGatewayProvider.overrideWithValue(store),
    ],
  );

  /// Lets real file work (the safety copy) finish.
  Future<void> settle(WidgetTester tester) async {
    // File work and the database take turns: real time for the one, a
    // frame for the other.
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> pickFile(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('restore-pick')));
    await tester.pumpAndSettle();
  }

  testWidgets('Example 1: a new phone restores from setup; setup is skipped', (
    tester,
  ) async {
    tall(tester);
    final db = await start(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Yedeğim var'));
    await tester.pumpAndSettle();
    expect(find.text('Yedekten geri yükle'), findsOneWidget);
    picker.pickPath(encryptedFixture);
    await pickFile(tester);
    expect(
      find.text('Bu yedek parolalı. Yedeği alırken yazdığın parolayı gir.'),
      findsOneWidget,
    );
    // Example 4: a wrong password; the field stays open.
    await tester.enterText(
      find.byKey(const ValueKey('restore-password')),
      'yanlış',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('restore-open')));
    await tester.pumpAndSettle();
    expect(find.text('Parola doğru değil.'), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-password')), findsOneWidget);
    expect(await db.select(db.appSettings).get(), isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('restore-password')),
      fixturePasswordText,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('restore-open')));
    await tester.pumpAndSettle();
    // The summary.
    expect(find.text('19 Kas 2026 tarihli yedek'), findsOneWidget);
    expect(
      find.text('4 plan (0 açık, 1 beklemede, 3 arşivde)'),
      findsOneWidget,
    );
    expect(find.text('1 sabit ödeme'), findsOneWidget);
    expect(find.text('2 kaynak, 1 kart'), findsOneWidget);
    expect(find.text('Para birimi: TRY'), findsOneWidget);
    // Nothing to replace: no note, no dialog, no copy.
    expect(find.byKey(const ValueKey('restore-replace-note')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await settle(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text('Yedek geri yüklendi: 4 plan, 1 sabit ödeme.'),
      findsOneWidget,
    );
    expect(await db.select(db.plans).get(), hasLength(4));
    expect(undoDir.listSync(recursive: true).whereType<File>(), isEmpty);
    // Reminders set up from the restored payments; last backup its day.
    expect(notifications.replaceCalls, greaterThan(0));
    expect(prefs.read().lastFullBackup.toString(), '2026-11-19');
  });

  testWidgets(
    'Example 2 and 3: over data, the currency changes, and back again',
    (tester) async {
      tall(tester);
      final db = await start(
        tester,
        route: Routes.settings,
        seed: (db) async {
          await seedSettings(db, currency: 'EUR');
          await seedPayIn4(db, title: 'Kulaklık');
          await seedPayIn4(db, title: 'Mont', source: 'Afterpay');
        },
      );
      await scrollTo(
        tester,
        find.byKey(const ValueKey('settings-restore-backup')),
      );
      await tester.tap(find.byKey(const ValueKey('settings-restore-backup')));
      await tester.pumpAndSettle();
      picker.pickPath(plainFixture);
      await pickFile(tester);
      expect(find.text('Para birimi: TRY olacak (şu an EUR)'), findsOneWidget);
      expect(
        find.text(
          'Telefondaki verinin yerine bu yedek geçecek. Önce mevcut verinin '
          'bir kopyası alınır; 30 gün içinde geri dönebilirsin.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('restore-button')));
      await tester.pumpAndSettle();
      expect(find.text('Bu yedek geri yüklensin mi?'), findsOneWidget);
      // "Cancel" changes nothing.
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect((await db.select(db.appSettings).getSingle()).currencyCode, 'EUR');
      await tester.tap(find.byKey(const ValueKey('restore-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-confirm')));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect((await db.select(db.appSettings).getSingle()).currencyCode, 'TRY');
      expect(undoDir.listSync(recursive: true).whereType<File>(), hasLength(1));

      // Settings > Data: "Go back to previous data · 20 Kas 2026".
      await tester.tap(find.text('Ayarlar'));
      await settle(tester);
      final undo = find.byKey(const ValueKey('settings-undo-copy'));
      await scrollTo(tester, undo);
      expect(find.text('Önceki verine dön · 20 Kas 2026'), findsOneWidget);
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(find.text('Önceki verine dönülsün mü?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('undo-confirm')));
      await settle(tester);
      expect(find.text('Önceki verine dönüldü.'), findsOneWidget);
      expect((await db.select(db.appSettings).getSingle()).currencyCode, 'EUR');
      expect(await db.select(db.plans).get(), hasLength(2));
    },
  );

  testWidgets(
    'Example 5 and a newer version: calm sentences, nothing changes',
    (tester) async {
      tall(tester);
      final db = await start(tester, route: Routes.restore, seed: seedSettings);
      final before = await db.select(db.appSettings).getSingle();
      picker.pickBytes([0x89, 0x50, 0x4E, 0x47, 0xFF, 0xD8]);
      await pickFile(tester);
      expect(find.text('Bu dosya bir Kalan yedeği değil.'), findsOneWidget);
      picker.pickBytes(
        utf8.encode(
          File(plainFixture)
              .readAsStringSync()
              .replaceFirst('"formatVersion": 1', '"formatVersion": 2'),
        ),
      );
      await pickFile(tester);
      expect(
        find.text(
          "Bu yedek Kalan'ın daha yeni bir sürümüyle alınmış. Uygulamayı "
          'güncelleyip yeniden dene.',
        ),
        findsOneWidget,
      );
      picker.pickBytes(
        utf8.encode(
          File(plainFixture).readAsStringSync().replaceFirst('"Mont"', '"Ma"'),
        ),
      );
      await pickFile(tester);
      expect(
        find.text('Dosya okunamadı. Başka bir yedek dene.'),
        findsOneWidget,
      );
      expect(
        (await db.select(db.appSettings).getSingle()).toJson(),
        before.toJson(),
      );
      // A closed picker leaves the screen as it is.
      picker.file = null;
      await pickFile(tester);
      expect(find.text('Dosya okunamadı. Başka bir yedek dene.'), findsNothing);
    },
  );

  testWidgets('English texts', (tester) async {
    tall(tester);
    await start(tester, locale: const Locale('en', 'US'));
    await tester.tap(find.text('I have a backup'));
    await tester.pumpAndSettle();
    expect(find.text('Restore from backup'), findsOneWidget);
    picker.pickPath(plainFixture);
    await pickFile(tester);
    expect(find.text('Backup from Nov 19, 2026'), findsOneWidget);
    expect(
      find.text('4 plans (0 open, 1 on hold, 3 archived)'),
      findsOneWidget,
    );
    expect(find.text('1 recurring payment'), findsOneWidget);
    expect(find.text('2 sources, 1 card'), findsOneWidget);
    expect(find.text('Currency: TRY'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await settle(tester);
    expect(
      find.text('Backup restored: 4 plans, 1 recurring payment.'),
      findsOneWidget,
    );
  });

  testWidgets('Example 7: six open plans on the free version', (tester) async {
    tall(tester);
    // A backup with six open plans.
    final bytes = await tester.runAsync(() async {
      final other = AppDatabase(NativeDatabase.memory());
      await seedSettings(other);
      for (var i = 0; i < 6; i++) {
        await seedPayIn4(other, title: 'Plan $i');
      }
      final data = (await collectBackup(other))!;
      await other.close();
      return utf8.encode(
        await writeBackup(
          data,
          appVersion: '1.0.0+1',
          createdAt: DateTime.utc(2026, 11, 19),
        ),
      );
    });
    final db = await start(tester, route: Routes.restore);
    picker.pickBytes(bytes!);
    await pickFile(tester);
    expect(
      find.text('6 plan (6 açık, 0 beklemede, 0 arşivde)'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await settle(tester);
    // All six came back.
    expect(await db.select(db.plans).get(), hasLength(6));
    // The calm line instead of the short message; the store is not asked
    // on its own.
    expect(find.byKey(const ValueKey('restore-pro-line')), findsOneWidget);
    expect(
      find.text(
        "Pro'yu daha önce aldıysan geri yükleyerek yeni plan ekleyebilirsin.",
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Yedek geri yüklendi'), findsNothing);
    expect(store.log, isNot(contains('restore')));
    // A new plan meets 11's limit sheet; nothing is saved.
    await fillFifthAndSave(tester);
    expect(find.text(limitText), findsOneWidget);
    expect(await db.select(db.plans).get(), hasLength(6));
    await tester.tap(find.byKey(const ValueKey('pro-limit-not-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(store.log, isNot(contains('restore')));
    await tester.tap(find.byKey(const ValueKey('restore-pro-restore')));
    await tester.pumpAndSettle();
    expect(store.log, contains('restore'));
  });

  testWidgets('Example 8: lock, dark theme, language and hidden amounts '
      'stay as they are', (tester) async {
    tall(tester);
    final lock = MemoryAppLockStore(const AppLockSettings(enabled: true));
    final theme = MemoryThemeModeStore(ThemeMode.dark);
    final hidden = MemoryAmountsHiddenStore(true);
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedSettings(db, currency: 'EUR', localeCode: 'en');
        await seedPayIn4(db, title: 'Kulaklık');
      },
      overrides: [
        initialRouteProvider.overrideWithValue(Routes.restore),
        ...restoreOverrides(picker, undoDir),
        backupPrefsStoreProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(notifications),
        reminderDebounceProvider.overrideWithValue(Duration.zero),
        storeGatewayProvider.overrideWithValue(store),
        appLockStoreProvider.overrideWithValue(lock),
        deviceLockGatewayProvider.overrideWithValue(FakeDeviceLock()),
        appIsActiveProvider.overrideWithValue(() => true),
        themeModeStoreProvider.overrideWithValue(theme),
        amountsHiddenStoreProvider.overrideWithValue(hidden),
      ],
    );
    // The lock opened with the phone's answer; the app is in English.
    expect(find.text('Restore from backup'), findsOneWidget);
    picker.pickPath(plainFixture);
    await pickFile(tester);
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restore-confirm')));
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect((await db.select(db.appSettings).getSingle()).currencyCode, 'TRY');
    // This phone's own choices did not move.
    expect(lock.read().enabled, isTrue);
    expect(theme.read(), ThemeMode.dark);
    expect(hidden.read(), isTrue);
    final s = await db.select(db.appSettings).getSingle();
    expect(s.localeCode, 'en');
    final context = tester.element(find.byType(HomeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Localizations.localeOf(context).languageCode, 'en');
    // Hidden amounts: the home screen still shows none.
    expect(find.text('•••'), findsWidgets);
  });
}
