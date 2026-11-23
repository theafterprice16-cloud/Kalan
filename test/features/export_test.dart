import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/data/backup/backup_collector.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/export/backup_prefs.dart';
import 'package:kalan/features/export/export_service.dart';
import 'package:kalan/features/export/export_texts.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/backup_seed.dart';
import '../helpers/fake_share.dart';

final tr = lookupAppLocalizations(const Locale('tr'));
final en = lookupAppLocalizations(const Locale('en'));
final today = LocalDate(2026, 11, 19);

void main() {
  group('export service', () {
    late AppDatabase db;
    late Directory temp;
    late FakeShare share;
    late MemoryBackupPrefsStore prefs;
    late ProviderContainer container;

    ProviderContainer make({bool hidden = false}) {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(today),
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 11, 19, 7, 30),
          ),
          exportTempDirectoryProvider.overrideWithValue(() async => temp),
          fileShareGatewayProvider.overrideWithValue(share),
          backupPrefsStoreProvider.overrideWithValue(prefs),
          amountsHiddenStoreProvider.overrideWithValue(
            MemoryAmountsHiddenStore(hidden),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await seedEverything(db);
      temp = Directory.systemTemp.createTempSync('kalan-export-test');
      share = FakeShare();
      prefs = MemoryBackupPrefsStore();
      container = make();
    });
    tearDown(() async {
      await db.close();
      temp.deleteSync(recursive: true);
    });

    Future<ShareOutcome> export(
      ExportKind kind, {
      String? password,
      AppLocalizations? l10n,
    }) => container
        .read(exportServiceProvider)
        .export(kind: kind, l10n: l10n ?? tr, password: password);

    List<String> leftovers() => [
      for (final f in temp.listSync(recursive: true))
        if (f is File) f.path,
    ];

    test('spreadsheet: named, shared, then deleted; no backup date', () async {
      expect(await export(ExportKind.spreadsheet), ShareOutcome.shared);
      final file = share.shared.single;
      expect(file.name, 'kalan-tablo-2026-11-19.csv');
      expect(file.mimeType, 'text/csv');
      expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(file.bytes);
      expect(text, contains('Ad,Tür,Durum,Kaynak'));
      expect(text, contains("'=TOPLAM"));
      expect(leftovers(), isEmpty);
      expect(container.read(backupPrefsProvider).lastFullBackup, isNull);
    });

    for (final (outcome, saved) in [
      (ShareOutcome.shared, true),
      (ShareOutcome.unknown, true),
      (ShareOutcome.dismissed, false),
    ]) {
      test('full backup, ${outcome.name}: last backup '
          '${saved ? 'saved' : 'unchanged'}', () async {
        share.outcome = outcome;
        await export(ExportKind.backup);
        expect(share.shared.single.name, 'kalan-yedek-2026-11-19.json');
        expect(share.shared.single.mimeType, 'application/json');
        expect(leftovers(), isEmpty);
        expect(
          container.read(backupPrefsProvider).lastFullBackup,
          saved ? today : null,
        );
        expect(prefs.read().lastFullBackup, saved ? today : null);
      });
    }

    test('a failed share deletes the file and saves nothing', () async {
      share.fail = true;
      await expectLater(export(ExportKind.backup), throwsA(isA<Object>()));
      expect(share.shared, hasLength(1));
      expect(leftovers(), isEmpty);
      expect(container.read(backupPrefsProvider).lastFullBackup, isNull);
    });

    test('earlier leftovers and the share plugin copy are cleared', () async {
      File('${temp.path}/kalan-export/kalan-yedek-2026-01-01.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      File('${temp.path}/share_plus/kalan-tablo-2026-01-01.csv')
        ..createSync(recursive: true)
        ..writeAsStringSync('x');
      final other = File('${temp.path}/share_plus/other.png')
        ..writeAsStringSync('x');
      await export(ExportKind.spreadsheet);
      expect(leftovers(), [other.path]);
    });

    test('encrypted with the password, readable only with it', () async {
      await export(ExportKind.backup, password: 'parola');
      final text = utf8.decode(share.shared.single.bytes);
      expect(text, isNot(contains('parola')));
      expect(text, isNot(contains('Kira')));
      final back = await readBackup(text, password: 'parola');
      expect(back.data.plans, hasLength(4));
      expect(back.header.appVersion, '1.0.0+1');
      expect(back.header.createdAt, DateTime.utc(2026, 11, 19, 7, 30));
      expect(leftovers(), isEmpty);
    });

    test('"Hide amounts" on: the files hold the real amounts', () async {
      container = make(hidden: true);
      await export(ExportKind.backup);
      await export(ExportKind.spreadsheet);
      expect(
        utf8.decode(share.shared.first.bytes),
        contains('"amount": 333334'),
      );
      expect(utf8.decode(share.shared.last.bytes), contains(',3333.34,'));
    });

    test('English names and headers', () async {
      await export(ExportKind.spreadsheet, l10n: en);
      await export(ExportKind.backup, l10n: en);
      expect(share.shared.first.name, 'kalan-spreadsheet-2026-11-19.csv');
      expect(share.shared.last.name, 'kalan-backup-2026-11-19.json');
      expect(
        utf8.decode(share.shared.first.bytes),
        startsWith(
          '﻿Name,Type,Status,Source,Payment no.,Due date,Amount,'
          'Extra fee,Fee per payment,Paid,Paid on,Currency\r\n',
        ),
      );
    });

    test('encryption runs away from the UI isolate', () async {
      final data = (await collectBackup(db))!;
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 5),
        (_) => ticks++,
      );
      final watch = Stopwatch()..start();
      final text = await container.read(backupWriterProvider)(
        BackupWriteRequest(
          data: data,
          createdAt: DateTime.utc(2026, 11, 19),
          password: 'p',
        ),
      );
      timer.cancel();
      expect(jsonDecode(text), containsPair('encrypted', true));
      expect(watch.elapsedMilliseconds, greaterThan(50));
      // The UI isolate kept running its timers the whole time.
      expect(ticks, greaterThan(watch.elapsedMilliseconds ~/ 5 ~/ 3));
    });
  });

  test('file names are ASCII, dated and start with "kalan-"', () {
    expect(
      exportFileName(tr, ExportKind.backup, today),
      'kalan-yedek-2026-11-19.json',
    );
    expect(
      exportFileName(tr, ExportKind.spreadsheet, today),
      'kalan-tablo-2026-11-19.csv',
    );
    for (final code in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(code);
      for (final kind in ExportKind.values) {
        expect(
          exportFileName(l10n, kind, today),
          matches(
            RegExp(r'^kalan-[a-z0-9-]*2026-11-19[a-z0-9-]*\.(json|csv)$'),
          ),
          reason: '$code',
        );
      }
    }
  });

  test('spreadsheet words in Turkish', () {
    final words = ExportTexts(tr);
    expect(words.headers, [
      'Ad',
      'Tür',
      'Durum',
      'Kaynak',
      'Ödeme sırası',
      'Son ödeme günü',
      'Tutar',
      'Ek ücret',
      'Taksit başı ücret',
      'Ödendi',
      'Ödeme günü',
      'Para birimi',
    ]);
    expect(words.recurringKind, 'Sabit ödeme');
  });
}
