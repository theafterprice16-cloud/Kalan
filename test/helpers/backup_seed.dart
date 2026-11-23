import 'package:drift/drift.dart' show Value;
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/holidays/holidays.dart';
import 'package:kalan/core/reminders/reminder_models.dart' show ReminderRepeat;
import 'package:kalan/data/db/app_database.dart';

/// A database where every column of every table that a backup holds has
/// a value other than its default (Roadmap 29): a card and a bank
/// account, a closed card plan with an extra fee, a "Pay later" plan
/// without a name, a plan on hold, an archived plan, a recurring payment
/// with paid occurrences, every setting changed. Also a snooze, which a
/// backup leaves out.
Future<void> seedEverything(AppDatabase db, {String currency = 'TRY'}) async {
  final holidays = CountryHolidays(
    country: 'TR',
    weekendDays: {6, 7},
    lastYear: 2028,
    holidayDays: {LocalDate(2026, 10, 29).epochDay},
  );
  await db
      .into(db.appSettings)
      .insert(
        AppSettingsCompanion.insert(
          currencyCode: currency,
          localeCode: const Value('en'),
          payFrequency: PayFrequency.biweekly,
          payDay: const Value(15),
          payAnchorDay: Value(LocalDate(2026, 11, 6).epochDay),
          netIncomeMinor: const Value(4500000),
          tightThresholdMinor: const Value(500000),
          debugPro: const Value(true),
          remindersEnabled: const Value(false),
          reminderLeadDays: const Value(5),
          reminderMinute: const Value(1230),
          hideAmountsInNotifications: const Value(true),
          reminderPromptShown: const Value(true),
          repeatMode: const Value(ReminderRepeat.daily),
          lastPayLaterRule: const Value(PayLaterRuleKind.nextMonthDay),
          lastPayLaterValue: const Value(10),
          lastAmountEntry: const Value(AmountEntry.installment),
          paydaySummaryEnabled: const Value(false),
          holidayCountry: const Value('TR'),
          appliedHolidays: Value(holidays.toSnapshot()),
        ),
      );
  final card = await db
      .into(db.sources)
      .insert(
        SourcesCompanion.insert(
          name: 'Bonus, "Gold"',
          kind: SourceKind.card,
          statementDay: const Value(25),
          dueDay: const Value(5),
          shiftDueToBusinessDay: const Value(false),
          shiftDueForHolidays: const Value(false),
          createdAt: Value(DateTime.utc(2026, 1, 2, 3, 4, 5)),
          statementReminderEnabled: const Value(true),
          statementReminderDays: const Value(1),
        ),
      );
  final account = await db
      .into(db.sources)
      .insert(
        SourcesCompanion.insert(
          name: 'Maaş hesabı',
          kind: SourceKind.account,
          createdAt: Value(DateTime.utc(2026, 1, 3)),
        ),
      );
  final klarna = await db
      .into(db.sources)
      .insert(
        SourcesCompanion.insert(
          name: 'Klarna',
          kind: SourceKind.provider,
          createdAt: Value(DateTime.utc(2026, 1, 4)),
        ),
      );

  // A closed card plan: every plan column set.
  final phone = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          sourceId: Value(card),
          title: const Value('=TOPLAM'),
          kind: PlanKind.card,
          installmentCount: 3,
          purchaseDay: Value(LocalDate(2026, 10, 10).epochDay),
          deferMonths: const Value(1),
          isCashAdvance: const Value(true),
          origin: PlanOrigin.manual,
          createdAt: Value(DateTime.utc(2026, 10, 10, 8)),
          remindersEnabled: const Value(false),
          reminderLeadDays: const Value(7),
          repeatMode: const Value(ReminderRepeat.evening),
          intervalDays: const Value(30),
          paymentMethod: const Value(PaymentMethod.automatic),
          chargeSourceId: Value(account),
          status: const Value(PlanStatus.closed),
          closeReason: const Value(CloseReason.refund),
          heldSinceDay: Value(LocalDate(2026, 11, 1).epochDay),
          holdCheckDay: Value(LocalDate(2026, 11, 2).epochDay),
          reopenedDay: Value(LocalDate(2026, 11, 3).epochDay),
          closedDay: Value(LocalDate(2026, 11, 4).epochDay),
          installmentFeeMinor: const Value(1500),
          installmentFeeScope: const Value(
            InstallmentFeeScope.firstPaymentOnly,
          ),
          productPriceMinor: const Value(900000),
        ),
      );
  await db
      .into(db.payments)
      .insert(
        PaymentsCompanion.insert(
          planId: phone,
          seq: 2,
          dueDay: LocalDate(2026, 12, 7).epochDay,
          amountMinor: 333334,
          paidAt: Value(DateTime.utc(2026, 12, 1, 9, 30, 15)),
          isEdited: const Value(true),
          paidBeforeKalan: const Value(false),
          paidOnDay: Value(LocalDate(2026, 12, 2).epochDay),
          originalDay: Value(LocalDate(2026, 12, 5).epochDay),
          extraFeeMinor: const Value(600),
          extraFeeNote: const Value('Gecikme, "faiz"'),
          installmentFeeMinor: const Value(1500),
        ),
      );
  await db
      .into(db.payments)
      .insert(
        PaymentsCompanion.insert(
          planId: phone,
          seq: 3,
          dueDay: LocalDate(2027, 1, 5).epochDay,
          amountMinor: 333333,
        ),
      );
  // A "Pay later" plan without a name, paid before Kalan.
  final later = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          kind: PlanKind.payLater,
          installmentCount: 1,
          origin: PlanOrigin.template,
          createdAt: Value(DateTime.utc(2026, 9, 1)),
          payLaterRule: const Value(PayLaterRuleKind.days),
          payLaterValue: const Value(30),
        ),
      );
  await db
      .into(db.payments)
      .insert(
        PaymentsCompanion.insert(
          planId: later,
          seq: 1,
          dueDay: LocalDate(2026, 12, 14).epochDay,
          amountMinor: 125050,
          paidAt: Value(DateTime.utc(2026, 9, 1)),
          paidBeforeKalan: const Value(true),
        ),
      );
  // A plan on hold.
  final held = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          sourceId: Value(klarna),
          kind: PlanKind.payIn4,
          installmentCount: 1,
          origin: PlanOrigin.template,
          createdAt: Value(DateTime.utc(2026, 8, 1)),
          status: const Value(PlanStatus.onHold),
          heldSinceDay: Value(LocalDate(2026, 11, 10).epochDay),
        ),
      );
  await db
      .into(db.payments)
      .insert(
        PaymentsCompanion.insert(
          planId: held,
          seq: 1,
          dueDay: LocalDate(2026, 12, 1).epochDay,
          amountMinor: 10000,
        ),
      );
  // An archived plan: open, every payment paid.
  final done = await db
      .into(db.plans)
      .insert(
        PlansCompanion.insert(
          sourceId: Value(klarna),
          title: const Value('Mont'),
          kind: PlanKind.monthly,
          installmentCount: 1,
          origin: PlanOrigin.template,
          createdAt: Value(DateTime.utc(2026, 7, 1)),
        ),
      );
  await db
      .into(db.payments)
      .insert(
        PaymentsCompanion.insert(
          planId: done,
          seq: 1,
          dueDay: LocalDate(2026, 8, 1).epochDay,
          amountMinor: 50000,
          paidAt: Value(DateTime.utc(2026, 8, 1, 12)),
        ),
      );

  final rent = await db
      .into(db.recurringPayments)
      .insert(
        RecurringPaymentsCompanion.insert(
          name: 'Kira',
          amountMinor: 1500000,
          recurrence: Recurrence.monthly,
          startDay: LocalDate(2026, 1, 1).epochDay,
          endDay: Value(LocalDate(2027, 12, 1).epochDay),
          createdAt: Value(DateTime.utc(2026, 1, 1, 10)),
          remindersEnabled: const Value(false),
          reminderLeadDays: const Value(3),
          repeatMode: const Value(ReminderRepeat.daily),
        ),
      );
  await db
      .into(db.recurringMarks)
      .insert(
        RecurringMarksCompanion.insert(
          recurringId: rent,
          occurrenceDay: LocalDate(2026, 11, 1).epochDay,
          paidAt: DateTime.utc(2026, 11, 1, 18),
        ),
      );
  await db
      .into(db.reminderSnoozes)
      .insert(
        ReminderSnoozesCompanion.insert(
          kind: 1,
          fireDay: LocalDate(2026, 11, 20).epochDay,
          minuteOfDay: 1200,
          refs: 'p1',
        ),
      );
}
