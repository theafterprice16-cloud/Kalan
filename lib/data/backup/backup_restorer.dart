import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/backup/backup_data.dart';
import '../../core/date/local_date.dart';
import '../../core/holidays/holidays.dart';
import '../db/app_database.dart';

/// Puts a backup's data in place of everything the user has (Roadmap 30),
/// in one transaction: should anything fail, nothing changes at all.
/// The inverse of `collectBackup`. [data] is validated
/// ([BackupData.validate]) before anything is touched.
///
/// - Every row of user data goes: sources and cards, plans and their
///   payments, recurring payments and their paid occurrences, and the
///   "remind later" snoozes (they point at the payments that go).
/// - The backup's rows are written with new ids; the file's own numbers
///   only tie them together ([BackupPlan.sourceId] and
///   [BackupPlan.chargeSourceId] go through an id map). The ids keep
///   counting up from the old ones (SQLite AUTOINCREMENT), so a
///   notification still showing an old payment cannot touch a new one.
/// - The product settings come from the backup. This device's own
///   choices stay: the app language, the debug Pro switch and whether
///   the notification permission was asked (Pro itself, the app lock,
///   "Hide amounts" and the theme live outside the database and are not
///   touched here).
/// - The holidays the backup's card dates were computed with are written
///   as they are, so the holiday sync moves a date only if this device's
///   list differs, and then once.
///
/// [debugBeforeCommit] runs inside the transaction once everything is
/// written; tests throw from it to see that nothing is left half done.
Future<void> restoreBackup(
  AppDatabase db,
  BackupData data, {
  @visibleForTesting Future<void> Function()? debugBeforeCommit,
}) => db.transaction(() async {
  // Checked once more here, so nothing unchecked is ever written.
  data.validate();
  final device = await db.select(db.appSettings).getSingleOrNull();

  // Children first: plans point at sources without a delete rule.
  await db.delete(db.reminderSnoozes).go();
  await db.delete(db.recurringMarks).go();
  await db.delete(db.recurringPayments).go();
  await db.delete(db.payments).go();
  await db.delete(db.plans).go();
  await db.delete(db.sources).go();
  await db.delete(db.appSettings).go();

  await db.into(db.appSettings).insert(_settings(data.settings, device));

  final sourceIds = <int, int>{};
  for (final s in data.sources) {
    sourceIds[s.id] = await db.into(db.sources).insert(_source(s));
  }
  int? mapped(int? fileId) => fileId == null ? null : sourceIds[fileId]!;

  for (final p in data.plans) {
    final planId = await db
        .into(db.plans)
        .insert(
          _plan(
            p,
            sourceId: mapped(p.sourceId),
            chargeSourceId: mapped(p.chargeSourceId),
          ),
        );
    await db.batch(
      (b) => b.insertAll(db.payments, [
        for (final pay in p.payments) _payment(pay, planId),
      ]),
    );
  }

  for (final r in data.recurringPayments) {
    final id = await db.into(db.recurringPayments).insert(_recurring(r));
    await db.batch(
      (b) => b.insertAll(db.recurringMarks, [
        for (final o in r.paidOccurrences)
          RecurringMarksCompanion.insert(
            recurringId: id,
            occurrenceDay: o.date.epochDay,
            paidAt: o.paidAt,
          ),
      ]),
    );
  }
  await debugBeforeCommit?.call();
});

int? _epoch(LocalDate? day) => day?.epochDay;

AppSettingsCompanion _settings(BackupSettings s, SettingsRow? device) {
  final holidays = s.appliedHolidays;
  return AppSettingsCompanion.insert(
    id: const Value(1),
    currencyCode: s.currency,
    // This device's own.
    localeCode: Value(device?.localeCode),
    debugPro: Value(device?.debugPro ?? false),
    reminderPromptShown: Value(device?.reminderPromptShown ?? false),
    payFrequency: s.payFrequency,
    payDay: Value(s.payDay),
    payAnchorDay: Value(_epoch(s.payAnchorDate)),
    netIncomeMinor: Value(s.netIncome),
    tightThresholdMinor: Value(s.tightThreshold),
    remindersEnabled: Value(s.remindersEnabled),
    reminderLeadDays: Value(s.reminderLeadDays),
    reminderMinute: Value(s.reminderMinuteOfDay),
    hideAmountsInNotifications: Value(!s.showAmountsInNotifications),
    repeatMode: Value(s.repeatMode),
    lastPayLaterRule: Value(s.lastPayLaterRule),
    lastPayLaterValue: Value(s.lastPayLaterValue),
    lastAmountEntry: Value(s.lastAmountEntry),
    paydaySummaryEnabled: Value(s.paydaySummaryEnabled),
    holidayCountry: Value(s.holidayCountry),
    appliedHolidays: Value(
      holidays == null
          ? null
          : CountryHolidays(
              country: holidays.country,
              weekendDays: holidays.weekendDays.toSet(),
              lastYear: holidays.lastYear,
              holidayDays: {for (final d in holidays.days) d.epochDay},
            ).toSnapshot(),
    ),
  );
}

SourcesCompanion _source(BackupSource s) => SourcesCompanion.insert(
  name: s.name,
  kind: SourceKind.values.byName(s.kind),
  statementDay: Value(s.statementDay),
  dueDay: Value(s.dueDay),
  shiftDueToBusinessDay: Value(s.moveDueToBusinessDay),
  shiftDueForHolidays: Value(s.moveDueForHolidays),
  createdAt: Value(s.createdAt),
  statementReminderEnabled: Value(s.statementReminderEnabled),
  statementReminderDays: Value(s.statementReminderDays),
);

PlansCompanion _plan(
  BackupPlan p, {
  required int? sourceId,
  required int? chargeSourceId,
}) => PlansCompanion.insert(
  sourceId: Value(sourceId),
  title: Value(p.title),
  kind: p.kind,
  installmentCount: p.installmentCount,
  purchaseDay: Value(_epoch(p.purchaseDate)),
  deferMonths: Value(p.deferMonths),
  isCashAdvance: Value(p.isCashAdvance),
  origin: PlanOrigin.values.byName(p.origin),
  createdAt: Value(p.createdAt),
  remindersEnabled: Value(p.reminders.enabled),
  reminderLeadDays: Value(p.reminders.leadDays),
  repeatMode: Value(p.repeatMode),
  payLaterRule: Value(p.payLaterRule),
  payLaterValue: Value(p.payLaterValue),
  intervalDays: Value(p.intervalDays),
  paymentMethod: Value(p.paymentMethod),
  chargeSourceId: Value(chargeSourceId),
  status: Value(p.status),
  closeReason: Value(p.closeReason),
  heldSinceDay: Value(_epoch(p.heldSince)),
  holdCheckDay: Value(_epoch(p.holdCheckFrom)),
  reopenedDay: Value(_epoch(p.reopenedOn)),
  closedDay: Value(_epoch(p.closedOn)),
  installmentFeeMinor: Value(p.installmentFee),
  installmentFeeScope: Value(p.installmentFeeScope),
  productPriceMinor: Value(p.productPrice),
);

PaymentsCompanion _payment(BackupPayment p, int planId) =>
    PaymentsCompanion.insert(
      planId: planId,
      seq: p.seq,
      dueDay: p.dueDate.epochDay,
      amountMinor: p.amount,
      paidAt: Value(p.paidAt),
      isEdited: Value(p.isEdited),
      paidBeforeKalan: Value(p.paidBeforeKalan),
      paidOnDay: Value(_epoch(p.paidOn)),
      originalDay: Value(_epoch(p.originalDueDate)),
      extraFeeMinor: Value(p.extraFee),
      extraFeeNote: Value(p.extraFeeNote),
      installmentFeeMinor: Value(p.installmentFee),
    );

RecurringPaymentsCompanion _recurring(BackupRecurring r) =>
    RecurringPaymentsCompanion.insert(
      name: r.name,
      amountMinor: r.amount,
      recurrence: r.recurrence,
      startDay: r.startDate.epochDay,
      endDay: Value(_epoch(r.endDate)),
      createdAt: Value(r.createdAt),
      remindersEnabled: Value(r.reminders.enabled),
      reminderLeadDays: Value(r.reminders.leadDays),
      repeatMode: Value(r.repeatMode),
    );
