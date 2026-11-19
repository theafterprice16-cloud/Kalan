import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import 'store_gateway.dart';

/// App Store (StoreKit 2) and Google Play Billing through the official
/// `in_app_purchase` plugin. The only file that imports it.
///
/// Nothing that identifies the user is ever passed to the store: no user
/// name, no account or profile id.
class IapStoreGateway implements StoreGateway {
  IapStoreGateway({InAppPurchase? iap, TargetPlatform? platform})
    : _iap = iap ?? InAppPurchase.instance,
      _platform = platform ?? defaultTargetPlatform;

  /// A store that does not answer in this time counts as unreachable.
  static const queryTimeout = Duration(seconds: 10);

  final InAppPurchase _iap;
  final TargetPlatform _platform;
  ProductDetails? _product;

  bool get _android => _platform == TargetPlatform.android;

  @override
  Stream<List<StoreEvent>> get events => _iap.purchaseStream.map(
    (list) => [
      for (final p in list)
        if (p.productID == proProductId)
          storeEventFrom(p, finishWithoutPro: !_android),
    ],
  );

  @override
  Future<PriceResult> loadPrice() async {
    try {
      if (!await _iap.isAvailable().timeout(queryTimeout)) {
        return const PriceUnavailable();
      }
      final response = await _iap
          .queryProductDetails({proProductId})
          .timeout(queryTimeout);
      final product = response.productDetails
          .where((d) => d.id == proProductId)
          .firstOrNull;
      if (response.error != null || product == null) {
        return const PriceUnavailable();
      }
      _product = product;
      return PriceLoaded(product.price);
    } on Object {
      return const PriceUnavailable();
    }
  }

  @override
  Future<bool> buy() async {
    if (_product == null && await loadPrice() is! PriceLoaded) return false;
    // A non-consumable, bought once. Nothing about the user is passed.
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _product!),
    );
  }

  @override
  Future<OwnershipQuery> queryOwnership() =>
      _guard(() => _android ? _queryPlay() : _queryAppStore(synced: false));

  @override
  Future<OwnershipQuery> restore() => _guard(() async {
    if (_android) return _queryPlay();
    // Asks the App Store for this account's purchases; may ask the user to
    // sign in. After it, the on-device list is the App Store's answer.
    await _iap
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
        .sync();
    return _queryAppStore(synced: true);
  }, timeout: const Duration(minutes: 2));

  @override
  Future<void> complete(StoreToken token) async {
    final details = token.raw;
    if (details is PurchaseDetails && details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  /// Google Play's purchase list for this account. A successful, empty
  /// answer is Play saying "not owned"; a refunded purchase drops out.
  Future<OwnershipQuery> _queryPlay() async {
    if (!await _iap.isAvailable()) {
      return const QueryFailed(FailureKind.unavailable);
    }
    final response = await _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    // The query asks for one-time products and subscriptions together; a
    // failure in either makes an empty answer untrustworthy, but Pro found
    // in the list is still Pro.
    return ownershipFrom(
      authoritative: response.error == null,
      failed: response.error != null,
      records: [
        for (final p in response.pastPurchases)
          (
            productId: p.productID,
            pending: p.status == PurchaseStatus.pending,
            token: StoreToken(p, needsCompletion: p.pendingCompletePurchase),
          ),
      ],
    );
  }

  /// StoreKit 2's current entitlements: refunded and revoked purchases are
  /// left out. Read from the device; without a fresh [restore] sync an
  /// empty list only means "not known here".
  Future<OwnershipQuery> _queryAppStore({required bool synced}) async {
    final entitlements = await SK2Transaction.currentEntitlements();
    return ownershipFrom(
      authoritative: synced,
      records: [
        for (final t in entitlements)
          (
            productId: t.productId,
            pending: false,
            token: StoreToken(
              t,
              needsCompletion: false,
              finishWithoutPro: true,
            ),
          ),
      ],
    );
  }

  Future<OwnershipQuery> _guard(
    Future<OwnershipQuery> Function() query, {
    Duration timeout = queryTimeout,
  }) async {
    try {
      return await query().timeout(timeout);
    } on TimeoutException {
      return const QueryFailed(FailureKind.timeout);
    } on PlatformException catch (e) {
      return QueryFailed(failureKindOf(e.code));
    } on Object {
      return const QueryFailed(FailureKind.unknown);
    }
  }
}

/// One purchase update as Kalan sees it.
StoreEvent storeEventFrom(PurchaseDetails p, {bool finishWithoutPro = false}) {
  final token = StoreToken(
    p,
    needsCompletion: p.pendingCompletePurchase,
    finishWithoutPro: finishWithoutPro,
  );
  return switch (p.status) {
    PurchaseStatus.purchased => StorePurchased(token),
    PurchaseStatus.restored => StorePurchased(token, restored: true),
    PurchaseStatus.pending => const StorePending(),
    PurchaseStatus.canceled => StoreCanceled(token),
    PurchaseStatus.error => StoreFailed(token),
  };
}

/// Only for wording; every failure keeps Pro as it is.
FailureKind failureKindOf(String code) {
  final c = code.toLowerCase();
  if (c.contains('network') || c.contains('offline')) {
    return FailureKind.network;
  }
  if (c.contains('unavailable') || c.contains('disconnected')) {
    return FailureKind.unavailable;
  }
  return FailureKind.unknown;
}
