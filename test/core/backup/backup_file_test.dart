import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/backup/backup_data.dart';
import 'package:kalan/core/backup/backup_file.dart';

/// A small backup: settings, one card, one plan with two payments.
BackupData sample({String currency = 'COP'}) => BackupData.fromJson({
  'settings': {
    'currency': currency,
    'payFrequency': 'monthly',
    'payDay': 15,
    'netIncome': 3000000,
    'reminders': {
      'enabled': true,
      'leadDays': 2,
      'minuteOfDay': 540,
      'showAmounts': true,
      'repeatMode': 'off',
      'paydaySummary': true,
    },
    'holidayCountry': '',
  },
  'sources': [
    {
      'id': 1,
      'name': 'Bancolombia',
      'kind': 'card',
      'statementDay': 25,
      'dueDay': 5,
      'moveDueToBusinessDay': true,
      'moveDueForHolidays': true,
      'statementReminder': {'enabled': false, 'daysBefore': 2},
      'createdAt': '2026-11-01T10:00:00Z',
    },
  ],
  'plans': [
    {
      'id': 1,
      'sourceId': 1,
      'title': 'Teléfono',
      'kind': 'card',
      'installmentCount': 2,
      'deferMonths': 0,
      'isCashAdvance': false,
      'origin': 'template',
      'createdAt': '2026-11-01T10:00:00Z',
      'reminders': {'enabled': true},
      'status': 'open',
      'installmentFeeScope': 'everyPayment',
      'payments': [
        {
          'seq': 1,
          'dueDate': '2026-12-04',
          'amount': 125000,
          'isEdited': false,
          'paidBeforeKalan': false,
        },
        {
          'seq': 2,
          'dueDate': '2027-01-05',
          'amount': 125000,
          'paidAt': '2026-11-20T08:00:00Z',
          'isEdited': false,
          'paidBeforeKalan': false,
        },
      ],
    },
  ],
  'recurringPayments': <Object?>[],
});

/// Fast settings for tests; the real ones are [BackupKdf.standard].
const fast = Argon2idKdf(memoryKiB: 64, iterations: 1);

Future<String> write({String? password, Random? random}) => writeBackup(
  sample(),
  appVersion: '1.0.0+1',
  createdAt: DateTime.utc(2026, 11, 19, 7, 30, 5, 123),
  password: password,
  kdf: fast,
  random: random,
);

Map<String, Object?> decode(String text) =>
    jsonDecode(text) as Map<String, Object?>;

Future<BackupReadError?> errorOf(String text, {String? password}) async {
  try {
    await readBackup(text, password: password);
    return null;
  } on BackupReadException catch (e) {
    return e.error;
  }
}

/// [json] (a file without a password) with its checksum written again
/// for its current content, as a newer app would.
String resummed(Map<String, Object?> json) {
  final sum = const DartSha256().hashSync(
    utf8.encode(jsonEncode(json['data'])),
  );
  json['dataSha256'] = [
    for (final b in sum.bytes) b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return jsonEncode(json);
}

/// [text] with one byte of the base64 field [path] changed.
String flip(String text, List<String> path) {
  final json = decode(text);
  var node = json;
  for (final key in path.take(path.length - 1)) {
    node = node[key]! as Map<String, Object?>;
  }
  final bytes = base64.decode(node[path.last]! as String);
  bytes[bytes.length ~/ 2] ^= 0x01;
  node[path.last] = base64.encode(bytes);
  return jsonEncode(json);
}

void main() {
  group('no password', () {
    test('envelope and content, read back the same', () async {
      final text = await write();
      final json = decode(text);
      expect(json['format'], 'kalan-backup');
      expect(json['formatVersion'], 1);
      expect(json['appVersion'], '1.0.0+1');
      expect(json['createdAt'], '2026-11-19T07:30:05Z');
      expect(json['currency'], 'COP');
      expect(json['encrypted'], false);
      expect(json['dataSha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      final back = await readBackup(text);
      expect(back.data.toJson(), sample().toJson());
      expect(back.header.encrypted, isFalse);
      expect(back.header.createdAt, DateTime.utc(2026, 11, 19, 7, 30, 5));
    });

    test('amounts are whole minor units, dates yyyy-MM-dd', () async {
      final text = await write();
      expect(text, contains('"amount": 125000'));
      expect(text, contains('"dueDate": "2026-12-04"'));
      expect(text, isNot(contains('125000.')));
    });

    test('a changed value does not open (accidental damage)', () async {
      final text = (await write()).replaceFirst('125000', '125001');
      expect(await errorOf(text), BackupReadError.damaged);
    });

    test('reformatted by an editor, it still opens', () async {
      final text = jsonEncode(decode(await write()));
      expect((await readBackup(text)).data.toJson(), sample().toJson());
    });
  });

  group('with a password', () {
    test('only the right password opens it', () async {
      final text = await write(password: 'çok gizli 1');
      final json = decode(text);
      expect(json['encrypted'], true);
      expect(json.containsKey('data'), isFalse);
      expect(json['kdf'], {
        'algorithm': 'argon2id',
        'memoryKiB': 64,
        'iterations': 1,
        'parallelism': 1,
        'salt': isA<String>(),
      });
      expect((json['cipher']! as Map)['algorithm'], 'AES-256-GCM');
      final back = await readBackup(text, password: 'çok gizli 1');
      expect(back.data.toJson(), sample().toJson());
      expect(
        await errorOf(text, password: 'çok gizli 2'),
        BackupReadError.wrongPasswordOrChanged,
      );
      expect(await errorOf(text), BackupReadError.passwordNeeded);
      expect(await errorOf(text, password: ''), BackupReadError.passwordNeeded);
    });

    test('the header opens without the password', () async {
      final header = readBackupHeader(await write(password: 'p'));
      expect(header.encrypted, isTrue);
      expect(header.currency, 'COP');
      expect(header.formatVersion, 1);
    });

    test(
      'one changed byte anywhere does not open, even with the password',
      () async {
        final text = await write(password: 'p');
        for (final path in [
          ['ciphertext'],
          ['cipher', 'nonce'],
          ['kdf', 'salt'],
        ]) {
          expect(
            await errorOf(flip(text, path), password: 'p'),
            BackupReadError.wrongPasswordOrChanged,
            reason: path.join('.'),
          );
        }
        // The header is authenticated with the content.
        for (final (from, to) in [
          ('"currency": "COP"', '"currency": "USD"'),
          ('2026-11-19T07:30:05Z', '2026-11-19T07:30:06Z'),
          ('"appVersion": "1.0.0+1"', '"appVersion": "1.0.0+2"'),
          ('"iterations": 1', '"iterations": 2'),
        ]) {
          expect(
            await errorOf(text.replaceFirst(from, to), password: 'p'),
            BackupReadError.wrongPasswordOrChanged,
            reason: from,
          );
        }
      },
    );

    test('a fresh salt and nonce every time', () async {
      final a = decode(await write(password: 'p'));
      final b = decode(await write(password: 'p'));
      expect((a['kdf']! as Map)['salt'], isNot((b['kdf']! as Map)['salt']));
      expect(
        (a['cipher']! as Map)['nonce'],
        isNot((b['cipher']! as Map)['nonce']),
      );
      expect(a['ciphertext'], isNot(b['ciphertext']));
      expect(
        base64.decode((a['kdf']! as Map)['salt']! as String),
        hasLength(16),
      );
      expect(
        base64.decode((a['cipher']! as Map)['nonce']! as String),
        hasLength(12),
      );
    });

    test('the password is nowhere in the file', () async {
      const password = 'BenimParolam-2026';
      final text = await write(password: password);
      expect(text, isNot(contains(password)));
      expect(text, isNot(contains(base64.encode(utf8.encode(password)))));
      expect(text, isNot(contains('Teléfono')));
    });

    test('reads the PBKDF2 fallback too', () async {
      final text = await writeBackup(
        sample(),
        appVersion: '1.0.0+1',
        createdAt: DateTime.utc(2026, 11, 19),
        password: 'p',
        kdf: const Pbkdf2Kdf(iterations: 1000),
      );
      expect(
        decode(text)['kdf'],
        containsPair('algorithm', 'pbkdf2-hmac-sha256'),
      );
      expect(
        (await readBackup(text, password: 'p')).data.toJson(),
        sample().toJson(),
      );
    });

    test('limits a changed file cannot get past', () async {
      final text = await write(password: 'p');
      for (final (from, to) in [
        ('"memoryKiB": 64', '"memoryKiB": 99999999'),
        ('"iterations": 1', '"iterations": 1000'),
        ('"algorithm": "argon2id"', '"algorithm": "scrypt"'),
        ('"algorithm": "AES-256-GCM"', '"algorithm": "AES-128-GCM"'),
      ]) {
        expect(
          await errorOf(text.replaceFirst(from, to), password: 'p'),
          BackupReadError.damaged,
          reason: to,
        );
      }
      final json = decode(text)..['ciphertext'] = 'not base64!';
      expect(
        await errorOf(jsonEncode(json), password: 'p'),
        BackupReadError.damaged,
      );
    });

    test('the standard settings: Argon2id, 46 MiB, 2 passes', () {
      expect(BackupKdf.standard.paramsJson(), {
        'algorithm': 'argon2id',
        'memoryKiB': 47104,
        'iterations': 2,
        'parallelism': 1,
      });
    });

    // RFC 9106, 5.3: the library's Argon2id gives the published tag.
    test('Argon2id known answer (RFC 9106)', () async {
      final key =
          await const DartArgon2id(
            parallelism: 4,
            memory: 32,
            iterations: 3,
            hashLength: 32,
            maxIsolates: 0,
          ).deriveKey(
            secretKey: SecretKey(List.filled(32, 1)),
            nonce: List.filled(16, 2),
            optionalSecret: List.filled(8, 3),
            associatedData: List.filled(12, 4),
          );
      final hex = [
        for (final b in await key.extractBytes())
          b.toRadixString(16).padLeft(2, '0'),
      ].join();
      expect(
        hex,
        '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
      );
    });
  });

  group('reader', () {
    test('not a backup', () async {
      expect(await errorOf('hello'), BackupReadError.notABackup);
      expect(await errorOf('[]'), BackupReadError.notABackup);
      expect(
        await errorOf(jsonEncode({'format': 'other', 'formatVersion': 1})),
        BackupReadError.notABackup,
      );
    });

    test('a newer format version is refused calmly', () async {
      final json = decode(await write())..['formatVersion'] = 2;
      expect(await errorOf(jsonEncode(json)), BackupReadError.newerVersion);
    });

    test('unknown fields are ignored at every level', () async {
      final json = decode(await write());
      json['futureField'] = {'x': 1};
      final data = json['data']! as Map<String, Object?>;
      data['futureList'] = [1, 2];
      ((data['settings']! as Map)['reminders']! as Map)['newSwitch'] = true;
      final plan = (data['plans']! as List).first as Map<String, Object?>;
      plan['newPlanField'] = 'x';
      ((plan['payments']! as List).first as Map)['newPaymentField'] = 1;
      // The checksum covers the content as written: a newer app writes it
      // with its own fields.
      final back = await readBackup(resummed(json));
      expect(back.data.toJson(), sample().toJson());
    });

    test('a missing or wrongly typed field is damage', () async {
      final json = decode(await write());
      final data = json['data']! as Map<String, Object?>;
      final plan = (data['plans']! as List).first as Map<String, Object?>;
      ((plan['payments']! as List).first as Map).remove('dueDate');
      expect(await errorOf(resummed(json)), BackupReadError.damaged);
      for (final (from, to) in [
        ('"amount": 125000', '"amount": 1250.5'),
        ('2026-12-04', '2026-02-30'),
        ('"kind": "card"', '"kind": "wallet"'),
        ('"isEdited": false', '"isEdited": "no"'),
      ]) {
        final changed = decode((await write()).replaceFirst(from, to));
        expect(
          await errorOf(resummed(changed)),
          BackupReadError.damaged,
          reason: to,
        );
      }
    });
  });
}
