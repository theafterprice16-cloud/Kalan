import '../core/engine/engine.dart';
import 'db/app_database.dart';

extension SourceRowX on SourceRow {
  bool get isCard => kind == SourceKind.card;

  /// Card terms, or null for providers and incomplete cards. [holidays]
  /// is the calendar the stored card dates were computed with (the
  /// settings' applied holidays, Roadmap 26); null: "None".
  CardTerms? cardTermsIn(HolidayCalendar? holidays) =>
      isCard && statementDay != null && dueDay != null
      ? CardTerms(
          statementDay: statementDay!,
          dueDay: dueDay!,
          shiftDueToBusinessDay: shiftDueToBusinessDay,
          shiftDueForHolidays: shiftDueForHolidays,
          holidays: holidays,
        )
      : null;
}

/// Payments from the start of a plan that are not marked paid in Kalan:
/// the ones "already underway" may cover. A payment with an extra fee
/// (21) is a record made in Kalan too: it is never covered, so its fee is
/// never hidden in "paid before Kalan".
int leadingRunOf(List<PaymentRow> payments) {
  var run = 0;
  for (final p in payments) {
    if (p.paidBeforeKalan) {
      run++;
      continue;
    }
    if (p.isPaid || p.extraFeeMinor != null) break;
    run++;
  }
  return run;
}

/// The highest "installments paid" a plan can take: its leading run, and
/// always at least one payment left.
int maxPaidBeforeOf(List<PaymentRow> payments) {
  final run = leadingRunOf(payments);
  return run < payments.length ? run : payments.length - 1;
}

extension PaymentRowX on PaymentRow {
  LocalDate get date => LocalDate.fromEpochDay(dueDay);
  bool get isPaid => paidAt != null;

  /// What this payment adds to "spoken for": its amount, its fee per
  /// payment (22) and its extra fee (21) ([spokenForAmount]). Period
  /// totals, reminders and the amount to keep in an account (18) use it;
  /// the plan's total and card statements (16) use
  /// [PaymentRow.amountMinor].
  int get spokenForMinor => spokenForAmount(
    amountMinor: amountMinor,
    installmentFeeMinor: installmentFeeMinor,
    extraFeeMinor: extraFeeMinor,
  );

  /// The installment shown on rows: its amount plus its fee per payment
  /// (22), without the extra fee (21) ([installmentAmount]).
  int get installmentMinor => installmentAmount(
    amountMinor: amountMinor,
    installmentFeeMinor: installmentFeeMinor,
  );

  FeePayment toFeePayment() => (
    seq: seq,
    isPaid: isPaid,
    paidBeforeKalan: paidBeforeKalan,
    feeMinor: installmentFeeMinor,
  );

  /// The date before "Change date" first moved it (20); null otherwise.
  LocalDate? get originalDate =>
      originalDay == null ? null : LocalDate.fromEpochDay(originalDay!);

  MovablePayment toMovable() => MovablePayment(
    seq: seq,
    date: date,
    isPaid: isPaid,
    originalDate: originalDate,
  );

  PaymentState toState() => PaymentState(
    seq: seq,
    date: date,
    amountMinor: amountMinor,
    isPaid: isPaid,
    isEdited: isEdited,
  );
}

/// A plan with its source and payments ordered by seq.
class PlanWithPayments {
  /// [allPayments] is every stored payment of the plan; [payments] is
  /// derived from it by the plan's status ([countsInTotals]).
  PlanWithPayments({
    required this.plan,
    required this.source,
    required List<PaymentRow> allPayments,
  }) : allPayments = List.unmodifiable(allPayments),
       payments = List.unmodifiable([
         for (final p in allPayments)
           if (countsInTotals(plan.status, isPaid: p.isPaid)) p,
       ]);

  final PlanRow plan;

  /// Null only for a "Pay later" plan saved without one.
  final SourceRow? source;

  /// The payments that count (19): every payment of an open plan; only the
  /// paid ones of a plan on hold or closed. The one place the status rule
  /// is applied: everything that sums money, lists payments by date or
  /// reminds (home, periods, calendar, statements, charges, notifications)
  /// reads this list and so never sees a held or closed payment.
  /// Plan-level screens (the plan, its edit screen, the plan list) read
  /// [allPayments].
  final List<PaymentRow> payments;

  /// Every stored payment, held and closed ones included.
  final List<PaymentRow> allPayments;

  PlanStatus get status => plan.status;
  bool get isOnHold => status == PlanStatus.onHold;
  bool get isClosed => status == PlanStatus.closed;

  /// Unpaid payments left out while the plan is on hold or closed.
  List<PaymentRow> get setAside => [
    for (final p in allPayments)
      if (!p.isPaid && status != PlanStatus.open) p,
  ];

  /// "Still waiting on the return?" is due on [today] (Decision 2).
  bool holdCheckDueOn(LocalDate today) =>
      isOnHold &&
      plan.holdCheckDay != null &&
      holdCheckDue(
        since: LocalDate.fromEpochDay(plan.holdCheckDay!),
        today: today,
      );

  /// Unpaid payments whose date passed while the plan was on hold, after
  /// "Reopen" (Decision 7); 0 otherwise.
  int get passedWhileHeld {
    final since = plan.heldSinceDay;
    final reopened = plan.reopenedDay;
    if (status != PlanStatus.open || since == null || reopened == null) {
      return 0;
    }
    return passedDuringHold(
      payments: [for (final p in allPayments) (date: p.date, isPaid: p.isPaid)],
      heldSince: LocalDate.fromEpochDay(since),
      reopenedOn: LocalDate.fromEpochDay(reopened),
    );
  }

  /// The plan's own name: its title, or its source's name when untitled.
  /// Null for an untitled "Pay later" plan: screens and notifications show
  /// a label in the app language instead ("Pay later · Dec 14", see
  /// `planNameIn`), so it follows a language change.
  String? get ownName {
    final title = plan.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    if (isPayLater) return null;
    return source?.name ?? '';
  }

  /// [ownName], empty for an untitled "Pay later" plan. Screens and
  /// notifications use `planNameIn` / `context.planName` instead.
  String get displayName => ownName ?? '';

  bool get isPayLater => plan.kind == PlanKind.payLater;

  /// The card a card plan belongs to; null for other kinds, even when
  /// their source happens to be a card.
  int? get ownCardId =>
      plan.kind == PlanKind.card && source != null && source!.isCard
      ? source!.id
      : null;

  /// Where an automatic payment is taken from: the chosen source, or a
  /// card plan's own card. Null when the plan is not automatic or nothing
  /// is chosen.
  int? get chargeSourceId => plan.paymentMethod == PaymentMethod.automatic
      ? plan.chargeSourceId ?? ownCardId
      : null;

  /// "Pay later": how the due date was found (null for other kinds).
  PayLaterRule? get payLaterRule =>
      PayLaterRule.from(plan.payLaterRule, plan.payLaterValue);

  /// "Monthly installments" and "Pay in 4": how often the payments
  /// repeat (null for other kinds). Stored empty: the same day each month.
  PaymentInterval? get interval => switch (plan.kind) {
    PlanKind.monthly ||
    PlanKind.payIn4 => PaymentInterval.fromDays(plan.intervalDays),
    _ => null,
  };

  LocalDate? get purchaseDate => plan.purchaseDay == null
      ? null
      : LocalDate.fromEpochDay(plan.purchaseDay!);

  /// A plan is open while any payment is unpaid; then it moves to the
  /// archive. A plan on hold stays open (it counts toward the free limit,
  /// Decision 1); a closed plan is in the archive.
  bool get isOpen => !isClosed && allPayments.any((p) => !p.isPaid);

  int get totalMinor => allPayments.fold(0, (sum, p) => sum + p.amountMinor);

  int get remainingMinor => allPayments
      .where((p) => !p.isPaid)
      .fold(0, (sum, p) => sum + p.amountMinor);

  /// What was paid, paid before Kalan included.
  int get paidMinor => totalMinor - remainingMinor;

  /// The extra fees (21) of the payments that count ([payments]): what
  /// the plan adds to period totals beyond its installments. Never part
  /// of [totalMinor].
  int get extraFeesMinor =>
      payments.fold(0, (sum, p) => sum + (p.extraFeeMinor ?? 0));

  /// The fees per payment (22) of every stored payment: "Payment fees" in
  /// the plan summary, beside [totalMinor] ("Plan amount"), never in it.
  int get installmentFeesMinor =>
      allPayments.fold(0, (sum, p) => sum + (p.installmentFeeMinor ?? 0));

  /// "Total" in the plan summary: the plan amount and its fees per payment.
  int get totalWithFeesMinor => totalMinor + installmentFeesMinor;

  /// What is left to pay on the plan, fees per payment included (22).
  int get remainingWithFeesMinor => allPayments
      .where((p) => !p.isPaid)
      .fold(0, (sum, p) => sum + p.installmentMinor);

  /// What was paid, fees per payment included (22).
  int get paidWithFeesMinor => totalWithFeesMinor - remainingWithFeesMinor;

  /// The plan's fee per payment as typed (22); null for none.
  int? get installmentFee => plan.installmentFeeMinor;

  /// The plan's product price as typed (23); null when not entered.
  int? get productPrice => plan.productPriceMinor;

  /// "Product price" and "Difference" (23), or null when hidden: no price,
  /// a difference of zero or below, a plan on hold or closed (19), or an
  /// old plan added midway whose first payments were never stored. "Total
  /// you repay" is [totalWithFeesMinor]: every payment, paid before Kalan
  /// included, with its fee per payment; extra fees (21) are not in it.
  PriceDifference? get priceDifference =>
      allPayments.isEmpty || allPayments.first.seq != 1
      ? null
      : priceDifferenceOf(
          totalRepaidMinor: totalRepaidMinor([
            for (final p in allPayments)
              (
                amountMinor: p.amountMinor,
                installmentFeeMinor: p.installmentFeeMinor,
              ),
          ]),
          productPriceMinor: productPrice,
          status: status,
        );

  /// Paid before Kalan plus paid in Kalan.
  int get paidCount =>
      (allPayments.isEmpty ? 0 : allPayments.first.seq - 1) +
      allPayments.where((p) => p.isPaid).length;

  /// Payments paid before the plan was added to Kalan: shown only as one
  /// summary line, never one by one.
  List<PaymentRow> get paidBefore => [
    for (final p in allPayments)
      if (p.paidBeforeKalan) p,
  ];

  int get paidBeforeMinor =>
      paidBefore.fold(0, (sum, p) => sum + p.amountMinor);

  /// The payments to list: everything except those paid before Kalan, by
  /// date. A payment moved past the next one keeps its number (20).
  List<PaymentRow> get listedPayments =>
      [
        for (final p in allPayments)
          if (!p.paidBeforeKalan) p,
      ]..sort((a, b) {
        final byDate = a.dueDay.compareTo(b.dueDay);
        return byDate != 0 ? byDate : a.seq.compareTo(b.seq);
      });

  /// Plans added with only their remaining payments (before schema v4) do
  /// not have the earlier ones; they cannot be edited as "underway".
  bool get startsAtFirstPayment =>
      allPayments.isEmpty || allPayments.first.seq == 1;

  /// The earliest unpaid payment by date (a moved payment can pass the
  /// next one, 20).
  PaymentRow? get nextUnpaid {
    PaymentRow? next;
    for (final p in allPayments) {
      if (p.isPaid) continue;
      if (next == null ||
          p.dueDay < next.dueDay ||
          p.dueDay == next.dueDay && p.seq < next.seq) {
        next = p;
      }
    }
    return next;
  }
}

/// A recurring payment with the occurrence days marked as paid.
class RecurringWithMarks {
  const RecurringWithMarks({required this.item, required this.paidDays});

  final RecurringPaymentRow item;
  final Set<int> paidDays;

  LocalDate get start => LocalDate.fromEpochDay(item.startDay);
  LocalDate? get end =>
      item.endDay == null ? null : LocalDate.fromEpochDay(item.endDay!);

  List<LocalDate> occurrences(LocalDate from, LocalDate toExclusive) =>
      recurringOccurrences(
        start: start,
        recurrence: item.recurrence,
        from: from,
        toExclusive: toExclusive,
        endDate: end,
      );
}

/// The "Pay later" rule to offer: the last one used, or 30 days.
PayLaterRule lastPayLaterRuleOf(SettingsRow? settings) =>
    PayLaterRule.from(
      settings?.lastPayLaterRule,
      settings?.lastPayLaterValue,
    ) ??
    defaultPayLaterRule;

/// The amount the add form asks for first: the one typed last, or the
/// total.
AmountEntry lastAmountEntryOf(SettingsRow? settings) =>
    settings?.lastAmountEntry ?? AmountEntry.total;
