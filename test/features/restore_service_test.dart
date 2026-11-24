import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/providers.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/engine/engine.dart' show PayFrequency;
import 'package:kalan/core/theme/theme_mode.dart';
import 'package:kalan/data/backup/backup_collector.dart';
import 'package:kalan/data/backup/backup_restorer.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/features/export/backup_prefs.dart';
import 'package:kalan/features/lock/app_lock_store.dart';
import 'package:kalan/features/privacy/amounts_hidden.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:kalan/features/restore/restore_service.dart';
import 'package:kalan/features/restore/restore_undo.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../core/backup/backup_upgrade_test.dart'
    show fixtureEncrypted, fixturePassword, fixturePlain;
import '../data/backup_restorer_test.dart' show everything, seedOther;
import '../helpers/fake_notifications.dart';
import '../helpers/fake_store.dart';

final today = LocalDate(2026, 11, 23);

class FakePicker implements BackupFilePicker {
  XFile? file;
  bool fail = false;

  @override
  Future<XFile?> pick() async {
    if (fail) throw StateError('picker');
    return file;
  }
}

Uint8List bytesOf(String path) => File(path).readAsBytesSync();

/// A plain backup file around raw [data] (a valid checksum), for content
/// the app could never write.
Uint8List plainFile(Map<String, Object?> data, {String currency = 'TRY'}) {
  final sum = [
    for (final b
        in const DartSha256().hashSync(utf8.encode(jsonEncode(data))).bytes)
      b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return utf8.encode(
    jsonEncode({
      'format': 'kalan-backup',
      'formatVersion': 1,
      'appVersion': '1.0.0+1',
      'createdAt': '2026-11-19T07:30:05Z',
      'currency': currency,
      'encrypted': false,
      'dataSha256': sum,
      'data': data,
    }),
  );
}

Map<Object?, Object?> firstPayment(Map<String, Object?> data) =>
    (((data['plans']! as List).first as Map)['payments'] as List).first as Map;

Map<String, Object?> fixtureData() =>
    (jsonDecode(File(fixturePlain).readAsStringSync())
            as Map<String, Object?>)['data']!
        as Map<String, Object?>;

void main() {
  late AppDatabase db;
  late Directory dir;
  late Directory temp;
  late FakePicker picker;
  late MemoryBackupPrefsStore prefs;
  late FakeNotificationGateway notifications;
  late FakeStoreGateway store;
  late ProviderContainer c;
  late LocalDate now;

  ProviderContainer make({
    Directory? undoDir,
    List<Override> extra = const [],
    bool real = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...extra,
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith((ref) => now),
        clockProvider.overrideWithValue(
          () => DateTime(now.year, now.month, now.day, 12),
        ),
        undoDirectoryProvider.overrideWithValue(() async => undoDir ?? dir),
        backupFilePickerProvider.overrideWithValue(picker),
        backupPrefsStoreProvider.overrideWithValue(prefs),
        // On the spot (the isolate is tested on its own below).
        backupReaderProvider.overrideWithValue(readBackupRequest),
        // Real: in its own isolate, as in the app.
        if (!real)
          undoCopyWriterProvider.overrideWith(
            (ref) =>
                (data) => writeBackup(
                  data,
                  appVersion: '1.0.0+1',
                  createdAt: ref.read(clockProvider)(),
                ),
          ),
        pickedCopyDirectoryProvider.overrideWithValue(() async => temp),
        notificationGatewayProvider.overrideWithValue(notifications),
        reminderDebounceProvider.overrideWithValue(Duration.zero),
        storeGatewayProvider.overrideWithValue(store),
        proStatusStoreProvider.overrideWithValue(
          MemoryProStatusStore(ProStatus.notPro),
        ),
        amountsHiddenStoreProvider.overrideWithValue(
          MemoryAmountsHiddenStore(true),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('kalan-restore-test');
    temp = Directory.systemTemp.createTempSync('kalan-picked-test');
    picker = FakePicker();
    prefs = MemoryBackupPrefsStore();
    notifications = FakeNotificationGateway();
    store = FakeStoreGateway();
    now = today;
    c = make();
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
    temp.deleteSync(recursive: true);
  });

  RestoreService service() => c.read(restoreServiceProvider);

  Future<BackupContents> read(Uint8List bytes, {String? password}) =>
      service().read(bytes, password: password);

  Matcher fails(RestoreFailure f) =>
      throwsA(isA<RestoreException>().having((e) => e.failure, 'failure', f));

  Future<UndoCopy?> undo() => c.read(undoCopyStoreProvider).info();

  group('example 1: a new phone', () {
    test(
      'password, summary, restore: no copy, last backup, reminders',
      () async {
        // Keep the reminder sync alive, as the app does.
        c.listen(reminderSyncProvider, (_, _) {});
        final bytes = bytesOf(fixtureEncrypted);
        await expectLater(read(bytes), fails(RestoreFailure.passwordNeeded));
        final contents = await read(bytes, password: fixturePassword);
        expect(await service().hasData(), isFalse);
        final summary = await service().restore(contents);
        expect(summary.plans, 4);
        expect(summary.recurring, 1);
        expect(summary.cards, 1);
        expect(summary.sources, 2);
        expect((await collectBackup(db))!.plans, hasLength(4));
        // Nothing to copy on a new phone.
        expect(await undo(), isNull);
        expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
        // "Last backup" is the backup's day.
        expect(prefs.read().lastFullBackup, LocalDate(2026, 11, 19));
        // Reminders set up from the restored payments.
        await c.read(reminderSyncProvider).idle;
        expect(notifications.replaceCalls, greaterThan(0));
      },
    );
  });

  group('example 2 and 3: over data, and back', () {
    setUp(() async {
      await seedOther(db);
      await prefs.write(BackupPrefs(lastFullBackup: LocalDate(2026, 6, 1)));
      c.dispose();
      c = make();
    });

    test('a copy is kept first, then the backup replaces the data', () async {
      final before = (await collectBackup(db))!;
      expect(await service().hasData(), isTrue);
      final contents = await read(bytesOf(fixturePlain));
      await service().restore(contents);
      final after = (await collectBackup(db))!;
      expect(after.settings.currency, 'TRY');
      expect(after.plans, hasLength(4));
      final copy = await undo();
      expect(copy!.copiedOn, today);
      expect(copy.lastFullBackup, LocalDate(2026, 6, 1));
      // The copy is exactly the data from before.
      final copied = await readBackup(
        (await c.read(undoCopyStoreProvider).read())!,
      );
      expect(jsonEncode(copied.data.toJson()), jsonEncode(before.toJson()));
      expect(await c.read(undoCopyProvider.future), isNotNull);
      expect(prefs.read().lastFullBackup, LocalDate(2026, 11, 19));
    });

    test(
      'going back brings the old data; the restored one is the copy',
      () async {
        await service().restore(await read(bytesOf(fixturePlain)));
        final restored = (await collectBackup(db))!;
        now = today.addDays(10);
        c.invalidate(todayProvider);
        await service().goBack();
        final back = (await collectBackup(db))!;
        expect(back.settings.currency, 'EUR');
        expect(back.plans, hasLength(2));
        // "Last backup" as it was before the restore.
        expect(prefs.read().lastFullBackup, LocalDate(2026, 6, 1));
        // The data just replaced is the new copy, its 30 days start again.
        final copy = await undo();
        expect(copy!.copiedOn, today.addDays(10));
        expect(copy.lastFullBackup, LocalDate(2026, 11, 19));
        final copied = await readBackup(
          (await c.read(undoCopyStoreProvider).read())!,
        );
        expect(jsonEncode(copied.data.toJson()), jsonEncode(restored.toJson()));
        // And back once more: the restored data again.
        await service().goBack();
        expect((await collectBackup(db))!.settings.currency, 'TRY');
      },
    );

    test('one copy at a time', () async {
      await service().restore(await read(bytesOf(fixturePlain)));
      await service().restore(await read(bytesOf(fixturePlain)));
      final files = dir.listSync(recursive: true).whereType<File>().toList();
      expect(files, hasLength(1));
      // The second copy holds the first restore's data.
      final copied = await readBackup(files.single.readAsStringSync());
      expect(copied.data.settings.currency, 'TRY');
    });

    test(
      'this phone keeps its lock, hidden amounts, theme, language and Pro',
      () async {
        final lock = MemoryAppLockStore();
        final theme = MemoryThemeModeStore(ThemeMode.dark);
        c.dispose();
        c = make(
          extra: [
            appLockStoreProvider.overrideWithValue(lock),
            themeModeStoreProvider.overrideWithValue(theme),
          ],
        );
        final lockBefore = lock.read();
        await service().restore(await read(bytesOf(fixturePlain)));
        expect(lock.read().enabled, lockBefore.enabled);
        expect(theme.read(), ThemeMode.dark);
        expect(c.read(amountsHiddenProvider), isTrue);
        final s = await db.select(db.appSettings).getSingle();
        expect(s.localeCode, 'tr');
        expect(s.debugPro, isTrue);
        expect(c.read(proControllerProvider).status, ProStatus.notPro);
        // No store query on its own.
        expect(store.log, isNot(contains('restore')));
      },
    );
  });

  group('nothing changes when', () {
    late String before;

    setUp(() async {
      await seedOther(db);
      // A copy from an earlier restore, which must survive too.
      await service().restore(await read(bytesOf(fixturePlain)));
      before = await everything(db);
    });

    Future<void> expectUnchanged() async {
      expect(await everything(db), before);
      expect((await undo())!.copiedOn, today);
      final copied = await readBackup(
        (await c.read(undoCopyStoreProvider).read())!,
      );
      expect(copied.data.settings.currency, 'EUR');
    }

    test('example 4: the password is wrong', () async {
      final bytes = bytesOf(fixtureEncrypted);
      await expectLater(
        read(bytes, password: 'yanlış'),
        fails(RestoreFailure.wrongPassword),
      );
      await expectUnchanged();
    });

    test('example 5: a photo or a text file', () async {
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0xFF, 0xFE]);
      await expectLater(read(png), fails(RestoreFailure.notABackup));
      await expectLater(
        read(utf8.encode('{"format": "other"}')),
        fails(RestoreFailure.notABackup),
      );
      await expectUnchanged();
    });

    test('the file is from a newer Kalan', () async {
      final newer = utf8.encode(
        File(fixturePlain)
            .readAsStringSync()
            .replaceFirst('"formatVersion": 1', '"formatVersion": 9'),
      );
      await expectLater(read(newer), fails(RestoreFailure.newerVersion));
      await expectUnchanged();
    });

    test('a byte of the file was changed', () async {
      final text = File(fixtureEncrypted).readAsStringSync();
      final changed = text.replaceFirst('"ciphertext": "q', '"ciphertext": "r');
      expect(changed, isNot(text));
      await expectLater(
        read(utf8.encode(changed), password: fixturePassword),
        fails(RestoreFailure.wrongPassword),
      );
      final plain = File(fixturePlain)
          .readAsStringSync()
          .replaceFirst('"Mont"', '"Mant"');
      await expectLater(
        read(utf8.encode(plain)),
        fails(RestoreFailure.unreadable),
      );
      await expectUnchanged();
    });

    test('the file is larger than 50 MB (never read)', () async {
      picker.file = XFile.fromData(
        Uint8List(8),
        name: 'big.json',
        length: backupMaxBytes + 1,
      );
      await expectLater(service().pick(), fails(RestoreFailure.unreadable));
      await expectUnchanged();
    });

    test('the picker fails', () async {
      picker.fail = true;
      await expectLater(service().pick(), fails(RestoreFailure.unreadable));
      picker
        ..fail = false
        ..file = null;
      expect(await service().pick(), isNull);
    });

    for (final (name, change) in [
      (
        'a link points at nothing',
        (Map<String, Object?> d) =>
            ((d['plans']! as List).first as Map)['sourceId'] = 999,
      ),
      (
        'an unknown currency',
        (Map<String, Object?> d) => (d['settings']! as Map)['currency'] = 'XXX',
      ),
      (
        'an impossible date',
        (Map<String, Object?> d) => firstPayment(d)['dueDate'] = '2026-02-30',
      ),
      (
        'an amount of zero',
        (Map<String, Object?> d) => firstPayment(d)['amount'] = 0,
      ),
    ]) {
      test('validation: $name', () async {
        final data = fixtureData();
        change(data);
        final currency = (data['settings']! as Map)['currency']! as String;
        await expectLater(
          read(plainFile(data, currency: currency)),
          fails(RestoreFailure.unreadable),
        );
        await expectUnchanged();
      });
    }

    test('example 6: writing fails halfway (forced)', () async {
      c.dispose();
      c = make(
        extra: [
          restoreWriterProvider.overrideWithValue(
            (db, data) => restoreBackup(
              db,
              data,
              debugBeforeCommit: () async => throw StateError('forced'),
            ),
          ),
        ],
      );
      await expectLater(
        service().restore(await read(bytesOf(fixturePlain))),
        fails(RestoreFailure.unreadable),
      );
      await expectUnchanged();
      expect(await c.read(undoCopyStoreProvider).hasStaged(), isFalse);
    });

    test('data that does not validate is not written', () async {
      final good = await read(bytesOf(fixturePlain));
      // A title over 80 characters, past the reader's check.
      final json = good.data.toJson();
      ((json['plans']! as List).last as Map)['title'] = 'x' * 81;
      final bad = BackupContents(
        header: good.header,
        data: BackupData.fromJson(jsonDecode(jsonEncode(json))),
      );
      await expectLater(
        service().restore(bad),
        fails(RestoreFailure.unreadable),
      );
      await expectUnchanged();
      expect(
        dir.listSync(recursive: true).whereType<File>().map((f) => f.path),
        everyElement(endsWith('previous.json')),
      );
    });

    test('the copy cannot be saved: the restore does not start', () async {
      // The folder becomes a file: nothing can be written there.
      final blocked = File('${dir.path}/blocked')..writeAsStringSync('x');
      c.dispose();
      c = make(undoDir: Directory(blocked.path));
      await expectLater(
        service().restore(await read(bytesOf(fixturePlain))),
        fails(RestoreFailure.copyFailed),
      );
      expect(await everything(db), before);
    });
  });

  group('30 days', () {
    test('the rule: kept on day 29, gone on day 30', () {
      final day = LocalDate(2026, 11, 19);
      expect(undoCopyKept(copiedOn: day, today: day), isTrue);
      expect(undoCopyKept(copiedOn: day, today: day.addDays(29)), isTrue);
      expect(undoCopyKept(copiedOn: day, today: day.addDays(30)), isFalse);
      // A phone clock set back keeps it.
      expect(undoCopyKept(copiedOn: day, today: day.addDays(-3)), isTrue);
    });

    Future<void> startOn(LocalDate day) async {
      now = day;
      c.dispose();
      c = make();
      await c.read(undoTidyProvider.future);
    }

    test('deleted at the first start from the 30th day on', () async {
      await seedOther(db);
      await service().restore(await read(bytesOf(fixturePlain)));
      await startOn(today.addDays(29));
      expect(await c.read(undoCopyProvider.future), isNotNull);
      await startOn(today.addDays(30));
      expect(await c.read(undoCopyProvider.future), isNull);
      expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('no copy when there was no data', () async {
      await service().restore(await read(bytesOf(fixturePlain)));
      expect(await c.read(undoCopyProvider.future), isNull);
    });
  });

  group('a restore stopped halfway (the app was closed)', () {
    setUp(() => seedOther(db));

    Future<String> copyOfNow() async => UndoCopyStore.withDevice(
      await writeBackup(
        (await collectBackup(db))!,
        appVersion: '1.0.0+1',
        createdAt: DateTime(2026, 11, 23, 12),
      ),
      null,
      sequences: await idSequences(db),
    );

    Future<void> restart() async {
      c.dispose();
      c = make();
      await c.read(undoTidyProvider.future);
    }

    test('the restore never happened: the staged copy goes, the older '
        'copy stays', () async {
      final store = c.read(undoCopyStoreProvider);
      await store.stage(await copyOfNow());
      await store.commit();
      final older = await store.read();
      // A later restore staged its copy, then its transaction rolled back
      // (no new ids); meanwhile the holiday sync changed a setting.
      await store.stage(await copyOfNow());
      await db
          .update(db.appSettings)
          .write(const AppSettingsCompanion(holidayCountry: Value('TR')));
      await restart();
      expect(await c.read(undoCopyStoreProvider).read(), older);
      expect(await c.read(undoCopyStoreProvider).hasStaged(), isFalse);
    });

    test(
      'the restore went through: the staged copy becomes the copy',
      () async {
        final store = c.read(undoCopyStoreProvider);
        final staged = await copyOfNow();
        await store.stage(staged);
        // The transaction wrote new rows (ids count up), then the app
        // stopped before the rename.
        await restoreBackup(db, (await read(bytesOf(fixturePlain))).data);
        await restart();
        expect(await c.read(undoCopyStoreProvider).read(), staged);
      },
    );

    test('a staged copy is never written over by the next restore', () async {
      // This run's tidy is done; then a restore's rename failed and its
      // staged copy stayed: the next restore does not start.
      await c.read(undoTidyProvider.future);
      final store = c.read(undoCopyStoreProvider);
      final staged = await copyOfNow();
      await store.stage(staged);
      final before = await everything(db);
      await expectLater(
        service().restore(await read(bytesOf(fixturePlain))),
        fails(RestoreFailure.copyFailed),
      );
      expect(await everything(db), before);
      expect(
        File('${dir.path}/kalan-restore/previous.next.json').readAsStringSync(),
        staged,
      );
    });

    test('a copy the system cannot read is left alone', () async {
      // previous.json is a folder: reading it fails.
      Directory('${dir.path}/kalan-restore/previous.json')
          .createSync(recursive: true);
      await restart();
      expect(
        Directory('${dir.path}/kalan-restore/previous.json').existsSync(),
        isTrue,
      );
      expect(await c.read(undoCopyProvider.future), isNull);
    });
  });

  group('the safety copy must be able to come back', () {
    test(
      'weekly pay without a known payday: the restore does not start',
      () async {
        await db
            .into(db.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                currencyCode: 'EUR',
                payFrequency: PayFrequency.weekly,
              ),
            );
        final before = await everything(db);
        await expectLater(
          service().restore(await read(bytesOf(fixturePlain))),
          fails(RestoreFailure.copyFailed),
        );
        expect(await everything(db), before);
        expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
      },
    );

    test(
      'the real writer, in its own isolate, inside the transaction',
      () async {
        await seedOther(db);
        c.dispose();
        c = make(real: true);
        await service().restore(await read(bytesOf(fixturePlain)));
        expect((await collectBackup(db))!.settings.currency, 'TRY');
        final copy = await readBackup(
          (await c.read(undoCopyStoreProvider).read())!,
        );
        expect(copy.data.settings.currency, 'EUR');
        await service().goBack();
        expect((await collectBackup(db))!.settings.currency, 'EUR');
      },
    );
  });

  group('the picker', () {
    test('its copy in the temporary folder is deleted, nothing else', () async {
      final copy = File('${temp.path}/picked/backup.json')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytesOf(fixturePlain));
      picker.file = XFile(copy.path);
      expect(await service().pick(), isNotNull);
      expect(copy.existsSync(), isFalse);
      // A file elsewhere (the user's own) stays.
      final own = File('${dir.path}/own.json')
        ..writeAsBytesSync(bytesOf(fixturePlain));
      picker.file = XFile(own.path);
      expect(await service().pick(), isNotNull);
      expect(own.existsSync(), isTrue);
    });
  });

  test('reading runs away from the UI isolate', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    var ticks = 0;
    final timer = Timer.periodic(
      const Duration(milliseconds: 5),
      (_) => ticks++,
    );
    final watch = Stopwatch()..start();
    final read = await container.read(backupReaderProvider)(
      BackupReadRequest(bytesOf(fixtureEncrypted), password: fixturePassword),
    );
    timer.cancel();
    expect(read.data.plans, hasLength(4));
    expect(watch.elapsedMilliseconds, greaterThan(50));
    // The UI isolate kept running its timers the whole time.
    expect(ticks, greaterThan(watch.elapsedMilliseconds ~/ 5 ~/ 3));
  });
}
