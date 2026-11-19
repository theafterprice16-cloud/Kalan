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
import 'package:kalan/core/engine/amount_entry.dart';
import 'package:kalan/core/engine/pay_later.dart';
import 'package:kalan/core/engine/pay_period.dart';
import 'package:kalan/core/engine/payment_method.dart';
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

  test(
    'v7 -> current: plans and payments untouched, no "Pay later" yet',
    () async {
      final schema = await verifier.schemaAt(7);
      seedCommon(schema);
      schema.rawDatabase.execute(
        'INSERT INTO payments (plan_id, seq, due_day, amount_minor, paid_at) '
        'VALUES (1, 2, 20435, 2500, 1700000000)',
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      // The plans table is rebuilt (its source becomes optional): payments
      // must not cascade away.
      final payments = await db.select(db.payments).get();
      expect(payments.map((p) => (p.seq, p.dueDay, p.amountMinor)), [
        (1, 20405, 2500),
        (2, 20435, 2500),
      ]);
      final plan = await db.select(db.plans).getSingle();
      expect(plan.sourceId, 1);
      expect(plan.kind, PlanKind.payIn4);
      expect(plan.payLaterRule, equals(null));
      expect(plan.payLaterValue, equals(null));
      final settings = await db.select(db.appSettings).getSingle();
      expect(settings.lastPayLaterRule, equals(null));
      expect(settings.lastPayLaterValue, equals(null));
      // Foreign keys are on again and hold.
      final check = await db.customSelect('PRAGMA foreign_key_check').get();
      expect(check, isEmpty);
      await db.close();
    },
  );

  test(
    'v8 -> current: Pay in 4 every 14 days, monthly same day, dates kept',
    () async {
      final schema = await verifier.schemaAt(8);
      seedCommon(schema);
      schema.rawDatabase.execute(
        'INSERT INTO plans (id, source_id, kind, installment_count, origin) '
        "VALUES (2, 1, 'monthly', 3, 'template'), "
        "(3, 1, 'card', 3, 'template'), (4, NULL, 'payLater', 1, 'template')",
      );
      schema.rawDatabase.execute(
        'INSERT INTO payments (plan_id, seq, due_day, amount_minor) '
        'VALUES (2, 1, 20500, 1000), (2, 2, 20531, 1000)',
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final plans = await (db.select(
        db.plans,
      )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
      expect(plans.map((p) => (p.id, p.kind, p.intervalDays)), [
        (1, PlanKind.payIn4, 14),
        (2, PlanKind.monthly, null),
        (3, PlanKind.card, null),
        (4, PlanKind.payLater, null),
      ]);
      final payments = await (db.select(
        db.payments,
      )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
      expect(payments.map((p) => (p.planId, p.seq, p.dueDay, p.amountMinor)), [
        (1, 1, 20405, 2500),
        (2, 1, 20500, 1000),
        (2, 2, 20531, 1000),
      ]);
      await db.close();
    },
  );

  test(
    'v9 -> current: no amount entry remembered, settings and plans kept',
    () async {
      final schema = await verifier.schemaAt(9);
      seedCommon(
        schema,
        settingsExtra: ', last_pay_later_rule, last_pay_later_value',
        values: ", 'days', 45",
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final settings = await db.select(db.appSettings).getSingle();
      expect(settings.lastAmountEntry, equals(null));
      expect(settings.currencyCode, 'TRY');
      expect(settings.payDay, 15);
      expect(settings.lastPayLaterRule, PayLaterRuleKind.days);
      expect(settings.lastPayLaterValue, 45);
      final payments = await db.select(db.payments).get();
      expect(payments.map((p) => (p.seq, p.dueDay, p.amountMinor)), [
        (1, 20405, 2500),
      ]);
      await db.close();
    },
  );

  test(
    'v10 -> current: card plans automatic, others not set, nothing else moves',
    () async {
      final schema = await verifier.schemaAt(10);
      seedCommon(schema);
      schema.rawDatabase.execute(
        'INSERT INTO sources (id, name, kind, statement_day, due_day) '
        "VALUES (2, 'Bonus', 'card', 5, 15)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO plans (id, source_id, kind, installment_count, origin, '
        'reminders_enabled, reminder_lead_days, interval_days) '
        "VALUES (2, 1, 'monthly', 3, 'template', 1, 5, NULL), "
        "(3, 2, 'card', 3, 'template', 0, NULL, NULL), "
        "(4, NULL, 'payLater', 1, 'template', 1, NULL, NULL), "
        "(5, 1, 'manual', 2, 'manual', 1, NULL, 30)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO payments (plan_id, seq, due_day, amount_minor, paid_at) '
        'VALUES (3, 1, 20500, 1000, 1700000000), (3, 2, 20531, 1000, NULL)',
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final plans = await (db.select(
        db.plans,
      )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
      expect(plans.map((p) => (p.id, p.paymentMethod, p.chargeSourceId)), [
        (1, null, null),
        (2, null, null),
        (3, PaymentMethod.automatic, null),
        (4, null, null),
        (5, null, null),
      ]);
      // Reminder choices, sources and intervals are untouched.
      expect(
        plans.map(
          (p) => (
            p.sourceId,
            p.kind,
            p.remindersEnabled,
            p.reminderLeadDays,
            p.intervalDays,
          ),
        ),
        [
          (1, PlanKind.payIn4, true, null, null),
          (1, PlanKind.monthly, true, 5, null),
          (2, PlanKind.card, false, null, null),
          (null, PlanKind.payLater, true, null, null),
          (1, PlanKind.manual, true, null, 30),
        ],
      );
      final payments = await (db.select(
        db.payments,
      )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
      expect(
        payments.map(
          (p) => (p.planId, p.seq, p.dueDay, p.amountMinor, p.paidAt != null),
        ),
        [
          (1, 1, 20405, 2500, false),
          (3, 1, 20500, 1000, true),
          (3, 2, 20531, 1000, false),
        ],
      );
      final check = await db.customSelect('PRAGMA foreign_key_check').get();
      expect(check, isEmpty);
      await db.close();
    },
  );

  test(
    'the payment method is stored by name; a deleted source clears it',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final card = await db
          .into(db.sources)
          .insert(
            SourcesCompanion.insert(name: 'Bonus', kind: SourceKind.card),
          );
      final zip = await db
          .into(db.sources)
          .insert(
            SourcesCompanion.insert(name: 'Zip', kind: SourceKind.provider),
          );
      await db
          .into(db.plans)
          .insert(
            PlansCompanion.insert(
              sourceId: Value(zip),
              kind: PlanKind.payIn4,
              installmentCount: 4,
              origin: PlanOrigin.template,
              paymentMethod: const Value(PaymentMethod.automatic),
              chargeSourceId: Value(card),
            ),
          );
      final raw = await db
          .customSelect('SELECT payment_method FROM plans')
          .getSingle();
      expect(raw.read<String>('payment_method'), 'automatic');
      await (db.delete(db.sources)..where((s) => s.id.equals(card))).go();
      final plan = await db.select(db.plans).getSingle();
      expect(plan.chargeSourceId, equals(null));
      expect(plan.paymentMethod, PaymentMethod.automatic);
      await db.close();
    },
  );

  test('v11 -> current: payday summary on, settings and plans kept', () async {
    final schema = await verifier.schemaAt(11);
    seedCommon(
      schema,
      settingsExtra: ', reminders_enabled, reminder_minute, net_income_minor',
      values: ', 0, 600, 2075000',
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.paydaySummaryEnabled, isTrue);
    expect(settings.remindersEnabled, isFalse);
    expect(settings.reminderMinute, 600);
    expect(settings.netIncomeMinor, 2075000);
    expect(settings.payDay, 15);
    final payments = await db.select(db.payments).get();
    expect(payments.map((p) => (p.seq, p.dueDay, p.amountMinor)), [
      (1, 20405, 2500),
    ]);
    await db.close();
  });

  test('v12 -> current: statement reminder off, 2 days, cards kept', () async {
    final schema = await verifier.schemaAt(12);
    seedCommon(schema);
    schema.rawDatabase.execute(
      'INSERT INTO sources (id, name, kind, statement_day, due_day) '
      "VALUES (2, 'Maximum', 'card', 14, 24)",
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final sources = await (db.select(
      db.sources,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    expect(
      sources.map(
        (s) => (
          s.name,
          s.statementDay,
          s.dueDay,
          s.statementReminderEnabled,
          s.statementReminderDays,
        ),
      ),
      [('Klarna', null, null, false, 2), ('Maximum', 14, 24, false, 2)],
    );
    await db.close();
  });

  test('statement reminder days outside 1 and 2 are refused', () async {
    final db = AppDatabase(NativeDatabase.memory());
    Future<int> insert(int days) => db
        .into(db.sources)
        .insert(
          SourcesCompanion.insert(
            name: 'Card $days',
            kind: SourceKind.card,
            statementDay: const Value(14),
            dueDay: const Value(24),
            statementReminderDays: Value(days),
          ),
        );
    await insert(1);
    await insert(2);
    await expectLater(insert(3), throwsA(isA<SqliteException>()));
    await expectLater(insert(0), throwsA(isA<SqliteException>()));
    await db.close();
  });

  test('the amount entry is stored by name', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            currencyCode: 'TRY',
            payFrequency: PayFrequency.monthly,
            payDay: const Value(15),
            lastAmountEntry: const Value(AmountEntry.installment),
          ),
        );
    final raw = await db
        .customSelect('SELECT last_amount_entry FROM app_settings')
        .getSingle();
    expect(raw.read<String>('last_amount_entry'), 'installment');
    await db.close();
  });

  test('interval days outside 1-365 are refused', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.sources)
        .insert(
          SourcesCompanion.insert(name: 'Klarna', kind: SourceKind.provider),
        );
    PlansCompanion plan(int days) => PlansCompanion.insert(
      sourceId: const Value(1),
      kind: PlanKind.monthly,
      installmentCount: 3,
      origin: PlanOrigin.template,
      intervalDays: Value(days),
    );
    await db.into(db.plans).insert(plan(365));
    for (final days in [0, 366]) {
      await expectLater(
        db.into(db.plans).insert(plan(days)),
        throwsA(isA<SqliteException>()),
      );
    }
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
      sourceId: Value(sourceId),
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
            sourceId: Value(sourceId),
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
              sourceId: const Value(999),
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
