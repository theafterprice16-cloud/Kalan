import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/backup/backup_file.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/reminders/reminder_models.dart' show ReminderRepeat;
import 'package:kalan/data/backup/backup_collector.dart';
import 'package:kalan/data/db/app_database.dart';

import '../helpers/backup_seed.dart';

/// Every column of every table, and where a backup keeps it (Roadmap 29).
/// A new column fails this test until it is mapped here, in the
/// collector, in BackupData and in docs/YEDEK_BICIMI.md, or left out on
/// purpose (null) with the reason in the comment.
const columns = <String, Map<String, String?>>{
  'sources': {
    'id': 'sources[].id',
    'name': 'sources[].name',
    'kind': 'sources[].kind',
    'statement_day': 'sources[].statementDay',
    'due_day': 'sources[].dueDay',
    'shift_due_to_business_day': 'sources[].moveDueToBusinessDay',
    'shift_due_for_holidays': 'sources[].moveDueForHolidays',
    'created_at': 'sources[].createdAt',
    'statement_reminder_enabled': 'sources[].statementReminder.enabled',
    'statement_reminder_days': 'sources[].statementReminder.daysBefore',
  },
  'plans': {
    'id': 'plans[].id',
    'source_id': 'plans[].sourceId',
    'title': 'plans[].title',
    'kind': 'plans[].kind',
    'installment_count': 'plans[].installmentCount',
    'purchase_day': 'plans[].purchaseDate',
    'defer_months': 'plans[].deferMonths',
    'is_cash_advance': 'plans[].isCashAdvance',
    'origin': 'plans[].origin',
    'created_at': 'plans[].createdAt',
    'reminders_enabled': 'plans[].reminders.enabled',
    'reminder_lead_days': 'plans[].reminders.leadDays',
    'repeat_mode': 'plans[].repeatMode',
    'pay_later_rule': 'plans[].payLaterRule.kind',
    'pay_later_value': 'plans[].payLaterRule.value',
    'interval_days': 'plans[].intervalDays',
    'payment_method': 'plans[].paymentMethod',
    'charge_source_id': 'plans[].chargeSourceId',
    'status': 'plans[].status',
    'close_reason': 'plans[].closeReason',
    'held_since_day': 'plans[].heldSince',
    'hold_check_day': 'plans[].holdCheckFrom',
    'reopened_day': 'plans[].reopenedOn',
    'closed_day': 'plans[].closedOn',
    'installment_fee_minor': 'plans[].installmentFee',
    'installment_fee_scope': 'plans[].installmentFeeScope',
    'product_price_minor': 'plans[].productPrice',
  },
  'payments': {
    // Only snoozes point at it (left out); the plan and seq identify it.
    'id': null,
    'plan_id': 'plans[].payments (nested)',
    'seq': 'plans[].payments[].seq',
    'due_day': 'plans[].payments[].dueDate',
    'amount_minor': 'plans[].payments[].amount',
    'paid_at': 'plans[].payments[].paidAt',
    'is_edited': 'plans[].payments[].isEdited',
    'paid_before_kalan': 'plans[].payments[].paidBeforeKalan',
    'paid_on_day': 'plans[].payments[].paidOn',
    'original_day': 'plans[].payments[].originalDueDate',
    'extra_fee_minor': 'plans[].payments[].extraFee',
    'extra_fee_note': 'plans[].payments[].extraFeeNote',
    'installment_fee_minor': 'plans[].payments[].installmentFee',
  },
  'recurring_payments': {
    'id': 'recurringPayments[].id',
    'name': 'recurringPayments[].name',
    'amount_minor': 'recurringPayments[].amount',
    'recurrence': 'recurringPayments[].recurrence',
    'start_day': 'recurringPayments[].startDate',
    'end_day': 'recurringPayments[].endDate',
    'created_at': 'recurringPayments[].createdAt',
    'reminders_enabled': 'recurringPayments[].reminders.enabled',
    'reminder_lead_days': 'recurringPayments[].reminders.leadDays',
    'repeat_mode': 'recurringPayments[].repeatMode',
  },
  'recurring_marks': {
    'recurring_id': 'recurringPayments[].paidOccurrences (nested)',
    'occurrence_day': 'recurringPayments[].paidOccurrences[].date',
    'paid_at': 'recurringPayments[].paidOccurrences[].paidAt',
  },
  'app_settings': {
    // The single row's fixed key.
    'id': null,
    'currency_code': 'settings.currency',
    // The app language: this device's choice.
    'locale_code': null,
    'pay_frequency': 'settings.payFrequency',
    'pay_day': 'settings.payDay',
    'pay_anchor_day': 'settings.payAnchorDate',
    'net_income_minor': 'settings.netIncome',
    'tight_threshold_minor': 'settings.tightThreshold',
    // Debug builds' Pro switch: Pro never travels in a backup.
    'debug_pro': null,
    'reminders_enabled': 'settings.reminders.enabled',
    'reminder_lead_days': 'settings.reminders.leadDays',
    'reminder_minute': 'settings.reminders.minuteOfDay',
    'hide_amounts_in_notifications': 'settings.reminders.showAmounts',
    // Whether this device asked for the notification permission.
    'reminder_prompt_shown': null,
    'repeat_mode': 'settings.reminders.repeatMode',
    'last_pay_later_rule': 'settings.lastPayLaterRule.kind',
    'last_pay_later_value': 'settings.lastPayLaterRule.value',
    'last_amount_entry': 'settings.lastAmountEntry',
    'payday_summary_enabled': 'settings.reminders.paydaySummary',
    'holiday_country': 'settings.holidayCountry',
    'applied_holidays': 'settings.appliedHolidays',
  },
  // "Remind later" from a notification: temporary.
  'reminder_snoozes': {},
};

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedEverything(db);
  });
  tearDown(() => db.close());

  test('every column is in the backup or left out on purpose', () {
    for (final table in db.allTables) {
      final mapped = columns[table.actualTableName];
      expect(mapped, isNotNull, reason: 'table ${table.actualTableName}');
      final actual = {for (final c in table.$columns) c.name};
      if (table.actualTableName == 'reminder_snoozes') continue;
      expect(actual, mapped!.keys.toSet(), reason: table.actualTableName);
    }
  });

  test('collects every value, by meaningful names', () async {
    final json = (await collectBackup(db))!.toJson();
    final settings = json['settings']! as Map<String, Object?>;
    expect(settings, {
      'currency': 'TRY',
      'payFrequency': 'biweekly',
      'payDay': 15,
      'payAnchorDate': '2026-11-06',
      'netIncome': 4500000,
      'tightThreshold': 500000,
      'reminders': {
        'enabled': false,
        'leadDays': 5,
        'minuteOfDay': 1230,
        'showAmounts': false,
        'repeatMode': 'daily',
        'paydaySummary': false,
      },
      'lastPayLaterRule': {'kind': 'nextMonthDay', 'value': 10},
      'lastAmountEntry': 'installment',
      'holidayCountry': 'TR',
      'appliedHolidays': {
        'country': 'TR',
        'weekendDays': [6, 7],
        'lastYear': 2028,
        'days': ['2026-10-29'],
      },
    });
    final sources = json['sources']! as List<Object?>;
    expect(sources.first, {
      'id': 1,
      'name': 'Bonus, "Gold"',
      'kind': 'card',
      'statementDay': 25,
      'dueDay': 5,
      'moveDueToBusinessDay': false,
      'moveDueForHolidays': false,
      'statementReminder': {'enabled': true, 'daysBefore': 1},
      'createdAt': '2026-01-02T03:04:05Z',
    });
    final plans = json['plans']! as List<Object?>;
    expect(plans, hasLength(4));
    expect(plans.first, {
      'id': 1,
      'sourceId': 1,
      'title': '=TOPLAM',
      'kind': 'card',
      'installmentCount': 3,
      'purchaseDate': '2026-10-10',
      'deferMonths': 1,
      'isCashAdvance': true,
      'origin': 'manual',
      'createdAt': '2026-10-10T08:00:00Z',
      'reminders': {'enabled': false, 'leadDays': 7},
      'repeatMode': 'evening',
      'payLaterRule': null,
      'intervalDays': 30,
      'paymentMethod': 'automatic',
      'chargeSourceId': 2,
      'status': 'closed',
      'closeReason': 'refund',
      'heldSince': '2026-11-01',
      'holdCheckFrom': '2026-11-02',
      'reopenedOn': '2026-11-03',
      'closedOn': '2026-11-04',
      'installmentFee': 1500,
      'installmentFeeScope': 'firstPaymentOnly',
      'productPrice': 900000,
      'payments': [
        {
          'seq': 2,
          'dueDate': '2026-12-07',
          'amount': 333334,
          'paidAt': '2026-12-01T09:30:15Z',
          'isEdited': true,
          'paidBeforeKalan': false,
          'paidOn': '2026-12-02',
          'originalDueDate': '2026-12-05',
          'extraFee': 600,
          'extraFeeNote': 'Gecikme, "faiz"',
          'installmentFee': 1500,
        },
        {
          'seq': 3,
          'dueDate': '2027-01-05',
          'amount': 333333,
          'paidAt': null,
          'isEdited': false,
          'paidBeforeKalan': false,
          'paidOn': null,
          'originalDueDate': null,
          'extraFee': null,
          'extraFeeNote': null,
          'installmentFee': null,
        },
      ],
    });
    expect((plans[1]! as Map)['payLaterRule'], {'kind': 'days', 'value': 30});
    expect(json['recurringPayments'], [
      {
        'id': 1,
        'name': 'Kira',
        'amount': 1500000,
        'recurrence': 'monthly',
        'startDate': '2026-01-01',
        'endDate': '2027-12-01',
        'createdAt': '2026-01-01T10:00:00Z',
        'reminders': {'enabled': false, 'leadDays': 3},
        'repeatMode': 'daily',
        'paidOccurrences': [
          {'date': '2026-11-01', 'paidAt': '2026-11-01T18:00:00Z'},
        ],
      },
    ]);
  });

  test('leaves out Pro, language, the permission prompt and snoozes', () async {
    final text = jsonEncode((await collectBackup(db))!.toJson());
    for (final word in [
      'debugPro',
      'locale',
      'language',
      'promptShown',
      'snooze',
      'theme',
      'lock',
      'hideAmounts',
    ]) {
      expect(text.toLowerCase(), isNot(contains('"${word.toLowerCase()}')));
    }
  });

  test('null before onboarding', () async {
    final empty = AppDatabase(NativeDatabase.memory());
    addTearDown(empty.close);
    expect(await collectBackup(empty), isNull);
  });

  for (final password in [null, 'parola 1']) {
    test('round trip through the file, '
        '${password == null ? 'no password' : 'encrypted'}', () async {
      final data = (await collectBackup(db))!;
      final text = await writeBackup(
        data,
        appVersion: '1.0.0+1',
        createdAt: DateTime.utc(2026, 11, 19, 7, 30),
        password: password,
        kdf: const Argon2idKdf(memoryKiB: 64, iterations: 1),
      );
      final back = await readBackup(text, password: password);
      expect(back.data.toJson(), data.toJson());
      expect(back.header.currency, 'TRY');
    });
  }

  // docs/YEDEK_BICIMI.md lists every field: the document and the file a
  // real database gives must agree, field by field and type by type.
  test('the format document matches the file', () async {
    final doc = File('docs/YEDEK_BICIMI.md').readAsStringSync();
    final documented = documentedFields(doc);
    final data = (await collectBackup(db))!;
    final plain = jsonDecode(
      await writeBackup(
        data,
        appVersion: '1.0.0+1',
        createdAt: DateTime.utc(2026, 11, 19),
      ),
    );
    final sealed = jsonDecode(
      await writeBackup(
        data,
        appVersion: '1.0.0+1',
        createdAt: DateTime.utc(2026, 11, 19),
        password: 'x',
        kdf: const Argon2idKdf(memoryKiB: 64, iterations: 1),
      ),
    );
    final actual = <String, String>{};
    collectTypes(plain, '', actual);
    collectTypes(sealed, '', actual);
    expect(actual.keys.toSet(), documented.keys.toSet());
    for (final MapEntry(:key, :value) in actual.entries) {
      expect(documented[key], value, reason: key);
    }
  });

  // A renamed value in code would change the file: freeze the names
  // (a rename needs a new format version and a reader for the old name).
  test('enum names in the file are frozen', () {
    List<String> names(List<Enum> values) => [for (final v in values) v.name];
    expect(names(PayFrequency.values), ['monthly', 'biweekly', 'weekly']);
    expect(names(ReminderRepeat.values), ['off', 'evening', 'daily']);
    expect(names(PayLaterRuleKind.values), [
      'days',
      'nextMonthDay',
      'chosenDate',
    ]);
    expect(names(AmountEntry.values), ['total', 'installment']);
    expect(names(PlanKind.values), [
      'payIn4',
      'monthly',
      'card',
      'manual',
      'payLater',
    ]);
    expect(names(PaymentMethod.values), ['automatic', 'manual']);
    expect(names(PlanStatus.values), ['open', 'onHold', 'closed']);
    expect(names(CloseReason.values), ['refund', 'cancel']);
    expect(names(InstallmentFeeScope.values), [
      'everyPayment',
      'firstPaymentOnly',
    ]);
    expect(names(Recurrence.values), [
      'weekly',
      'biweekly',
      'monthly',
      'yearly',
    ]);
    expect(names(SourceKind.values).toSet(), backupSourceKinds);
    expect(names(PlanOrigin.values).toSet(), backupPlanOrigins);
  });
}

/// Field paths and types from the tables of docs/YEDEK_BICIMI.md: rows
/// "| `path` | type | ... |".
Map<String, String> documentedFields(String doc) => {
  for (final m in RegExp(
    r'^\| `([^`]+)` \| (\w+) \|',
    multiLine: true,
  ).allMatches(doc))
    m[1]!: m[2]!,
};

/// "data.plans[].payments[].amount" → "int", for every field present in
/// [json] (a field that is null everywhere reads as a string).
void collectTypes(Object? json, String path, Map<String, String> out) {
  if (json is Map<String, Object?>) {
    if (path.isNotEmpty) out[path] = 'object';
    for (final MapEntry(:key, :value) in json.entries) {
      collectTypes(value, path.isEmpty ? key : '$path.$key', out);
    }
  } else if (json is List<Object?>) {
    out[path] = 'array';
    for (final item in json) {
      collectTypes(item, '$path[]', out);
    }
  } else {
    final type = switch (json) {
      null => null,
      int() => 'int',
      bool() => 'bool',
      String() => 'string',
      _ => 'other',
    };
    if (type != null) out[path] = type;
    out.putIfAbsent(path, () => 'string');
  }
}
