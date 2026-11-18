import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/entitlement/pro_controller.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/store_gateway.dart';

import '../helpers/fake_store.dart';

void main() {
  late List<String> log;
  late FakeStoreGateway store;
  late LoggingProStatusStore saved;

  ProviderContainer start([ProStatus stored = ProStatus.notPro]) {
    saved.status = stored;
    final container = ProviderContainer.test(
      overrides: [
        storeGatewayProvider.overrideWithValue(store),
        proStatusStoreProvider.overrideWithValue(saved),
      ],
    );
    container.read(proControllerProvider);
    return container;
  }

  setUp(() {
    log = [];
    store = FakeStoreGateway(log: log);
    saved = LoggingProStatusStore(log);
  });

  ProStatus status(ProviderContainer c) => c.read(proControllerProvider).status;

  group('start', () {
    test('stored Pro counts at once, while the store never answers', () async {
      store.hangingQuery = Completer();
      final c = start(ProStatus.pro);
      expect(status(c), ProStatus.pro);
      await pumpEventQueue();
      expect(status(c), ProStatus.pro);
    });

    test('offline or time-out at start: Pro stays', () async {
      for (final kind in FailureKind.values) {
        store.ownership = QueryFailed(kind);
        final c = start(ProStatus.pro);
        await pumpEventQueue();
        expect(status(c), ProStatus.pro, reason: kind.name);
        c.dispose();
      }
    });

    test('store says refunded: Pro is removed and saved', () async {
      store.ownership = const Revoked();
      final c = start(ProStatus.pro);
      await pumpEventQueue();
      expect(status(c), ProStatus.notPro);
      expect(saved.status, ProStatus.notPro);
    });

    test('store says not owned: Pro is removed', () async {
      store.ownership = const NotOwned();
      final c = start(ProStatus.pro);
      await pumpEventQueue();
      expect(status(c), ProStatus.notPro);
    });

    test('an unacknowledged purchase is saved, then acknowledged', () async {
      store.ownership = const Owned([
        StoreToken('old', needsCompletion: true),
        StoreToken('done', needsCompletion: false),
      ]);
      final c = start();
      await pumpEventQueue();
      expect(status(c), ProStatus.pro);
      expect(log, ['query', 'save pro', 'complete old']);
    });
  });

  group('buy', () {
    test('purchased: saved before it is acknowledged', () async {
      final c = start();
      await pumpEventQueue();
      log.clear();
      final outcome = await c.read(proControllerProvider.notifier).buy();
      expect(outcome, PurchaseOutcome.unlocked);
      expect(status(c), ProStatus.pro);
      expect(log, ['buy', 'save pro', 'complete purchase']);
      expect(c.read(proControllerProvider).busy, ProBusy.none);
    });

    test('canceled: quiet, nothing changes', () async {
      store.afterBuy = [const StoreCanceled()];
      final c = start();
      await pumpEventQueue();
      final outcome = await c.read(proControllerProvider.notifier).buy();
      expect(outcome, PurchaseOutcome.canceled);
      expect(status(c), ProStatus.notPro);
    });

    test('error: failed, and the store transaction is closed', () async {
      store.afterBuy = [
        const StoreFailed(StoreToken('broken', needsCompletion: true)),
      ];
      final c = start();
      await pumpEventQueue();
      final outcome = await c.read(proControllerProvider.notifier).buy();
      expect(outcome, PurchaseOutcome.failed);
      expect(status(c), ProStatus.notPro);
      expect(log, contains('complete broken'));
    });

    test('store sheet does not open: failed', () async {
      store.buyOpens = false;
      final c = start();
      await pumpEventQueue();
      expect(
        await c.read(proControllerProvider.notifier).buy(),
        PurchaseOutcome.failed,
      );
      expect(c.read(proControllerProvider).busy, ProBusy.none);
    });

    test('pending, then approved later: Pro', () async {
      store.afterBuy = [const StorePending()];
      final c = start();
      await pumpEventQueue();
      final outcome = await c.read(proControllerProvider.notifier).buy();
      expect(outcome, PurchaseOutcome.pending);
      expect(status(c), ProStatus.pending);
      expect(saved.status, ProStatus.pending);

      // Approved while the app is open: the store's list decides.
      store.ownership = const Owned([
        StoreToken('approved', needsCompletion: true),
      ]);
      store.emit([
        const StorePurchased(StoreToken('approved', needsCompletion: true)),
      ]);
      await pumpEventQueue();
      expect(status(c), ProStatus.pro);
      expect(log, contains('complete approved'));
    });

    test('an update from outside is checked against the store', () async {
      // An App Store refund arrives as a "purchased" update.
      store.ownership = const Inconclusive();
      final c = start();
      await pumpEventQueue();
      store.emit([
        const StorePurchased(StoreToken('refund', needsCompletion: true)),
      ]);
      await pumpEventQueue();
      expect(status(c), ProStatus.notPro);
      expect(log, isNot(contains('complete refund')));
    });

    test('a second tap while buying is ignored', () async {
      store.afterBuy = null;
      final c = start();
      await pumpEventQueue();
      final notifier = c.read(proControllerProvider.notifier);
      final first = notifier.buy();
      await pumpEventQueue();
      expect(c.read(proControllerProvider).busy, ProBusy.buying);
      expect(await notifier.buy(), isNull);
      expect(store.buyCalls, 1);
      store.emit([
        const StorePurchased(StoreToken('late', needsCompletion: true)),
      ]);
      expect(await first, PurchaseOutcome.unlocked);
    });
  });

  group('restore', () {
    test('found: Pro is on', () async {
      store.restoreAnswer = const Owned();
      final c = start();
      await pumpEventQueue();
      expect(
        await c.read(proControllerProvider.notifier).restore(),
        PurchaseOutcome.unlocked,
      );
      expect(status(c), ProStatus.pro);
    });

    test('not found on this account', () async {
      store.restoreAnswer = const NotOwned();
      final c = start();
      await pumpEventQueue();
      expect(
        await c.read(proControllerProvider.notifier).restore(),
        PurchaseOutcome.notFound,
      );
      expect(status(c), ProStatus.notPro);
    });

    test('store unreachable: Pro stays as it was', () async {
      store.restoreAnswer = const QueryFailed(FailureKind.network);
      final c = start(ProStatus.pro);
      await pumpEventQueue();
      expect(
        await c.read(proControllerProvider.notifier).restore(),
        PurchaseOutcome.unreachable,
      );
      expect(status(c), ProStatus.pro);
    });
  });
}
