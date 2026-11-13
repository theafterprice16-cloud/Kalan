import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colors live only in lib/core/theme (KalanColors, "Mürekkep ve Safran").
/// Anywhere else in lib, a color literal fails here:
/// Color(0x…), Color.fromARGB, Color.fromRGBO, `Colors.<name>` (except
/// Colors.transparent), a hex color code in quotes or comments, or an
/// opacity-derived tone.
final banned = <String, RegExp>{
  'Color(0x…)': RegExp(r'\bColor\(\s*0x'),
  'Color.fromARGB': RegExp(r'\bColor\.fromARGB\b'),
  'Color.fromRGBO': RegExp(r'\bColor\.fromRGBO\b'),
  'Colors.<name>': RegExp(r'\bColors\.(?!transparent\b)\w+'),
  'hex color': RegExp(r'#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?\b'),
  'opacity tone': RegExp(r'\.(withOpacity|withValues|withAlpha)\('),
};

/// Files allowed to break the rule, with a reason. Starts empty.
const exceptions = <String>{};

List<String> offendersIn(String path, List<String> lines) => [
  for (var i = 0; i < lines.length; i++)
    for (final MapEntry(:key, :value) in banned.entries)
      if (value.hasMatch(lines[i])) '$path:${i + 1} ($key)',
];

void main() {
  test('no colors outside lib/core/theme', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/theme/') ||
          path.startsWith('lib/l10n/generated/') ||
          exceptions.contains(path)) {
        continue;
      }
      offenders.addAll(offendersIn(path, entity.readAsLinesSync()));
    }
    expect(offenders, isEmpty);
  });

  test('the guard catches every form', () {
    const samples = [
      'const c = Color(0xFF1D4E89);',
      'Color.fromARGB(255, 29, 78, 137)',
      'Color.fromRGBO(29, 78, 137, 1)',
      'color: Colors.red',
      "final hex = '#1D4E89';",
      'c.text.withValues(alpha: 0.5)',
    ];
    for (final line in samples) {
      expect(offendersIn('x.dart', [line]), isNotEmpty, reason: line);
    }
    expect(offendersIn('x.dart', ['color: Colors.transparent']), isEmpty);
    expect(offendersIn('x.dart', ['color: context.colors.accent']), isEmpty);
  });

  test('no exceptions are listed', () => expect(exceptions, isEmpty));
}
