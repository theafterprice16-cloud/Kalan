/// What a full backup holds (Roadmap 29): every piece of the user's data
/// and the product settings, by meaningful names, independent of the
/// database schema. The file format is in docs/YEDEK_BICIMI.md; a test
/// keeps that document and this code in step.
///
/// Amounts are whole numbers in minor units of [BackupSettings.currency]
/// (never fractions); calendar days are "yyyy-MM-dd"; moments are UTC
/// ISO 8601. Enum values are written by their names, which a test
/// freezes.
///
/// Not in a backup, on purpose: Kalan Pro (a store purchase, not data),
/// the app lock, "Hide amounts", theme and language (this device's
/// choices), the reminder permission prompt and "remind later" snoozes
/// (temporary).
///
/// Pure Dart.
library;

import '../date/local_date.dart';
import '../engine/amount_entry.dart';
import '../engine/installment_fee.dart';
import '../engine/pay_later.dart';
import '../engine/pay_period.dart';
import '../engine/payment_method.dart';
import '../engine/plan_draft.dart';
import '../engine/plan_status.dart';
import '../engine/recurring.dart';
import '../money/currency.dart';
import '../reminders/reminder_models.dart' show ReminderRepeat;
import 'backup_json.dart';

/// Source kinds as written ([SourceKind] in the database).
const backupSourceKinds = {'provider', 'card', 'account'};

/// Plan origins as written ([PlanOrigin] in the database).
const backupPlanOrigins = {'template', 'manual'};

class BackupData {
  const BackupData({
    required this.settings,
    required this.sources,
    required this.plans,
    required this.recurringPayments,
  });

  factory BackupData.fromJson(Object? json) {
    final f = JsonFields(json, 'data');
    return BackupData(
      settings: BackupSettings.fromJson(f.object('settings')),
      sources: [for (final s in f.objects('sources')) BackupSource.fromJson(s)],
      plans: [for (final p in f.objects('plans')) BackupPlan.fromJson(p)],
      recurringPayments: [
        for (final r in f.objects('recurringPayments'))
          BackupRecurring.fromJson(r),
      ],
    );
  }

  final BackupSettings settings;
  final List<BackupSource> sources;

  /// By id, as the app lists them.
  final List<BackupPlan> plans;
  final List<BackupRecurring> recurringPayments;

  /// Checks what types alone cannot: known currency, values in range,
  /// unique numbers and links that point at something. A file that fails
  /// is damaged ([BackupFormatException]); Roadmap 30 writes nothing from
  /// it.
  void validate() {
    void check(bool ok, String at) {
      if (!ok) throw BackupFormatException(at);
    }

    bool day(int? v) => v == null || (v >= 1 && v <= 31);
    bool lead(int? v) => v == null || const {1, 2, 3, 5, 7}.contains(v);
    bool positive(int? v) => v == null || v >= 1;
    bool length(String? v, int min, int max) =>
        v == null || (v.length >= min && v.length <= max);

    final s = settings;
    check(Currency.byCode(s.currency) != null, 'settings.currency');
    check(day(s.payDay), 'settings.payDay');
    check(s.netIncome == null || s.netIncome! >= 0, 'settings.netIncome');
    check(
      s.tightThreshold == null || s.tightThreshold! >= 0,
      'settings.tightThreshold',
    );
    check(lead(s.reminderLeadDays), 'settings.reminders.leadDays');
    check(
      s.reminderMinuteOfDay >= 0 && s.reminderMinuteOfDay < 24 * 60,
      'settings.reminders.minuteOfDay',
    );
    check(length(s.holidayCountry, 0, 2), 'settings.holidayCountry');

    final sourceIds = <int>{};
    for (final (i, x) in sources.indexed) {
      final at = 'sources[$i]';
      check(sourceIds.add(x.id), '$at.id');
      check(length(x.name, 1, 60), '$at.name');
      check(day(x.statementDay) && day(x.dueDay), '$at.dueDay');
      check(const {1, 2}.contains(x.statementReminderDays), '$at.daysBefore');
    }
    final planIds = <int>{};
    for (final (i, p) in plans.indexed) {
      final at = 'plans[$i]';
      check(planIds.add(p.id), '$at.id');
      check(
        p.sourceId == null || sourceIds.contains(p.sourceId),
        '$at.sourceId',
      );
      check(
        p.chargeSourceId == null || sourceIds.contains(p.chargeSourceId),
        '$at.chargeSourceId',
      );
      check(length(p.title, 0, 80), '$at.title');
      check(p.installmentCount >= 1, '$at.installmentCount');
      check(p.deferMonths >= 0, '$at.deferMonths');
      check(
        p.intervalDays == null ||
            (p.intervalDays! >= 1 && p.intervalDays! <= 365),
        '$at.intervalDays',
      );
      check(lead(p.reminders.leadDays), '$at.reminders.leadDays');
      check(positive(p.installmentFee), '$at.installmentFee');
      check(positive(p.productPrice), '$at.productPrice');
      final seqs = <int>{};
      for (final (j, pay) in p.payments.indexed) {
        final payAt = '$at.payments[$j]';
        check(seqs.add(pay.seq), '$payAt.seq');
        check(pay.amount >= 1, '$payAt.amount');
        check(positive(pay.extraFee), '$payAt.extraFee');
        check(positive(pay.installmentFee), '$payAt.installmentFee');
        check(length(pay.extraFeeNote, 0, 80), '$payAt.extraFeeNote');
      }
    }
    final recurringIds = <int>{};
    for (final (i, r) in recurringPayments.indexed) {
      final at = 'recurringPayments[$i]';
      check(recurringIds.add(r.id), '$at.id');
      check(length(r.name, 1, 60), '$at.name');
      check(r.amount >= 1, '$at.amount');
      check(lead(r.reminders.leadDays), '$at.reminders.leadDays');
      final days = <LocalDate>{};
      for (final (j, o) in r.paidOccurrences.indexed) {
        check(days.add(o.date), '$at.paidOccurrences[$j].date');
      }
    }
  }

  Map<String, Object?> toJson() => {
    'settings': settings.toJson(),
    'sources': [for (final s in sources) s.toJson()],
    'plans': [for (final p in plans) p.toJson()],
    'recurringPayments': [for (final r in recurringPayments) r.toJson()],
  };
}

/// Reminder choice of a plan or a recurring payment: off, the general
/// "days before" ([leadDays] null) or its own.
class BackupReminderChoice {
  const BackupReminderChoice({required this.enabled, this.leadDays});

  factory BackupReminderChoice.fromJson(JsonFields f) => BackupReminderChoice(
    enabled: f.boolean('enabled'),
    leadDays: f.optionalInteger('leadDays'),
  );

  final bool enabled;
  final int? leadDays;

  Map<String, Object?> toJson() => {'enabled': enabled, 'leadDays': leadDays};
}

/// The weekend and public holidays the stored card dates were computed
/// with (Roadmap 26); null in [BackupSettings] for "None".
class BackupHolidays {
  const BackupHolidays({
    required this.country,
    required this.weekendDays,
    required this.lastYear,
    required this.days,
  });

  factory BackupHolidays.fromJson(JsonFields f) {
    final weekend = f.ints('weekendDays');
    if (weekend.any((d) => d < 1 || d > 7)) {
      throw BackupFormatException('${f.path}.weekendDays');
    }
    return BackupHolidays(
      country: f.string('country'),
      weekendDays: weekend,
      lastYear: f.integer('lastYear'),
      days: f.days('days'),
    );
  }

  final String country;

  /// ISO weekdays (1 Monday … 7 Sunday).
  final List<int> weekendDays;
  final int lastYear;
  final List<LocalDate> days;

  Map<String, Object?> toJson() => {
    'country': country,
    'weekendDays': weekendDays,
    'lastYear': lastYear,
    'days': [for (final d in days) formatDay(d)],
  };
}

class BackupSettings {
  const BackupSettings({
    required this.currency,
    required this.payFrequency,
    required this.payDay,
    required this.payAnchorDate,
    required this.netIncome,
    required this.tightThreshold,
    required this.remindersEnabled,
    required this.reminderLeadDays,
    required this.reminderMinuteOfDay,
    required this.showAmountsInNotifications,
    required this.repeatMode,
    required this.paydaySummaryEnabled,
    required this.lastPayLaterRule,
    required this.lastPayLaterValue,
    required this.lastAmountEntry,
    required this.holidayCountry,
    required this.appliedHolidays,
  });

  factory BackupSettings.fromJson(JsonFields f) {
    final reminders = f.object('reminders');
    final payLater = f.optionalObject('lastPayLaterRule');
    final holidays = f.optionalObject('appliedHolidays');
    return BackupSettings(
      currency: f.string('currency'),
      payFrequency: f.name('payFrequency', PayFrequency.values),
      payDay: f.optionalInteger('payDay'),
      payAnchorDate: f.optionalDay('payAnchorDate'),
      netIncome: f.optionalAmount('netIncome'),
      tightThreshold: f.optionalAmount('tightThreshold'),
      remindersEnabled: reminders.boolean('enabled'),
      reminderLeadDays: reminders.integer('leadDays'),
      reminderMinuteOfDay: reminders.integer('minuteOfDay'),
      showAmountsInNotifications: reminders.boolean('showAmounts'),
      repeatMode: reminders.name('repeatMode', ReminderRepeat.values),
      paydaySummaryEnabled: reminders.boolean('paydaySummary'),
      lastPayLaterRule: payLater?.name('kind', PayLaterRuleKind.values),
      lastPayLaterValue: payLater?.optionalInteger('value'),
      lastAmountEntry: f.optionalName('lastAmountEntry', AmountEntry.values),
      holidayCountry: f.optionalString('holidayCountry'),
      appliedHolidays: holidays == null
          ? null
          : BackupHolidays.fromJson(holidays),
    );
  }

  /// ISO 4217 code: what every amount in the file is in.
  final String currency;
  final PayFrequency payFrequency;

  /// Monthly payday, day of the month (1-31).
  final int? payDay;

  /// Weekly and biweekly: a known payday.
  final LocalDate? payAnchorDate;

  /// One paycheck; null when not entered.
  final int? netIncome;

  /// "Tight period" threshold; null when off.
  final int? tightThreshold;

  final bool remindersEnabled;

  /// General "days before": 1, 2, 3, 5 or 7.
  final int reminderLeadDays;

  /// Reminder time, minutes after local midnight (540 is 09:00).
  final int reminderMinuteOfDay;

  /// "Show amount in notifications" (a notification preference; not
  /// "Hide amounts", which stays on the device).
  final bool showAmountsInNotifications;
  final ReminderRepeat repeatMode;
  final bool paydaySummaryEnabled;

  /// The "Pay later" rule used last; null until first used.
  final PayLaterRuleKind? lastPayLaterRule;
  final int? lastPayLaterValue;

  /// The amount typed last when adding a plan: the total or one
  /// installment; null until a plan is saved.
  final AmountEntry? lastAmountEntry;

  /// ISO 3166-1 alpha-2; "" for "None"; null until suggested.
  final String? holidayCountry;
  final BackupHolidays? appliedHolidays;

  Map<String, Object?> toJson() => {
    'currency': currency,
    'payFrequency': payFrequency.name,
    'payDay': payDay,
    'payAnchorDate': payAnchorDate == null ? null : formatDay(payAnchorDate!),
    'netIncome': netIncome,
    'tightThreshold': tightThreshold,
    'reminders': {
      'enabled': remindersEnabled,
      'leadDays': reminderLeadDays,
      'minuteOfDay': reminderMinuteOfDay,
      'showAmounts': showAmountsInNotifications,
      'repeatMode': repeatMode.name,
      'paydaySummary': paydaySummaryEnabled,
    },
    'lastPayLaterRule': lastPayLaterRule == null
        ? null
        : {'kind': lastPayLaterRule!.name, 'value': lastPayLaterValue},
    'lastAmountEntry': lastAmountEntry?.name,
    'holidayCountry': holidayCountry,
    'appliedHolidays': appliedHolidays?.toJson(),
  };
}

/// A provider, a card or a bank account.
class BackupSource {
  const BackupSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.statementDay,
    required this.dueDay,
    required this.moveDueToBusinessDay,
    required this.moveDueForHolidays,
    required this.statementReminderEnabled,
    required this.statementReminderDays,
    required this.createdAt,
  });

  factory BackupSource.fromJson(JsonFields f) {
    final reminder = f.object('statementReminder');
    return BackupSource(
      id: f.integer('id'),
      name: f.string('name'),
      kind: f.oneOf('kind', backupSourceKinds),
      statementDay: f.optionalInteger('statementDay'),
      dueDay: f.optionalInteger('dueDay'),
      moveDueToBusinessDay: f.boolean('moveDueToBusinessDay'),
      moveDueForHolidays: f.boolean('moveDueForHolidays'),
      statementReminderEnabled: reminder.boolean('enabled'),
      statementReminderDays: reminder.integer('daysBefore'),
      createdAt: f.instant('createdAt'),
    );
  }

  /// Ties plans to it inside this file only.
  final int id;
  final String name;

  /// provider, card or account.
  final String kind;

  /// Card statement and due days: day of the month (1-31).
  final int? statementDay;
  final int? dueDay;
  final bool moveDueToBusinessDay;
  final bool moveDueForHolidays;
  final bool statementReminderEnabled;
  final int statementReminderDays;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'moveDueToBusinessDay': moveDueToBusinessDay,
    'moveDueForHolidays': moveDueForHolidays,
    'statementReminder': {
      'enabled': statementReminderEnabled,
      'daysBefore': statementReminderDays,
    },
    'createdAt': formatInstant(createdAt),
  };
}

class BackupPlan {
  const BackupPlan({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.kind,
    required this.installmentCount,
    required this.purchaseDate,
    required this.deferMonths,
    required this.isCashAdvance,
    required this.origin,
    required this.createdAt,
    required this.reminders,
    required this.repeatMode,
    required this.payLaterRule,
    required this.payLaterValue,
    required this.intervalDays,
    required this.paymentMethod,
    required this.chargeSourceId,
    required this.status,
    required this.closeReason,
    required this.heldSince,
    required this.holdCheckFrom,
    required this.reopenedOn,
    required this.closedOn,
    required this.installmentFee,
    required this.installmentFeeScope,
    required this.productPrice,
    required this.payments,
  });

  factory BackupPlan.fromJson(JsonFields f) {
    final payLater = f.optionalObject('payLaterRule');
    return BackupPlan(
      id: f.integer('id'),
      sourceId: f.optionalInteger('sourceId'),
      title: f.optionalString('title'),
      kind: f.name('kind', PlanKind.values),
      installmentCount: f.integer('installmentCount'),
      purchaseDate: f.optionalDay('purchaseDate'),
      deferMonths: f.integer('deferMonths'),
      isCashAdvance: f.boolean('isCashAdvance'),
      origin: f.oneOf('origin', backupPlanOrigins),
      createdAt: f.instant('createdAt'),
      reminders: BackupReminderChoice.fromJson(f.object('reminders')),
      repeatMode: f.optionalName('repeatMode', ReminderRepeat.values),
      payLaterRule: payLater?.name('kind', PayLaterRuleKind.values),
      payLaterValue: payLater?.optionalInteger('value'),
      intervalDays: f.optionalInteger('intervalDays'),
      paymentMethod: f.optionalName('paymentMethod', PaymentMethod.values),
      chargeSourceId: f.optionalInteger('chargeSourceId'),
      status: f.name('status', PlanStatus.values),
      closeReason: f.optionalName('closeReason', CloseReason.values),
      heldSince: f.optionalDay('heldSince'),
      holdCheckFrom: f.optionalDay('holdCheckFrom'),
      reopenedOn: f.optionalDay('reopenedOn'),
      closedOn: f.optionalDay('closedOn'),
      installmentFee: f.optionalAmount('installmentFee'),
      installmentFeeScope: f.name(
        'installmentFeeScope',
        InstallmentFeeScope.values,
      ),
      productPrice: f.optionalAmount('productPrice'),
      payments: [
        for (final p in f.objects('payments')) BackupPayment.fromJson(p),
      ],
    );
  }

  /// Ties nothing outside this file; plans are listed by it.
  final int id;

  /// [BackupSource.id]; null only for a "Pay later" plan without one.
  final int? sourceId;
  final String? title;
  final PlanKind kind;
  final int installmentCount;
  final LocalDate? purchaseDate;
  final int deferMonths;
  final bool isCashAdvance;

  /// template or manual.
  final String origin;
  final DateTime createdAt;
  final BackupReminderChoice reminders;

  /// Null follows the general setting.
  final ReminderRepeat? repeatMode;
  final PayLaterRuleKind? payLaterRule;
  final int? payLaterValue;

  /// Every N days; null is the same day each month.
  final int? intervalDays;

  /// Null is "not set".
  final PaymentMethod? paymentMethod;

  /// [BackupSource.id] an automatic payment is taken from.
  final int? chargeSourceId;
  final PlanStatus status;
  final CloseReason? closeReason;
  final LocalDate? heldSince;

  /// Where the 30 days before "Still waiting on the return?" start.
  final LocalDate? holdCheckFrom;
  final LocalDate? reopenedOn;
  final LocalDate? closedOn;

  /// Fee per payment as typed (22).
  final int? installmentFee;
  final InstallmentFeeScope installmentFeeScope;

  /// Product price as typed (23).
  final int? productPrice;

  /// By [BackupPayment.seq].
  final List<BackupPayment> payments;

  Map<String, Object?> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'title': title,
    'kind': kind.name,
    'installmentCount': installmentCount,
    'purchaseDate': purchaseDate == null ? null : formatDay(purchaseDate!),
    'deferMonths': deferMonths,
    'isCashAdvance': isCashAdvance,
    'origin': origin,
    'createdAt': formatInstant(createdAt),
    'reminders': reminders.toJson(),
    'repeatMode': repeatMode?.name,
    'payLaterRule': payLaterRule == null
        ? null
        : {'kind': payLaterRule!.name, 'value': payLaterValue},
    'intervalDays': intervalDays,
    'paymentMethod': paymentMethod?.name,
    'chargeSourceId': chargeSourceId,
    'status': status.name,
    'closeReason': closeReason?.name,
    'heldSince': _day(heldSince),
    'holdCheckFrom': _day(holdCheckFrom),
    'reopenedOn': _day(reopenedOn),
    'closedOn': _day(closedOn),
    'installmentFee': installmentFee,
    'installmentFeeScope': installmentFeeScope.name,
    'productPrice': productPrice,
    'payments': [for (final p in payments) p.toJson()],
  };
}

String? _day(LocalDate? day) => day == null ? null : formatDay(day);

class BackupPayment {
  const BackupPayment({
    required this.seq,
    required this.dueDate,
    required this.amount,
    required this.paidAt,
    required this.isEdited,
    required this.paidBeforeKalan,
    required this.paidOn,
    required this.originalDueDate,
    required this.extraFee,
    required this.extraFeeNote,
    required this.installmentFee,
  });

  factory BackupPayment.fromJson(JsonFields f) => BackupPayment(
    seq: f.integer('seq'),
    dueDate: f.day('dueDate'),
    amount: f.amount('amount'),
    paidAt: f.optionalInstant('paidAt'),
    isEdited: f.boolean('isEdited'),
    paidBeforeKalan: f.boolean('paidBeforeKalan'),
    paidOn: f.optionalDay('paidOn'),
    originalDueDate: f.optionalDay('originalDueDate'),
    extraFee: f.optionalAmount('extraFee'),
    extraFeeNote: f.optionalString('extraFeeNote'),
    installmentFee: f.optionalAmount('installmentFee'),
  );

  /// The payment's number in its plan (an old plan added midway may not
  /// start at 1).
  final int seq;

  /// The effective due date.
  final LocalDate dueDate;
  final int amount;

  /// When it was marked paid; null while unpaid. For a payment paid
  /// before Kalan, when the plan was saved.
  final DateTime? paidAt;
  final bool isEdited;
  final bool paidBeforeKalan;

  /// The day chosen in the past-due list ("today" or "on the due date").
  final LocalDate? paidOn;

  /// The date before "Change date" first moved it (20).
  final LocalDate? originalDueDate;
  final int? extraFee;
  final String? extraFeeNote;

  /// The fee per payment it took (22).
  final int? installmentFee;

  Map<String, Object?> toJson() => {
    'seq': seq,
    'dueDate': formatDay(dueDate),
    'amount': amount,
    'paidAt': paidAt == null ? null : formatInstant(paidAt!),
    'isEdited': isEdited,
    'paidBeforeKalan': paidBeforeKalan,
    'paidOn': _day(paidOn),
    'originalDueDate': _day(originalDueDate),
    'extraFee': extraFee,
    'extraFeeNote': extraFeeNote,
    'installmentFee': installmentFee,
  };
}

/// Rent, bills, subscriptions.
class BackupRecurring {
  const BackupRecurring({
    required this.id,
    required this.name,
    required this.amount,
    required this.recurrence,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.reminders,
    required this.repeatMode,
    required this.paidOccurrences,
  });

  factory BackupRecurring.fromJson(JsonFields f) => BackupRecurring(
    id: f.integer('id'),
    name: f.string('name'),
    amount: f.amount('amount'),
    recurrence: f.name('recurrence', Recurrence.values),
    startDate: f.day('startDate'),
    endDate: f.optionalDay('endDate'),
    createdAt: f.instant('createdAt'),
    reminders: BackupReminderChoice.fromJson(f.object('reminders')),
    repeatMode: f.optionalName('repeatMode', ReminderRepeat.values),
    paidOccurrences: [
      for (final o in f.objects('paidOccurrences'))
        BackupPaidOccurrence.fromJson(o),
    ],
  );

  final int id;
  final String name;

  /// Today's amount; past occurrences keep no amount of their own.
  final int amount;
  final Recurrence recurrence;
  final LocalDate startDate;
  final LocalDate? endDate;
  final DateTime createdAt;
  final BackupReminderChoice reminders;
  final ReminderRepeat? repeatMode;

  /// The occurrences marked paid, by date.
  final List<BackupPaidOccurrence> paidOccurrences;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'recurrence': recurrence.name,
    'startDate': formatDay(startDate),
    'endDate': _day(endDate),
    'createdAt': formatInstant(createdAt),
    'reminders': reminders.toJson(),
    'repeatMode': repeatMode?.name,
    'paidOccurrences': [for (final o in paidOccurrences) o.toJson()],
  };
}

class BackupPaidOccurrence {
  const BackupPaidOccurrence({required this.date, required this.paidAt});

  factory BackupPaidOccurrence.fromJson(JsonFields f) =>
      BackupPaidOccurrence(date: f.day('date'), paidAt: f.instant('paidAt'));

  final LocalDate date;
  final DateTime paidAt;

  Map<String, Object?> toJson() => {
    'date': formatDay(date),
    'paidAt': formatInstant(paidAt),
  };
}
