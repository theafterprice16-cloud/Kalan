import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/features/roadmap/roadmap.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';

/// The ```json block in docs/ROADMAP_CONTENT.md.
String docExample() {
  final doc = File('docs/ROADMAP_CONTENT.md').readAsStringSync();
  final match = RegExp(r'```json\n(.*?)```', dotAll: true).firstMatch(doc);
  return match!.group(1)!;
}

void main() {
  group('roadmap schema', () {
    test('the shipped file is valid and currently empty', () {
      final items = parseRoadmap(File(roadmapAsset).readAsStringSync());
      expect(items, isEmpty);
    });

    test('the documented example is valid', () {
      final items = parseRoadmap(docExample());
      expect(items, hasLength(2));
      final first = items.first;
      expect(first.id, 'yerel-bildirimler');
      expect(first.title('tr'), 'Ödeme hatırlatmaları');
      expect(first.title('en'), 'Payment reminders');
      expect(first.status, RoadmapStatus.inProgress);
      expect(first.targetVersion, '1.1');
      expect(items.last.targetVersion, isNull);
      expect(items.last.status, RoadmapStatus.planned);
    });

    final invalid = <String, String>{
      'not a list': '{}',
      'missing English title':
          '[{"id":"a","title":{"tr":"A"},"summary":{"tr":"x","en":"x"},'
          '"status":"planned"}]',
      'empty summary':
          '[{"id":"a","title":{"tr":"A","en":"A"},'
          '"summary":{"tr":"","en":"x"},"status":"planned"}]',
      'unknown status':
          '[{"id":"a","title":{"tr":"A","en":"A"},'
          '"summary":{"tr":"x","en":"x"},"status":"done"}]',
      'numeric target version':
          '[{"id":"a","title":{"tr":"A","en":"A"},'
          '"summary":{"tr":"x","en":"x"},"status":"shipped",'
          '"targetVersion":1.1}]',
      'missing id':
          '[{"title":{"tr":"A","en":"A"},"summary":{"tr":"x","en":"x"},'
          '"status":"planned"}]',
      'duplicate id':
          '[{"id":"a","title":{"tr":"A","en":"A"},'
          '"summary":{"tr":"x","en":"x"},"status":"planned"},'
          '{"id":"a","title":{"tr":"B","en":"B"},'
          '"summary":{"tr":"y","en":"y"},"status":"shipped"}]',
    };
    for (final MapEntry(key: name, value: json) in invalid.entries) {
      test('rejects $name', () {
        expect(() => parseRoadmap(json), throwsFormatException);
      });
    }
  });

  testWidgets('empty roadmap shows one calm sentence', (tester) async {
    await pumpApp(tester, seed: seedSettings);
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Yol Haritası'));
    await tester.tap(find.text('Yol Haritası'));
    await tester.pumpAndSettle();
    expect(find.text('Şu an burada paylaşılacak bir şey yok.'), findsOneWidget);
  });

  testWidgets('roadmap items are listed in the app language', (tester) async {
    await pumpApp(
      tester,
      seed: seedSettings,
      overrides: [
        roadmapSourceProvider.overrideWith((ref) async => docExample()),
      ],
    );
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Yol Haritası'));
    await tester.tap(find.text('Yol Haritası'));
    await tester.pumpAndSettle();
    expect(find.text('Ödeme hatırlatmaları'), findsOneWidget);
    expect(find.text('Dosyaya dışa aktarma'), findsOneWidget);
    expect(find.text('Yapılıyor'), findsOneWidget);
    expect(find.text('Planlandı'), findsOneWidget);
    expect(find.text('Hedef sürüm 1.1'), findsOneWidget);
    expect(find.text('Payment reminders'), findsNothing);
  });

  testWidgets('English roadmap', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en', 'US'),
      seed: seedSettings,
      overrides: [
        roadmapSourceProvider.overrideWith((ref) async => docExample()),
      ],
    );
    await openTab(tester, 'Settings');
    await scrollTo(tester, find.text('Roadmap'));
    await tester.tap(find.text('Roadmap'));
    await tester.pumpAndSettle();
    expect(find.text('Payment reminders'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Target version 1.1'), findsOneWidget);
  });

  testWidgets('a broken file shows an error sentence', (tester) async {
    await pumpApp(
      tester,
      seed: seedSettings,
      overrides: [roadmapSourceProvider.overrideWith((ref) async => '{')],
    );
    await openTab(tester, 'Ayarlar');
    await scrollTo(tester, find.text('Yol Haritası'));
    await tester.tap(find.text('Yol Haritası'));
    await tester.pumpAndSettle();
    expect(find.text('Yol haritası okunamadı.'), findsOneWidget);
  });
}
