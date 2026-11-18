/// When Pro turns on and off. The only place these rules are written;
/// `test/entitlement/pro_rules_test.dart` keeps them as a table.
library;

import 'store_gateway.dart';

/// The last known Pro state, kept on the device.
enum ProStatus {
  notPro,

  /// Bought, waiting for payment approval (Ask to Buy, cash payment).
  /// Not Pro yet.
  pending,
  pro,
}

/// What a store answer does to the stored state.
enum ProVerdict { grant, markPending, keep, revoke }

/// Pro is removed only on the store's explicit word: a successful query
/// that says the product is not owned, refunded or revoked. No answer
/// (offline, time-out, store unreachable, an error) and an answer that
/// cannot tell keep the state as it is.
ProVerdict verdictFor(OwnershipQuery query) => switch (query) {
  Owned() => ProVerdict.grant,
  OwnedPending() => ProVerdict.markPending,
  NotOwned() || Revoked() => ProVerdict.revoke,
  Inconclusive() || QueryFailed() => ProVerdict.keep,
};

ProStatus applyVerdict(ProStatus status, ProVerdict verdict) =>
    switch (verdict) {
      ProVerdict.grant => ProStatus.pro,
      // A pending payment never takes away Pro already owned.
      ProVerdict.markPending =>
        status == ProStatus.pro ? ProStatus.pro : ProStatus.pending,
      ProVerdict.keep => status,
      ProVerdict.revoke => ProStatus.notPro,
    };

/// The stored state after a store answer. A pending payment is not Pro,
/// so an answer that cannot see it (the App Store after a declined Ask to
/// Buy, which sends no event) clears it instead of keeping it forever.
ProStatus statusAfter(ProStatus status, OwnershipQuery query) =>
    status == ProStatus.pending && query is Inconclusive
    ? ProStatus.notPro
    : applyVerdict(status, verdictFor(query));
