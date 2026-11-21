// Key integrity across the 22 locales (Roadmap 24, decision 6).
//
// Open locales (users can see them) carry every message with the same
// placeholders as English. Closed ones may lack messages, but exactly the
// ones docs/ceviriler/cevrilecekler.json lists: gen-l10n writes that file
// (l10n.yaml, untranslated-messages-file) on `flutter gen-l10n`,
// `flutter pub get`, `flutter run` and builds; CI checks the committed
// file is the regenerated one.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/l10n/app_locales.dart';

const arbDir = 'lib/l10n';
const untranslatedPath = 'docs/ceviriler/cevrilecekler.json';

Map<String, dynamic> loadArb(String code) =>
    jsonDecode(File('$arbDir/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Message keys of an ARB map (no "@" metadata).
Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Placeholder names a message uses, plain ("{amount}") or as a plural
/// or select argument ("{count, plural, …}"); the words inside a branch
/// ("EUR{Euro}") are text, not placeholders.
Set<String> placeholdersIn(String message) {
  final out = <String>{};
  late final int Function(int) argument;
  // Reads text from [i] up to its closing "}" (or the end); returns the
  // index after it.
  int text(int i) {
    while (i < message.length) {
      final c = message[i];
      if (c == '}') return i + 1;
      if (c == '{') {
        i = argument(i + 1);
      } else {
        i++;
      }
    }
    return i;
  }

  argument = (i) {
    final start = i;
    while (i < message.length && message[i] != ',' && message[i] != '}') {
      i++;
    }
    out.add(message.substring(start, i).trim());
    if (i >= message.length || message[i] == '}') return i + 1;
    final typeStart = ++i;
    while (i < message.length && message[i] != ',' && message[i] != '}') {
      i++;
    }
    final type = message.substring(typeStart, i).trim();
    if (i >= message.length || message[i] == '}') return i + 1;
    i++;
    if (!{'plural', 'select', 'selectordinal'}.contains(type)) {
      // A style ("{n, number, compact}"): skip to the closing brace.
      return text(i);
    }
    // Branches: a selector, then its text in braces.
    while (i < message.length) {
      final c = message[i];
      if (c == '}') return i + 1;
      i = c == '{' ? text(i + 1) : i + 1;
    }
    return i;
  };

  text(0);
  return out;
}

/// The ARB codes in lib/l10n ('en', 'en_GB', 'zh_Hant').
Set<String> arbCodes() => {
  for (final f in Directory(arbDir).listSync())
    if (f is File && f.path.endsWith('.arb'))
      RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)![1]!,
};

/// What gen-l10n lists as untranslated: per locale (other than English),
/// the [template]'s messages missing from it, from its script parent
/// (zh_Hant_TW → zh_Hant) and from its language file. [keysOf] gives
/// each ARB's message keys.
Map<String, List<String>> untranslatedFor(
  List<String> template,
  Map<String, Set<String>> keysOf,
) {
  final codes = keysOf.keys.where((c) => c != 'en').toList()..sort();
  final out = <String, List<String>>{};
  for (final code in codes) {
    final parts = code.split('_');
    final chain = {
      code,
      if (parts.length > 2) '${parts[0]}_${parts[1]}',
      parts[0],
    }.where(keysOf.containsKey);
    final present = {for (final c in chain) ...keysOf[c]!};
    final missing = [
      for (final k in template)
        if (!present.contains(k)) k,
    ];
    if (missing.isNotEmpty) out[code] = missing;
  }
  return out;
}

List<String> templateKeys() => [
  for (final k in loadArb('en').keys)
    if (!k.startsWith('@')) k,
];

Map<String, Set<String>> repoKeys() => {
  for (final c in arbCodes()) c: messageKeys(loadArb(c)),
};

Map<String, List<String>> expectedUntranslated() =>
    untranslatedFor(templateKeys(), repoKeys());

void main() {
  final en = loadArb('en');

  test('the placeholder reader skips branch text', () {
    expect(placeholdersIn('{amount} left'), {'amount'});
    expect(placeholdersIn('{code, select, EUR{Euro} other{{code}}}'), {'code'});
    expect(placeholdersIn('{code, select, EUR{ユーロ} other{{code}}}'), {'code'});
    expect(
      placeholdersIn(
        '{count, plural, =1{1 plan on {date}} other{{count} plans}} {total}',
      ),
      {'count', 'date', 'total'},
    );
  });
  final enKeys = messageKeys(en);

  test('every registry locale has an ARB file, and no other file', () {
    expect(arbCodes(), {
      for (final l in appLocales) l.code,
      ...fallbackArbCodes,
    });
  });

  test('each ARB file names its own locale', () {
    for (final code in arbCodes()) {
      expect(loadArb(code)['@@locale'], code, reason: 'app_$code.arb');
    }
  });

  test('no locale has a message English lacks', () {
    for (final code in arbCodes()) {
      expect(
        messageKeys(loadArb(code)).difference(enKeys),
        isEmpty,
        reason: code,
      );
    }
  });

  test('open locales carry every message with English placeholders', () {
    final open = openLocales();
    expect(open.map((l) => l.code), containsAll(['tr', 'en']));
    for (final locale in open) {
      final arb = loadArb(locale.code);
      expect(
        enKeys.difference(messageKeys(arb)),
        isEmpty,
        reason: '${locale.code} is open but untranslated',
      );
      for (final k in enKeys) {
        final message = arb[k] as String;
        expect(message.trim(), isNotEmpty, reason: '${locale.code}.$k');
        expect(
          placeholdersIn(message),
          placeholdersIn(en[k] as String),
          reason: '${locale.code}.$k',
        );
      }
    }
  });

  test('the untranslated list matches the ARB files', () {
    final file = File(untranslatedPath);
    expect(file.existsSync(), isTrue, reason: 'run flutter gen-l10n');
    final listed = (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as List).cast<String>()));
    expect(
      listed,
      expectedUntranslated(),
      reason: 'run flutter gen-l10n and commit $untranslatedPath',
    );
  });

  test('no open locale is waiting for translation', () {
    final listed = expectedUntranslated().keys.toSet();
    for (final l in openLocales()) {
      expect(listed, isNot(contains(l.code)), reason: l.code);
    }
  });

  test('gen-l10n writes the untranslated list to docs/ceviriler', () {
    final yaml = File('l10n.yaml').readAsStringSync();
    expect(yaml, contains('untranslated-messages-file: $untranslatedPath'));
    expect(yaml, contains('template-arb-file: app_en.arb'));
  });

  // Example 2: a later item adds "providerStart" to the English and
  // Turkish files only. It is listed under the 20 other locales (en_GB
  // inherits English), whatever has been translated by then.
  test('a new message lands in the list for 20 locales', () {
    final keys = repoKeys();
    keys['en'] = {...keys['en']!, 'providerStart'};
    keys['tr'] = {...keys['tr']!, 'providerStart'};
    final listed = untranslatedFor([...templateKeys(), 'providerStart'], keys);
    final withNew = {
      for (final e in listed.entries)
        if (e.value.contains('providerStart')) e.key,
    };
    expect(withNew, hasLength(20));
    expect(withNew, isNot(contains('en_GB')));
    expect(withNew, isNot(contains('tr')));
    expect(withNew, containsAll(['ar', 'pt', 'pt_BR', 'zh_Hant', 'es_419']));
  });
}
