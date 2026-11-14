// Schema checks for AppDatabase.
//
// When schemaVersion grows:
// 1. bump AppDatabase.schemaVersion and run
//    `dart run drift_dev make-migrations` (exports the new schema and
//    regenerates the helpers in generated/),
// 2. add the step in AppDatabase.migration,
// 3. add data-preserving checks below for the new step.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/plan_draft.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/reminders/reminder_models.dart' show ReminderRepeat;
import 'package:kalan/data/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('latest exported schema matches schemaVersion', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(GeneratedHelper.versions.last, db.schemaVersion);
    await db.close();
  });

  test('a fresh install creates the expected schema', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.validateDatabaseSchema();
    await db.close();
  });

  for (final from in GeneratedHelper.versions) {
    test('upgrade from v$from to current validates', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      await db.close();
    });
  }

  for (final code in ['TRY', 'USD', 'GBP', 'EUR']) {
    test('v1 settings with $code read back unchanged', () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        'INSERT INTO app_settings (id, currency_code, pay_frequency, pay_day, '
        'net_income_minor) VALUES (1, ?, ?, 15, 123456)',
        [code, 'monthly'],
      );
      final db = AppDatabase(schema.newConnection());
      final row = await db.select(db.appSettings).getSingle();
      expect(row.currencyCode, code);
      expect(Currency.fromCode(row.currencyCode).code, code);
      expect(row.netIncomeMinor, 123456);
      await db.close();
    });
  }

  /// Plan, payment, recurring payment and settings rows any version has.
  void seedCommon(
    InitializedSchema schema, {
    String settingsExtra = '',
    String values = '',
  }) {
    schema.rawDatabase.execute(
      'INSERT INTO app_settings (id, currency_code, pay_frequency, pay_day'
      '$settingsExtra) VALUES (1, \'TRY\', \'monthly\', 15$values)',
    );
    schema.rawDatabase.execute(
      "INSERT INTO sources (id, name, kind) VALUES (1, 'Klarna', 'provider')",
    );
    schema.rawDatabase.execute(
      'INSERT INTO plans (id, source_id, kind, installment_count, origin) '
      "VALUES (1, 1, 'payIn4', 4, 'template')",
    );
    schema.rawDatabase.execute(
      'INSERT INTO payments (plan_id, seq, due_day, amount_minor) '
      'VALUES (1, 1, 20405, 2500)',
    );
    schema.rawDatabase.execute(
      'INSERT INTO recurring_payments (id, name, amount_minor, recurrence, '
      "start_day) VALUES (1, 'Kira', 100, 'monthly', 20400)",
    );
  }

  Future<Map<String, Object?>> row(AppDatabase db, String sql) async =>
      (await db.customSelect(sql).getSingle()).data;

  test(
    'v1 -> current: data kept, reminder defaults, plans "General"',
    () async {
      final schema = await verifier.schemaAt(1);
      seedCommon(schema);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);

      final s = await row(
        db,
        'SELECT currency_code, reminders_enabled, reminder_lead_days, '
        'reminder_minute, hide_amounts_in_notifications, reminder_prompt_shown '
        'FROM app_settings',
      );
      expect(s, {
        'currency_code': 'TRY',
        'reminders_enabled': 1,
        'reminder_lead_days': 2,
        'reminder_minute': 540,
        'hide_amounts_in_notifications': 0,
        'reminder_prompt_shown': 0,
      });
      for (final table in ['plans', 'recurring_payments']) {
        expect(
          await row(
            db,
            'SELECT reminders_enabled, reminder_lead_days FROM $table',
          ),
          {'reminders_enabled': 1, 'reminder_lead_days': null},
          reason: table,
        );
      }
      expect(await row(db, 'SELECT amount_minor FROM payments'), {
        'amount_minor': 2500,
      });
      await db.close();
    },
  );

  test('v2 -> current: choices kept, offsets become "2 days"', () async {
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    seedCommon(
      schema,
      settingsExtra:
          ', reminders_enabled, remind_days7, remind_days3, remind_days1, '
          'remind_same_day, reminder_minute, hide_amounts_in_notifications, '
          'reminder_prompt_shown',
      values: ', 0, 1, 1, 0, 1, 600, 1, 1',
    );
    raw.execute('UPDATE plans SET reminders_enabled = 0 WHERE id = 1');
    raw.execute(
      'INSERT INTO plans (id, source_id, kind, installment_count, origin) '
      "VALUES (2, 1, 'payIn4', 4, 'template')",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final s = await row(
      db,
      'SELECT reminders_enabled, reminder_lead_days, reminder_minute, '
      'hide_amounts_in_notifications, reminder_prompt_shown FROM app_settings',
    );
    expect(s, {
      'reminders_enabled': 0,
      'reminder_lead_days': 2,
      'reminder_minute': 600,
      'hide_amounts_in_notifications': 1,
      'reminder_prompt_shown': 1,
    });
    final plans = await db
        .customSelect(
          'SELECT id, reminders_enabled, reminder_lead_days FROM plans '
          'ORDER BY id',
        )
        .get();
    expect(plans.map((r) => r.data), [
      {'id': 1, 'reminders_enabled': 0, 'reminder_lead_days': null}, // Off
      {'id': 2, 'reminders_enabled': 1, 'reminder_lead_days': null}, // General
    ]);
    await db.close();
  });

  test('v3 -> current: payments unchanged, none paid before Kalan', () async {
    final schema = await verifier.schemaAt(3);
    seedCommon(schema);
    schema.rawDatabase.execute(
      'INSERT INTO payments (plan_id, seq, due_day, amount_minor, paid_at) '
      'VALUES (1, 2, 20435, 2500, 1700000000)',
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final rows = await db
        .customSelect(
          'SELECT seq, due_day, amount_minor, paid_at, paid_before_kalan '
          'FROM payments ORDER BY seq',
        )
        .get();
    expect(rows.map((r) => r.data), [
      {
        'seq': 1,
        'due_day': 20405,
        'amount_minor': 2500,
        'paid_at': null,
        'paid_before_kalan': 0,
      },
      {
        'seq': 2,
        'due_day': 20435,
        'amount_minor': 2500,
        'paid_at': 1700000000,
        'paid_before_kalan': 0,
      },
    ]);
    await db.close();
  });

  test(
    'v4 -> current: no paid-on day, payments stay where they were',
    () async {
      final schema = await verifier.schemaAt(4);
      seedCommon(schema);
      schema.rawDatabase.execute(
        'INSERT INTO payments (plan_id, seq, due_day, amount_minor, paid_at, '
        'paid_before_kalan) VALUES (1, 2, 20435, 2500, 1700000000, 1)',
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final rows = await db
          .customSelect(
            'SELECT seq, due_day, paid_at, paid_before_kalan, paid_on_day '
            'FROM payments ORDER BY seq',
          )
          .get();
      expect(rows.map((r) => r.data), [
        {
          'seq': 1,
          'due_day': 20405,
          'paid_at': null,
          'paid_before_kalan': 0,
          'paid_on_day': null,
        },
        {
          'seq': 2,
          'due_day': 20435,
          'paid_at': 1700000000,
          'paid_before_kalan': 1,
          'paid_on_day': null,
        },
      ]);
      await db.close();
    },
  );

  test('v5 -> current: no snoozes, payments and marks unchanged', () async {
    final schema = await verifier.schemaAt(5);
    seedCommon(schema);
    schema.rawDatabase.execute(
      'INSERT INTO recurring_marks (recurring_id, occurrence_day, paid_at) '
      'VALUES (1, 20400, 1700000000)',
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.reminderSnoozes).get(), isEmpty);
    final payment = await db.select(db.payments).getSingle();
    expect(payment.dueDay, 20405);
    expect(payment.paidAt, equals(null));
    final mark = await db.select(db.recurringMarks).getSingle();
    expect(mark.occurrenceDay, 20400);
    await db.close();
  });

  test('v6 -> current: repeat reminders off for everyone', () async {
    final schema = await verifier.schemaAt(6);
    seedCommon(schema);
    schema.rawDatabase.execute(
      'INSERT INTO reminder_snoozes (kind, fire_day, minute_of_day, refs) '
      "VALUES (1, 20406, 1200, 'p1')",
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.repeatMode, ReminderRepeat.off);
    final plan = await db.select(db.plans).getSingle();
    expect(plan.repeatMode, equals(null));
    final rent = await db.select(db.recurringPayments).getSingle();
    expect(rent.repeatMode, equals(null));
    final snooze = await db.select(db.reminderSnoozes).getSingle();
    expect(snooze.refs, 'p1');
    expect(snooze.fireDay, 20406);
    expect(snooze.skipsDay, isFalse);
    // Overdue reminders can be snoozed now.
    await db
        .into(db.reminderSnoozes)
        .insert(
          ReminderSnoozesCompanion.insert(
            kind: 2,
            fireDay: 20407,
            minuteOfDay: 540,
            refs: 'p1',
            skipsDay: const Value(true),
          ),
        );
    expect(await db.select(db.reminderSnoozes).get(), hasLength(2));
    await db.close();
  });

  test('the same snooze twice is stored once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final entry = ReminderSnoozesCompanion.insert(
      kind: 1,
      fireDay: 20406,
      minuteOfDay: 1200,
      refs: 'p1,p2',
    );
    await db.into(db.reminderSnoozes).insert(entry);
    await db
        .into(db.reminderSnoozes)
        .insert(entry, mode: InsertMode.insertOrIgnore);
    expect(await db.select(db.reminderSnoozes).get(), hasLength(1));
    await expectLater(
      db
          .into(db.reminderSnoozes)
          .insert(
            ReminderSnoozesCompanion.insert(
              kind: 3,
              fireDay: 20406,
              minuteOfDay: 540,
              refs: 'p1',
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
    await db.close();
  });

  test('per-plan days outside 1, 2, 3, 5, 7 are refused', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final sourceId = await db
        .into(db.sources)
        .insert(
          SourcesCompanion.insert(name: 'Klarna', kind: SourceKind.provider),
        );
    PlansCompanion plan(int? days) => PlansCompanion.insert(
      sourceId: sourceId,
      kind: PlanKind.payIn4,
      installmentCount: 4,
      origin: PlanOrigin.template,
      reminderLeadDays: Value(days),
    );
    await db.into(db.plans).insert(plan(5));
    await db.into(db.plans).insert(plan(null));
    await expectLater(
      db.into(db.plans).insert(plan(4)),
      throwsA(isA<SqliteException>()),
    );
    await db.close();
  });

  test('foreign keys are enforced and payments cascade', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final sourceId = await db
        .into(db.sources)
        .insert(
          SourcesCompanion.insert(name: 'Klarna', kind: SourceKind.provider),
        );
    final planId = await db
        .into(db.plans)
        .insert(
          PlansCompanion.insert(
            sourceId: sourceId,
            kind: PlanKind.payIn4,
            installmentCount: 4,
            origin: PlanOrigin.template,
          ),
        );
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            planId: planId,
            seq: 1,
            dueDay: 20000,
            amountMinor: 100,
          ),
        );
    await expectLater(
      db
          .into(db.plans)
          .insert(
            PlansCompanion.insert(
              sourceId: 999,
              kind: PlanKind.monthly,
              installmentCount: 1,
              origin: PlanOrigin.manual,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
    await (db.delete(db.plans)..where((p) => p.id.equals(planId))).go();
    expect(await db.select(db.payments).get(), isEmpty);
    await db.close();
  });
}
