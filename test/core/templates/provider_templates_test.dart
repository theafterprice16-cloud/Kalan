import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/engine.dart';
import 'package:kalan/core/templates/provider_templates.dart';
import 'package:kalan/l10n/app_locales.dart';

import '../../../tool/check_provider_templates.dart' show staleWarning;

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

final _file = File(providerTemplatesAsset).readAsStringSync();

String _wrap(List<Map<String, Object?>> templates) =>
    jsonEncode({'schemaVersion': 1, 'templates': templates});

Map<String, Object?> _template({
  String country = 'IT',
  String id = 'scalapay',
  Object? variants,
  Map<String, Object?> extra = const {},
}) => {
  'country': country,
  'id': id,
  'name': 'Scalapay',
  'sources': ['https://www.scalapay.com/it/'],
  'checked': '2026-11-22',
  'variants':
      variants ??
      [
        {'kind': 'monthly', 'count': 3, 'interval': 'sameDay'},
      ],
  ...extra,
};

void main() {
  group('the shipped file', () {
    final templates = parseProviderTemplates(_file);

    test('reads with the schema (every key known, every value in range)', () {
      expect(templates, isNotEmpty);
    });

    test('every template has an official https link and a check date', () {
      for (final t in templates) {
        expect(t.sources, isNotEmpty, reason: '$t');
        for (final s in t.sources) {
          expect(s.scheme, 'https', reason: '$t');
          expect(s.host, isNotEmpty, reason: '$t');
        }
        expect(
          t.checked > d(2026, 1, 1),
          isTrue,
          reason: '$t checked ${t.checked}',
        );
      }
    });

    test('at most 5 providers per country, only for a locale country', () {
      final perCountry = <String, int>{};
      for (final t in templates) {
        perCountry[t.country] = (perCountry[t.country] ?? 0) + 1;
        expect(templateCountries, contains(t.country), reason: '$t');
      }
      for (final e in perCountry.entries) {
        expect(
          e.value,
          lessThanOrEqualTo(maxProvidersPerCountry),
          reason: e.key,
        );
      }
    });

    test('every variant maps to a plan kind the app offers', () {
      for (final t in templates) {
        for (final v in t.variants) {
          expect(
            v.kind,
            isIn([PlanKind.payIn4, PlanKind.monthly, PlanKind.payLater]),
          );
          // The draft the form would build is valid for the kind.
          final first = v.firstDate(d(2026, 11, 22));
          switch (v.kind) {
            case PlanKind.payIn4:
              PlanCalculator.payIn4(
                firstDate: first,
                totalMinor: 10000,
                interval: v.interval!,
              );
            case PlanKind.monthly:
              PlanCalculator.monthly(
                firstDate: first,
                totalMinor: 100000,
                count: v.count,
                interval: v.interval!,
              );
            case PlanKind.payLater:
              PlanCalculator.payLater(
                purchaseDate: first,
                rule: v.payLaterRule!,
                totalMinor: 10000,
              );
            case PlanKind.card || PlanKind.manual:
              fail('$t has a ${v.kind} variant');
          }
        }
      }
    });

    test('no fee, interest, rate, late rule, color or logo anywhere', () {
      // Whole words of a key or a closed value ("lateFee" → late, fee).
      const banned = {
        'fee', 'fees', 'interest', 'rate', 'rates', 'apr', 'tae', 'late', //
        'penalty', 'charge', 'cost', 'price', 'color', 'colour', 'logo', //
        'font', 'brand', 'percent', 'faiz', 'ücret', 'gecikme', 'renk', //
      };
      final words = (
        hasMatch: (String text) => text
            .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]}')
            .toLowerCase()
            .split(RegExp(r'[^a-zçğıöşü%]+'))
            .any((w) => banned.contains(w) || w.contains('%')),
      );
      void walk(Object? node, String at) {
        if (node is Map) {
          for (final e in node.entries) {
            expect(
              words.hasMatch(e.key as String),
              isFalse,
              reason: 'key ${e.key} at $at',
            );
            // Links and names are free text; every other value is a
            // closed word or a number.
            if (e.key != 'sources' && e.key != 'name') {
              walk(e.value, '$at.${e.key}');
            }
          }
        } else if (node is List) {
          for (final (i, v) in node.indexed) {
            walk(v, '$at[$i]');
          }
        } else if (node is String) {
          expect(words.hasMatch(node), isFalse, reason: '"$node" at $at');
        }
      }

      walk(jsonDecode(_file), r'$');
    });

    test('no image or icon file ships with the templates', () {
      final assets = Directory('assets').listSync().map((f) => f.path);
      expect(assets.where((p) => p.contains('provider')), [
        'assets/provider_templates.json',
      ]);
    });
  });

  group('schema', () {
    void refused(String json, String why) => expect(
      () => parseProviderTemplates(json),
      throwsA(isA<ProviderTemplateFormatException>()),
      reason: why,
    );

    test('a valid entry reads', () {
      final t = parseProviderTemplates(_wrap([_template()])).single;
      expect(t.country, 'IT');
      expect(t.name, 'Scalapay');
      expect(t.checked, d(2026, 11, 22));
      expect(
        t.variants.single,
        const TemplateVariant.monthly(
          count: 3,
          interval: PaymentInterval.sameDay,
        ),
      );
    });

    test('required fields', () {
      for (final key in ['country', 'id', 'name', 'sources', 'checked']) {
        refused(_wrap([_template()..remove(key)]), 'without $key');
      }
      refused(_wrap([_template(variants: [])]), 'no variants');
    });

    test('fee, interest, rate, late and color fields are refused', () {
      for (final key in [
        'fee',
        'interest',
        'rate',
        'apr',
        'lateFee',
        'color',
        'logo',
      ]) {
        refused(
          _wrap([
            _template(extra: {key: 1}),
          ]),
          'template $key',
        );
        refused(
          _wrap([
            _template(
              variants: [
                {'kind': 'payIn4', key: 1},
              ],
            ),
          ]),
          'variant $key',
        );
      }
      refused(
        jsonEncode({'schemaVersion': 1, 'templates': <Object>[], 'fee': 0}),
        'file key',
      );
    });

    test('only kinds and rules the app has', () {
      for (final v in <Map<String, Object?>>[
        {'kind': 'card', 'count': 3},
        {'kind': 'manual', 'count': 3},
        {'kind': 'monthly', 'count': 3, 'interval': 'weekdays'},
        {'kind': 'monthly', 'count': 1, 'interval': 'sameDay'},
        {'kind': 'monthly', 'count': 61, 'interval': 'sameDay'},
        {'kind': 'monthly', 'count': 3, 'interval': 'everyDays'},
        {
          'kind': 'monthly',
          'count': 3,
          'interval': 'everyDays',
          'intervalDays': 400,
        },
        {
          'kind': 'monthly',
          'count': 3,
          'interval': 'everyDays',
          'intervalDays': 30,
          'first': 'nextMonthDay',
          'firstDay': 27,
        },
        {'kind': 'monthly', 'count': 3, 'interval': 'sameDay', 'first': 'eom'},
        // Day 29-31 would move to a month end in short months.
        {
          'kind': 'monthly',
          'count': 3,
          'interval': 'sameDay',
          'first': 'nextMonthDay',
          'firstDay': 29,
        },
        {'kind': 'payIn4', 'count': 3},
        {'kind': 'payLater', 'payLater': 'endOfMonth', 'payLaterValue': 1},
        {'kind': 'payLater', 'payLater': 'days', 'payLaterValue': 181},
        {'kind': 'payLater', 'payLater': 'nextMonthDay', 'payLaterValue': 32},
        {'kind': 'payLater', 'payLater': 'days'},
      ]) {
        refused(
          _wrap([
            _template(variants: [v]),
          ]),
          '$v',
        );
      }
    });

    test('links, dates, slugs and countries are checked', () {
      refused(
        _wrap([
          _template(
            extra: {
              'sources': ['http://example.com'],
            },
          ),
        ]),
        'http link',
      );
      refused(
        _wrap([
          _template(extra: {'checked': '2026-02-30'}),
        ]),
        'no such day',
      );
      refused(
        _wrap([
          _template(extra: {'checked': '22.11.2026'}),
        ]),
        'date format',
      );
      refused(_wrap([_template(id: 'Scala Pay')]), 'slug');
      refused(_wrap([_template(country: 'ita')]), 'country');
      refused(_wrap([_template(), _template()]), 'duplicate');
    });

    test('a sixth provider in a country is refused', () {
      refused(
        _wrap([for (var i = 0; i < 6; i++) _template(id: 'p$i')]),
        'six providers',
      );
      expect(
        parseProviderTemplates(
          _wrap([for (var i = 0; i < 5; i++) _template(id: 'p$i')]),
        ),
        hasLength(5),
      );
    });
  });

  group('first payment date', () {
    test('on the purchase day, one interval later, or next month on day N', () {
      const sameDay = PaymentInterval.sameDay;
      expect(
        const TemplateVariant.monthly(
          count: 3,
          interval: sameDay,
        ).firstDate(d(2026, 11, 22)),
        d(2026, 11, 22),
      );
      expect(
        const TemplateVariant.monthly(
          count: 6,
          interval: sameDay,
          first: TemplateFirstPayment.afterInterval,
        ).firstDate(d(2026, 1, 31)),
        d(2026, 2, 28),
      );
      expect(
        const TemplateVariant.monthly(
          count: 3,
          interval: PaymentInterval.every30Days,
          first: TemplateFirstPayment.afterInterval,
        ).firstDate(d(2026, 11, 22)),
        d(2026, 12, 22),
      );
      // Paidy-like: day 27 of the month after the purchase.
      expect(
        const TemplateVariant.monthly(
          count: 3,
          interval: sameDay,
          first: TemplateFirstPayment.nextMonthDay,
          firstDay: 27,
        ).firstDate(d(2026, 11, 30)),
        d(2026, 12, 27),
      );
    });
  });

  group('region', () {
    final all = parseProviderTemplates(
      _wrap([
        _template(),
        _template(id: 'klarna')..['name'] = 'Klarna',
        _template(country: 'ID', id: 'kredivo')..['name'] = 'Kredivo',
        _template(country: 'JP', id: 'paidy')..['name'] = 'Paidy',
      ]),
    );

    test('Italy, Indonesia, Japan', () {
      expect(templatesForRegion(all, 'IT').map((t) => t.name), [
        'Klarna',
        'Scalapay',
      ]);
      expect(templatesForRegion(all, 'ID').map((t) => t.id), ['kredivo']);
      expect(templatesForRegion(all, 'jp').map((t) => t.id), ['paidy']);
    });

    test('a region without templates, an unknown one or none: empty', () {
      expect(templatesForRegion(all, 'TR'), isEmpty);
      expect(templatesForRegion(all, 'ZZ'), isEmpty);
      expect(templatesForRegion(all, null), isEmpty);
      expect(templatesForRegion(all, ''), isEmpty);
    });

    test('sorted by name, never by the order in the file', () {
      final reversed = templatesForRegion(all.reversed.toList(), 'IT');
      expect(reversed.map((t) => t.name), ['Klarna', 'Scalapay']);
    });

    test('every locale of Roadmap 24 has its countries', () {
      expect(templateCountriesByLocale.keys.toSet(), {
        for (final l in appLocales) l.code,
      });
      for (final list in templateCountriesByLocale.values) {
        expect(list, isNotEmpty);
      }
    });
  });

  group('six months', () {
    final today = d(2026, 11, 22);

    test('5 months: no warning; 7 months: warning', () {
      expect(isTemplateStale(d(2026, 6, 22), today), isFalse);
      expect(isTemplateStale(d(2026, 5, 22), today), isFalse);
      expect(isTemplateStale(d(2026, 4, 22), today), isTrue);
      expect(isTemplateStale(today, today), isFalse);
    });

    test('the warning names the provider and the country', () {
      final all = parseProviderTemplates(
        _wrap([
          _template(extra: {'checked': '2026-04-22'}),
          _template(country: 'ES', extra: {'checked': '2026-06-22'}),
        ]),
      );
      final stale = staleTemplates(all, today);
      expect(stale.map((t) => t.country), ['IT']);
      expect(
        staleWarning(stale.single),
        'Şablon kontrol tarihi 6 aydan eski: Scalapay, IT',
      );
    });

    test('a check date in the future is caught', () {
      final all = parseProviderTemplates(
        _wrap([
          _template(extra: {'checked': '2062-11-22'}),
        ]),
      );
      expect(futureCheckedTemplates(all, today), hasLength(1));
      expect(staleTemplates(all, today), isEmpty);
    });

    test('the shipped file: checked on or before today, none stale', () {
      final now = DateTime.now();
      final realToday = LocalDate(now.year, now.month, now.day);
      final shipped = parseProviderTemplates(_file);
      expect(futureCheckedTemplates(shipped, realToday), isEmpty);
      expect(staleTemplates(shipped, today), isEmpty);
    });
  });

  group('names', () {
    test('case and accents do not matter', () {
      expect(foldName(' Scalapay '), foldName('scalapay'));
      expect(foldName('SCALAPAY'), 'scalapay');
      expect(foldName('BLIK Płacę Później'), 'blik place pozniej');
      expect(foldName('Ví Trả Sau'), 'vi tra sau');
      expect(foldName('İŞBANK'), 'isbank');
      expect(foldName('Долями'), 'долями');
      // A decomposed accent (e + combining acute).
      expect(foldName('Café'), 'cafe');
    });
  });
}
