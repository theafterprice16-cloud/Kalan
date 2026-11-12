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
