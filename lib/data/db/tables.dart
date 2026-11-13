// Drift's check constraints reference their own column getter.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../core/engine/pay_period.dart';
import '../../core/engine/plan_draft.dart';
import '../../core/engine/recurring.dart';

/// Provider ("sonra öde" service) or credit card.
enum SourceKind { provider, card }

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
}

@DataClassName('PlanRow')
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId => integer().references(Sources, #id)();
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

  @override
  Set<Column> get primaryKey => {id};
}
