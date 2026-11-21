import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens in lib/features follow the cross-platform UI rules
/// (`.claude/skills/flutter-cross-ui`): no glass, no platform branching,
/// dialogs through `showKalanDialog`, spacing and corners from
/// `KalanSpace` / `KalanRadius` (lib/core/theme/kalan_spacing.dart).
final bannedLines = <String, RegExp>{
  'BackdropFilter': RegExp(r'\bBackdropFilter\b'),
  'ImageFilter.blur': RegExp(r'\bImageFilter\.blur\b'),
  'platform branching': RegExp(
    r'\bPlatform\.is(IOS|Android|MacOS)\b|\bdefaultTargetPlatform\b|\.platform\s*==',
  ),
  'bare showDialog': RegExp(r'\bshowDialog\s*[<(]'),
  // Apple's dialogs and sheets are frosted glass; use showKalanDialog.
  'glass dialog': RegExp(
    r'\b(showCupertino\w*|CupertinoAlertDialog|CupertinoActionSheet|showAdaptiveDialog)\b|\bAlertDialog\.adaptive\b',
  ),
  'HapticFeedback': RegExp(r'\bHapticFeedback\.'),
  'non-adaptive switch': RegExp(r'\b(SwitchListTile|Switch)\('),
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

/// Layout pinned to the left or the right (Roadmap 24): in Arabic the
/// screen reads from the right, so start/end and Directional variants
/// are used. A line may opt out with a `// rtl-ok: <reason>` comment.
/// Searched across line breaks, since the formatter splits long calls.
final directionalPatterns = <String, RegExp>{
  'left/right alignment': RegExp(
    r'\b(Alignment|FractionalOffset)\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b',
  ),
  'left/right text align': RegExp(r'\bTextAlign\.(left|right)\b'),
  'fixed text direction': RegExp(r'\btextDirection:\s*TextDirection\.'),
};

/// Constructors whose own left/right arguments pin the layout.
final directionalCalls = <String, RegExp>{
  'left/right insets': RegExp(r'\bEdgeInsets\.only\('),
  'left/right position': RegExp(r'\bPositioned(\.fill)?\('),
  // A Rect is measured from the left.
  'left/right rect': RegExp(r'\bPositioned\.from(Rect|RelativeRect)\('),
  'left/right corners': RegExp(r'\bBorderRadius\.(only|horizontal)\('),
  'left/right border': RegExp(r'\bBorder\('),
};

final _sideArgument = RegExp(
  r'^(left|right|topLeft|topRight|bottomLeft|bottomRight)\s*:',
);

/// The arguments of the call whose "(" is at [open], split at its own
/// commas (not those of nested calls or collections).
List<String> _argumentsAt(String source, int open) {
  final args = <String>[];
  var depth = 0;
  var start = open + 1;
  for (var i = open; i < source.length; i++) {
    final c = source[i];
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) depth--;
    if (depth == 0) {
      args.add(source.substring(start, i));
      break;
    }
    if (depth == 1 && c == ',') {
      args.add(source.substring(start, i));
      start = i + 1;
    }
  }
  return [
    for (final a in args)
      if (a.trim().isNotEmpty) a.trim(),
  ];
}

/// The index of the ")" closing the call whose "(" is at [open].
int _callEnd(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if ('([{'.contains(source[i])) depth++;
    if (')]}'.contains(source[i]) && --depth == 0) return i;
  }
  return source.length - 1;
}

List<String> directionalOffendersIn(String path, String source) {
  final out = <String>[];
  final lines = source.split('\n');
  int lineOf(int offset) =>
      '\n'.allMatches(source.substring(0, offset)).length + 1;
  // The opt-out may sit on any line of the match (the formatter splits
  // long calls).
  void report(int start, String what, [int? end]) {
    final first = lineOf(start);
    final last = lineOf(end ?? start);
    for (var l = first; l <= last; l++) {
      if (lines[l - 1].contains('// rtl-ok:')) return;
    }
    out.add('$path:$first ($what)');
  }

  for (final MapEntry(:key, :value) in directionalPatterns.entries) {
    for (final m in value.allMatches(source)) {
      report(m.start, key, m.end);
    }
  }
  for (final MapEntry(:key, :value) in directionalCalls.entries) {
    for (final m in value.allMatches(source)) {
      final args = _argumentsAt(source, m.end - 1);
      if (key == 'left/right rect' || args.any(_sideArgument.hasMatch)) {
        report(m.start, key, _callEnd(source, m.end - 1));
      }
    }
  }
  // Alignment(x, y) with an x other than 0; FractionalOffset(x, y) with
  // an x other than 0.5.
  for (final (pattern, centre) in [
    (RegExp(r'\bAlignment\('), {'0', '0.0'}),
    (RegExp(r'\bFractionalOffset\('), {'0.5'}),
  ]) {
    for (final m in pattern.allMatches(source)) {
      final args = _argumentsAt(source, m.end - 1);
      if (args.isNotEmpty && !centre.contains(args.first)) {
        report(
          m.start,
          'left/right alignment value',
          _callEnd(source, m.end - 1),
        );
      }
    }
  }
  // fromLTRB with different left and right, or arguments it cannot read.
  for (final m in RegExp(r'\bEdgeInsets\.fromLTRB\(').allMatches(source)) {
    final args = _argumentsAt(source, m.end - 1);
    final end = _callEnd(source, m.end - 1);
    if (args.length != 4) {
      report(m.start, 'unreadable fromLTRB', end);
    } else if (args[0] != args[2]) {
      report(m.start, 'uneven fromLTRB', end);
    }
  }
  return out;
}

/// lib/ without generated code.
Iterable<File> libSources() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.steps.dart') &&
              !f.path.replaceAll(r'\', '/').contains('/l10n/generated/'),
        );

void main() {
  test('lib/ lays out by start and end, never left and right', () {
    final offenders = <String>[];
    for (final file in libSources()) {
      final path = file.path.replaceAll(r'\', '/');
      offenders.addAll(directionalOffendersIn(path, file.readAsStringSync()));
    }
    expect(offenders, isEmpty);
  });

  test('the right-to-left guard catches every form', () {
    const samples = [
      'padding: EdgeInsets.only(left: KalanSpace.md)',
      'EdgeInsets.only(\n  top: 4,\n  right: KalanSpace.sm,\n)',
      'EdgeInsets.fromLTRB(KalanSpace.md, 0, KalanSpace.xs, 0)',
      'alignment: Alignment.centerLeft',
      'Alignment.topRight',
      'textAlign: TextAlign.right',
      'Positioned(top: f(1), left: 0, child: x)',
      'BorderRadius.only(topLeft: r)',
      'BorderRadius.horizontal(right: r)',
      'Border(left: BorderSide())',
      'Text(a, textDirection: TextDirection.ltr)',
      'Text(\n  a,\n  textDirection:\n      TextDirection.rtl,\n)',
      'Positioned.fill(left: 8, child: x)',
      'alignment: Alignment(-1, 0)',
      'FractionalOffset.centerRight',
      'EdgeInsets.fromLTRB(f(a, b), 0, 0, 0)',
      'Alignment(f(x), 0)',
      'FractionalOffset(0, 0.5)',
      'Positioned.fromRect(rect: r, child: x)',
    ];
    for (final sample in samples) {
      expect(
        directionalOffendersIn('x.dart', sample),
        isNotEmpty,
        reason: sample,
      );
    }
    const allowed = [
      'padding: EdgeInsetsDirectional.only(start: KalanSpace.md)',
      'EdgeInsets.only(top: KalanSpace.xs, bottom: 4)',
      'EdgeInsets.fromLTRB(KalanSpace.md, 0, KalanSpace.md, KalanSpace.xs)',
      'alignment: AlignmentDirectional.centerStart',
      'Alignment.center',
      'textAlign: TextAlign.start',
      'PositionedDirectional(start: 0, end: 0, child: x)',
      'Positioned(top: 0, bottom: 0, child: x)',
      'BorderRadius.vertical(top: r)',
      'BorderRadiusDirectional.only(topStart: r)',
      'Border(top: BorderSide())',
      'Directionality.of(context) == TextDirection.rtl',
      'textDirection: Directionality.of(context),',
      'Text(a, textDirection: TextDirection.ltr) // rtl-ok: a code',
      'Positioned(top: 0, child: Foo(right: 1))',
      'Positioned.fill(child: x)',
      'Alignment(0, -1)',
      'Alignment(0.0, 1)',
      'EdgeInsets.fromLTRB(f(a, b), 0, f(a, b), 0)',
      'FractionalOffset(0.5, 1)',
      'Text(\n  a,\n  textDirection:\n      TextDirection.ltr, // rtl-ok: a code\n)',
      'EdgeInsets.only(\n  left: 4, // rtl-ok: a ruler\n)',
    ];
    for (final sample in allowed) {
      expect(directionalOffendersIn('x.dart', sample), isEmpty, reason: sample);
    }
  });

  test('screens follow the cross-platform UI rules', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      offenders.addAll(
        offendersIn(path, entity.readAsStringSync()).where(
          (o) =>
              !(platformExceptions.contains(path) &&
                  o.contains('platform branching')),
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
      'showAdaptiveDialog<bool>(',
      'builder: (_) => AlertDialog.adaptive(',
      'showCupertinoModalPopup(context: context)',
      'if (defaultTargetPlatform == TargetPlatform.iOS) {}',
      'Theme.of(context).platform == TargetPlatform.iOS',
      'Switch(value: v, onChanged: f)',
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
      'Switch.adaptive(value: v, onChanged: f)',
      'if (followsApple(context)) {}',
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
