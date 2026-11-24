import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app_version.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/backup/backup_json.dart';
import 'package:kalan/core/backup/backup_upgrade.dart';
import 'package:kalan/core/engine/engine.dart';

/// Real version 1 files, written by Roadmap 29's code (main at 525ece2)
/// from test/helpers/backup_seed.dart and kept as they are for good:
/// every later Kalan must still read them (Roadmap 30, decision 10).
/// Never regenerate them; a new format version adds its own files.
const fixturePlain = 'test/fixtures/backup_v1.json';
const fixtureEncrypted = 'test/fixtures/backup_v1_encrypted.json';

/// The fixture's password (a test value, not anyone's password).
const fixturePassword = 'Pelin-şifre 1';

String fixture(String path) => File(path).readAsStringSync();

/// What the version 1 fixtures hold, field by field where it matters.
void expectFixtureContent(BackupContents read) {
  expect(read.header.formatVersion, 1);
  expect(read.header.createdAt, DateTime.utc(2026, 11, 19, 7, 30, 5));
  expect(read.header.currency, 'TRY');
  final d = read.data;
  expect(d.settings.currency, 'TRY');
  expect(d.settings.payFrequency, PayFrequency.biweekly);
  expect(d.settings.netIncome, 4500000);
  expect(d.settings.appliedHolidays?.country, 'TR');
  expect(d.sources.map((s) => s.kind), ['card', 'account', 'provider']);
  expect(d.plans.map((p) => p.status), [
    PlanStatus.closed,
    PlanStatus.open,
    PlanStatus.onHold,
    PlanStatus.open,
  ]);
  final card = d.plans.first;
  expect(card.title, '=TOPLAM');
  expect(card.sourceId, d.sources[0].id);
  expect(card.chargeSourceId, d.sources[1].id);
  expect(card.payments.map((p) => p.seq), [2, 3]);
  expect(card.payments.first.extraFeeNote, 'Gecikme, "faiz"');
  expect(d.plans[1].sourceId, isNull);
  expect(d.plans[1].payments.single.paidBeforeKalan, isTrue);
  expect(d.recurringPayments.single.paidOccurrences, isNotEmpty);
}

void main() {
  group('version 1 fixtures', () {
    test('the plain file loads', () async {
      expectFixtureContent(await readBackup(fixture(fixturePlain)));
    });

    test('the encrypted file loads with its password', () async {
      final read = await readBackup(
        fixture(fixtureEncrypted),
        password: fixturePassword,
      );
      expectFixtureContent(read);
      // The same content as the plain file.
      final plain = await readBackup(fixture(fixturePlain));
      expect(jsonEncode(read.data.toJson()), jsonEncode(plain.data.toJson()));
    });

    test('they are real version 1 files from this app', () {
      for (final path in [fixturePlain, fixtureEncrypted]) {
        final header = readBackupHeader(fixture(path));
        expect(header.formatVersion, 1);
        expect(header.appVersion, appVersion);
      }
    });
  });

  group('upgrade chain', () {
    // A made-up version 2 that renames a field, to try the chain on.
    Map<String, Object?> renameIncome(Map<String, Object?> data) {
      final settings = data['settings']! as Map<String, Object?>;
      settings['takeHome'] = settings.remove('netIncome');
      return data;
    }

    Map<String, Object?> back(Map<String, Object?> data) {
      final settings = data['settings']! as Map<String, Object?>;
      settings['netIncome'] = settings.remove('takeHome');
      return data;
    }

    test('no steps today: version 1 is the current version', () {
      expect(backupFormatVersion, 1);
      expect(backupUpgradeSteps, isEmpty);
      final data = {'a': 1};
      expect(upgradeBackupContent(data, from: 1, to: 1), data);
    });

    test('runs every step in order, on a copy', () {
      final data = <String, Object?>{
        'settings': <String, Object?>{'netIncome': 5, 'other': true},
      };
      final out = upgradeBackupContent(
        data,
        from: 1,
        to: 3,
        steps: {1: renameIncome, 2: back},
      );
      expect(out, {
        'settings': {'netIncome': 5, 'other': true},
      });
      final once = upgradeBackupContent(
        data,
        from: 1,
        to: 2,
        steps: {1: renameIncome},
      );
      expect(once, {
        'settings': {'takeHome': 5, 'other': true},
      });
      // The input is left as it was.
      expect(data, {
        'settings': {'netIncome': 5, 'other': true},
      });
    });

    test('a missing step or a bad version reads as damage', () {
      expect(
        () => upgradeBackupContent(const <String, Object?>{}, from: 1, to: 2),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => upgradeBackupContent(const <String, Object?>{}, from: 0, to: 1),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => upgradeBackupContent(const <String, Object?>{}, from: 3, to: 2),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => upgradeBackupContent(const [1], from: 1, to: 1),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test(
      'a newer app reads the version 1 fixtures through its steps',
      () async {
        // As if this were version 3: the v1 files go through both steps,
        // the encrypted one still opens (sealed with its own version).
        for (final (path, password) in [
          (fixturePlain, null),
          (fixtureEncrypted, fixturePassword),
        ]) {
          final read = await readBackup(
            fixture(path),
            password: password,
            currentVersion: 3,
            steps: {1: renameIncome, 2: back},
          );
          expectFixtureContent(read);
        }
      },
    );

    test('a broken step stops the read: nothing comes out', () async {
      // Drops a required field.
      Map<String, Object?> broken(Map<String, Object?> data) =>
          data..remove('plans');
      await expectLater(
        readBackup(
          fixture(fixturePlain),
          currentVersion: 2,
          steps: {1: broken},
        ),
        throwsA(
          isA<BackupReadException>().having(
            (e) => e.error,
            'error',
            BackupReadError.damaged,
          ),
        ),
      );
    });

    test('a newer version than the app is refused', () async {
      final newer = fixture(fixturePlain)
          .replaceFirst('"formatVersion": 1', '"formatVersion": 2');
      await expectLater(
        readBackup(newer),
        throwsA(
          isA<BackupReadException>().having(
            (e) => e.error,
            'error',
            BackupReadError.newerVersion,
          ),
        ),
      );
    });
  });

  group('bytes as picked', () {
    Matcher fails(BackupReadError error) => throwsA(
      isA<BackupReadException>().having((e) => e.error, 'error', error),
    );

    test('a backup file reads', () async {
      expectFixtureContent(
        await readBackupBytes(File(fixturePlain).readAsBytesSync()),
      );
    });

    test('a photo is not a backup', () async {
      // The start of a PNG file: not UTF-8 text.
      final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFF, 0x00];
      await expectLater(
        readBackupBytes(png),
        fails(BackupReadError.notABackup),
      );
      await expectLater(
        readBackupBytes(utf8.encode('Merhaba')),
        fails(BackupReadError.notABackup),
      );
    });

    test('more than 50 MB is never parsed', () async {
      expect(backupMaxBytes, 50 * 1024 * 1024);
      final big = List<int>.filled(backupMaxBytes + 1, 0x20);
      await expectLater(readBackupBytes(big), fails(BackupReadError.damaged));
    });
  });

  test('BackupData of the fixture writes and reads back the same', () async {
    final d = (await readBackup(fixture(fixturePlain))).data;
    final again = BackupData.fromJson(jsonDecode(jsonEncode(d.toJson())))
      ..validate();
    expect(jsonEncode(again.toJson()), jsonEncode(d.toJson()));
  });
}
