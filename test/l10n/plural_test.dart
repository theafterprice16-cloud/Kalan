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
  'providerVariantPayLaterNextMonth', // day of the month
  'planPaidOf', // "2/4 paid"
  'numberValue', // a bare number
  'previewSameMonthItem', // "August 2027 (2)"
  'holidayListUntil', // a calendar year ("2028")
};

/// Categories CLDR has for a language that read the same in it, so a
/// translation may leave them to "other": Turkish nouns do not change
/// after a number (CLDR minimal pairs: "{0} gün" for one and other).
const optionalCategories = {
  'tr': {'one'},
};

/// Whole numbers the plural checks look at.
final _samples = [...List.generate(1001, (i) => i), 1000000, 1000001];

/// The CLDR category of [n] in [language], from intl's rules.
String categoryOf(int n, String language) => Intl.pluralLogic(
  n,
  locale: language,
  zero: 'zero',
  one: 'one',
  two: 'two',
  few: 'few',
  many: 'many',
  other: 'other',
  useExplicitNumberCases: false,
);

/// The CLDR plural categories of [language]: those whole numbers reach,
/// and "other" (ICU needs it; in Russian and Polish it holds fractions).
Set<String> categoriesOf(String language) => {
  'other',
  for (final n in _samples) categoryOf(n, language),
};

/// Whether a plural's [selectors] cover [category] in [language]. gen-l10n
/// fills zero, one and two from "=0", "=1" and "=2" too, but such a
/// branch says that one number ("1 plan"): it covers the category only
/// where the category holds that number alone (English "one" is 1;
/// Russian "one" is also 21 and 31, so it needs a real "one" branch).
bool covers(Set<String> selectors, String category, String language) {
  if (selectors.contains(category)) return true;
  const explicit = {'zero': '=0', 'one': '=1', 'two': '=2'};
  final exact = explicit[category];
  if (exact == null || !selectors.contains(exact)) return false;
  final members = {
    for (final n in _samples)
      if (categoryOf(n, language) == category) n,
  };
  return members.length == 1 && members.single == int.parse(exact.substring(1));
}

/// Each plural argument in [message] with its selectors as written
/// ("=1", "one", "other").
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
      selectors.add(message.substring(start, i));
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

  test('"=1" stands for "one" only where "one" is 1 alone', () {
    expect(covers({'=1', 'other'}, 'one', 'en'), isTrue);
    expect(covers({'=1', 'other'}, 'one', 'ru'), isFalse);
    expect(covers({'one', 'other'}, 'one', 'ru'), isTrue);
    expect(covers({'=0', 'other'}, 'zero', 'ar'), isTrue);
    expect(covers({'=2', 'other'}, 'two', 'ar'), isTrue);
    expect(covers({'other'}, 'few', 'pl'), isFalse);
    // Portuguese of Portugal: "one" is 1 alone; of Brazil: 0 and 1.
    expect(covers({'=1', 'other'}, 'one', 'pt_PT'), isTrue);
    expect(covers({'=1', 'other'}, 'one', 'pt'), isFalse);
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
      'n: [=0, =1, other]',
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
      // The locale's own rules (pt_PT differs from pt); optional
      // categories go by language.
      final rules = locale.intlLocale;
      final required = categoriesOf(rules)
          .difference(optionalCategories[locale.languageCode] ?? const {});
      for (final k in messages) {
        for (final (name, selectors) in pluralsIn(arb[k] as String)) {
          for (final category in required) {
            expect(
              covers(selectors, category, rules),
              isTrue,
              reason: '${locale.code}.$k ($name): $category',
            );
          }
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
