// TEMPORARY (Roadmap 29): times the backup password key derivation on a
// CI runner, to choose its parameters. Removed before the merge.
// ignore_for_file: avoid_print

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final password = SecretKey('correct horse battery staple'.codeUnits);
  final salt = List<int>.generate(16, (i) => i);
  for (final (memory, iterations) in [
    (19456, 2),
    (12288, 3),
    (47104, 1),
    (65536, 3),
  ]) {
    final kdf = DartArgon2id(
      parallelism: 1,
      memory: memory,
      iterations: iterations,
      hashLength: 32,
      maxIsolates: 0,
    );
    await kdf.deriveKey(secretKey: password, nonce: salt); // warm up
    final watch = Stopwatch()..start();
    await kdf.deriveKey(secretKey: password, nonce: salt);
    print('argon2id m=$memory KiB t=$iterations: ${watch.elapsedMilliseconds} ms');
  }
  final pbkdf2 = DartPbkdf2(
    macAlgorithm: DartHmac.sha256(),
    iterations: 600000,
    bits: 256,
  );
  final watch = Stopwatch()..start();
  await pbkdf2.deriveKey(secretKey: password, nonce: salt);
  print('pbkdf2-sha256 600000: ${watch.elapsedMilliseconds} ms');
}
