import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Locale;

import '../../app/debounced_task.dart';
import '../../app/locale.dart';
import '../../app/providers.dart';
import '../../core/date/local_date.dart';
import '../../core/money/currency.dart';
import '../../core/widget/widget_snapshot.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../lock/app_lock_controller.dart';
import '../privacy/amounts_hidden.dart';
import '../reminders/reminder_providers.dart';
import 'lock_screen_left.dart';
import 'widget_amounts.dart';
import 'widget_collector.dart';
import 'widget_gateway.dart';
import 'widget_texts.dart';

/// Builds the widget's snapshot from stored data and hands it over.
class WidgetPublisher {
  WidgetPublisher({
    required this.db,
    required this.gateway,
    required this.now,
    required this.localeFor,
    required this.masked,
    this.lockScreen = _noLockScreen,
  });

  static LockScreenOptions _noLockScreen(SettingsRow? settings) =>
      const LockScreenOptions();

  final AppDatabase db;
  final WidgetGateway gateway;
  final DateTime Function() now;

  /// App language: the settings' choice or the device's (null: not set up).
  final Locale Function(SettingsRow? settings) localeFor;

  /// [widgetAmountsMasked] as the choices stand at each run.
  final bool Function() masked;

  /// The Lock Screen widget's choices (Roadmap 32) as they stand at each
  /// run: Pro (the Settings test switch is in [settings]) and whether
  /// what's left shows.
  final LockScreenOptions Function(SettingsRow? settings) lockScreen;

  /// The last JSON handed over, so an unchanged widget is not redrawn.
  String? _last;

  /// The snapshot as it would be published now.
  Future<WidgetSnapshot> build() async {
    final settings = await SettingsRepository(db).get();
    final l10n = lookupAppLocalizations(localeFor(settings));
    // Month names, also in a background isolate.
    await loadLocaleData();
    return buildWidgetSnapshot(
      input: await readWidgetInput(
        db,
        today: LocalDate.fromDateTime(now()),
        l10n: l10n,
      ),
      masked: masked(),
      lock: lockScreen(settings),
      texts: L10nWidgetTexts(
        l10n: l10n,
        currency: settings == null
            ? Currency.fallback
            : Currency.fromCode(settings.currencyCode),
      ),
    );
  }

  Future<void> publish() async {
    if (!gateway.supported) return;
    final json = jsonEncode((await build()).toJson());
    if (json == _last) return;
    await gateway.publish(json);
    _last = json;
  }
}

/// Overridden in main() with [HomeWidgetGateway] on phones.
final widgetGatewayProvider = Provider<WidgetGateway>(
  (ref) => const NoopWidgetGateway(),
);

/// Whether the widget masks amounts now (product owner's decision 1).
final widgetMaskedProvider = Provider<bool>(
  (ref) => widgetAmountsMasked(
    hideAmounts: ref.watch(amountsHiddenProvider),
    appLock: ref.watch(appLockProvider.select((s) => s.enabled)),
    showInWidget: ref.watch(widgetAmountsProvider),
  ),
);

/// The Lock Screen widget's choices now (Roadmap 32): Pro, and what's
/// left only on an iPhone, with "Show what's left" on and nothing masked
/// (decision 3).
final lockScreenOptionsProvider = Provider<LockScreenOptions>(
  (ref) => LockScreenOptions(
    pro: ref.watch(entitlementProvider.select((e) => e.isPro)),
    showLeft:
        ref.watch(lockScreenWidgetSupportedProvider) &&
        lockScreenLeftShown(
          showLeft: ref.watch(lockScreenLeftProvider),
          hideAmounts: ref.watch(amountsHiddenProvider),
          appLock: ref.watch(appLockProvider.select((s) => s.enabled)),
          showInWidget: ref.watch(widgetAmountsProvider),
        ),
  ),
);

final widgetPublisherProvider = Provider((ref) {
  final appLocales = ref.watch(appLocalesProvider);
  return WidgetPublisher(
    db: ref.watch(databaseProvider),
    gateway: ref.watch(widgetGatewayProvider),
    now: ref.watch(clockProvider),
    localeFor: (s) => appLocale(s?.localeCode, appLocales),
    // Read at each run, as the choices stand then.
    masked: () => ref.read(widgetMaskedProvider),
    lockScreen: (_) => ref.read(lockScreenOptionsProvider),
  );
});

/// Redraws the widget whenever what it shows may change: plans and
/// payments, recurring payments, sources (card dates), settings (language,
/// currency, pay schedule, income), the privacy choices, Pro and "Show
/// what's left" (Lock Screen, 32). The app also
/// asks on start and when it comes back to the foreground (the date may
/// have changed). The same listeners as [reminderSyncProvider], in one
/// central place instead of calls from screens.
final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final sync = WidgetSync(
    ref.watch(widgetPublisherProvider),
    debounce: ref.watch(reminderDebounceProvider),
  );
  ref.listen(plansProvider, (_, _) => sync.request());
  ref.listen(recurringProvider, (_, _) => sync.request());
  ref.listen(sourcesProvider, (_, _) => sync.request());
  ref.listen(settingsProvider, (_, _) => sync.request());
  ref.listen(widgetMaskedProvider, (_, _) => sync.request());
  // Lock Screen widget (32): Pro bought or refunded, "Show what's left".
  ref.listen(lockScreenOptionsProvider, (a, b) {
    if (a?.pro != b.pro || a?.showLeft != b.showLeft) sync.request();
  });
  ref.onDispose(sync.dispose);
  return sync;
});

/// Debounces requests and runs at most one publish at a time, in the
/// background (the UI never waits for it).
class WidgetSync extends DebouncedTask {
  WidgetSync(WidgetPublisher publisher, {required super.debounce})
    : super(publisher.publish);
}
