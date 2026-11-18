/// The store as Kalan sees it: one lifetime product, no user identity.
///
/// Pure Dart. The only implementation that talks to App Store / Google
/// Play is `iap_store_gateway.dart`; screens and tests never touch the
/// store package.
library;

/// The one Pro product, the same on App Store and Google Play. Not tied to
/// the app's bundle identifier, which may still change.
const proProductId = 'kalan_pro_lifetime';

/// A store purchase that may still need acknowledging. Opaque outside the
/// gateway that created it.
class StoreToken {
  const StoreToken(this.raw, {required this.needsCompletion});

  final Object raw;

  /// Google Play refunds an unacknowledged purchase after three days and
  /// the App Store keeps re-delivering an unfinished one.
  final bool needsCompletion;
}

/// What the store reported about the Pro product, in the order it came.
sealed class StoreEvent {
  const StoreEvent();
}

/// Bought, or delivered again by the store (restore, Ask to Buy approved,
/// family sharing, an update from outside the app).
final class StorePurchased extends StoreEvent {
  const StorePurchased(this.token, {this.restored = false});

  final StoreToken token;
  final bool restored;
}

/// Waiting for payment approval (Ask to Buy, cash payment, ...).
final class StorePending extends StoreEvent {
  const StorePending();
}

/// The user closed the store sheet. Not an error.
final class StoreCanceled extends StoreEvent {
  const StoreCanceled([this.token]);

  final StoreToken? token;
}

final class StoreFailed extends StoreEvent {
  const StoreFailed([this.token]);

  final StoreToken? token;
}

sealed class PriceResult {
  const PriceResult();
}

/// The store's own localized price, shown as it is.
final class PriceLoaded extends PriceResult {
  const PriceLoaded(this.price);

  final String price;
}

final class PriceUnavailable extends PriceResult {
  const PriceUnavailable();
}

/// Why a store query did not give an answer.
enum FailureKind { network, timeout, unavailable, unknown }

/// The answer to "does this store account own Pro?".
sealed class OwnershipQuery {
  const OwnershipQuery();
}

/// A successful query that lists Pro.
final class Owned extends OwnershipQuery {
  const Owned([this.tokens = const []]);

  final List<StoreToken> tokens;
}

/// A successful query that lists Pro, still waiting for payment.
final class OwnedPending extends OwnershipQuery {
  const OwnedPending();
}

/// A successful, authoritative query that does not list Pro.
final class NotOwned extends OwnershipQuery {
  const NotOwned();
}

/// A successful query that says Pro was refunded or revoked.
final class Revoked extends OwnershipQuery {
  const Revoked();
}

/// The query worked but cannot tell "not owned" apart from "not known
/// here" (the App Store's on-device cache before a sync).
final class Inconclusive extends OwnershipQuery {
  const Inconclusive();
}

/// No answer: offline, timed out, store unavailable or an error.
final class QueryFailed extends OwnershipQuery {
  const QueryFailed(this.kind);

  final FailureKind kind;
}

/// One purchase as a store query lists it.
typedef StoreRecord = ({String productId, bool pending, StoreToken token});

/// Turns a finished store query into an [OwnershipQuery]. [authoritative]
/// is true only when an empty answer really means "not owned" (Google
/// Play's purchase query, or the App Store right after a successful sync).
OwnershipQuery ownershipFrom({
  required bool authoritative,
  required List<StoreRecord> records,
}) {
  final pro = records.where((r) => r.productId == proProductId).toList();
  final owned = pro.where((r) => !r.pending).toList();
  if (owned.isNotEmpty) return Owned([for (final r in owned) r.token]);
  if (pro.isNotEmpty) return const OwnedPending();
  return authoritative ? const NotOwned() : const Inconclusive();
}

/// App Store / Google Play behind one small interface. No method takes or
/// sends anything that identifies the user.
abstract interface class StoreGateway {
  /// Purchase updates, including ones that started outside the app.
  Stream<List<StoreEvent>> get events;

  Future<PriceResult> loadPrice();

  /// Opens the store's purchase sheet. False when it could not open; the
  /// outcome otherwise arrives on [events].
  Future<bool> buy();

  /// A quiet check at app start. Never asks the user to sign in.
  Future<OwnershipQuery> queryOwnership();

  /// "Restore purchase": may ask the user to sign in to the store.
  Future<OwnershipQuery> restore();

  /// Acknowledges a purchase once Pro has been saved on the device.
  Future<void> complete(StoreToken token);
}

/// Web, desktop and tests: no store. Queries fail, so Pro never changes.
class UnavailableStoreGateway implements StoreGateway {
  const UnavailableStoreGateway();

  @override
  Stream<List<StoreEvent>> get events => const Stream.empty();

  @override
  Future<PriceResult> loadPrice() async => const PriceUnavailable();

  @override
  Future<bool> buy() async => false;

  @override
  Future<OwnershipQuery> queryOwnership() async =>
      const QueryFailed(FailureKind.unavailable);

  @override
  Future<OwnershipQuery> restore() async =>
      const QueryFailed(FailureKind.unavailable);

  @override
  Future<void> complete(StoreToken token) async {}
}
