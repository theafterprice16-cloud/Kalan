import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/engine/engine.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../holidays/holiday_providers.dart';

/// A card's coming statements from the engine ([cardStatements]), with the
/// plans their installments belong to.
class CardStatementsView {
  const CardStatementsView({
    required this.card,
    required this.statements,
    required this.plans,
  });

  final SourceRow card;
  final List<CardStatement> statements;

  /// The card's card plans by id.
  final Map<int, PlanWithPayments> plans;

  /// The statement cut on [statementDate], or null when it is not one of
  /// the coming ones (any more).
  CardStatement? statementOn(LocalDate statementDate) {
    for (final s in statements) {
      if (s.statementDate == statementDate) return s;
    }
    return null;
  }
}

/// [card]'s next statement and the five after it. Only the card's own card
/// plans count (decision 3): any other plan paid from the card (a
/// "Pay later" plan taken from it) is not on a statement here. Paid
/// installments count too (decision 4).
///
/// Null for a provider, a card without its days, or a card none of whose
/// coming statements has an installment: the section is not shown
/// (decision 10).
CardStatementsView? cardStatementsOf({
  required SourceRow card,
  required Iterable<PlanWithPayments> plans,
  required LocalDate today,
  HolidayCalendar? holidays,
}) {
  final terms = card.cardTermsIn(holidays);
  if (terms == null) return null;
  final own = {
    for (final p in plans)
      if (p.ownCardId == card.id) p.plan.id: p,
  };
  final statements = cardStatements(
    terms: terms,
    today: today,
    installments: [
      for (final p in own.values)
        for (final pay in p.payments)
          StatementInstallment(
            paymentId: pay.id,
            planId: p.plan.id,
            seq: pay.seq,
            installmentCount: p.plan.installmentCount,
            amountMinor: pay.amountMinor,
            dueDate: pay.date,
            isPaid: pay.isPaid,
            paidBeforeKalan: pay.paidBeforeKalan,
          ),
    ],
  );
  if (statements.every((s) => s.isEmpty)) return null;
  return CardStatementsView(card: card, statements: statements, plans: own);
}

/// [cardStatementsOf] for the card with this id, following plans,
/// payments, the card's days and the day.
final cardStatementsProvider = Provider.family<CardStatementsView?, int>((
  ref,
  cardId,
) {
  final sources = ref.watch(sourcesProvider).value;
  final plans = ref.watch(plansProvider).value;
  if (sources == null || plans == null) return null;
  for (final s in sources) {
    if (s.id == cardId) {
      return cardStatementsOf(
        card: s,
        plans: plans,
        today: ref.watch(todayProvider),
        holidays: ref.watch(appliedHolidaysProvider),
      );
    }
  }
  return null;
});
