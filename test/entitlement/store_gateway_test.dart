import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kalan/entitlement/entitlement.dart';
import 'package:kalan/entitlement/iap_store_gateway.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/entitlement/store_gateway.dart';

StoreRecord record(String id, {bool pending = false}) => (
  productId: id,
  pending: pending,
  token: StoreToken(id, needsCompletion: true),
);

PurchaseDetails details(PurchaseStatus status, {String id = proProductId}) =>
    PurchaseDetails(
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    );

void main() {
  group('ownershipFrom', () {
    test('Pro listed: owned, with its token', () {
      final q = ownershipFrom(
        authoritative: true,
        records: [record('other'), record(proProductId)],
      );
      expect(q, isA<Owned>());
      expect((q as Owned).tokens.single.raw, proProductId);
    });

    test('Pro listed but waiting for payment: pending', () {
      expect(
        ownershipFrom(
          authoritative: true,
          records: [record(proProductId, pending: true)],
        ),
        isA<OwnedPending>(),
      );
    });

    test('Google Play, successful and empty: not owned', () {
      expect(
        ownershipFrom(authoritative: true, records: [record('other')]),
        isA<NotOwned>(),
      );
    });

    test('partly failed query: Pro found counts, an empty list does not', () {
      expect(
        ownershipFrom(
          authoritative: false,
          failed: true,
          records: [record(proProductId)],
        ),
        isA<Owned>(),
      );
      expect(
        ownershipFrom(authoritative: false, failed: true, records: const []),
        isA<QueryFailed>(),
      );
    });

    test('App Store cache without a sync: never "not owned"', () {
      expect(
        ownershipFrom(authoritative: false, records: const []),
        isA<Inconclusive>(),
      );
    });
  });

  group('storeEventFrom', () {
    test('maps every purchase status', () {
      expect(
        storeEventFrom(details(PurchaseStatus.purchased)),
        isA<StorePurchased>(),
      );
      final restored = storeEventFrom(details(PurchaseStatus.restored));
      expect(restored, isA<StorePurchased>());
      expect((restored as StorePurchased).restored, isTrue);
      expect(
        storeEventFrom(details(PurchaseStatus.pending)),
        isA<StorePending>(),
      );
      expect(
        storeEventFrom(details(PurchaseStatus.canceled)),
        isA<StoreCanceled>(),
      );
      expect(storeEventFrom(details(PurchaseStatus.error)), isA<StoreFailed>());
    });
  });

  test('failure codes are only wording', () {
    expect(failureKindOf('BillingResponse.networkError'), FailureKind.network);
    expect(failureKindOf('serviceUnavailable'), FailureKind.unavailable);
    expect(failureKindOf('storekit2_failed'), FailureKind.unknown);
  });

  test('the store that is not there never changes Pro', () async {
    const store = UnavailableStoreGateway();
    expect(verdictFor(await store.queryOwnership()), ProVerdict.keep);
    expect(verdictFor(await store.restore()), ProVerdict.keep);
    expect(await store.loadPrice(), isA<PriceUnavailable>());
    expect(await store.buy(), isFalse);
  });

  group('KalanEntitlement', () {
    test('Pro from the store', () {
      expect(
        const KalanEntitlement(
          status: ProStatus.pro,
          debugProSwitch: false,
        ).isPro,
        isTrue,
      );
      expect(
        const KalanEntitlement(
          status: ProStatus.pending,
          debugProSwitch: false,
        ).isPro,
        isFalse,
      );
    });

    test('the debug switch does nothing in a release build', () {
      expect(
        const KalanEntitlement(
          status: ProStatus.notPro,
          debugProSwitch: true,
          debugBuild: false,
        ).isPro,
        isFalse,
      );
      expect(
        const KalanEntitlement(
          status: ProStatus.notPro,
          debugProSwitch: true,
          debugBuild: true,
        ).isPro,
        isTrue,
      );
    });

    test('free limit: four open plans', () {
      const free = KalanEntitlement(
        status: ProStatus.notPro,
        debugProSwitch: false,
      );
      expect(canAddPlan(openPlans: 3, entitlement: free), isTrue);
      expect(canAddPlan(openPlans: 4, entitlement: free), isFalse);
      const pro = KalanEntitlement(
        status: ProStatus.pro,
        debugProSwitch: false,
      );
      expect(canAddPlan(openPlans: 6, entitlement: pro), isTrue);
    });
  });

  test('stored names: unreadable counts as free', () {
    for (final s in ProStatus.values) {
      expect(proStatusFromName(s.name), s);
    }
    expect(proStatusFromName(null), ProStatus.notPro);
    expect(proStatusFromName('gold'), ProStatus.notPro);
  });
}
