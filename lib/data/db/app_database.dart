import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/engine/pay_later.dart';
import '../../core/engine/pay_period.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/recurring.dart';
import '../../core/reminders/reminder_models.dart' show ReminderRepeat;
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
    ReminderSnoozes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openShared());

  /// The app's database file, shared by every isolate in the process: the
  /// app, a notification action handled in the background and Android's
  /// reschedule receiver. The first one to open it starts a small database
  /// isolate; the others connect to it, so there is one SQLite connection,
  /// writes never collide, and the app's screens see a background write
  /// at once (see DECISIONS, "Bildirimden ödendi").
  ///
  /// [path] and [tempDirectory] are for tests (no path_provider there).
  static QueryExecutor openShared({
    String name = 'kalan',
    Future<String> Function()? path,
    Future<String?> Function()? tempDirectory,
  }) => driftDatabase(
    name: name,
    native: DriftNativeOptions(
      shareAcrossIsolates: true,
      databasePath: path,
      tempDirectoryPath: tempDirectory,
    ),
  );

  /// Bump together with `dart run drift_dev make-migrations` and add a step.
  @override
  int get schemaVersion => 9;

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
      // v5: the day a past-due payment was paid. Empty for every existing
      // payment, so they stay in their periods.
      from4To5: (m, schema) async {
        await m.addColumn(schema.payments, schema.payments.paidOnDay);
      },
      // v6: "remind later" chosen from a notification. Starts empty.
      from5To6: (m, schema) async {
        await m.createTable(schema.reminderSnoozes);
      },
      // v7: repeat reminders. Everyone starts with them off (global) and
      // every plan follows the global setting; snoozes can be "skip the
      // rest of today" and can come from an overdue reminder.
      from6To7: (m, schema) async {
        await m.addColumn(schema.appSettings, schema.appSettings.repeatMode);
        await m.addColumn(schema.plans, schema.plans.repeatMode);
        await m.addColumn(
          schema.recurringPayments,
          schema.recurringPayments.repeatMode,
        );
        await m.alterTable(
          TableMigration(
            schema.reminderSnoozes,
            newColumns: [schema.reminderSnoozes.skipsDay],
          ),
        );
      },
      // v8: "Pay later" plans. Their source is optional (the column
      // becomes nullable; every existing plan keeps its source) and they
      // store their due date rule. The last used rule is a setting.
      from7To8: (m, schema) async {
        await m.alterTable(
          TableMigration(
            schema.plans,
            newColumns: [schema.plans.payLaterRule, schema.plans.payLaterValue],
          ),
        );
        await m.addColumn(
          schema.appSettings,
          schema.appSettings.lastPayLaterRule,
        );
        await m.addColumn(
          schema.appSettings,
          schema.appSettings.lastPayLaterValue,
        );
      },
      // v9: payment interval. Existing monthly plans stay "same day each
      // month" (empty); existing Pay in 4 plans were every 14 days. No
      // date or amount changes.
      from8To9: (m, schema) async {
        await m.addColumn(schema.plans, schema.plans.intervalDays);
        await customStatement(
          "UPDATE plans SET interval_days = 14 WHERE kind = 'payIn4'",
        );
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Should a second connection ever open the file (another process),
      // readers do not block the writer and a busy writer waits instead of
      // failing. In-memory databases ignore both.
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
