// Longer texts (Roadmap 24, decision 13, Example 5): with every English
// word 40% longer (pseudo-localization, test/helpers/pseudo_l10n.dart),
// real font widths and large text, the main screens open without an
// overflow. Where text would not fit it wraps or buttons stack; type is
// never made smaller to fit.
import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/app/app.dart';
import 'package:kalan/core/backup/backup_summary.dart';
import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/features/restore/restore_notice.dart';
import 'package:kalan/features/restore/restore_service.dart';
import 'package:kalan/features/restore/restore_undo.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/fonts.dart';
import '../helpers/pseudo_l10n.dart';
import '../helpers/restore_fakes.dart';

final t = PseudoLocalizations.load();

Future<void> seedLong(AppDatabase db) async {
  await seedSettings(db, incomeMinor: 1900000, thresholdMinor: 500000);
  await seedCard(db);
  await seedPayIn4(db, totalMinor: 240000, title: 'Kulaklık');
  await seedPayIn4(
    db,
    first: LocalDate(2026, 10, 30),
    totalMinor: 1800000,
    source: 'Afterpay',
    title: 'Mont ve ayakkabı, kış alışverişi',
  );
  await seedRent(db);
}

/// A phone ([size] in points) at text scale [scale], English device.
Future<void> start(
  WidgetTester tester,
  Size size,
  double scale, {
  List<Override> extra = const [],
  Future<void> Function(AppDatabase db) seed = seedLong,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpApp(
    tester,
    locale: const Locale('en', 'US'),
    seed: seed,
    overrides: [
      appLocalizationsDelegateProvider.overrideWithValue(
        const PseudoLocalizationsDelegate(),
      ),
      ...extra,
    ],
  );
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) => tap(tester, find.byType(BackButton));

/// Scrolls every visible scrollable to its end, so lazily built rows
/// are laid out too.
Future<void> scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return;
  await tester.drag(scrollable.first, const Offset(0, -3000));
  await tester.pumpAndSettle();
  await tester.drag(scrollable.first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  test('pseudo texts are about 40% longer and keep their numbers', () {
    expect(PseudoLocalizations.expand('Save'), 'Savesa');
    expect(t.actionSave.length, greaterThanOrEqualTo('Save'.length * 1.4));
    expect(t.proIntro(4), contains('4'));
    // Every message of the generated class is read from the English file.
    expect(t.parameters.keys.toSet(), t.messages.keys.toSet());
    final total = t.messages.values.fold<int>(0, (n, m) => n + m.length);
    final longer = t.messages.values.fold<int>(
      0,
      (n, m) => n + PseudoLocalizations.expand(m).length,
    );
    expect(longer / total, greaterThan(1.3));
  });

  for (final (name, size, scale) in [
    ('iPhone, large text', const Size(390, 844), 1.5),
    ('small phone, larger text', const Size(360, 640), 2.0),
  ]) {
    group(name, () {
      testWidgets('home and coming periods', (tester) async {
        await start(tester, size, scale);
        await scrollThrough(tester);
        const strip = ValueKey('coming-periods-strip');
        await scrollTo(tester, find.byKey(strip));
        await tap(tester, find.byKey(strip));
        await scrollThrough(tester);
        await tap(tester, find.byKey(const ValueKey('coming-period-1')));
        await scrollThrough(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await tap(tester, find.text(t.comingViewCalendar));
        await scrollThrough(tester);
      });

      testWidgets('add plan, every kind', (tester) async {
        await start(tester, size, scale);
        await tap(tester, find.text(t.actionAddPlan));
        for (final kind in [
          t.kindPayIn4,
          t.kindMonthly,
          t.kindCard,
          t.kindManual,
          t.kindPayLater,
        ]) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 5000),
          );
          await tester.pumpAndSettle();
          await scrollTo(tester, find.widgetWithText(ChoiceChip, kind));
          await tap(tester, find.widgetWithText(ChoiceChip, kind));
          final more = find.byKey(const ValueKey('more-details'));
          if (more.evaluate().isNotEmpty) {
            await scrollTo(tester, more);
            await tap(tester, more);
          }
          await scrollThrough(tester);
        }
      });

      testWidgets('plans, a plan, sources', (tester) async {
        await start(tester, size, scale);
        await openTab(tester, t.navPlans);
        await scrollThrough(tester);
        await tap(tester, find.textContaining('Mont ve'));
        await scrollThrough(tester);
        await back(tester);
        await tap(tester, find.byTooltip(t.sourcesTitle));
        await scrollThrough(tester);
      });

      // Restore (30): every step of the screen, the go-back row in
      // Settings and the Pro line on the home screen.
      testWidgets('restore from backup', (tester) async {
        final picker = FakePicker();
        final dir = Directory.systemTemp.createTempSync('kalan-overflow');
        addTearDown(() => dir.deleteSync(recursive: true));
        await start(
          tester,
          size,
          scale,
          extra: [
            ...restoreOverrides(picker, dir),
            undoCopyProvider.overrideWith(
              (ref) async => UndoCopy(
                copiedOn: LocalDate(2026, 11, 19),
                lastFullBackup: null,
              ),
            ),
            restoreNoticeProvider.overrideWith(_SixRestored.new),
          ],
        );
        await openTab(tester, t.navSettings);
        await scrollTo(
          tester,
          find.byKey(const ValueKey('settings-undo-copy')),
        );
        await scrollThrough(tester);
        await scrollTo(
          tester,
          find.byKey(const ValueKey('settings-restore-backup')),
        );
        await tap(
          tester,
          find.byKey(const ValueKey('settings-restore-backup')),
        );
        picker.pickBytes([0x89, 0x50, 0x4E, 0x47]);
        await tap(tester, find.byKey(const ValueKey('restore-pick')));
        await scrollThrough(tester);
        picker.pickPath(encryptedFixture);
        await tap(tester, find.byKey(const ValueKey('restore-pick')));
        await tester.enterText(
          find.byKey(const ValueKey('restore-password')),
          'x',
        );
        await tester.pump();
        await tap(tester, find.byKey(const ValueKey('restore-open')));
        await scrollThrough(tester);
        picker.pickPath(plainFixture);
        await scrollTo(tester, find.text(t.restoreChooseOther));
        await tap(tester, find.text(t.restoreChooseOther));
        await scrollThrough(tester);
        await scrollTo(tester, find.byKey(const ValueKey('restore-button')));
        await tap(tester, find.byKey(const ValueKey('restore-button')));
        expect(find.text(t.restoreConfirmTitle), findsOneWidget);
      });

      testWidgets('home with the Pro line after a restore', (tester) async {
        await start(
          tester,
          size,
          scale,
          extra: [restoreNoticeProvider.overrideWith(_SixRestored.new)],
          // Five open plans: none can be added, so the line shows.
          seed: (db) async {
            await seedLong(db);
            for (final name in ['A', 'B', 'C']) {
              await seedPayIn4(db, source: name);
            }
          },
        );
        await tester.pump();
        // Below the big number: on a small phone with large text, further
        // down.
        await scrollTo(tester, find.byKey(const ValueKey('restore-pro-line')));
        expect(find.byKey(const ValueKey('restore-pro-line')), findsOneWidget);
        expect(find.text(t.proRestore), findsOneWidget);
        await scrollThrough(tester);
      });

      testWidgets('settings and the language picker', (tester) async {
        await start(tester, size, scale);
        await openTab(tester, t.navSettings);
        await scrollThrough(tester);
        await scrollTo(tester, find.text(t.settingsLanguage));
        await tap(tester, find.text(t.settingsLanguage));
      });
    });
  }
}

/// A restore that brought six open plans; its message already shown.
class _SixRestored extends RestoreNoticeController {
  @override
  RestoreNoticeState? build() => const RestoreNoticeState(
    BackupSummary(
      plans: 6,
      open: 6,
      onHold: 0,
      archived: 0,
      recurring: 0,
      sources: 1,
      cards: 0,
    ),
    shown: true,
  );
}
