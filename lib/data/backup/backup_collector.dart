import 'package:drift/drift.dart' show OrderingTerm;

import '../../core/backup/backup_data.dart';
import '../../core/date/local_date.dart';
import '../../core/holidays/holidays.dart';
import '../db/app_database.dart';

/// Reads everything a backup holds from the database, in one transaction
/// (a consistent copy even while a reminder action writes in the
/// background). Every column of every table is either mapped here or
/// left out on purpose (test/data/backup_collector_test.dart keeps that
/// list); see [BackupData] for what is left out and why.
///
/// Null before onboarding (no settings yet).
Future<BackupData?> collectBackup(AppDatabase db) => db.transaction(() async {
  final settings = await db.select(db.appSettings).getSingleOrNull();
  if (settings == null) return null;
  final sources = await (db.select(
    db.sources,
  )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
  final plans = await (db.select(
    db.plans,
  )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
  final payments = await (db.select(db.payments)..orderBy([
        (p) => OrderingTerm.asc(p.planId),
        (p) => OrderingTerm.asc(p.seq),
      ]))
      .get();
  final recurring = await (db.select(
    db.recurringPayments,
  )..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
  final marks = await (db.select(db.recurringMarks)..orderBy([
        (m) => OrderingTerm.asc(m.recurringId),
        (m) => OrderingTerm.asc(m.occurrenceDay),
      ]))
      .get();

  final paymentsOf = <int, List<PaymentRow>>{};
  for (final p in payments) {
    (paymentsOf[p.planId] ??= []).add(p);
  }
  final marksOf = <int, List<RecurringMarkRow>>{};
  for (final m in marks) {
    (marksOf[m.recurringId] ??= []).add(m);
  }
  return BackupData(
    settings: _settings(settings),
    sources: [for (final s in sources) _source(s)],
    plans: [for (final p in plans) _plan(p, paymentsOf[p.id] ?? const [])],
    recurringPayments: [
      for (final r in recurring) _recurring(r, marksOf[r.id] ?? const []),
    ],
  );
});

LocalDate? _day(int? epochDay) =>
    epochDay == null ? null : LocalDate.fromEpochDay(epochDay);

BackupSettings _settings(SettingsRow s) {
  final applied = CountryHolidays.fromSnapshot(s.appliedHolidays);
  return BackupSettings(
    currency: s.currencyCode,
    payFrequency: s.payFrequency,
    payDay: s.payDay,
    payAnchorDate: _day(s.payAnchorDay),
    netIncome: s.netIncomeMinor,
    tightThreshold: s.tightThresholdMinor,
    remindersEnabled: s.remindersEnabled,
    reminderLeadDays: s.reminderLeadDays,
    reminderMinuteOfDay: s.reminderMinute,
    showAmountsInNotifications: !s.hideAmountsInNotifications,
    repeatMode: s.repeatMode,
    paydaySummaryEnabled: s.paydaySummaryEnabled,
    lastPayLaterRule: s.lastPayLaterRule,
    lastPayLaterValue: s.lastPayLaterValue,
    lastAmountEntry: s.lastAmountEntry,
    holidayCountry: s.holidayCountry,
    appliedHolidays: applied == null
        ? null
        : BackupHolidays(
            country: applied.country,
            weekendDays: [...applied.weekendDays]..sort(),
            lastYear: applied.lastYear,
            days: applied.dates,
          ),
  );
}

BackupSource _source(SourceRow s) => BackupSource(
  id: s.id,
  name: s.name,
  kind: s.kind.name,
  statementDay: s.statementDay,
  dueDay: s.dueDay,
  moveDueToBusinessDay: s.shiftDueToBusinessDay,
  moveDueForHolidays: s.shiftDueForHolidays,
  statementReminderEnabled: s.statementReminderEnabled,
  statementReminderDays: s.statementReminderDays,
  createdAt: s.createdAt,
);

BackupPlan _plan(PlanRow p, List<PaymentRow> payments) => BackupPlan(
  id: p.id,
  sourceId: p.sourceId,
  title: p.title,
  kind: p.kind,
  installmentCount: p.installmentCount,
  purchaseDate: _day(p.purchaseDay),
  deferMonths: p.deferMonths,
  isCashAdvance: p.isCashAdvance,
  origin: p.origin.name,
  createdAt: p.createdAt,
  reminders: BackupReminderChoice(
    enabled: p.remindersEnabled,
    leadDays: p.reminderLeadDays,
  ),
  repeatMode: p.repeatMode,
  payLaterRule: p.payLaterRule,
  payLaterValue: p.payLaterValue,
  intervalDays: p.intervalDays,
  paymentMethod: p.paymentMethod,
  chargeSourceId: p.chargeSourceId,
  status: p.status,
  closeReason: p.closeReason,
  heldSince: _day(p.heldSinceDay),
  holdCheckFrom: _day(p.holdCheckDay),
  reopenedOn: _day(p.reopenedDay),
  closedOn: _day(p.closedDay),
  installmentFee: p.installmentFeeMinor,
  installmentFeeScope: p.installmentFeeScope,
  productPrice: p.productPriceMinor,
  payments: [
    for (final pay in payments)
      BackupPayment(
        seq: pay.seq,
        dueDate: LocalDate.fromEpochDay(pay.dueDay),
        amount: pay.amountMinor,
        paidAt: pay.paidAt,
        isEdited: pay.isEdited,
        paidBeforeKalan: pay.paidBeforeKalan,
        paidOn: _day(pay.paidOnDay),
        originalDueDate: _day(pay.originalDay),
        extraFee: pay.extraFeeMinor,
        extraFeeNote: pay.extraFeeNote,
        installmentFee: pay.installmentFeeMinor,
      ),
  ],
);

BackupRecurring _recurring(
  RecurringPaymentRow r,
  List<RecurringMarkRow> marks,
) => BackupRecurring(
  id: r.id,
  name: r.name,
  amount: r.amountMinor,
  recurrence: r.recurrence,
  startDate: LocalDate.fromEpochDay(r.startDay),
  endDate: _day(r.endDay),
  createdAt: r.createdAt,
  reminders: BackupReminderChoice(
    enabled: r.remindersEnabled,
    leadDays: r.reminderLeadDays,
  ),
  repeatMode: r.repeatMode,
  paidOccurrences: [
    for (final m in marks)
      BackupPaidOccurrence(
        date: LocalDate.fromEpochDay(m.occurrenceDay),
        paidAt: m.paidAt,
      ),
  ],
);
