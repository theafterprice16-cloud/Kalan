import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/engine/pay_period.dart';
import 'package:kalan/core/engine/period_summary.dart';
import 'package:kalan/core/money/money_format.dart' show amountMask;
import 'package:kalan/core/widget/widget_snapshot.dart';

/// Plain texts: amounts as "<minor>u", short ones as "<minor>s", so a
/// test sees exactly which path made each string.
class _Texts implements WidgetTexts {
  _Texts({this.failOnMoney = false});

  /// Masked: formatting any amount is a failure.
  final bool failOnMoney;
  final calls = <int>[];

  @override
  String get leftTitle => 'Left';
  @override
  String get paymentsTitle => 'Payments this period';
  @override
  String until(LocalDate lastDay) => 'Until ${shortDate(lastDay)}';
  @override
  String shortDate(LocalDate date) => '${date.month}/${date.day}';
  @override
  String money(int minor) {
    if (failOnMoney) fail('money($minor) while masked');
    calls.add(minor);
    return '${minor}u';
  }

  @override
  String moneyShort(int minor) {
    if (failOnMoney) fail('moneyShort($minor) while masked');
    return '${minor}s';
  }

  @override
  String get amountHidden => 'Amount hidden';
  @override
  String get noPayments => 'No payments yet.';
  @override
  String get noUpcoming => 'No upcoming payments.';
  @override
  String get setup => 'Open Kalan to finish setup.';
  @override
  String get stale => 'Open Kalan for the latest.';
  @override
  String spokenSummary({
    required String title,
    required String amount,
    required String date,
  }) => '$title $amount, until $date.';
  @override
  String spokenPayment({
    required String name,
    required String date,
    required String amount,
  }) => '$name, $date, $amount.';
  @override
  bool get rightToLeft => false;
}

final _period = PayPeriod(LocalDate(2026, 11, 15), LocalDate(2026, 12, 15));

PeriodSummary _summary({
  required int spokenFor,
  int? income,
  PeriodStatus? status,
}) => PeriodSummary(
  period: _period,
  spokenForMinor: spokenFor,
  itemCount: 3,
  incomeMinor: income,
  status:
      status ??
      (income == null
          ? PeriodStatus.noIncome
          : income - spokenFor < 0
          ? PeriodStatus.negative
          : PeriodStatus.comfortable),
);

final _rows = [
  WidgetPayment(name: 'Telefon taksiti', date: _d22, amountMinor: 140000),
  WidgetPayment(name: 'Laptop taksiti', date: _d25, amountMinor: 150000),
  WidgetPayment(name: 'Kira', date: _d1, amountMinor: 900000),
  WidgetPayment(name: 'Fourth', date: _d2, amountMinor: 100),
];
final _d22 = LocalDate(2026, 11, 22);
final _d25 = LocalDate(2026, 11, 25);
final _d1 = LocalDate(2026, 12, 1);
final _d2 = LocalDate(2026, 12, 2);

WidgetDayText _one(
  PeriodSummary summary, {
  bool masked = false,
  List<WidgetPayment>? upcoming,
  WidgetTexts? texts,
}) => buildWidgetSnapshot(
  input: WidgetDaysInput([
    WidgetDayInput(
      date: LocalDate(2026, 11, 20),
      summary: summary,
      upcoming: upcoming ?? _rows,
    ),
  ]),
  masked: masked,
  texts: texts ?? _Texts(),
).days.single;

void main() {
  group('day record by period status (table)', () {
    for (final (name, summary, state, title, number) in [
      // Example 1: income entered, 12.450 left.
      (
        'left',
        _summary(spokenFor: 1190000, income: 2435000),
        WidgetState.left,
        'Left',
        '1245000u',
      ),
      // A tight period is still "Left" in accent (no warning colour).
      (
        'tight',
        _summary(
          spokenFor: 1190000,
          income: 1200000,
          status: PeriodStatus.tight,
        ),
        WidgetState.left,
        'Left',
        '10000u',
      ),
      // Example 2: −850, the negative token and the sign from the money
      // path.
      (
        'negative',
        _summary(spokenFor: 2520000, income: 2435000),
        WidgetState.negative,
        'Left',
        '-85000u',
      ),
      // Example 3: no income, this period's payments.
      (
        'no income',
        _summary(spokenFor: 875000),
        WidgetState.noIncome,
        'Payments this period',
        '875000u',
      ),
    ]) {
      test(name, () {
        final day = _one(summary);
        expect(day.state, state);
        expect(day.title, title);
        expect(day.number, number);
        expect(day.until, 'Until 12/14');
      });
    }
  });

  test('at most three upcoming payments, in the given order', () {
    final day = _one(_summary(spokenFor: 1, income: 2));
    expect(
      [for (final r in day.rows) '${r.name}|${r.date}|${r.amount}'],
      [
        'Telefon taksiti|11/22|140000u',
        'Laptop taksiti|11/25|150000u',
        'Kira|12/1|900000u',
      ],
    );
    expect(day.message, isEmpty);
    expect(
      day.spoken,
      'Left 1u, until 12/14. Telefon taksiti, 11/22, 140000u. '
      'Laptop taksiti, 11/25, 150000u. Kira, 12/1, 900000u.',
    );
  });

  test('nothing upcoming: "No upcoming payments." in place of the rows', () {
    final day = _one(_summary(spokenFor: 0, income: 2), upcoming: const []);
    expect(day.rows, isEmpty);
    expect(day.message, 'No upcoming payments.');
    expect(day.spoken, contains('No upcoming payments.'));
  });

  group('masked: no amount is ever formatted', () {
    for (final summary in [
      _summary(spokenFor: 1190000, income: 2435000),
      _summary(spokenFor: 2520000, income: 2435000),
      _summary(spokenFor: 875000),
    ]) {
      test('${summary.status.name}: dots in place, names and dates kept', () {
        final day = _one(
          summary,
          masked: true,
          texts: _Texts(failOnMoney: true),
        );
        expect(day.number, amountMask);
        expect(day.numberSmall, amountMask);
        expect([for (final r in day.rows) r.amount], everyElement(amountMask));
        expect(
          [for (final r in day.rows) r.name],
          ['Telefon taksiti', 'Laptop taksiti', 'Kira'],
        );
        expect(day.until, 'Until 12/14');
        // The state and so the colour stay (28: "in its normal colour").
        expect(day.state, _one(summary).state);
        expect(day.spoken, contains('Amount hidden'));
        expect(day.spoken, isNot(contains(amountMask)));
      });
    }
  });

  test('privacy matrix: hide amounts, app lock, show in widget', () {
    for (final hide in [false, true]) {
      for (final lock in [false, true]) {
        for (final show in [false, true]) {
          final masked = widgetAmountsMasked(
            hideAmounts: hide,
            appLock: lock,
            showInWidget: show,
          );
          // Product owner's decision 1.
          expect(
            masked,
            hide || (lock && !show),
            reason: 'hide $hide, lock $lock, show $show',
          );
        }
      }
    }
    // Examples 4 and 5.
    expect(
      widgetAmountsMasked(
        hideAmounts: false,
        appLock: true,
        showInWidget: false,
      ),
      isTrue,
    );
    expect(
      widgetAmountsMasked(
        hideAmounts: true,
        appLock: false,
        showInWidget: true,
      ),
      isTrue,
    );
  });

  test('long numbers: the small size gets the short form (example 8)', () {
    // "Rp125.450.000" is 13 characters.
    final texts = _LongTexts();
    final day = _one(_summary(spokenFor: 0, income: 125450000), texts: texts);
    expect(day.number, 'Rp125.450.000');
    expect(day.numberSmall, '125450000s');
    final short = _one(_summary(spokenFor: 0, income: 1245000));
    expect(short.numberSmall, short.number);
  });

  test('setup and no payments: one message on any date, no days', () {
    for (final (input, mode, message) in [
      (
        const WidgetSetupInput(),
        WidgetMode.setup,
        'Open Kalan to finish setup.',
      ),
      (
        const WidgetNoPaymentsInput(),
        WidgetMode.noPayments,
        'No payments yet.',
      ),
    ]) {
      final snapshot = buildWidgetSnapshot(
        input: input,
        masked: false,
        texts: _Texts(failOnMoney: true),
      );
      expect(snapshot.mode, mode);
      expect(snapshot.message, message);
      expect(snapshot.days, isEmpty);
      final json = snapshot.toJson();
      expect(json['mode'], mode.name);
      expect(json['v'], widgetSnapshotVersion);
    }
  });

  test('JSON: eight days, today first; the stale text has no amount', () {
    final today = LocalDate(2026, 11, 20);
    final snapshot = buildWidgetSnapshot(
      input: WidgetDaysInput([
        for (var i = 0; i < widgetDayCount + 2; i++)
          WidgetDayInput(
            date: today.addDays(i),
            summary: _summary(spokenFor: 1, income: 2),
            upcoming: const [],
          ),
      ]),
      masked: false,
      texts: _Texts(),
    );
    expect(snapshot.days, hasLength(widgetDayCount));
    expect(snapshot.stale, 'Open Kalan for the latest.');
    final json = jsonDecode(jsonEncode(snapshot.toJson())) as Map;
    final days = json['days'] as List;
    expect(
      [for (final d in days) (d as Map)['d']],
      [for (var i = 0; i < 8; i++) today.addDays(i).day],
    );
    expect((days.first as Map).keys, containsAll(['y', 'm', 'd', 'state']));
    expect(json['stale'], isNot(contains(RegExp('[0-9]'))));
  });
}

class _LongTexts extends _Texts {
  @override
  String money(int minor) => minor == 125450000 ? 'Rp125.450.000' : '${minor}u';
}
