import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/engine/pay_period.dart';
import 'package:kalan/core/engine/period_summary.dart';
import 'package:kalan/core/theme/kalan_colors.dart';
import 'package:kalan/core/widget/widget_snapshot.dart';
import 'package:kalan/features/home_widget/widget_gateway.dart';
import 'package:material_ui/material_ui.dart' show Color;

/// Home screen widget (Roadmap 31): the native pieces Flutter cannot draw
/// or compile here (Android in CI, iOS in Xcode) stay in step with the
/// app: colours are token copies, picker texts are ARB copies, the App
/// Group is one id, and native code formats nothing.
void main() {
  const kotlin =
      'android/app/src/main/kotlin/app/kalan/mobile/KalanWidgetProvider.kt';
  const swift = 'ios/KalanWidget/KalanWidget.swift';
  const swiftColors = 'ios/KalanWidget/KalanWidgetColors.swift';
  const res = 'android/app/src/main/res';
  String read(String path) => File(path).readAsStringSync();

  String hex(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  // The widget's tokens (design brief): surface ground, text rows and
  // amounts, textMuted labels and dates, accent "left", negative.
  Map<String, Color> tokens(KalanColors c) => {
    'surface': c.surface,
    'text': c.text,
    'textMuted': c.textMuted,
    'accent': c.accent,
    'negative': c.negative,
  };
  const androidNames = {
    'surface': 'kalan_widget_surface',
    'text': 'kalan_widget_text',
    'textMuted': 'kalan_widget_text_muted',
    'accent': 'kalan_widget_accent',
    'negative': 'kalan_widget_negative',
  };

  group('colours are exact token copies', () {
    for (final (mode, colors, folder) in [
      ('light', KalanColors.light, 'values'),
      ('dark', KalanColors.dark, 'values-night'),
    ]) {
      test('Android, $mode', () {
        final xml = read('$res/$folder/kalan_widget_colors.xml');
        final found = {
          for (final m in RegExp(
            r'<color name="(\w+)">#([0-9A-Fa-f]{6})</color>',
          ).allMatches(xml))
            m[1]!: m[2]!.toUpperCase(),
        };
        expect(found, {
          for (final MapEntry(:key, :value) in tokens(colors).entries)
            androidNames[key]!: hex(value),
        });
      });

      test('iOS, $mode', () {
        final source = read(swiftColors);
        final found = {
          for (final m in RegExp(
            r'static let (\w+) = dynamic\(light: 0x([0-9A-F]{6}), '
            r'dark: 0x([0-9A-F]{6})\)',
          ).allMatches(source))
            m[1]!: mode == 'light' ? m[2]! : m[3]!,
        };
        expect(found, {
          for (final MapEntry(:key, :value) in tokens(colors).entries)
            key: hex(value),
        });
      });
    }

    test('no other colour in the widget', () {
      // Layouts only use the widget tokens; late and chartCommitted never
      // appear (no warning colour on the widget).
      for (final name in [
        'kalan_widget_small',
        'kalan_widget_medium',
        'kalan_widget_preview',
      ]) {
        final xml = read('$res/layout/$name.xml');
        expect(xml, isNot(contains('#')), reason: name);
        for (final m in RegExp(r'@color/(\w+)').allMatches(xml)) {
          expect(androidNames.values, contains(m[1]), reason: name);
        }
        expect(xml, isNot(contains('android:alpha')), reason: name);
        expect(xml, isNot(contains('elevation')), reason: name);
      }
      expect(
        read('$res/drawable/kalan_widget_background.xml'),
        isNot(contains('<gradient')),
      );
      final swiftSource = read(swift);
      expect(RegExp(r'\bColor\(').hasMatch(swiftSource), isFalse);
      expect(swiftSource, isNot(contains('opacity')));
      expect(swiftSource, isNot(contains('shadow')));
      expect(swiftSource, isNot(contains('Gradient')));
      expect(swiftSource, isNot(contains('Material')));
    });
  });

  group('native code calculates and formats nothing', () {
    final banned = {
      kotlin: [
        'NumberFormat',
        'DecimalFormat',
        'SimpleDateFormat',
        'DateTimeFormatter',
        'DateFormat',
        'String.format',
        '.format(',
        'Currency',
        'toLong',
        'toDouble',
      ],
      swift: [
        'NumberFormatter',
        'DateFormatter',
        '.formatted',
        'String(format',
        'Currency',
        'Decimal',
        'Double(',
      ],
    };
    for (final MapEntry(key: path, value: words) in banned.entries) {
      test(path, () {
        final source = read(path);
        for (final word in words) {
          expect(source, isNot(contains(word)), reason: word);
        }
      });
    }

    test('every field native code reads is one the app writes', () {
      final snapshot = buildWidgetSnapshot(
        input: WidgetDaysInput([
          WidgetDayInput(
            date: LocalDate(2026, 11, 20),
            summary: PeriodSummary(
              period: PayPeriod(
                LocalDate(2026, 11, 15),
                LocalDate(2026, 12, 15),
              ),
              spokenForMinor: 1,
              itemCount: 1,
              status: PeriodStatus.noIncome,
            ),
            upcoming: [
              WidgetPayment(
                name: 'a',
                date: LocalDate(2026, 11, 22),
                amountMinor: 1,
              ),
            ],
          ),
        ]),
        masked: true,
        texts: const _NoTexts(),
      );
      final json = jsonDecode(jsonEncode(snapshot.toJson())) as Map;
      final day = (json['days'] as List).first as Map;
      final row = (day['rows'] as List).first as Map;
      final written = {...json.keys, ...day.keys, ...row.keys};
      final kotlinReads =
          RegExp(r'opt(?:String|Int|Boolean|JSONArray)\("(\w+)"\)')
              .allMatches(read(kotlin))
              .map((m) => m[1]!)
              .toSet()
            ..addAll(['number', 'numberSmall']);
      final swiftReads =
          RegExp(
              r'^\s+let (\w+): ',
              multiLine: true,
            ).allMatches(read(swift)).map((m) => m[1]!).toSet()
            // The timeline entry's own fields, not the snapshot's.
            ..removeAll(['date', 'content', 'entry']);
      expect(written, containsAll(kotlinReads));
      expect(written, containsAll(swiftReads));
      expect(
        read(kotlin),
        contains('SNAPSHOT_VERSION = $widgetSnapshotVersion'),
      );
      expect(read(swift), contains('snapshotVersion = $widgetSnapshotVersion'));
      expect(read(kotlin), contains('"$widgetSnapshotKey"'));
      expect(read(swift), contains('"$widgetSnapshotKey"'));
    });
  });

  test('one App Group id: Dart, Swift and both entitlements', () {
    expect(widgetAppGroupId, 'group.app.kalan.mobile');
    expect(read(swift), contains('appGroup = "$widgetAppGroupId"'));
    for (final path in [
      'ios/Runner/Runner.entitlements',
      'ios/KalanWidget/KalanWidget.entitlements',
    ]) {
      expect(read(path), contains('<string>$widgetAppGroupId</string>'));
    }
    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'.allMatches(
        project,
      ),
      hasLength(3),
    );
    expect(
      'CODE_SIGN_ENTITLEMENTS = KalanWidget/KalanWidget.entitlements;'
          .allMatches(project),
      hasLength(3),
    );
    expect(project, contains('com.apple.product-type.app-extension'));
    expect(project, contains('Embed Foundation Extensions'));
    // Embedded before the Flutter "Thin Binary" script (no build cycle).
    final runner = project.substring(
      project.indexOf('97C146ED1CF9000F007C117D /* Runner */ = {'),
    );
    final phases = RegExp(r'buildPhases = \(([^)]*)\);')
        .firstMatch(runner)![1]!;
    expect(
      phases.indexOf('Embed Foundation Extensions'),
      lessThan(phases.indexOf('Thin Binary')),
    );
  });

  test('the widget kind and provider names match the gateway', () {
    expect(read(swift), contains('kind = "$widgetIosKind"'));
    expect(widgetAndroidProvider, 'app.kalan.mobile.KalanWidgetProvider');
    expect(read(kotlin), contains('class KalanWidgetProvider'));
  });

  group('picker name and description are the ARB texts', () {
    for (final lang in ['en', 'tr']) {
      test(lang, () {
        final arb =
            jsonDecode(read('lib/l10n/app_$lang.arb')) as Map<String, Object?>;
        final name = arb['widgetPickerName']! as String;
        final description = arb['widgetPickerDescription']! as String;
        final android = read(
          '$res/${lang == 'en' ? 'values' : 'values-tr'}/'
          'kalan_widget_strings.xml',
        );
        expect(
          android,
          contains('<string name="kalan_widget_name">$name</string>'),
        );
        expect(
          android,
          contains(
            '<string name="kalan_widget_description">'
            '${description.replaceAll("'", r"\'")}</string>',
          ),
        );
        final ios = read('ios/KalanWidget/$lang.lproj/Localizable.strings');
        expect(ios, contains('"widget.name" = "$name";'));
        expect(ios, contains('"widget.description" = "$description";'));
      });
    }
  });

  test('Android: the provider, no network, no deep links', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:name=".KalanWidgetProvider"'));
    expect(manifest, contains('@xml/kalan_widget_info'));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(
      manifest,
      contains(
        'android:name="android.permission.ACCESS_NETWORK_STATE"\n'
        '        tools:node="remove"',
      ),
    );
    expect(manifest, contains('"flutter_deeplinking_enabled"'));
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    final info = read('$res/xml/kalan_widget_info.xml');
    expect(info, contains('android:resizeMode="horizontal|vertical"'));
    expect(info, contains('android:widgetCategory="home_screen"'));
  });

  test('iOS: a widget tap opens the app through home_widget only', () {
    final plist = read('ios/Runner/Info.plist');
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    expect(plist, contains('<string>kalan</string>'));
    expect(read(swift), contains('"kalan://widget?homeWidget"'));
  });

  test('Android layouts: start and end, never left and right', () {
    for (final name in ['kalan_widget_small', 'kalan_widget_medium']) {
      final xml = read('$res/layout/$name.xml')
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      expect(
        RegExp(r'Left|Right|"left|"right|\|left|\|right').hasMatch(xml),
        isFalse,
        reason: name,
      );
      // Only the big number may shrink; to 60 % at most.
      final sizes = RegExp(
        r'autoSizeMaxTextSize="(\d+)sp"\s+android:autoSizeMinTextSize="(\d+)sp"',
      ).allMatches(xml).toList();
      expect(sizes, hasLength(3), reason: name);
      for (final m in sizes) {
        final max = int.parse(m[1]!);
        final min = int.parse(m[2]!);
        expect(min, greaterThanOrEqualTo((max * 0.6).floor()), reason: name);
      }
    }
    expect(read(swift), contains('.minimumScaleFactor(0.6)'));
    expect('.minimumScaleFactor('.allMatches(read(swift)), hasLength(1));
  });
}

class _NoTexts implements WidgetTexts {
  const _NoTexts();
  @override
  String get leftTitle => '';
  @override
  String get paymentsTitle => '';
  @override
  String until(LocalDate lastDay) => '';
  @override
  String shortDate(LocalDate date) => '';
  @override
  String money(int minor) => '';
  @override
  String moneyShort(int minor) => '';
  @override
  String get amountHidden => '';
  @override
  String get noPayments => '';
  @override
  String get noUpcoming => '';
  @override
  String get setup => '';
  @override
  String get stale => '';
  @override
  String spokenSummary({
    required String title,
    required String amount,
    required String date,
  }) => '';
  @override
  String spokenPayment({
    required String name,
    required String date,
    required String amount,
  }) => '';
  @override
  bool get rightToLeft => false;
}
