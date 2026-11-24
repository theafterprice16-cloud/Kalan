import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/backup/backup_summary.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/data/backup/backup_collector.dart';
import 'package:kalan/data/backup/backup_restorer.dart';
import 'package:kalan/data/db/app_database.dart';

import '../helpers/backup_seed.dart';

/// [data] as JSON with the file's own numbers replaced by positions, so
/// two databases with different ids but the same rows and links compare
/// equal.
String withoutIds(BackupData data) {
  final json = data.toJson();
  final sources = json['sources']! as List<Object?>;
  final sourceIndex = <Object?, int>{};
  for (final (i, s) in sources.indexed) {
    final m = s! as Map<String, Object?>;
    sourceIndex[m['id']] = i;
    m['id'] = i;
  }
  for (final (i, p) in (json['plans']! as List<Object?>).indexed) {
    final m = p! as Map<String, Object?>;
    m['id'] = i;
    m['sourceId'] = sourceIndex[m['sourceId']];
    m['chargeSourceId'] = sourceIndex[m['chargeSourceId']];
  }
  for (final (i, r) in (json['recurringPayments']! as List<Object?>).indexed) {
    (r! as Map<String, Object?>)['id'] = i;
  }
  return jsonEncode(json);
}

/// Every row of every table, ids included: what "nothing changed" means.
Future<String> everything(AppDatabase db) async => jsonEncode([
  for (final rows in [
    await db.select(db.appSettings).get(),
    await db.select(db.sources).get(),
    await db.select(db.plans).get(),
    await db.select(db.payments).get(),
    await db.select(db.recurringPayments).get(),
    await db.select(db.recurringMarks).get(),
    await db.select(db.reminderSnoozes).get(),
  ])
    [for (final r in rows) r.toJson()],
]);

Future<int> maxPaymentId(AppDatabase db) async {
  final rows = await db.select(db.payments).get();
  return rows.map((r) => r.id).fold<int>(0, (a, b) => a > b ? a : b);
}

/// A different, smaller set of data: what the phone has before.
Future<void> seedOther(AppDatabase db) async {
  await db
      .into(db.appSettings)
      .insert(
        AppSettingsCompanion.insert(
          currencyCode: 'EUR',
          localeCode: const Value('tr'),
          payFrequency: PayFrequency.monthly,
          payDay: const Value(1),
          debugPro: const Value(true),
          reminderPromptShown: const Value(true),
        ),
      );
  final source = await db
      .into(db.sources)
      .insert(
        SourcesCompanion.insert(name: 'Afterpay', kind: SourceKind.provider),
      );
  for (var i = 0; i < 2; i++) {
    final plan = await db
        .into(db.plans)
        .insert(
          PlansCompanion.insert(
            sourceId: Value(source),
            kind: PlanKind.payIn4,
            installmentCount: 1,
            origin: PlanOrigin.manual,
          ),
        );
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            planId: plan,
            seq: 1,
            dueDay: LocalDate(2026, 12, 10 + i).epochDay,
            amountMinor: 5000,
          ),
        );
  }
  await db
      .into(db.reminderSnoozes)
      .insert(
        ReminderSnoozesCompanion.insert(
          kind: 1,
          fireDay: LocalDate(2026, 12, 10).epochDay,
          minuteOfDay: 1200,
          refs: 'p1',
        ),
      );
}

void main() {
  late AppDatabase source;
  late AppDatabase target;
  late BackupData backup;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    await seedEverything(source);
    backup = (await collectBackup(source))!;
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  group('round trip', () {
    for (final password in [null, 'Doğru parola']) {
      test(
        'everything comes back, links kept (${password == null ? 'plain' : 'encrypted'})',
        () async {
          final file = await writeBackup(
            backup,
            appVersion: '1.0.0+1',
            createdAt: DateTime.utc(2026, 11, 19),
            password: password,
            // Fast settings for the test; the format is the same.
            kdf: const Argon2idKdf(memoryKiB: 64, iterations: 1),
          );
          final read = await readBackup(file, password: password);
          await restoreBackup(target, read.data);
          final back = (await collectBackup(target))!;
          expect(withoutIds(back), withoutIds(backup));
          // Settings, holidays included, byte for byte: the holiday sync
          // finds nothing to move.
          final before = await source.select(source.appSettings).getSingle();
          final after = await target.select(target.appSettings).getSingle();
          expect(after.appliedHolidays, before.appliedHolidays);
          expect(after.holidayCountry, before.holidayCountry);
          expect(after.currencyCode, before.currencyCode);
        },
      );
    }

    test('the version 1 fixture goes into the database', () async {
      final read = await readBackup(
        File('test/fixtures/backup_v1.json').readAsStringSync(),
      );
      await restoreBackup(target, read.data);
      final back = (await collectBackup(target))!;
      expect(withoutIds(back), withoutIds(read.data));
      final summary = BackupSummary.of(back);
      expect(summary.plans, 4);
      expect(summary.recurring, 1);
    });
  });

  group('over existing data', () {
    setUp(() => seedOther(target));

    test(
      'the backup takes the place of everything; nothing is merged',
      () async {
        await restoreBackup(target, backup);
        final back = (await collectBackup(target))!;
        expect(withoutIds(back), withoutIds(backup));
        expect(back.settings.currency, 'TRY');
        expect(
          (await target.select(target.sources).get()).map((s) => s.name),
          isNot(contains('Afterpay')),
        );
      },
    );

    test(
      'this device keeps its language, debug Pro and permission prompt',
      () async {
        await restoreBackup(target, backup);
        final s = await target.select(target.appSettings).getSingle();
        expect(s.localeCode, 'tr');
        expect(s.debugPro, isTrue);
        expect(s.reminderPromptShown, isTrue);
      },
    );

    test('on an empty phone the device fields keep their defaults', () async {
      final empty = AppDatabase(NativeDatabase.memory());
      addTearDown(empty.close);
      await restoreBackup(empty, backup);
      final s = await empty.select(empty.appSettings).getSingle();
      expect(s.localeCode, isNull);
      expect(s.debugPro, isFalse);
      expect(s.reminderPromptShown, isFalse);
    });

    test('snoozes go with the payments they pointed at', () async {
      await restoreBackup(target, backup);
      expect(await target.select(target.reminderSnoozes).get(), isEmpty);
    });

    test('new ids never reuse old ones', () async {
      final oldMax = await maxPaymentId(target);
      final oldSources = await target.select(target.sources).get();
      final oldPlans = await target.select(target.plans).get();
      await restoreBackup(target, backup);
      final payments = await target.select(target.payments).get();
      expect(payments.every((p) => p.id > oldMax), isTrue);
      final sources = await target.select(target.sources).get();
      expect(
        sources.every((s) => oldSources.every((o) => s.id > o.id)),
        isTrue,
      );
      final plans = await target.select(target.plans).get();
      expect(plans.every((p) => oldPlans.every((o) => p.id > o.id)), isTrue);
    });

    test('a failure while writing leaves everything as it was', () async {
      final before = await everything(target);
      await expectLater(
        restoreBackup(
          target,
          backup,
          debugBeforeCommit: () async => throw StateError('forced'),
        ),
        throwsStateError,
      );
      expect(await everything(target), before);
    });

    test('a row the database refuses rolls everything back', () async {
      final before = await everything(target);
      // Past validation (a title over 80 characters): the database
      // refuses it halfway through the writing.
      final json = backup.toJson();
      final plans = json['plans']! as List<Object?>;
      (plans.last! as Map<String, Object?>)['title'] = 'x' * 81;
      final bad = BackupData.fromJson(jsonDecode(jsonEncode(json)));
      await expectLater(restoreBackup(target, bad), throwsA(anything));
      expect(await everything(target), before);
    });
  });

  test('the summary counts plans as the app lists them', () {
    final s = BackupSummary.of(backup);
    // Closed card plan and the all-paid plans are in the archive; the
    // plan on hold counts toward the free limit.
    expect(s.plans, backup.plans.length);
    expect(s.open + s.onHold + s.archived, s.plans);
    expect(s.onHold, 1);
    expect(s.cards, 1);
    expect(s.sources, 2);
    expect(s.recurring, 1);
    expect(s.openForLimit, s.open + 1);
  });
}
