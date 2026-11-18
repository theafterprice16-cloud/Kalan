import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:material_ui/material_ui.dart' show BackButton;

import '../helpers/app_harness.dart';

/// Records haptic calls sent to the platform.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Future<void> seed(AppDatabase db) async {
  await seedSettings(db);
  await seedPayIn4(db);
}

void main() {
  testWidgets('marking paid gives one light tap; undoing gives none', (
    tester,
  ) async {
    await pumpApp(tester, seed: seed);
    final haptics = recordHaptics(tester);

    await tester.tap(find.byTooltip('Ödendi olarak işaretle').first);
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    await tester.tap(find.byTooltip('Ödenmedi olarak işaretle').first);
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('opening screens and dialogs gives no haptics', (tester) async {
    await pumpApp(tester, seed: seed);
    final haptics = recordHaptics(tester);
    await openTab(tester, 'Planlar');
    await tester.tap(find.text('Klarna'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Planı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
  });

  testWidgets(
    'twice the text size fits',
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, seed: seed);
      await openTab(tester, 'Planlar');
      await tester.tap(find.text('Klarna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Planı sil'));
      await tester.pumpAndSettle();
      expect(find.text('Sil'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await openTab(tester, 'Ayarlar');
      await scrollTo(tester, find.text('Tema'));
      await tester.tap(find.text('Tema'));
      await tester.pumpAndSettle();
      expect(find.text('Koyu'), findsOneWidget);
      // Overflow errors fail the test on their own.
      expect(tester.takeException(), isNull);
    },
  );
}
