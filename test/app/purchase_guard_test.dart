import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The store package stays behind the Entitlement layer, and Kalan never
/// hands the store anything that identifies the user.
void main() {
  Iterable<File> dartFiles(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

  test('screens never import the store package', () {
    final offenders = [
      for (final dir in ['lib/features', 'lib/core', 'lib/app'])
        for (final f in dartFiles(dir))
          if (f.readAsStringSync().contains('package:in_app_purchase')) f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('no user identifier is passed to the store', () {
    final offenders = [
      for (final f in dartFiles('lib'))
        if (RegExp(
          r'applicationUserName|obfuscatedAccountId|obfuscatedProfileId',
        ).hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('the price is never written in code or text', () {
    final offenders = <String>[];
    final price = RegExp(r'14[.,]99|249[.,]99');
    for (final dir in ['lib']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart') && !entity.path.endsWith('.arb')) {
          continue;
        }
        if (price.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
