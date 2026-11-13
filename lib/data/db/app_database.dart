import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/engine/pay_period.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/recurring.dart';
import 'app_database.steps.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Sources,
    Plans,
    Payments,
    RecurringPayments,
    RecurringMarks,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  static QueryExecutor _openDefault() => driftDatabase(name: 'kalan');

  /// Bump together with `dart run drift_dev make-migrations` and add a step.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: reminders (plan switches and reminder settings).
      from1To2: (m, schema) async {
        await m.addColumn(schema.plans, schema.plans.remindersEnabled);
        await m.addColumn(
          schema.recurringPayments,
          schema.recurringPayments.remindersEnabled,
        );
        final s = schema.appSettings;
        for (final column in [
          s.remindersEnabled,
          s.remindDays7,
          s.remindDays3,
          s.remindDays1,
          s.remindSameDay,
          s.reminderMinute,
          s.hideAmountsInNotifications,
          s.reminderPromptShown,
        ]) {
          await m.addColumn(s, column);
        }
      },
      // v3: one "days before" choice instead of separate offsets, and a
      // per-plan "days before". Plans keep their on/off switch; with no
      // own days they follow the global setting ("General").
      from2To3: (m, schema) async {
        await m.addColumn(schema.plans, schema.plans.reminderLeadDays);
        await m.addColumn(
          schema.recurringPayments,
          schema.recurringPayments.reminderLeadDays,
        );
        // Rebuilds the settings row without the v2 offset columns.
        await m.alterTable(
          TableMigration(
            schema.appSettings,
            newColumns: [schema.appSettings.reminderLeadDays],
          ),
        );
      },
      // v4: payments paid before the plan was added to Kalan. Every
      // existing payment is false; amounts and dates do not change.
      from3To4: (m, schema) async {
        await m.addColumn(schema.payments, schema.payments.paidBeforeKalan);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
