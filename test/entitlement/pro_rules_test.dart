import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/entitlement/pro_rules.dart';
import 'package:kalan/entitlement/store_gateway.dart';

/// Pro is removed only on the store's explicit word (owner decision,
/// 18 November 2026). Every other answer keeps what the device knows.
void main() {
  const owned = Owned();
  final table = <(String, OwnershipQuery, ProVerdict)>[
    ('successful query, owned', owned, ProVerdict.grant),
    (
      'successful query, payment pending',
      const OwnedPending(),
      ProVerdict.markPending,
    ),
    ('successful query, refunded', const Revoked(), ProVerdict.revoke),
    ('successful query, not owned', const NotOwned(), ProVerdict.revoke),
    ('answer that cannot tell', const Inconclusive(), ProVerdict.keep),
    ('network error', const QueryFailed(FailureKind.network), ProVerdict.keep),
    ('time-out', const QueryFailed(FailureKind.timeout), ProVerdict.keep),
    (
      'store unreachable',
      const QueryFailed(FailureKind.unavailable),
      ProVerdict.keep,
    ),
    ('unknown error', const QueryFailed(FailureKind.unknown), ProVerdict.keep),
  ];

  group('verdictFor', () {
    for (final (name, query, verdict) in table) {
      test('$name -> ${verdict.name}', () {
        expect(verdictFor(query), verdict);
      });
    }
  });

  group('a failed or unclear answer never removes Pro', () {
    for (final (name, query, _) in table) {
      if (query is! QueryFailed && query is! Inconclusive) continue;
      for (final status in ProStatus.values) {
        test('$name keeps ${status.name}', () {
          expect(applyVerdict(status, verdictFor(query)), status);
        });
      }
    }
  });

  group('applyVerdict', () {
    final cases = <(ProStatus, ProVerdict, ProStatus)>[
      (ProStatus.notPro, ProVerdict.grant, ProStatus.pro),
      (ProStatus.pending, ProVerdict.grant, ProStatus.pro),
      (ProStatus.pro, ProVerdict.grant, ProStatus.pro),
      (ProStatus.notPro, ProVerdict.markPending, ProStatus.pending),
      (ProStatus.pending, ProVerdict.markPending, ProStatus.pending),
      // A pending payment never takes away Pro already owned.
      (ProStatus.pro, ProVerdict.markPending, ProStatus.pro),
      (ProStatus.pro, ProVerdict.keep, ProStatus.pro),
      (ProStatus.pro, ProVerdict.revoke, ProStatus.notPro),
      (ProStatus.pending, ProVerdict.revoke, ProStatus.notPro),
      (ProStatus.notPro, ProVerdict.revoke, ProStatus.notPro),
    ];
    for (final (from, verdict, to) in cases) {
      test('${from.name} + ${verdict.name} -> ${to.name}', () {
        expect(applyVerdict(from, verdict), to);
      });
    }
  });

  group('statusAfter', () {
    test('an unclear answer clears a pending payment (not Pro)', () {
      expect(
        statusAfter(ProStatus.pending, const Inconclusive()),
        ProStatus.notPro,
      );
    });

    test('an unclear answer keeps Pro', () {
      expect(statusAfter(ProStatus.pro, const Inconclusive()), ProStatus.pro);
    });

    test('no answer keeps a pending payment', () {
      expect(
        statusAfter(ProStatus.pending, const QueryFailed(FailureKind.network)),
        ProStatus.pending,
      );
    });

    test('never removes Pro without the store saying so', () {
      for (final q in [
        const Inconclusive(),
        for (final k in FailureKind.values) QueryFailed(k),
      ]) {
        expect(statusAfter(ProStatus.pro, q), ProStatus.pro);
      }
    });
  });
}
