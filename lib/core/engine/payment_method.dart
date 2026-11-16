/// How a plan's payments are paid. Kalan never pays and never checks a
/// payment; this is only what the user told it. A plan without one
/// ("not set", null) behaves exactly as before the choice existed.
enum PaymentMethod {
  /// Taken automatically (card, direct debit): the money must be there.
  automatic,

  /// The user pays it themselves (store, transfer, ATM): they must
  /// remember to pay.
  manual,
}
