import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/engine.dart';
import '../core/money/currency.dart';
import '../data/db/app_database.dart';
import '../data/models.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/source_repository.dart';
import '../entitlement/entitlement.dart';
import '../entitlement/pro_controller.dart';

/// Overridden in tests with an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Today's date. Overridden in tests for deterministic periods.
final todayProvider = Provider<LocalDate>((ref) => LocalDate.today());

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
final planRepositoryProvider = Provider(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);
final sourceRepositoryProvider = Provider(
  (ref) => SourceRepository(
    ref.watch(databaseProvider),
    ref.watch(planRepositoryProvider),
  ),
);
final recurringRepositoryProvider = Provider(
  (ref) => RecurringRepository(ref.watch(databaseProvider)),
);

final settingsProvider = StreamProvider<SettingsRow?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);
final plansProvider = StreamProvider<List<PlanWithPayments>>(
  (ref) => ref.watch(planRepositoryProvider).watchAll(),
);
final sourcesProvider = StreamProvider<List<SourceRow>>(
  (ref) => ref.watch(sourceRepositoryProvider).watchAll(),
);
final recurringProvider = StreamProvider<List<RecurringWithMarks>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);

/// The device's region (ISO 3166-1), independent of the app language.
/// Decides the default currency and whether "$" needs a prefix.
/// Overridden in tests.
final deviceRegionProvider = Provider<String?>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.countryCode,
);

/// The chosen currency; before onboarding, the one suggested for the region.
final currencyProvider = Provider<Currency>((ref) {
  final code = ref.watch(settingsProvider).value?.currencyCode;
  return code == null
      ? Currency.forRegion(ref.watch(deviceRegionProvider))
      : Currency.fromCode(code);
});

final entitlementProvider = Provider<Entitlement>(
  (ref) => KalanEntitlement(
    status: ref.watch(proControllerProvider.select((s) => s.status)),
    debugProSwitch: ref.watch(settingsProvider).value?.debugPro ?? false,
  ),
);

final payScheduleProvider = Provider<PaySchedule?>((ref) {
  final s = ref.watch(settingsProvider).value;
  return s == null ? null : payScheduleOf(s);
});

PaySchedule payScheduleOf(SettingsRow s) => switch (s.payFrequency) {
  PayFrequency.monthly => PaySchedule.monthly(s.payDay ?? 1),
  PayFrequency.biweekly => PaySchedule.biweekly(
    LocalDate.fromEpochDay(s.payAnchorDay ?? 0),
  ),
  PayFrequency.weekly => PaySchedule.weekly(
    LocalDate.fromEpochDay(s.payAnchorDay ?? 0),
  ),
};
