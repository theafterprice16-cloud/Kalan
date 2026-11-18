import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens in lib/features follow the cross-platform UI rules
/// (`.claude/skills/flutter-cross-ui`): no glass, no platform branching,
/// dialogs through `showKalanDialog`, spacing and corners from
/// `KalanSpace` / `KalanRadius` (lib/core/theme/kalan_spacing.dart).
final bannedLines = <String, RegExp>{
  'BackdropFilter': RegExp(r'\bBackdropFilter\b'),
  'ImageFilter.blur': RegExp(r'\bImageFilter\.blur\b'),
  'Platform.isIOS': RegExp(r'\bPlatform\.is(IOS|Android|MacOS)\b'),
  'bare showDialog': RegExp(r'\bshowDialog\s*[<(]'),
  'Cupertino dialog': RegExp(r'\b(showCupertinoDialog|CupertinoAlertDialog)\b'),
  'HapticFeedback': RegExp(r'\bHapticFeedback\.'),
  'non-adaptive switch': RegExp(r'\bSwitchListTile\('),
};

final _number = RegExp(r'(?<![\w.])[1-9]\d*(\.\d+)?(?![\w.])');

/// Spacing and corners written as numbers. Searched across line breaks,
/// since the formatter splits long constructor calls.
final bannedNumbers = <String, RegExp>{
  'numeric radius': RegExp(r'\b(BorderRadius|Radius)\.circular\(([^()]*)\)'),
  'numeric insets': RegExp(
    r'\bEdgeInsets(Directional)?\.(all|symmetric|only|fromLTRB|fromSTEB)\(([^()]*)\)',
  ),
  // A lone height or width is a gap; one with a child is a size.
  'numeric gap': RegExp(r'\bSizedBox\(\s*(height|width):\s*([\d.]+)\s*,?\s*\)'),
  'numeric spacing': RegExp(r'\b(runSpacing|spacing):\s*([\d.]+)'),
};

/// Platform checks for notification payloads, not screens: iOS shows the
/// expanded body in the banner (lib/features/reminders gateway code).
const platformExceptions = {'lib/features/reminders/local_notifications.dart'};

List<String> offendersIn(String path, String source) {
  final out = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    for (final MapEntry(:key, :value) in bannedLines.entries) {
      if (value.hasMatch(lines[i])) out.add('$path:${i + 1} ($key)');
    }
  }
  for (final MapEntry(:key, :value) in bannedNumbers.entries) {
    for (final m in value.allMatches(source)) {
      final args = m.group(m.groupCount)!;
      if (_number.hasMatch(args)) {
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        out.add('$path:$line ($key)');
      }
    }
  }
  return out;
}

void main() {
  test('screens follow the cross-platform UI rules', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      offenders.addAll(
        offendersIn(path, entity.readAsStringSync()).where(
          (o) => !(platformExceptions.contains(path) && o.contains('Platform')),
        ),
      );
    }
    expect(offenders, isEmpty);
  });

  test('the guard catches every form', () {
    const samples = [
      'child: BackdropFilter(filter: f)',
      'filter: ImageFilter.blur(sigmaX: 10)',
      'if (Platform.isIOS) {}',
      'await showDialog<bool>(',
      'showDialog(context: context)',
      'showCupertinoDialog(context: context)',
      'HapticFeedback.lightImpact();',
      'SwitchListTile(',
      'borderRadius: BorderRadius.circular(8)',
      'Radius.circular(16)',
      'padding: EdgeInsets.all(15)',
      'EdgeInsets.fromLTRB(\n  16,\n  0,\n  16,\n  8,\n)',
      'EdgeInsetsDirectional.only(start: 12)',
      'const SizedBox(height: 6)',
      'Wrap(spacing: 12, runSpacing: 2)',
    ];
    for (final sample in samples) {
      expect(offendersIn('x.dart', sample), isNotEmpty, reason: sample);
    }
    const allowed = [
      'await showKalanDialog<bool>(',
      'SwitchListTile.adaptive(',
      'KalanHaptics.success();',
      'BorderRadius.circular(KalanRadius.input)',
      'EdgeInsets.fromLTRB(KalanSpace.md, 0, KalanSpace.md, KalanSpace.xs)',
      'EdgeInsets.zero',
      'const SizedBox(height: KalanSpace.sm)',
      'Wrap(spacing: KalanSpace.sm, runSpacing: KalanSpace.xxs)',
      'const Divider(height: 1)',
      'SizedBox(width: 56, child: x)',
    ];
    for (final sample in allowed) {
      expect(offendersIn('x.dart', sample), isEmpty, reason: sample);
    }
  });
}
