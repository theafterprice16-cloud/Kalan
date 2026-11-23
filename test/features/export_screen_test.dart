import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/features/export/backup_prefs.dart';
import 'package:kalan/features/export/export_service.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_share.dart';

/// Roadmap 29 on screen: Settings > Data, the export screen and the
/// calm backup note on the home screen.
void main() {
  late Directory temp;
  late FakeShare share;
  late MemoryBackupPrefsStore prefs;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kalan-export-ui');
    share = FakeShare();
    prefs = MemoryBackupPrefsStore();
  });
  tearDown(() => temp.deleteSync(recursive: true));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> start(
    WidgetTester tester, {
    String? route,
    Locale locale = const Locale('tr', 'TR'),
  }) => pumpApp(
    tester,
    locale: locale,
    seed: (db) async {
      await seedSettings(db, incomeMinor: 4500000);
      await seedPayIn4(db, title: 'Kulaklık');
    },
    overrides: [
      if (route != null) initialRouteProvider.overrideWithValue(route),
      exportTempDirectoryProvider.overrideWithValue(() async => temp),
      fileShareGatewayProvider.overrideWithValue(share),
      backupPrefsStoreProvider.overrideWithValue(prefs),
      // The real writer runs in another isolate; a widget test's clock
      // does not wait for it.
      backupWriterProvider.overrideWithValue(
        (request) async => '{"password": "${request.password ?? ''}"}',
      ),
    ],
  );

  testWidgets('Settings: Data section, free, last backup and the switch', (
    tester,
  ) async {
    tall(tester);
    prefs = MemoryBackupPrefsStore(
      BackupPrefs(lastFullBackup: LocalDate(2026, 11, 19)),
    );
    await start(tester, route: Routes.settings);
    await scrollTo(tester, find.byKey(const ValueKey('settings-backup-reminder')));
    expect(find.text('Veri'), findsOneWidget);
    expect(find.text('Dışa aktar'), findsOneWidget);
    expect(find.text('Son yedek'), findsOneWidget);
    expect(find.text('19 Kas 2026'), findsOneWidget);
    expect(find.text('Yedek hatırlatması'), findsOneWidget);
    await tester.tap(find.text('Yedek hatırlatması'));
    await tester.pumpAndSettle();
    expect(prefs.read().reminderEnabled, isFalse);
    expect(prefs.read().lastFullBackup, LocalDate(2026, 11, 19));
  });

  testWidgets('Example 1: full backup without a password', (tester) async {
    tall(tester);
    await start(tester, route: Routes.settings);
    await scrollTo(tester, find.byKey(const ValueKey('settings-export')));
    await tester.tap(find.byKey(const ValueKey('settings-export')));
    await tester.pumpAndSettle();
    // Spreadsheet first; then the full backup.
    expect(find.text('Tablo (CSV)'), findsOneWidget);
    await tester.tap(find.text('Tam yedek'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz yedek yok.'), findsOneWidget);
    expect(find.text('Bu yedek parolasız.'), findsOneWidget);
    expect(
      find.text('Parolayı unutursan bu yedeği kimse açamaz.'),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet ya da paylaş'));
      await share.called.future.timeout(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(share.shared.single.name, 'kalan-yedek-2026-11-20.json');
    expect(prefs.read().lastFullBackup, testToday);
    // Back in Settings: "Last backup" shows the day.
    await scrollTo(tester, find.byKey(const ValueKey('settings-last-backup')));
    expect(find.text('20 Kas 2026'), findsOneWidget);
  });

  testWidgets('Example 2: passwords that differ make no file', (tester) async {
    tall(tester);
    await start(tester, route: Routes.export(backup: true));
    await tester.enterText(
      find.byKey(const ValueKey('export-password')),
      'gizli',
    );
    await tester.enterText(
      find.byKey(const ValueKey('export-password-again')),
      'gizlı',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu yedek parolasız.'), findsNothing);
    await tester.tap(find.text('Kaydet ya da paylaş'));
    await tester.pumpAndSettle();
    expect(find.text('Parolalar aynı değil.'), findsOneWidget);
    expect(share.shared, isEmpty);
    // The same password twice: the file is written with it.
    await tester.enterText(
      find.byKey(const ValueKey('export-password-again')),
      'gizli',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet ya da paylaş'));
      await share.called.future.timeout(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(String.fromCharCodes(share.shared.single.bytes), contains('gizli'));
  });

  testWidgets('show and hide the password; no rules', (tester) async {
    tall(tester);
    await start(tester, route: Routes.export(backup: true));
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('export-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const ValueKey('export-password-show')));
    await tester.pumpAndSettle();
    expect(field().obscureText, isFalse);
    expect(
      tester.getSize(find.byKey(const ValueKey('export-password-show'))),
      const Size(48, 48),
    );
  });

  testWidgets('a closed share sheet keeps the screen and the date', (
    tester,
  ) async {
    tall(tester);
    share.outcome = ShareOutcome.dismissed;
    await start(tester, route: Routes.export(backup: true));
    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet ya da paylaş'));
      await share.called.future.timeout(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Kaydet ya da paylaş'), findsOneWidget);
    expect(prefs.read().lastFullBackup, isNull);
  });

  testWidgets('Example 6: backup 91 days ago, note on home and in Settings', (
    tester,
  ) async {
    tall(tester);
    prefs = MemoryBackupPrefsStore(
      BackupPrefs(lastFullBackup: testToday.addDays(-91)),
    );
    await start(tester);
    expect(find.text('Son yedek 3 ay önce.'), findsOneWidget);
    await tester.tap(find.text('Son yedek 3 ay önce.'));
    await tester.pumpAndSettle();
    // The export screen, full backup chosen.
    expect(find.byKey(const ValueKey('export-password')), findsOneWidget);
  });

  testWidgets('the note goes away with the switch off', (tester) async {
    tall(tester);
    prefs = MemoryBackupPrefsStore(
      BackupPrefs(lastFullBackup: testToday.addDays(-91)),
    );
    await start(tester, route: Routes.settings);
    await scrollTo(tester, find.byKey(const ValueKey('settings-backup-reminder')));
    expect(find.text('Son yedek 3 ay önce.'), findsOneWidget);
    await tester.tap(find.text('Yedek hatırlatması'));
    await tester.pumpAndSettle();
    expect(find.text('Son yedek 3 ay önce.'), findsNothing);
  });

  testWidgets('no note 89 days after a backup', (tester) async {
    tall(tester);
    prefs = MemoryBackupPrefsStore(
      BackupPrefs(lastFullBackup: testToday.addDays(-89)),
    );
    await start(tester);
    expect(find.byKey(const ValueKey('backup-note')), findsNothing);
  });

  testWidgets('English', (tester) async {
    tall(tester);
    prefs = MemoryBackupPrefsStore(
      BackupPrefs(lastFullBackup: testToday.addDays(-120)),
    );
    await start(tester, locale: const Locale('en', 'US'));
    expect(find.text('Last backup was 4 months ago.'), findsOneWidget);
  });
}
