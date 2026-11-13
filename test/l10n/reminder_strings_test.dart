import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reminder texts: calm, ICU plurals for counts, notes for translators.
void main() {
  Map<String, dynamic> arb(String lang) =>
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
  final en = arb('en');
  final tr = arb('tr');
  final keys = en.keys
      .where((k) => !k.startsWith('@'))
      .where(
        (k) =>
            k.startsWith('reminder') ||
            k.startsWith('reminders') ||
            k.startsWith('planReminder') ||
            k == 'openPhoneSettings' ||
            k.contains('estNotification'),
      )
      .toList();

  test('there are reminder strings to check', () {
    expect(keys, contains('reminderAhead'));
    expect(keys, contains('planReminderGeneral'));
  });

  test('calm: no exclamation, no deadline or alarm words', () {
    final banned = RegExp(
      r'!|son gün|acele|unutma|gecikme|acil|last day|hurry|'
      r"don't forget|overdue|urgent|late (payment|fee)",
      caseSensitive: false,
    );
    for (final k in keys) {
      for (final (lang, file) in [('en', en), ('tr', tr)]) {
        expect(
          banned.hasMatch(file[k] as String),
          isFalse,
          reason: '$lang $k: ${file[k]}',
        );
      }
    }
  });

  test('every new reminder string has a note for translators', () {
    for (final k in [
      'reminderAhead',
      'reminderAheadHidden',
      'reminderAheadMixed',
      'reminderAheadMixedHidden',
      'reminderToday',
      'reminderTodayHidden',
      'reminderExpanded',
      'reminderLeadDays',
      'reminderLeadDaysValue',
      'reminderLeadDaysSemantics',
      'reminderShowAmount',
      'reminderPromptBody',
      'reminderPromptAccept',
      'reminderPromptLater',
      'remindersPermissionOff',
      'openPhoneSettings',
      'planReminder',
      'planReminderGeneral',
      'planReminderOff',
      'planReminderCustom',
      'debugTestNotification',
    ]) {
      final meta = en['@$k'] as Map<String, dynamic>?;
      expect(meta?['description'], isNotEmpty, reason: k);
      final placeholders = meta?['placeholders'] as Map<String, dynamic>?;
      for (final MapEntry(:key, :value) in (placeholders ?? {}).entries) {
        final p = value as Map<String, dynamic>;
        expect(p['description'] ?? p['example'], isNotNull, reason: '$k.$key');
      }
    }
  });

  test('counts use ICU plurals in both languages', () {
    for (final k in [
      'reminderAhead',
      'reminderAheadHidden',
      'reminderToday',
      'reminderTodayHidden',
      'reminderLeadDaysValue',
      'planReminderGeneral',
    ]) {
      for (final (lang, file) in [('en', en), ('tr', tr)]) {
        expect(file[k], contains('plural,'), reason: '$lang $k');
        expect(file[k], contains('=1{'), reason: '$lang $k');
      }
    }
  });
}
