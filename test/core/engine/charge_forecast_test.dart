import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';

import '../date/local_date_test.dart' show d;

const maas = 1;
const kart = 2;
const auto = PaymentMethod.automatic;

ChargeItem item(
  String name,
  String iso,
  int minor, {
  int? source = maas,
  PaymentMethod? method = auto,
  bool paid = false,
  int? plan,
  String? paidOn,
  bool before = false,
  bool ownCard = false,
}) => ChargeItem(
  planId: plan ?? name.hashCode,
  name: name,
  sourceId: source,
  method: method,
  dueDate: d(iso),
  amountMinor: minor,
  isPaid: paid,
  paidOn: paidOn == null ? null : d(paidOn),
  paidBeforeKalan: before,
  isOwnCardInstallment: ownCard,
);

/// A row as (date, amount, running total, paid, past due, names).
typedef Row = (String, int, int, bool, bool, String);

Row rowOf(ChargeRow r) => (
  r.date.toString(),
  r.amountMinor,
  r.cumulativeMinor,
  r.isPaid,
  r.includesPastDue,
  [for (final i in r.items) i.name!].join(', '),
);

void main() {
  // Monthly payday on the 15th (examples): 15 Nov - 14 Dec, then
  // 15 Dec - 14 Jan.
  final nov = PayPeriod(d('2026-11-15'), d('2026-12-15'));
  final dec = PayPeriod(d('2026-12-15'), d('2027-01-15'));

  ChargeForecast run(List<ChargeItem> items, String today) =>
      chargeForecast(items: items, current: nov, next: dec, today: d(today));

  // Example 1: Naz's salary account on 15 Nov.
  final example1 = [
    item('Telefon taksiti', '2026-11-18', 140000),
    item('Spor salonu', '2026-11-18', 100000),
    item('Laptop taksiti', '2026-11-25', 150000),
    item('Kulaklık taksiti', '2026-11-20', 80000, method: PaymentMethod.manual),
  ];

  group('table: rows of one source this period', () {
    final cases = <(String, List<ChargeItem>, String, List<Row>)>[
      (
        'example 1: same day summed, running total, by date, manual left out',
        example1,
        '2026-11-15',
        [
          (
            '2026-11-18',
            240000,
            240000,
            false,
            false,
            'Spor salonu, Telefon taksiti',
          ),
          ('2026-11-25', 150000, 390000, false, false, 'Laptop taksiti'),
        ],
      ),
      (
        'example 2: paid on 18 Nov, today 19 Nov: muted row, not in total',
        [
          item('Telefon taksiti', '2026-11-18', 140000, paid: true),
          item('Laptop taksiti', '2026-11-25', 150000),
        ],
        '2026-11-19',
        [
          ('2026-11-18', 140000, 0, true, false, 'Telefon taksiti'),
          ('2026-11-25', 150000, 150000, false, false, 'Laptop taksiti'),
        ],
      ),
      (
        'unpaid and past due: on today, with the clock',
        [
          item('Eski', '2026-11-16', 50000),
          item('Bugün', '2026-11-19', 20000),
          item('Sonra', '2026-11-30', 10000),
        ],
        '2026-11-19',
        [
          ('2026-11-19', 70000, 70000, false, true, 'Bugün, Eski'),
          ('2026-11-30', 10000, 80000, false, false, 'Sonra'),
        ],
      ),
      (
        'past due from an earlier period still counts today',
        [item('Ekim', '2026-10-20', 30000)],
        '2026-11-19',
        [('2026-11-19', 30000, 30000, false, true, 'Ekim')],
      ),
      (
        'paid and unpaid on one day: paid row first, unpaid row counts',
        [
          item('A', '2026-11-20', 10000, paid: true),
          item('B', '2026-11-20', 20000),
        ],
        '2026-11-19',
        [
          ('2026-11-20', 10000, 0, true, false, 'A'),
          ('2026-11-20', 20000, 20000, false, false, 'B'),
        ],
      ),
      (
        'paid "today" from the past-due list: on the day it was paid',
        [item('Geç', '2026-11-10', 40000, paid: true, paidOn: '2026-11-17')],
        '2026-11-19',
        [('2026-11-17', 40000, 0, true, false, 'Geç')],
      ),
      (
        'paid before Kalan and the card\'s own installments: never listed',
        [
          item('Önce', '2026-11-16', 10000, paid: true, before: true),
          item('Kendi', '2026-11-24', 20000, ownCard: true),
          item('Not set', '2026-11-24', 30000, method: null),
        ],
        '2026-11-15',
        [],
      ),
    ];
    for (final (name, items, today, rows) in cases) {
      test(name, () {
        final f = run(items, today);
        final current = f.of(maas, nov, dec).current;
        expect([for (final r in current.rows) rowOf(r)], rows);
      });
    }
  });

  test('example 1: next withdrawal and the period total', () {
    final current = run(example1, '2026-11-15').of(maas, nov, dec).current;
    expect(current.nextCharge!.date, d('2026-11-18'));
    expect(current.nextCharge!.amountMinor, 240000);
    expect(current.totalMinor, 390000);
  });

  test('example 2: next withdrawal after a paid one', () {
    final current = run([
      item('Telefon taksiti', '2026-11-18', 140000, paid: true),
      item('Laptop taksiti', '2026-11-25', 150000),
    ], '2026-11-19').of(maas, nov, dec).current;
    expect(current.nextCharge!.date, d('2026-11-25'));
    expect(current.nextCharge!.amountMinor, 150000);
    expect(current.totalMinor, 150000);
  });

  test('period edge: the last day here, the next first day there', () {
    final f = run([
      item('Son gün', '2026-12-14', 10000),
      item('İlk gün', '2026-12-15', 20000),
      item('Ocak', '2027-01-14', 30000),
      item('Dışarıda', '2027-01-15', 40000),
    ], '2026-11-15').of(maas, nov, dec);
    expect(
      [for (final r in f.current.rows) rowOf(r)],
      [('2026-12-14', 10000, 10000, false, false, 'Son gün')],
    );
    // The next period starts its own running total.
    expect(
      [for (final r in f.next.rows) rowOf(r)],
      [
        ('2026-12-15', 20000, 20000, false, false, 'İlk gün'),
        ('2027-01-14', 30000, 50000, false, false, 'Ocak'),
      ],
    );
  });

  test('past due never reaches the next period', () {
    final f = run([
      item('Eski', '2026-11-16', 50000),
    ], '2026-11-19').of(maas, nov, dec);
    expect(f.next.rows, isEmpty);
  });

  test('without a source: their own group, by next unpaid payment', () {
    final f = run([
      item('Kaynaksız', '2026-11-28', 10000, source: null, plan: 7),
      item('Kaynaksız', '2026-12-28', 10000, source: null, plan: 7),
      item('Erken', '2026-11-10', 5000, source: null, plan: 8, paid: true),
      item('Erken', '2026-11-20', 5000, source: null, plan: 8),
      item('Elle', '2026-11-20', 5000, source: null, method: null),
      item('Hesaptan', '2026-11-20', 5000),
    ], '2026-11-15');
    expect(
      [for (final i in f.unassigned) (i.name, i.dueDate.toString())],
      [('Erken', '2026-11-20'), ('Kaynaksız', '2026-11-28')],
    );
    expect(f.bySource.keys, [maas]);
  });

  test('example 4: a card lists only other plans taken from it', () {
    final f = run([
      item('Klarna', '2026-12-05', 60000, source: kart),
      item('Kart taksidi', '2026-11-24', 120000, source: kart, ownCard: true),
      item('Kart taksidi', '2026-12-24', 120000, source: kart, ownCard: true),
    ], '2026-11-15').of(kart, nov, dec);
    expect(
      [for (final r in f.current.rows) rowOf(r)],
      [('2026-12-05', 60000, 60000, false, false, 'Klarna')],
    );
  });

  test('a source with only manual payments has no forecast', () {
    final f = run([
      item('Elle', '2026-11-20', 5000, method: PaymentMethod.manual),
    ], '2026-11-15');
    expect(f.bySource, isEmpty);
    final empty = f.of(maas, nov, dec);
    expect(empty.current.rows, isEmpty);
    expect(empty.current.hasNothingDue, isTrue);
    expect(empty.current.totalMinor, 0);
  });

  test('a fully paid period keeps its rows but nothing is due', () {
    final current = run([
      item('A', '2026-11-16', 10000, paid: true),
    ], '2026-11-19').of(maas, nov, dec).current;
    expect(current.rows, hasLength(1));
    expect(current.hasNothingDue, isTrue);
    expect(current.totalMinor, 0);
  });

  test('amounts add as integer minor units (IDR, no decimals)', () {
    // Rp 1.500.000 + Rp 2.250.000 + Rp 999.999: stored as whole rupiah.
    final current = run([
      item('A', '2026-11-20', 1500000),
      item('B', '2026-11-20', 2250000),
      item('C', '2026-11-21', 999999),
    ], '2026-11-15').of(maas, nov, dec).current;
    expect(current.rows.first.amountMinor, 3750000);
    expect(current.totalMinor, 4749999);
  });
}
