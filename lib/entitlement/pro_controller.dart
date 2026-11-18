import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pro_rules.dart';
import 'pro_status_store.dart';
import 'store_gateway.dart';

/// Overridden in main() with the App Store / Google Play gateway on phones.
final storeGatewayProvider = Provider<StoreGateway>(
  (ref) => const UnavailableStoreGateway(),
);

/// Overridden in main() with [PrefsProStatusStore].
final proStatusStoreProvider = Provider<ProStatusStore>(
  (ref) => MemoryProStatusStore(),
);

/// Pro state for the whole app. Started with the app so purchases that
/// finish outside a Pro screen (Ask to Buy, an interrupted purchase) are
/// saved and acknowledged.
final proControllerProvider = NotifierProvider<ProController, ProState>(
  ProController.new,
);

/// The store's localized price. `ref.invalidate` tries again.
final proPriceProvider = FutureProvider.autoDispose<PriceResult>((ref) async {
  try {
    return await ref.watch(storeGatewayProvider).loadPrice();
  } on Object {
    return const PriceUnavailable();
  }
});

enum ProBusy { none, buying, restoring }

class ProState {
  const ProState(this.status, {this.busy = ProBusy.none});

  final ProStatus status;
  final ProBusy busy;

  ProState copyWith({ProStatus? status, ProBusy? busy}) =>
      ProState(status ?? this.status, busy: busy ?? this.busy);

  @override
  bool operator ==(Object other) =>
      other is ProState && other.status == status && other.busy == busy;

  @override
  int get hashCode => Object.hash(status, busy);
}

/// What a tap on "Get Pro" or "Restore purchase" ended with.
enum PurchaseOutcome {
  unlocked,
  pending,

  /// Closed by the user; shown as nothing.
  canceled,
  failed,

  /// Restore: the store answered and this account has no Pro.
  notFound,

  /// Restore: no answer from the store. Pro is left as it was.
  unreachable,
}

class ProController extends Notifier<ProState> {
  /// How long "Get Pro" waits for the store before the button is free
  /// again. A late answer still arrives and is handled.
  static const purchaseWait = Duration(minutes: 2);

  late ProStatusStore _store;
  late StoreGateway _gateway;
  Completer<PurchaseOutcome>? _purchase;
  Timer? _purchaseTimer;

  /// Store updates are handled one batch at a time, in order.
  Future<void> _events = Future.value();

  /// Counts purchases saved here. A store answer that started before one
  /// of them is out of date and never takes Pro away.
  int _grants = 0;

  @override
  ProState build() {
    _store = ref.watch(proStatusStoreProvider);
    _gateway = ref.watch(storeGatewayProvider);
    final events = _gateway.events.listen(
      (list) => _events = _events.then((_) => _onEvents(list)),
      onError: (Object _) {},
    );
    ref.onDispose(() {
      unawaited(events.cancel());
      _purchaseTimer?.cancel();
      final purchase = _purchase;
      _purchase = null;
      if (purchase != null && !purchase.isCompleted) {
        purchase.complete(PurchaseOutcome.canceled);
      }
    });
    // The stored state counts right away, offline too; the store is asked
    // in the background.
    scheduleMicrotask(() => unawaited(_check()));
    return ProState(_store.read());
  }

  /// Back in the foreground: ask the store again. Acknowledges a purchase
  /// whose acknowledgement failed earlier; never shows anything.
  Future<void> recheck() async {
    if (state.busy != ProBusy.none) return;
    await _check();
  }

  /// Opens the store's purchase sheet. Null when a purchase or restore is
  /// already running.
  Future<PurchaseOutcome?> buy() async {
    if (state.busy != ProBusy.none) return null;
    if (state.status == ProStatus.pro) return PurchaseOutcome.unlocked;
    final purchase = _purchase = Completer<PurchaseOutcome>();
    state = state.copyWith(busy: ProBusy.buying);
    _purchaseTimer = Timer(
      purchaseWait,
      () => _endPurchase(PurchaseOutcome.canceled),
    );
    var started = false;
    try {
      started = await _gateway.buy();
    } on Object {
      started = false;
    }
    if (!started) _endPurchase(PurchaseOutcome.failed);
    return purchase.future;
  }

  /// "Restore purchase". Null when something is already running.
  Future<PurchaseOutcome?> restore() async {
    if (state.busy != ProBusy.none) return null;
    state = state.copyWith(busy: ProBusy.restoring);
    final grants = _grants;
    OwnershipQuery query;
    try {
      query = await _gateway.restore();
    } on Object {
      query = const QueryFailed(FailureKind.unknown);
    }
    await _apply(query, grantsBefore: grants);
    if (!ref.mounted) return null;
    state = state.copyWith(busy: ProBusy.none);
    return switch (query) {
      Owned() => PurchaseOutcome.unlocked,
      OwnedPending() => PurchaseOutcome.pending,
      NotOwned() || Revoked() => PurchaseOutcome.notFound,
      Inconclusive() =>
        state.status == ProStatus.pro
            ? PurchaseOutcome.unlocked
            : PurchaseOutcome.notFound,
      QueryFailed() => PurchaseOutcome.unreachable,
    };
  }

  /// Background check at start, on resume, and after a store update that
  /// did not come from a purchase started here.
  Future<OwnershipQuery> _check() async {
    final grants = _grants;
    OwnershipQuery query;
    try {
      query = await _gateway.queryOwnership();
    } on Object {
      query = const QueryFailed(FailureKind.unknown);
    }
    await _apply(query, grantsBefore: grants);
    return query;
  }

  /// Saves the verdict, then acknowledges what the store listed. Saving
  /// comes first so a crash in between never loses a paid purchase.
  Future<void> _apply(OwnershipQuery query, {required int grantsBefore}) async {
    if (!ref.mounted) return;
    final next = statusAfter(state.status, query);
    final outdated = _grants != grantsBefore && next != ProStatus.pro;
    if (!outdated) await _save(next);
    if (query is Owned) {
      for (final token in query.tokens) {
        await _complete(token);
      }
    }
  }

  Future<void> _onEvents(List<StoreEvent> events) async {
    for (final event in events) {
      if (!ref.mounted) return;
      switch (event) {
        case StorePurchased(:final token):
          if (_purchase != null) {
            // The purchase started from the Pro screen: saved first, the
            // screen told, then acknowledged.
            await _save(ProStatus.pro);
            _grants++;
            _endPurchase(PurchaseOutcome.unlocked);
            await _complete(token);
          } else {
            // From outside (approval, family sharing, a store update):
            // the store's own list decides. A refund on the App Store
            // also arrives here, so it is never taken as a purchase.
            final query = await _check();
            if (!ref.mounted) return;
            final answered = query is! QueryFailed;
            if (state.status == ProStatus.pro ||
                (answered && token.finishWithoutPro)) {
              await _complete(token);
            }
          }
        case StorePending():
          await _save(applyVerdict(state.status, ProVerdict.markPending));
          _endPurchase(PurchaseOutcome.pending);
        case StoreCanceled(:final token):
          if (token != null) await _complete(token);
          _endPurchase(PurchaseOutcome.canceled);
        case StoreFailed(:final token):
          if (token != null) await _complete(token);
          if (_purchase != null) {
            // "Already owned" arrives as an error: the store's list
            // decides whether this is Pro after all.
            await _check();
            if (!ref.mounted) return;
            _endPurchase(
              state.status == ProStatus.pro
                  ? PurchaseOutcome.unlocked
                  : PurchaseOutcome.failed,
            );
          }
      }
    }
  }

  Future<void> _save(ProStatus status) async {
    if (!ref.mounted || status == state.status) return;
    await _store.write(status);
    if (ref.mounted) state = state.copyWith(status: status);
  }

  Future<void> _complete(StoreToken token) async {
    if (!token.needsCompletion) return;
    try {
      await _gateway.complete(token);
    } on Object {
      // Tried again by the next check (start or back in the foreground).
    }
  }

  void _endPurchase(PurchaseOutcome outcome) {
    final purchase = _purchase;
    if (purchase == null) return;
    _purchase = null;
    _purchaseTimer?.cancel();
    _purchaseTimer = null;
    if (!purchase.isCompleted) purchase.complete(outcome);
    if (ref.mounted) state = state.copyWith(busy: ProBusy.none);
  }
}
