// Plurals (Roadmap 24, decision 11): a message that counts something is
// an ICU plural, and every translated locale gives each plural every
// category CLDR uses for its language (Arabic six, Russian and Polish
// four). Today Turkish and English; the bulk translation adds the rest.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalan/l10n/app_locales.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Map<String, dynamic> loadArb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Numbers that are not a count of something: a day of the month, a
/// position, a fraction or a bare number. Every other message with a
/// number is a plural. Add here only with a reason.
const notCounts = {
  'progressLabel', // "3/10"
  'progressSemantics', // "Payment 3 of 10": a position
  'cardSummary', // statement and due days of the month
  'paySummaryMonthly', // day of the month
  'payLaterNextMonthDay', // day of the month
  'planPaidOf', // "2/4 paid"
  'numberValue', // a bare number
  'previewSameMonthItem', // "August 2027 (2)"
};

/// Categories CLDR has for a language that read the same in it, so a
/// translation may leave them to "other": Turkish nouns do not change
/// after a number (CLDR minimal pairs: "{0} gün" for one and other).
const optionalCategories = {
  'tr': {'one'},
};

/// The CLDR plural categories of [language], from intl's rules: those
/// whole numbers reach, and "other" (ICU needs it; in Russian and Polish
/// it holds fractions).
Set<String> categoriesOf(String language) => {
  'other',
  for (final n in [...List.generate(1001, (i) => i), 1000000, 1000001])
    Intl.pluralLogic(
      n,
      locale: language,
      zero: 'zero',
      one: 'one',
      two: 'two',
      few: 'few',
      many: 'many',
      other: 'other',
      useExplicitNumberCases: false,
    ),
};

/// Each plural argument in [message] with its selectors, read as
/// gen-l10n does (=0, =1 and =2 fill zero, one and two).
List<(String, Set<String>)> pluralsIn(String message) {
  final out = <(String, Set<String>)>[];
  for (final m in RegExp(r'\{(\w+)\s*,\s*plural\s*,').allMatches(message)) {
    final selectors = <String>{};
    var i = m.end;
    while (i < message.length) {
      while (i < message.length && message[i].trim().isEmpty) {
        i++;
      }
      if (i >= message.length || message[i] == '}') break;
      final start = i;
      while (message[i] != '{' && message[i].trim().isNotEmpty) {
        i++;
      }
      final selector = message.substring(start, i);
      selectors.add(switch (selector) {
        '=0' => 'zero',
        '=1' => 'one',
        '=2' => 'two',
        _ => selector,
      });
      while (message[i] != '{') {
        i++;
      }
      var depth = 0;
      do {
        if (message[i] == '{') depth++;
        if (message[i] == '}') depth--;
        i++;
      } while (depth > 0);
    }
    out.add((m[1]!, selectors));
  }
  return out;
}

void main() {
  final en = loadArb('en');
  final messages = [
    for (final k in en.keys)
      if (!k.startsWith('@')) k,
  ];

  test('CLDR categories as decision 11 lists them', () {
    expect(categoriesOf('ar'), {'zero', 'one', 'two', 'few', 'many', 'other'});
    expect(categoriesOf('ru'), {'one', 'few', 'many', 'other'});
    expect(categoriesOf('pl'), {'one', 'few', 'many', 'other'});
    expect(categoriesOf('tr'), {'one', 'other'});
    expect(categoriesOf('en'), {'one', 'other'});
    expect(categoriesOf('ja'), {'other'});
  });

  test('a message that counts something is a plural', () {
    for (final k in messages) {
      final meta = en['@$k'] as Map<String, dynamic>?;
      final placeholders =
          (meta?['placeholders'] as Map<String, dynamic>?) ?? const {};
      final numbers = placeholders.entries.where(
        (e) => ['int', 'num', 'double'].contains((e.value as Map)['type']),
      );
      if (numbers.isEmpty || notCounts.contains(k)) continue;
      expect(pluralsIn(en[k] as String), isNotEmpty, reason: k);
    }
    for (final k in notCounts) {
      expect(messages, contains(k), reason: 'stale exception $k');
    }
  });

  test('the plural reader sees every selector', () {
    List<String> read(String m) => [
      for (final (name, s) in pluralsIn(m)) '$name: ${s.toList()..sort()}',
    ];
    expect(read('{n, plural, =0{none} =1{one {n}} other{{n} of {m}}}'), [
      'n: [one, other, zero]',
    ]);
    expect(
      read(
        '{a} {n, plural, few{x} many{y} other{z}} {k, plural, one{q} '
        'other{w}}',
      ),
      ['n: [few, many, other]', 'k: [one, other]'],
    );
  });

  // Every translated locale (open ones today; the bulk translation's
  // drafts and reviews later) gives each plural its language's categories.
  for (final locale in openLocales()) {
    test('${locale.code}: every plural has every category', () {
      final arb = loadArb(locale.code);
      final language = locale.languageCode;
      final required = categoriesOf(language)
          .difference(optionalCategories[language] ?? const {});
      for (final k in messages) {
        for (final (name, selectors) in pluralsIn(arb[k] as String)) {
          expect(
            selectors,
            containsAll(required),
            reason: '${locale.code}.$k ($name)',
          );
        }
      }
    });
  }

  test('the plural messages read as before in Turkish and English', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(
      en.proIntro(4),
      'The free version keeps up to 4 open plans. Pro removes the limit and '
      'adds:',
    );
    expect(
      tr.proIntro(4),
      'Ücretsiz sürümde 4 açık plan var. Pro ile sınır kalkar ve şunlar '
      'açılır:',
    );
    expect(
      en.limitSheetBody(4),
      'The free version keeps up to 4 open plans. You can add a new one when '
      'a plan finishes, or with Pro.',
    );
    expect(
      tr.limitSheetBody(4),
      'Ücretsiz sürümde 4 açık plan var. Bir planı bitirdiğinde ya da Pro ile '
      'yenisini ekleyebilirsin.',
    );
    expect(en.pastDueShowAll(1), 'Show all (1)');
    expect(en.pastDueShowAll(5), 'Show all (5)');
    expect(en.calendarCellSomeLate(1), '1 late');
    expect(en.calendarCellSomePaid(2), '2 paid');
  });
}
