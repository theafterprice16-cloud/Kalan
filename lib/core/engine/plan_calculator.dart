import '../date/local_date.dart';
import 'pay_later.dart';
import 'plan_draft.dart';
import 'schedule.dart';
import 'split.dart';

/// Thrown when plan inputs cannot produce a valid schedule.
class InvalidPlanInput implements Exception {
  const InvalidPlanInput(this.field);

  /// Name of the offending input.
  final String field;

  @override
  String toString() => 'InvalidPlanInput($field)';
}

/// Builds [PlanDraft]s from user inputs. Pure and deterministic.
abstract final class PlanCalculator {
  static const maxInstallments = 120;

  static void _checkTotal(int totalMinor, int count) {
    if (count < 1 || count > maxInstallments) {
      throw const InvalidPlanInput('count');
    }
    if (totalMinor < count) throw const InvalidPlanInput('total');
  }

  static List<DraftPayment> _zip(
    List<LocalDate> dates,
    List<int> amounts, {
    int firstSeq = 1,
  }) => [
    for (var i = 0; i < dates.length; i++)
      DraftPayment(seq: firstSeq + i, date: dates[i], amountMinor: amounts[i]),
  ];

  /// Pay in 4: four payments, two weeks apart, first one on [firstDate].
  static PlanDraft payIn4({
    required LocalDate firstDate,
    required int totalMinor,
  }) {
    _checkTotal(totalMinor, 4);
    return PlanDraft(
      kind: PlanKind.payIn4,
      installmentCount: 4,
      payments: _zip(payIn4Dates(firstDate), splitEvenly(totalMinor, 4)),
    );
  }

  /// Monthly installments on the same day each month.
  static PlanDraft monthly({
    required LocalDate firstDate,
    required int totalMinor,
    required int count,
  }) {
    _checkTotal(totalMinor, count);
    return PlanDraft(
      kind: PlanKind.monthly,
      installmentCount: count,
      payments: _zip(
        monthlyDates(firstDate, count),
        splitEvenly(totalMinor, count),
      ),
    );
  }

  /// Credit card installments placed on statements by purchase date.
  static PlanDraft card({
    required LocalDate purchaseDate,
    required int totalMinor,
    required int count,
    required CardTerms terms,
    int deferMonths = 0,
    bool isCashAdvance = false,
  }) {
    _checkTotal(totalMinor, count);
    if (deferMonths < 0 || deferMonths > 12) {
      throw const InvalidPlanInput('deferMonths');
    }
    return PlanDraft(
      kind: PlanKind.card,
      installmentCount: count,
      purchaseDate: purchaseDate,
      deferMonths: deferMonths,
      isCashAdvance: isCashAdvance,
      payments: _zip(
        cardInstallmentDates(
          purchaseDate: purchaseDate,
          terms: terms,
          count: count,
          deferMonths: deferMonths,
        ),
        splitEvenly(totalMinor, count),
      ),
    );
  }

  /// "Pay later": one payment of [totalMinor] on the due date [rule] gives
  /// for [purchaseDate] ([chosenDate] for a picked date).
  static PlanDraft payLater({
    required LocalDate purchaseDate,
    required PayLaterRule rule,
    required int totalMinor,
    LocalDate? chosenDate,
  }) {
    _checkTotal(totalMinor, 1);
    final due = payLaterDueDate(
      purchase: purchaseDate,
      rule: rule,
      chosen: chosenDate,
    );
    return PlanDraft(
      kind: PlanKind.payLater,
      installmentCount: 1,
      payments: [DraftPayment(seq: 1, date: due, amountMinor: totalMinor)],
      purchaseDate: purchaseDate,
      payLaterRule: rule,
    );
  }

  /// Free-form: any count, every [step] [unit]s.
  static PlanDraft manual({
    required LocalDate firstDate,
    required int totalMinor,
    required int count,
    required IntervalUnit unit,
    int step = 1,
  }) {
    _checkTotal(totalMinor, count);
    if (step < 1 || step > 365) throw const InvalidPlanInput('step');
    return PlanDraft(
      kind: PlanKind.manual,
      installmentCount: count,
      payments: _zip(
        intervalDates(firstDate, count, unit: unit, step: step),
        splitEvenly(totalMinor, count),
      ),
    );
  }

  /// A plan already in progress: only the remaining payments are tracked.
  ///
  /// With [cardTerms], later payments follow the card's due day; otherwise
  /// they repeat every [step] [unit]s from [nextDate].
  static PlanDraft midway({
    required int totalCount,
    required int remainingCount,
    required int installmentMinor,
    required LocalDate nextDate,
    IntervalUnit unit = IntervalUnit.month,
    int step = 1,
    CardTerms? cardTerms,
  }) {
    if (totalCount < 1 || totalCount > maxInstallments) {
      throw const InvalidPlanInput('totalCount');
    }
    if (remainingCount < 1 || remainingCount > totalCount) {
      throw const InvalidPlanInput('remainingCount');
    }
    if (installmentMinor < 1) throw const InvalidPlanInput('installment');
    if (step < 1 || step > 365) throw const InvalidPlanInput('step');

    final dates = cardTerms != null
        ? cardDatesFromNextDue(
            nextDue: nextDate,
            terms: cardTerms,
            count: remainingCount,
          )
        : intervalDates(nextDate, remainingCount, unit: unit, step: step);
    final kind = cardTerms != null
        ? PlanKind.card
        : unit == IntervalUnit.month && step == 1
        ? PlanKind.monthly
        : PlanKind.manual;
    return PlanDraft(
      kind: kind,
      installmentCount: totalCount,
      payments: _zip(
        dates,
        List.filled(remainingCount, installmentMinor),
        firstSeq: totalCount - remainingCount + 1,
      ),
    );
  }

  /// New dates for a card plan after the card's days changed. Returns one
  /// date per tracked seq, keyed by seq.
  ///
  /// Plans with a purchase date are rebuilt from it. Plans started midway
  /// keep their first tracked payment's month as the anchor.
  static Map<int, LocalDate> recomputeCardDates({
    required List<DraftPayment> payments,
    required int installmentCount,
    required CardTerms oldTerms,
    required CardTerms newTerms,
    LocalDate? purchaseDate,
    int deferMonths = 0,
  }) {
    if (payments.isEmpty) return const {};
    if (purchaseDate != null) {
      final dates = cardInstallmentDates(
        purchaseDate: purchaseDate,
        terms: newTerms,
        count: installmentCount,
        deferMonths: deferMonths,
      );
      return {for (final p in payments) p.seq: dates[p.seq - 1]};
    }
    final first = payments.first;
    final base = dueMonthOf(first.date, oldTerms);
    return {
      for (final p in payments)
        p.seq: newTerms.dueInMonth(base.year, base.month + p.seq - first.seq),
    };
  }
}
