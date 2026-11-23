import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_csv.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/engine/plan_draft.dart';
import 'package:kalan/core/money/currency.dart';
import 'package:kalan/core/money/money_format.dart';

/// Turkish words, as the app gives them (test/features/export checks the
/// real ARB texts).
class TrTexts implements CsvTexts {
  @override
  List<String> get headers => [
    'Ad',
    'Tür',
    'Durum',
    'Kaynak',
    'Ödeme sırası',
    'Son ödeme günü',
    'Tutar',
    'Ek ücret',
    'Taksit başı ücret',
    'Ödendi',
    'Ödeme günü',
    'Para birimi',
  ];

  @override
  String planKind(PlanKind kind, {required bool cashAdvance}) =>
      cashAdvance ? 'Nakit avans' : kind.name;

  @override
  String get recurringKind => 'Sabit ödeme';

  @override
  String status(ExportStatus status) => switch (status) {
    ExportStatus.open => 'açık',
    ExportStatus.onHold => 'beklemede',
    ExportStatus.closed => 'kapatıldı',
    ExportStatus.archived => 'arşivde',
  };

  @override
  String payLaterName(LocalDate due) => 'Sonra öde · $due';
}

Map<String, Object?> payment(
  int seq,
  String due,
  int amount, {
  String? paidAt,
  String? paidOn,
  bool before = false,
  int? extraFee,
  int? fee,
}) => {
  'seq': seq,
  'dueDate': due,
  'amount': amount,
  'paidAt': paidAt,
  'isEdited': false,
  'paidBeforeKalan': before,
  'paidOn': paidOn,
  'extraFee': extraFee,
  'installmentFee': fee,
};

Map<String, Object?> plan(
  int id,
  List<Map<String, Object?>> payments, {
  String? title,
  String kind = 'monthly',
  String status = 'open',
  int? sourceId = 1,
}) => {
  'id': id,
  'sourceId': sourceId,
  'title': title,
  'kind': kind,
  'installmentCount': payments.length,
  'deferMonths': 0,
  'isCashAdvance': false,
  'origin': 'template',
  'createdAt': '2026-11-01T10:00:00Z',
  'reminders': {'enabled': true},
  'status': status,
  'installmentFeeScope': 'everyPayment',
  'payments': payments,
};

BackupData data(
  String currency,
  List<Map<String, Object?>> plans, {
  List<Map<String, Object?>> recurring = const [],
}) => BackupData.fromJson({
  'settings': {
    'currency': currency,
    'payFrequency': 'monthly',
    'reminders': {
      'enabled': true,
      'leadDays': 2,
      'minuteOfDay': 540,
      'showAmounts': true,
      'repeatMode': 'off',
      'paydaySummary': true,
    },
  },
  'sources': [
    {
      'id': 1,
      'name': 'Bancolombia',
      'kind': 'card',
      'moveDueToBusinessDay': true,
      'moveDueForHolidays': true,
      'statementReminder': {'enabled': false, 'daysBefore': 2},
      'createdAt': '2026-11-01T10:00:00Z',
    },
  ],
  'plans': plans,
  'recurringPayments': recurring,
});

final today = LocalDate(2026, 11, 19);

List<List<String>> rowsOf(String csv) {
  expect(csv.startsWith('﻿'), isTrue, reason: 'byte order mark');
  final body = csv.substring(1);
  expect(body.endsWith('\r\n'), isTrue);
  return [
    for (final line in body.substring(0, body.length - 2).split('\r\n'))
      line.split(','),
  ];
}

void main() {
  test('Example 4: Turkish, COP', () {
    final csv = buildCsv(
      data('COP', [
        plan(1, [payment(1, '2026-12-04', 125000)], title: 'Telefon'),
        plan(2, [
          payment(1, '2026-08-01', 50000, paidAt: '2026-08-01T12:00:00Z'),
        ], title: 'Mont'),
        plan(3, [payment(1, '2026-12-01', 1000)], title: '=TOPLAM'),
      ]),
      TrTexts(),
      today: today,
    );
    final rows = rowsOf(csv);
    expect(rows.first, TrTexts().headers);
    expect(rows[1], [
      'Telefon',
      'monthly',
      'açık',
      'Bancolombia',
      '1',
      '2026-12-04',
      '125000',
      '',
      '',
      'false',
      '',
      r'COL$ · COP',
    ]);
    expect(rows[2][2], 'arşivde');
    expect(rows[2][9], 'true');
    expect(rows[2][10], '2026-08-01');
    expect(rows[3].first, "'=TOPLAM");
  });

  test('Example 5: amounts keep the currency digits, no grouping', () {
    expect(formatMinorPlain(125050, Currency.fromCode('EUR')), '1250.50');
    expect(formatMinorPlain(12345, Currency.fromCode('KWD')), '12.345');
    expect(formatMinorPlain(2500, Currency.fromCode('JPY')), '2500');
    expect(formatMinorPlain(125000, Currency.fromCode('EUR')), '1250.00');
    expect(formatMinorPlain(5, Currency.fromCode('KWD')), '0.005');
    expect(formatMinorPlain(-150, Currency.fromCode('TRY')), '-1.50');
    expect(formatMinorPlain(123456789012, Currency.fromCode('IDR')), '123456789012');
  });

  test('every currency: dot and its own digits', () {
    for (final c in Currency.all) {
      final text = formatMinorPlain(1234567 * c.minorPerMajor + 1, c);
      expect(
        text,
        c.decimals == 0
            ? '1234568'
            : '1234567.${'1'.padLeft(c.decimals, '0')}',
        reason: c.code,
      );
    }
  });

  test('0, 2 and 3 digits in the file', () {
    for (final (code, amount, text) in [
      ('JPY', 2500, '2500'),
      ('EUR', 125050, '1250.50'),
      ('KWD', 12345, '12.345'),
    ]) {
      final rows = rowsOf(
        buildCsv(
          data(code, [plan(1, [payment(1, '2026-12-04', amount)])]),
          TrTexts(),
          today: today,
        ),
      );
      expect(rows[1][6], text, reason: code);
    }
  });

  test('quoting (RFC 4180) and formula guard on text cells only', () {
    final csv = buildCsv(
      data('TRY', [
        plan(1, [payment(1, '2026-12-04', 100, extraFee: 50, fee: 25)],
            title: 'Kulaklık, "kablosuz"'),
        plan(2, [payment(1, '2026-12-04', 100)], title: '+90 hat'),
        plan(3, [payment(1, '2026-12-04', 100)], title: '-indirim'),
        plan(4, [payment(1, '2026-12-04', 100)], title: '@ev'),
        plan(5, [payment(1, '2026-12-04', 100)], title: 'iki\nsatır'),
      ]),
      TrTexts(),
      today: today,
    );
    expect(csv, contains('"Kulaklık, ""kablosuz"""'));
    expect(csv, contains("\r\n'+90 hat,"));
    expect(csv, contains("\r\n'-indirim,"));
    expect(csv, contains("\r\n'@ev,"));
    expect(csv, contains('"iki\nsatır"'));
    // Amounts are numbers, never guarded or quoted.
    expect(csv, contains(',1.00,0.50,0.25,false,'));
  });

  test('statuses, paid before Kalan, untitled "Pay later" and recurring', () {
    final csv = buildCsv(
      data(
        'TRY',
        [
          plan(1, [payment(1, '2026-12-04', 100)], status: 'onHold'),
          plan(2, [
            payment(1, '2026-12-04', 100, paidAt: '2026-11-02T10:00:00Z'),
          ], status: 'closed'),
          plan(3, [
            payment(1, '2026-12-14', 100, paidAt: '2026-09-01T00:00:00Z',
                before: true),
          ], kind: 'payLater', sourceId: null),
          plan(4, [
            payment(1, '2026-11-01', 100,
                paidAt: '2026-11-19T10:00:00Z', paidOn: '2026-11-01'),
          ], status: 'onHold'),
        ],
        recurring: [
          {
            'id': 1,
            'name': 'Kira',
            'amount': 1500000,
            'recurrence': 'monthly',
            'startDate': '2026-01-01',
            'endDate': '2026-11-01',
            'createdAt': '2026-01-01T10:00:00Z',
            'reminders': {'enabled': true},
            'paidOccurrences': [
              {'date': '2026-10-01', 'paidAt': '2026-10-01T12:00:00Z'},
            ],
          },
        ],
      ),
      TrTexts(),
      today: today,
    );
    final rows = rowsOf(csv);
    expect(rows[1][2], 'beklemede');
    expect(rows[2][2], 'kapatıldı');
    // Paid before Kalan: paid, the day is not known.
    expect(rows[3].sublist(0, 4), ['Sonra öde · 2026-12-14', 'payLater',
        'arşivde', '']);
    expect(rows[3][9], 'true');
    expect(rows[3][10], '');
    // On hold but every payment paid: in the archive; "paid on" is the
    // day chosen in the past-due list.
    expect(rows[4][2], 'arşivde');
    expect(rows[4][10], '2026-11-01');
    expect(rows[5], [
      'Kira',
      'Sabit ödeme',
      'arşivde',
      '',
      '',
      '2026-10-01',
      '15000.00',
      '',
      '',
      'true',
      '2026-10-01',
      '₺ · TRY',
    ]);
  });
}
