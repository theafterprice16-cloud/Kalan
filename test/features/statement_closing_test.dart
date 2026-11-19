import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/reminders/reminder_models.dart';
import 'package:kalan/core/routing/router.dart';
import 'package:kalan/core/routing/routes.dart';
import 'package:kalan/data/db/app_database.dart';
import 'package:kalan/data/repositories/plan_repository.dart';
import 'package:kalan/data/repositories/source_repository.dart';
import 'package:kalan/features/reminders/local_notifications.dart';
import 'package:kalan/features/reminders/reminder_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_harness.dart';
import '../helpers/statement_seed.dart';

void main() {
  group('card settings', () {
    late int cardId;

    Future<AppDatabase> openCard(
      WidgetTester tester, {
      bool on = false,
      int days = 2,
      Locale locale = const Locale('tr', 'TR'),
    }) =>
        pumpApp(
          tester,
          locale: locale,
          seed: (db) async {
            await seedSettings(db);
            cardId = await SourceRepository(db, PlanRepository(db)).create(
              name: 'Maximum',
              kind: SourceKind.card,
              statementDay: 14,
              dueDay: 24,
              statementReminderEnabled: on,
              statementReminderDays: days,
            );
          },
          overrides: [initialRouteProvider.overrideWithValue(Routes.sources)],
        ).then((db) async {
          // Opened from its row, as in the app, so saving goes back.
          await tester.tap(find.text('Maximum'));
          await tester.pumpAndSettle();
          return db;
        });

    Future<SourceRow> stored(AppDatabase db) =>
        (db.select(db.sources)..where((s) => s.id.equals(cardId))).getSingle();

    testWidgets('off by default; on shows 1 / 2 days, 2 selected; saved', (
      tester,
    ) async {
      final db = await openCard(tester);
      final toggle = find.byKey(const ValueKey('statement-reminder'));
      await scrollTo(tester, toggle);
      expect(find.text('Hesap kesim hatırlatması'), findsOneWidget);
      expect(
        find.text(
          'Hesap kesim gününden önce, hatırlatma saatinde bir bildirim.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(
        find.byKey(const ValueKey('statement-reminder-days')),
        findsNothing,
      );

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final days = find.byKey(const ValueKey('statement-reminder-days'));
      await scrollTo(tester, days);
      expect(find.text('Kaç gün önce'), findsOneWidget);
      final chips = tester
          .widgetList<ChoiceChip>(
            find.descendant(of: days, matching: find.byType(ChoiceChip)),
          )
          .toList();
      expect(chips, hasLength(2));
      expect(chips.map((c) => c.selected), [false, true]);
      expect(find.text('1 gün önce'), findsOneWidget);
      expect(find.text('2 gün önce'), findsOneWidget);
      // At least 48 x 48 to tap.
      for (final chip
          in find
              .descendant(of: days, matching: find.byType(ChoiceChip))
              .evaluate()) {
        final size = tester.getSize(find.byWidget(chip.widget));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));

      await tester.tap(find.text('1 gün önce'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('save-source')));
      await tester.tap(find.byKey(const ValueKey('save-source')));
      await tester.pumpAndSettle();
      final row = await tester.runAsync(() => stored(db));
      expect(row!.statementReminderEnabled, isTrue);
      expect(row.statementReminderDays, 1);
    });

    testWidgets('a saved choice comes back; off hides the days', (
      tester,
    ) async {
      final db = await openCard(
        tester,
        on: true,
        days: 1,
        locale: const Locale('en'),
      );
      final toggle = find.byKey(const ValueKey('statement-reminder'));
      await scrollTo(tester, toggle);
      expect(find.text('Statement closing reminder'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      final days = find.byKey(const ValueKey('statement-reminder-days'));
      await scrollTo(tester, days);
      expect(find.text('Days before'), findsOneWidget);
      expect(
        tester
            .widgetList<ChoiceChip>(
              find.descendant(of: days, matching: find.byType(ChoiceChip)),
            )
            .map((c) => c.selected),
        [true, false],
      );
      await scrollTo(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(days, findsNothing);
      await scrollTo(tester, find.byKey(const ValueKey('save-source')));
      await tester.tap(find.byKey(const ValueKey('save-source')));
      await tester.pumpAndSettle();
      final row = await tester.runAsync(() => stored(db));
      expect(row!.statementReminderEnabled, isFalse);
      expect(row.statementReminderDays, 1);
    });

    testWidgets('only with a statement day: not for a new card or provider', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: seedSettings,
        overrides: [
          initialRouteProvider.overrideWithValue(Routes.newSource(card: true)),
        ],
      );
      final toggle = find.byKey(const ValueKey('statement-reminder'));
      expect(toggle, findsNothing);
      await pickDropdown(tester, const ValueKey('statement-day'), '14');
      await scrollTo(tester, toggle);
      expect(toggle, findsOneWidget);
      await scrollTo(tester, find.text('Sonra öde sağlayıcısı'));
      await tester.tap(find.text('Sonra öde sağlayıcısı'));
      await tester.pumpAndSettle();
      expect(toggle, findsNothing);
    });
  });

  group('a tap opens the card\'s statements (16)', () {
    late StatementCards cards;

    Future<void> open(WidgetTester tester, {String? launch}) async {
      tester.view.physicalSize = const Size(780, 1000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        today: statementToday,
        seed: (db) async => cards = await seedStatements(db),
        overrides: [
          if (launch != null) launchPayloadProvider.overrideWithValue(launch),
        ],
      );
    }

    void expectCardOnScreen(WidgetTester tester, int card) {
      expect(find.byKey(const ValueKey('sources-list')), findsOneWidget);
      final next = find.byKey(ValueKey('card-statement-$card-0'));
      expect(next, findsOneWidget);
      expect(tester.getRect(next).bottom, lessThan(500));
    }

    testWidgets('while the app runs: over the current screen, back returns', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const ValueKey('sources-list')), findsNothing);
      notificationTaps.add(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: cardStatementPayload(cards.gece),
        ),
      );
      await tester.pumpAndSettle();
      expectCardOnScreen(tester, cards.gece);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sources-list')), findsNothing);
    });

    testWidgets('launched by the tap: the card opens over home', (
      tester,
    ) async {
      await open(tester, launch: cardStatementPayload(cards.gece));
      expectCardOnScreen(tester, cards.gece);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sources-list')), findsNothing);
    });

    testWidgets('a payment reminder still opens home', (tester) async {
      await open(tester, launch: reminderPayload);
      expect(find.byKey(const ValueKey('sources-list')), findsNothing);
      notificationTaps.add(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: reminderPayload,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sources-list')), findsNothing);
    });
  });
}
