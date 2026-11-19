import '../core/engine/engine.dart';
import 'db/app_database.dart';

extension SourceRowX on SourceRow {
  bool get isCard => kind == SourceKind.card;

  /// Card terms, or null for providers and incomplete cards.
  CardTerms? get cardTerms => isCard && statementDay != null && dueDay != null
      ? CardTerms(
          statementDay: statementDay!,
          dueDay: dueDay!,
          shiftDueToBusinessDay: shiftDueToBusinessDay,
        )
      : null;
}

/// Payments from the start of a plan that are not marked paid in Kalan:
/// the ones "already underway" may cover.
int leadingRunOf(List<PaymentRow> payments) {
  var run = 0;
  for (final p in payments) {
    if (p.isPaid && !p.paidBeforeKalan) break;
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

  /// The payments to list: everything except those paid before Kalan.
  List<PaymentRow> get listedPayments => [
    for (final p in allPayments)
      if (!p.paidBeforeKalan) p,
  ];

  /// Plans added with only their remaining payments (before schema v4) do
  /// not have the earlier ones; they cannot be edited as "underway".
  bool get startsAtFirstPayment =>
      allPayments.isEmpty || allPayments.first.seq == 1;

  PaymentRow? get nextUnpaid {
    for (final p in allPayments) {
      if (!p.isPaid) return p;
    }
    return null;
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
