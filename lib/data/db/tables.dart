// Drift's check constraints reference their own column getter.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../core/engine/amount_entry.dart';
import '../../core/engine/pay_later.dart';
import '../../core/engine/pay_period.dart';
import '../../core/engine/payment_method.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/plan_status.dart';
import '../../core/engine/recurring.dart';
import '../../core/reminders/reminder_models.dart' show ReminderRepeat;

/// Provider ("sonra öde" service), credit card or bank account. A bank
/// account (18) is only where automatic payments are taken from: it is not
/// offered as a plan's provider. Stored by name, so adding a kind needs no
/// schema change.
enum SourceKind { provider, card, account }

/// Where a plan came from. Screenshot and pasted text readers will add
/// values here; every origin goes through draft → confirm → save.
enum PlanOrigin { template, manual }

/// Dates are stored as epoch days (see `LocalDate.epochDay`); amounts as
/// integer minor units.
@DataClassName('SourceRow')
class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get kind => textEnum<SourceKind>()();
  IntColumn get statementDay => integer().nullable().check(
    statementDay.isNull() | statementDay.isBetweenValues(1, 31),
  )();
  IntColumn get dueDay => integer().nullable().check(
    dueDay.isNull() | dueDay.isBetweenValues(1, 31),
  )();
  BoolColumn get shiftDueToBusinessDay =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Statement closing reminder (schema v13): off by default, only for
  /// cards with a statement day.
  BoolColumn get statementReminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// How many days before the statement date it comes: 1 or 2.
  IntColumn get statementReminderDays => integer()
      .check(statementReminderDays.isIn(const [1, 2]))
      .withDefault(const Constant(2))();
}

@DataClassName('PlanRow')
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Optional only for "Pay later" plans (schema v8).
  IntColumn get sourceId => integer().nullable().references(Sources, #id)();
  TextColumn get title => text().nullable().withLength(max: 80)();
  TextColumn get kind => textEnum<PlanKind>()();
  IntColumn get installmentCount =>
      integer().check(installmentCount.isBiggerOrEqualValue(1))();
  IntColumn get purchaseDay => integer().nullable()();
  IntColumn get deferMonths => integer().withDefault(const Constant(0))();
  BoolColumn get isCashAdvance =>
      boolean().withDefault(const Constant(false))();
  TextColumn get origin => textEnum<PlanOrigin>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Reminder choice (schema v2, v3): off when false; otherwise the
  /// global "days before" ([reminderLeadDays] null) or its own.
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderLeadDays => integer().nullable().check(
    reminderLeadDays.isNull() | reminderLeadDays.isIn(const [1, 2, 3, 5, 7]),
  )();

  /// Repeat reminders (schema v7): null follows the global setting.
  IntColumn get repeatMode => intEnum<ReminderRepeat>().nullable()();

  /// "Pay later" (schema v8): the due date rule, so the date follows a
  /// changed purchase date ([purchaseDay]). Null for other kinds.
  TextColumn get payLaterRule => textEnum<PayLaterRuleKind>().nullable()();
  IntColumn get payLaterValue => integer().nullable()();

  /// "Monthly installments" and "Pay in 4" (schema v9): every N days
  /// (1-365); null is the same day each month. Unused by other kinds.
  IntColumn get intervalDays => integer().nullable().check(
    intervalDays.isNull() | intervalDays.isBetweenValues(1, 365),
  )();

  /// How the payments are paid (schema v11): null is "not set" and keeps
  /// the reminders exactly as before.
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();

  /// Where an automatic payment is taken from (schema v11): any source or
  /// card. Null is "not chosen"; a card plan then means its own card
  /// (`PlanWithPayments.chargeSource`). Deleting the source clears it.
  IntColumn get chargeSourceId => integer().nullable().references(
    Sources,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Open, on hold or closed (schema v14, 19). Every existing plan is
  /// open: a plan whose payments are all paid is in the archive as before.
  TextColumn get status =>
      textEnum<PlanStatus>().withDefault(const Constant('open'))();

  /// Why a closed plan was closed: return or cancellation. Null for every
  /// other plan, finished (all paid) plans included.
  TextColumn get closeReason => textEnum<CloseReason>().nullable()();

  /// The day the plan was put on hold (epoch day). Kept after "Reopen",
  /// with [reopenedDay], to count payments whose date passed meanwhile.
  IntColumn get heldSinceDay => integer().nullable()();

  /// Where the 30 days before "Still waiting on the return?" start: the
  /// hold day, or the day "Keep on hold" was last chosen.
  IntColumn get holdCheckDay => integer().nullable()();

  /// The day a plan on hold was reopened; null while on hold or never held.
  IntColumn get reopenedDay => integer().nullable()();

  /// The day a plan was closed; null for every other plan. Closing cannot
  /// be undone.
  IntColumn get closedDay => integer().nullable()();
}

@DataClassName('PaymentRow')
@TableIndex(name: 'payments_due_day', columns: {#dueDay})
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  IntColumn get dueDay => integer()();
  IntColumn get amountMinor =>
      integer().check(amountMinor.isBiggerOrEqualValue(1))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();

  /// Paid before the plan was added to Kalan (schema v4): stored as paid,
  /// never overdue, never listed one by one or reminded.
  BoolColumn get paidBeforeKalan =>
      boolean().withDefault(const Constant(false))();

  /// The day it was paid, as chosen in the past-due list (schema v5):
  /// "today" or "on the due date". Empty for every other "paid", which
  /// keeps counting on its due date ([countingDate]).
  IntColumn get paidOnDay => integer().nullable()();

  /// The date the payment had before its date was first changed with
  /// "Change date" (schema v15, 20). Written once, never overwritten;
  /// cleared when the payment goes back to it. Empty for every other
  /// payment.
  IntColumn get originalDay => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {planId, seq},
  ];
}

/// Rent, bills, subscriptions: no categories.
@DataClassName('RecurringPaymentRow')
class RecurringPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get amountMinor =>
      integer().check(amountMinor.isBiggerOrEqualValue(1))();
  TextColumn get recurrence => textEnum<Recurrence>()();
  IntColumn get startDay => integer()();
  IntColumn get endDay => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Reminder choice, as on [Plans] (schema v2, v3).
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderLeadDays => integer().nullable().check(
    reminderLeadDays.isNull() | reminderLeadDays.isIn(const [1, 2, 3, 5, 7]),
  )();

  /// Repeat reminders, as on [Plans] (schema v7).
  IntColumn get repeatMode => intEnum<ReminderRepeat>().nullable()();
}

/// "Paid" marks for individual occurrences of a recurring payment.
@DataClassName('RecurringMarkRow')
class RecurringMarks extends Table {
  IntColumn get recurringId => integer().references(
    RecurringPayments,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get occurrenceDay => integer()();
  DateTimeColumn get paidAt => dateTime()();

  @override
  Set<Column> get primaryKey => {recurringId, occurrenceDay};
}

/// Single row, written when onboarding finishes.
@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get localeCode => text().nullable()();
  TextColumn get payFrequency => textEnum<PayFrequency>()();

  /// Monthly: day of month 1-31.
  IntColumn get payDay => integer().nullable()();

  /// Weekly and biweekly: a known payday (epoch day).
  IntColumn get payAnchorDay => integer().nullable()();

  /// One paycheck, minor units. Optional.
  IntColumn get netIncomeMinor => integer().nullable()();
  IntColumn get tightThresholdMinor => integer().nullable()();

  /// Honoured only in debug builds.
  BoolColumn get debugPro => boolean().withDefault(const Constant(false))();

  // Reminders (schema v2, v3). Defaults: on, 2 days before and on the
  // day, 09:00, amounts shown.
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Global "days before" (1, 2, 3, 5 or 7).
  IntColumn get reminderLeadDays => integer()
      .withDefault(const Constant(2))
      .check(reminderLeadDays.isIn(const [1, 2, 3, 5, 7]))();

  /// Local time, minutes after midnight.
  IntColumn get reminderMinute => integer()
      .withDefault(const Constant(540))
      .check(reminderMinute.isBetweenValues(0, 1439))();

  /// Privacy: hide amounts in notifications ("show amount" off).
  BoolColumn get hideAmountsInNotifications =>
      boolean().withDefault(const Constant(false))();

  /// The permission sheet was shown (never asked again).
  BoolColumn get reminderPromptShown =>
      boolean().withDefault(const Constant(false))();

  /// Repeat reminders (schema v7): off for everyone until chosen.
  IntColumn get repeatMode =>
      intEnum<ReminderRepeat>().withDefault(const Constant(0))();

  /// The "Pay later" rule used last (schema v8), offered next time. A
  /// picked date is never stored here. Null until first used: 30 days.
  TextColumn get lastPayLaterRule => textEnum<PayLaterRuleKind>().nullable()();
  IntColumn get lastPayLaterValue => integer().nullable()();

  /// The amount typed last when adding a plan with several payments
  /// (schema v10): the total or one installment. Null until a plan is
  /// saved: the total, as before.
  TextColumn get lastAmountEntry => textEnum<AmountEntry>().nullable()();

  /// Payday summary notification (schema v12): on for everyone until
  /// turned off, existing users included.
  BoolColumn get paydaySummaryEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// "Remind tonight" / "Remind tomorrow" chosen from a notification (schema
/// v6). Kept so a full reschedule does not lose it; deleted once its time
/// has passed or none of its payments is still unpaid.
@DataClassName('ReminderSnoozeRow')
class ReminderSnoozes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The kind of the notification it came from: 0 ahead, 1 on the day,
  /// 2 overdue (schema v7).
  IntColumn get kind => integer().check(kind.isIn(const [0, 1, 2]))();

  /// Local day and time it fires (epoch day, minutes after midnight).
  IntColumn get fireDay => integer()();
  IntColumn get minuteOfDay =>
      integer().check(minuteOfDay.isBetweenValues(0, 1439))();

  /// The payments in it, as comma-separated keys ("p12,r3.20406").
  TextColumn get refs => text()();

  /// "Remind tomorrow" with repeat reminders (schema v7): skips the rest
  /// of the day before [fireDay] instead of adding a reminder.
  BoolColumn get skipsDay => boolean().withDefault(const Constant(false))();

  /// The same button twice makes one snooze.
  @override
  List<Set<Column>> get uniqueKeys => [
    {kind, fireDay, minuteOfDay, refs},
  ];
}
