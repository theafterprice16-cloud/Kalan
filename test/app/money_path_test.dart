import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Amounts are formatted only in lib/core/money; nothing else hard-codes a
/// currency symbol, minor-unit size or number format.
void main() {
  test('only lib/core/money formats money', () {
    final banned = <String, RegExp>{
      'NumberFormat': RegExp(r'\bNumberFormat\b'),
      'currency symbol': RegExp(
        r'''['"][^'"]*(₺|€|£|₽|₸|¥|R\$|Rp|RM|CHF|\bTL\b)''',
      ),
      'fixed minor units': RegExp(r'(~/|%)\s*100\b'),
      'decimalDigits': RegExp(r'\bdecimalDigits\b'),
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/money/') ||
          path.startsWith('lib/l10n/generated/')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final MapEntry(key: what, value: pattern) in banned.entries) {
        if (pattern.hasMatch(source)) offenders.add('$path: $what');
      }
    }
    expect(offenders, isEmpty);
  });

  // Roadmap 24: dates and numbers read the intl locale (intlLocaleOf),
  // never the generated localeName as is (zh_Hant would read zh's data).
  test('dates and amounts use the intl locale', () {
    final raw = RegExp(
      r'(?<!intlLocaleOf\()\b(l10n|AppLocalizations\.of\(\w+\))\.localeName\b',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/l10n/generated/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (raw.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
    expect(raw.hasMatch('DateFormat.E(l10n.localeName)'), isTrue);
    expect(raw.hasMatch('intlLocaleOf(l10n.localeName)'), isFalse);
  });

  // Roadmap 28: "Hide amounts" is applied once, in the display path
  // (MoneyRefX in lib/app/format.dart). Screens show amounts only through
  // ref.money / ref.moneyShort; formatting directly would skip the mask.
  test('hide amounts: no way around the mask', () {
    // Where an amount is formatted directly, and why the mask does not
    // apply there.
    const direct = {
      'lib/app/format.dart': 'the display path itself',
      'lib/features/reminders/reminder_texts.dart':
          'notifications: the planner decides (amountsInText)',
      'lib/features/currency/currency_picker.dart':
          "each currency's example amount, not the user's",
      'lib/features/home_widget/widget_texts.dart':
          'home screen widget (31): the snapshot builder decides '
          '(widgetAmountsMasked)',
    };
    // The flow where the user types or edits an amount (fields and their
    // draft preview): never masked. How many calls each file may have.
    const drafts = {
      'lib/app/format.dart': 1,
      'lib/features/plans/add_plan_screen.dart': 8,
      'lib/features/plans/adjust_amount_screen.dart': 6,
      'lib/features/plans/installment_fee_fields.dart': 1,
      'lib/features/plans/plan_detail_screen.dart': 1,
    };
    // The fee summary's preview flag: only the add plan screen's previews.
    const draftSummaries = {'lib/features/plans/add_plan_screen.dart': 2};
    final format = RegExp(r'\bformatMoney(Short)?\(');
    final draft = RegExp(r'\bdraftMoney\(');
    final draftFlag = RegExp(r'\bdraft:\s*true\b');
    // A value passed in would hide from the count above: only the add
    // plan screen's own _Preview(draft: ...) takes one.
    final draftValue = RegExp(
      r'(?<!_Preview\()\bdraft:\s*(?!\s|true\b|false\b)',
    );
    // An amount field's own text, the only place moneyInput may go.
    final input = RegExp(r'\bmoneyInput\(');
    final fieldText = RegExp(r'\.text\s*=\s*.*\bmoneyInput\(');
    final offenders = <String>[];
    final seen = <String, int>{};
    final flagged = <String, int>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/money/') ||
          path.startsWith('lib/l10n/generated/')) {
        continue;
      }
      final source = entity.readAsStringSync();
      if (format.hasMatch(source) && !direct.containsKey(path)) {
        offenders.add('$path: formatMoney');
      }
      final drafted = draft.allMatches(source).length;
      if (drafted > 0) seen[path] = drafted;
      final flags = draftFlag.allMatches(source).length;
      if (flags > 0) flagged[path] = flags;
      if (draftValue.hasMatch(source)) offenders.add('$path: draft: value');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (input.hasMatch(line) &&
            !fieldText.hasMatch(line) &&
            !line.contains('String moneyInput(')) {
          offenders.add('$path:${i + 1}: moneyInput outside a field');
        }
      }
    }
    expect(offenders, isEmpty);
    // format.dart: the definition itself.
    expect(seen, drafts);
    expect(flagged, draftSummaries);
    expect(draftValue.hasMatch('Summary(draft: editing)'), isTrue);
    expect(draftValue.hasMatch('_Preview(draft: _buildDraft())'), isFalse);
    expect(fieldText.hasMatch('_amount.text = ref.moneyInput(c, 1);'), isTrue);
    expect(fieldText.hasMatch('Text(ref.moneyInput(c, 1))'), isFalse);
    expect(format.hasMatch('formatMoneyShort(1, c, localeName: l)'), isTrue);
    expect(draft.hasMatch('ref.draftMoney(context, 1)'), isTrue);
  });
}
