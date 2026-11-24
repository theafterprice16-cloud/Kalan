/// The full backup file (Roadmap 29): a small JSON envelope around
/// [BackupData], optionally encrypted with a password. Writer and reader
/// both live here; restoring (Roadmap 30) reads with [readBackupBytes].
/// Format: docs/YEDEK_BICIMI.md.
///
/// Encryption: the password is stretched into a 256-bit key with Argon2id
/// (fresh random salt per file) and the content is sealed with
/// AES-256-GCM (fresh random nonce per file). Every envelope field but
/// the ciphertext is authenticated too (as additional data), so a file
/// whose header, ciphertext or tag changed by a single byte does not
/// open, even with the right password. The password itself is never
/// stored, logged or kept: forgotten, the file cannot be opened.
///
/// Pure Dart (the cryptography package's Dart implementations, the same
/// on every platform and in tests). Deriving the key takes about a
/// second by design: callers run [writeBackup] and [readBackup] away from
/// the UI isolate.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import 'backup_data.dart';
import 'backup_json.dart';
import 'backup_upgrade.dart';

/// The file's format name.
const backupFormatName = 'kalan-backup';

/// The format version this app writes, and the newest it reads. Older
/// versions are brought up to it by [upgradeBackupContent].
const backupFormatVersion = 1;

/// The largest file Kalan opens (Roadmap 30): 50 MB, far above any real
/// backup (a few hundred plans are well under 1 MB). Anything larger is
/// not read at all.
const backupMaxBytes = 50 * 1024 * 1024;

/// Why a file could not be read. Never carries the password or content.
enum BackupReadError {
  /// Not JSON, or not a Kalan backup.
  notABackup,

  /// Written by a newer Kalan: update the app first.
  newerVersion,

  /// Encrypted, and no password was given.
  passwordNeeded,

  /// Encrypted, and it does not open with the given password: a wrong
  /// password or a changed file (the two cannot be told apart).
  wrongPasswordOrChanged,

  /// The content is missing parts or was changed.
  damaged,
}

class BackupReadException implements Exception {
  const BackupReadException(this.error);

  final BackupReadError error;

  @override
  String toString() => 'BackupReadException(${error.name})';
}

/// Password key derivation settings, as written in the file.
sealed class BackupKdf {
  const BackupKdf();

  /// What Kalan writes: Argon2id, 46 MiB, 2 passes, 1 lane (above
  /// OWASP's minimum of 46 MiB and 1 pass); about 0.35 s on a CI server,
  /// an estimated 1-2 s on a mid-range phone. See docs/DECISIONS.md,
  /// "Dışa aktarma (29)".
  static const standard = Argon2idKdf(memoryKiB: 47104, iterations: 2);

  Future<SecretKey> deriveKey(List<int> password, List<int> salt);

  Map<String, Object?> paramsJson();

  /// The values authenticated with the content, in a fixed order.
  List<Object?> get authenticated;
}

class Argon2idKdf extends BackupKdf {
  const Argon2idKdf({
    required this.memoryKiB,
    required this.iterations,
    this.parallelism = 1,
  });

  static const algorithm = 'argon2id';

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  @override
  Future<SecretKey> deriveKey(List<int> password, List<int> salt) =>
      DartArgon2id(
        parallelism: parallelism,
        memory: memoryKiB,
        iterations: iterations,
        hashLength: 32,
        // Already away from the UI isolate (see the library note).
        maxIsolates: 0,
      ).deriveKey(secretKey: SecretKey(password), nonce: salt);

  @override
  Map<String, Object?> paramsJson() => {
    'algorithm': algorithm,
    'memoryKiB': memoryKiB,
    'iterations': iterations,
    'parallelism': parallelism,
  };

  @override
  List<Object?> get authenticated => [
    algorithm,
    memoryKiB,
    iterations,
    parallelism,
  ];
}

/// Read only (a fallback the format allows; Kalan writes Argon2id).
class Pbkdf2Kdf extends BackupKdf {
  const Pbkdf2Kdf({required this.iterations});

  static const algorithm = 'pbkdf2-hmac-sha256';

  final int iterations;

  @override
  Future<SecretKey> deriveKey(List<int> password, List<int> salt) => DartPbkdf2(
    macAlgorithm: DartHmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(password), nonce: salt);

  @override
  Map<String, Object?> paramsJson() => {
    'algorithm': algorithm,
    'iterations': iterations,
  };

  @override
  List<Object?> get authenticated => [algorithm, iterations];
}

/// The envelope fields readable without a password.
class BackupHeader {
  const BackupHeader({
    required this.formatVersion,
    required this.appVersion,
    required this.createdAt,
    required this.currency,
    required this.encrypted,
  });

  final int formatVersion;
  final String appVersion;

  /// When the file was made, UTC to the second.
  final DateTime createdAt;

  /// ISO 4217 code of every amount inside.
  final String currency;
  final bool encrypted;
}

/// A file read back: its header and its content.
class BackupContents {
  const BackupContents({required this.header, required this.data});

  final BackupHeader header;
  final BackupData data;
}

const _saltLength = 16;
const _nonceLength = 12;
const _tagLength = 16;
const _cipherName = 'AES-256-GCM';

/// Writes [data] as a backup file (UTF-8 JSON text). With a non-empty
/// [password] the content is encrypted. [random] is for tests only; the
/// default is the platform's secure random generator.
Future<String> writeBackup(
  BackupData data, {
  required String appVersion,
  required DateTime createdAt,
  String? password,
  BackupKdf kdf = BackupKdf.standard,
  Random? random,
}) async {
  final header = <String, Object?>{
    'format': backupFormatName,
    'formatVersion': backupFormatVersion,
    'appVersion': appVersion,
    'createdAt': formatInstant(createdAt),
    'currency': data.settings.currency,
  };
  final content = utf8.encode(jsonEncode(data.toJson()));
  if (password == null || password.isEmpty) {
    return _pretty({
      ...header,
      'encrypted': false,
      'dataSha256': _sha256Hex(content),
      'data': data.toJson(),
    });
  }
  final rng = random ?? Random.secure();
  List<int> bytes(int n) => [for (var i = 0; i < n; i++) rng.nextInt(256)];
  final salt = bytes(_saltLength);
  final nonce = bytes(_nonceLength);
  final key = await kdf.deriveKey(utf8.encode(password), salt);
  final kdfJson = {...kdf.paramsJson(), 'salt': base64.encode(salt)};
  final cipherJson = {'algorithm': _cipherName, 'nonce': base64.encode(nonce)};
  final box = await DartAesGcm.with256bits().encrypt(
    content,
    secretKey: key,
    nonce: nonce,
    aad: _aad(
      formatVersion: backupFormatVersion,
      appVersion: appVersion,
      createdAt: header['createdAt']! as String,
      currency: data.settings.currency,
      kdf: kdf,
      salt: kdfJson['salt']! as String,
      nonce: cipherJson['nonce']!,
    ),
  );
  return _pretty({
    ...header,
    'encrypted': true,
    'kdf': kdfJson,
    'cipher': cipherJson,
    'ciphertext': base64.encode([...box.cipherText, ...box.mac.bytes]),
  });
}

/// The header of a backup file, without opening its content (Roadmap 30
/// shows it before asking for a password).
BackupHeader readBackupHeader(String text) =>
    _parse(text, backupFormatVersion).header;

/// [readBackup] on a file's bytes, as picked (Roadmap 30): more than
/// [backupMaxBytes] or text that is not UTF-8 (a photo, a PDF) is never
/// parsed. Run away from the UI isolate.
Future<BackupContents> readBackupBytes(
  List<int> bytes, {
  String? password,
}) async {
  if (bytes.length > backupMaxBytes) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const BackupReadException(BackupReadError.notABackup);
  }
  return readBackup(text, password: password);
}

/// Reads a backup file written by [writeBackup] (any format version up to
/// [backupFormatVersion]; older content goes through [upgradeBackupContent]
/// first). Unknown fields are ignored; anything else unexpected is a
/// [BackupReadException]. The content is fully checked
/// ([BackupData.validate]) before it is returned, so nothing is written
/// from a file that fails.
///
/// [currentVersion] and [steps] are for tests of the upgrade chain only.
Future<BackupContents> readBackup(
  String text, {
  String? password,
  int currentVersion = backupFormatVersion,
  Map<int, BackupUpgradeStep> steps = backupUpgradeSteps,
}) async {
  final (:header, :fields) = _parse(text, currentVersion);
  final Object? dataJson;
  if (!header.encrypted) {
    dataJson = _guard(() => fields.object('data').raw);
    final sum = _guard(() => fields.string('dataSha256'));
    if (_sha256Hex(utf8.encode(jsonEncode(dataJson))) != sum) {
      throw const BackupReadException(BackupReadError.damaged);
    }
  } else {
    if (password == null || password.isEmpty) {
      throw const BackupReadException(BackupReadError.passwordNeeded);
    }
    final (kdf, salt, nonce, sealed) = _guard(() => _sealedParts(fields));
    final key = await kdf.deriveKey(utf8.encode(password), salt);
    final List<int> clear;
    try {
      clear = await DartAesGcm.with256bits().decrypt(
        SecretBox(
          sealed.sublist(0, sealed.length - _tagLength),
          nonce: nonce,
          mac: Mac(sealed.sublist(sealed.length - _tagLength)),
        ),
        secretKey: key,
        aad: _aad(
          // The file's own version: an older file was sealed with it.
          formatVersion: header.formatVersion,
          appVersion: header.appVersion,
          // As written: the text is what was authenticated.
          createdAt: fields.string('createdAt'),
          currency: header.currency,
          kdf: kdf,
          salt: fields.object('kdf').string('salt'),
          nonce: fields.object('cipher').string('nonce'),
        ),
      );
    } on SecretBoxAuthenticationError {
      throw const BackupReadException(BackupReadError.wrongPasswordOrChanged);
    }
    dataJson = _guard(() => jsonDecode(utf8.decode(clear)));
  }
  final data = _guard(
    () => BackupData.fromJson(
      upgradeBackupContent(
        dataJson,
        from: header.formatVersion,
        to: currentVersion,
        steps: steps,
      ),
    )..validate(),
  );
  if (data.settings.currency != header.currency) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  return BackupContents(header: header, data: data);
}

String _pretty(Map<String, Object?> json) =>
    '${const JsonEncoder.withIndent('  ').convert(json)}\n';

String _sha256Hex(List<int> bytes) => [
  for (final b in const DartSha256().hashSync(bytes).bytes)
    b.toRadixString(16).padLeft(2, '0'),
].join();

/// Everything in the envelope but the ciphertext, in a fixed order; text
/// values (salt and nonce included) exactly as written in the file.
List<int> _aad({
  required int formatVersion,
  required String appVersion,
  required String createdAt,
  required String currency,
  required BackupKdf kdf,
  required String salt,
  required String nonce,
}) => utf8.encode(
  jsonEncode([
    backupFormatName,
    formatVersion,
    appVersion,
    createdAt,
    currency,
    true,
    ...kdf.authenticated,
    salt,
    _cipherName,
    nonce,
  ]),
);

T _guard<T>(T Function() read) {
  try {
    return read();
  } on BackupReadException {
    rethrow;
  } on Object {
    throw const BackupReadException(BackupReadError.damaged);
  }
}

({BackupHeader header, JsonFields fields}) _parse(
  String text,
  int currentVersion,
) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const BackupReadException(BackupReadError.notABackup);
  }
  if (json is! Map<String, Object?> || json['format'] != backupFormatName) {
    throw const BackupReadException(BackupReadError.notABackup);
  }
  final version = json['formatVersion'];
  if (version is! int || version < 1) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  if (version > currentVersion) {
    throw const BackupReadException(BackupReadError.newerVersion);
  }
  final fields = JsonFields(json, '');
  final header = _guard(
    () => BackupHeader(
      formatVersion: version,
      appVersion: fields.string('appVersion'),
      createdAt: fields.instant('createdAt'),
      currency: fields.string('currency'),
      encrypted: fields.boolean('encrypted'),
    ),
  );
  return (header: header, fields: fields);
}

/// The key derivation, salt, nonce and sealed bytes of an encrypted
/// file, with limits so a changed file cannot ask for absurd work.
(BackupKdf, Uint8List, Uint8List, Uint8List) _sealedParts(JsonFields f) {
  final kdfFields = f.object('kdf');
  final BackupKdf kdf = switch (kdfFields.string('algorithm')) {
    Argon2idKdf.algorithm => Argon2idKdf(
      memoryKiB: _within(kdfFields.integer('memoryKiB'), 8, 256 * 1024),
      iterations: _within(kdfFields.integer('iterations'), 1, 64),
      parallelism: _within(kdfFields.integer('parallelism'), 1, 16),
    ),
    Pbkdf2Kdf.algorithm => Pbkdf2Kdf(
      iterations: _within(kdfFields.integer('iterations'), 1, 2000000),
    ),
    _ => throw const BackupReadException(BackupReadError.damaged),
  };
  if (kdf case Argon2idKdf(:final memoryKiB, :final parallelism)
      when memoryKiB < 8 * parallelism) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  final salt = base64.decode(kdfFields.string('salt'));
  final cipher = f.object('cipher');
  if (cipher.string('algorithm') != _cipherName) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  final nonce = base64.decode(cipher.string('nonce'));
  final sealed = base64.decode(f.string('ciphertext'));
  if (salt.length < _saltLength ||
      salt.length > 64 ||
      nonce.length != _nonceLength ||
      sealed.length < _tagLength) {
    throw const BackupReadException(BackupReadError.damaged);
  }
  return (kdf, salt, nonce, sealed);
}

int _within(int value, int min, int max) => value < min || value > max
    ? throw const BackupReadException(BackupReadError.damaged)
    : value;
