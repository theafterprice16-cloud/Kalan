import 'dart:async';

import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/pro_status_store.dart';
import 'package:kalan/entitlement/store_gateway.dart';

/// A store that answers what the test says. Every call is logged in
/// [log], shared with [LoggingProStatusStore] to check the order.
class FakeStoreGateway implements StoreGateway {
  FakeStoreGateway({List<String>? log}) : log = log ?? [];

  final List<String> log;
  final _events = StreamController<List<StoreEvent>>.broadcast();

  PriceResult price = const PriceLoaded('249,99 ₺');
  OwnershipQuery ownership = const QueryFailed(FailureKind.network);
  OwnershipQuery restoreAnswer = const NotOwned();

  /// Never answers the start-up check while set.
  Completer<OwnershipQuery>? hangingQuery;

  /// Sent on [events] right after [buy]; null sends nothing.
  List<StoreEvent>? afterBuy = [
    const StorePurchased(StoreToken('purchase', needsCompletion: true)),
  ];
  bool buyOpens = true;
  int buyCalls = 0;
  int priceCalls = 0;

  void emit(List<StoreEvent> events) => _events.add(events);

  @override
  Stream<List<StoreEvent>> get events => _events.stream;

  @override
  Future<PriceResult> loadPrice() async {
    priceCalls++;
    return price;
  }

  @override
  Future<bool> buy() async {
    buyCalls++;
    log.add('buy');
    if (!buyOpens) return false;
    final events = afterBuy;
    if (events != null) scheduleMicrotask(() => _events.add(events));
    return true;
  }

  @override
  Future<OwnershipQuery> queryOwnership() {
    log.add('query');
    return hangingQuery?.future ?? Future.value(ownership);
  }

  @override
  Future<OwnershipQuery> restore() async {
    log.add('restore');
    return restoreAnswer;
  }

  @override
  Future<void> complete(StoreToken token) async =>
      log.add('complete ${token.raw}');
}

class LoggingProStatusStore implements ProStatusStore {
  LoggingProStatusStore(this.log, [this.status = ProStatus.notPro]);

  final List<String> log;
  ProStatus status;

  @override
  ProStatus read() => status;

  @override
  Future<void> write(ProStatus value) async {
    log.add('save ${value.name}');
    status = value;
  }
}
