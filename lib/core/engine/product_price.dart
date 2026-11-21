import 'plan_draft.dart';
import 'plan_status.dart';

/// Product price (23): the cash price of what was bought, typed by the user
/// with a plan. Display only: it shows how much the plan repays in all and
/// how much more that is than the price. Never part of "left", a period
/// total or a reminder; Kalan never asks for or computes a rate.

/// Whether a plan of [kind] can have a product price: monthly
/// installments, card installments and manual entry. Not "Pay in 4" and
/// not "Pay later".
bool canHaveProductPrice(PlanKind kind) => switch (kind) {
  PlanKind.monthly || PlanKind.card || PlanKind.manual => true,
  PlanKind.payIn4 || PlanKind.payLater => false,
};

/// The price to store: null for an empty or zero price ("not entered").
int? normalizeProductPrice(int? priceMinor) =>
    priceMinor == null || priceMinor <= 0 ? null : priceMinor;

/// A payment as "Total you repay" sees it: its installment amount and its
/// fee per payment (22). Extra fees (21) are not part of it.
typedef RepaidPayment = ({int amountMinor, int? installmentFeeMinor});

/// "Total you repay": every payment of the plan (paid, unpaid and paid
/// before Kalan) with its fee per payment (22). Extra fees (21) added
/// later are never part of it.
int totalRepaidMinor(Iterable<RepaidPayment> payments) => payments.fold(
  0,
  (sum, p) => sum + p.amountMinor + (p.installmentFeeMinor ?? 0),
);

/// The "Product price" and "Difference" rows.
class PriceDifference {
  const PriceDifference({
    required this.totalRepaidMinor,
    required this.productPriceMinor,
  });

  final int totalRepaidMinor;
  final int productPriceMinor;

  /// "Difference": always above zero ([priceDifferenceOf]).
  int get differenceMinor => totalRepaidMinor - productPriceMinor;

  @override
  bool operator ==(Object other) =>
      other is PriceDifference &&
      other.totalRepaidMinor == totalRepaidMinor &&
      other.productPriceMinor == productPriceMinor;

  @override
  int get hashCode => Object.hash(totalRepaidMinor, productPriceMinor);

  @override
  String toString() =>
      'PriceDifference($totalRepaidMinor - $productPriceMinor)';
}

/// The rows to show, or null when they stay hidden: no price entered, a
/// difference of zero or below (no warning either), or a plan on hold or
/// closed (19).
PriceDifference? priceDifferenceOf({
  required int totalRepaidMinor,
  required int? productPriceMinor,
  PlanStatus status = PlanStatus.open,
}) {
  final price = normalizeProductPrice(productPriceMinor);
  if (price == null || status != PlanStatus.open) return null;
  if (totalRepaidMinor - price <= 0) return null;
  return PriceDifference(
    totalRepaidMinor: totalRepaidMinor,
    productPriceMinor: price,
  );
}
