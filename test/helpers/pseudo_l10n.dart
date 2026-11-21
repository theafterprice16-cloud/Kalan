// Pseudo-localization for tests (Roadmap 24, decision 13): English texts
// made about 40% longer, the way German or Russian run longer, to find
// text that overflows before a real translation does.
//
// No generated code to keep up to date: every message comes from
// lib/l10n/app_en.arb, its parameters' names from the generated
// AppLocalizations signatures, and intl's MessageFormat fills in plurals,
// selects and placeholders. Each word then grows by 40% of its letters
// (it stays one word, so it can only wrap where English wraps).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/message_format.dart';
import 'package:kalan/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class PseudoLocalizations implements AppLocalizations {
  PseudoLocalizations._(this.messages, this.parameters);

  factory PseudoLocalizations.load() {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final source = File('lib/l10n/generated/app_localizations.dart')
        .readAsStringSync();
    final parameters = <String, List<String>>{
      for (final m in RegExp(
        r'^  String get (\w+);',
        multiLine: true,
      ).allMatches(source))
        m[1]!: const [],
      for (final m in RegExp(
        r'^  String (\w+)\(([^)]*)\);',
        multiLine: true,
      ).allMatches(source))
        m[1]!: [
          for (final p in m[2]!.split(','))
            if (p.trim().isNotEmpty) p.trim().split(RegExp(r'\s+')).last,
        ],
    };
    return PseudoLocalizations._({
      for (final e in arb.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    }, parameters);
  }

  /// English messages by key.
  final Map<String, String> messages;

  /// Parameter names by message key, in the generated order.
  final Map<String, List<String>> parameters;

  /// Dates and numbers stay English.
  @override
  String get localeName => 'en';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final symbol = invocation.memberName.toString();
    final name = symbol.substring('Symbol("'.length, symbol.length - 2);
    final message = messages[name];
    if (message == null) return super.noSuchMethod(invocation);
    final names = parameters[name]!;
    final values = <String, Object>{
      for (final (i, v) in invocation.positionalArguments.indexed)
        names[i]: v is String ? v : '$v',
    };
    final text = message.contains('{')
        ? MessageFormat(message, locale: 'en').format(values)
        : message;
    return expand(text);
  }

  /// [text] with every word 40% longer: "Save" → "Savesa".
  static String expand(String text) =>
      text.replaceAllMapped(RegExp(r'\p{L}+', unicode: true), (m) {
        final word = m[0]!;
        final extra = (word.length * 0.4).ceil();
        final runes = word.runes.toList();
        return word +
            String.fromCharCodes([
              for (var i = 0; i < extra; i++) runes[i % runes.length],
            ]).toLowerCase();
      });
}

/// Loads [PseudoLocalizations] for every locale.
class PseudoLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const PseudoLocalizationsDelegate();

  static final _instance = PseudoLocalizations.load();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(_instance);

  @override
  bool shouldReload(PseudoLocalizationsDelegate old) => false;
}
