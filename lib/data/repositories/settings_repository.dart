import 'package:drift/drift.dart';

import '../../core/engine/pay_later.dart';
import '../../core/money/currency.dart';
import '../db/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Null until onboarding is finished.
  Stream<SettingsRow?> watch() =>
      _db.select(_db.appSettings).watchSingleOrNull();

  Future<SettingsRow?> get() => _db.select(_db.appSettings).getSingleOrNull();

  Future<void> save(AppSettingsCompanion settings) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(settings.copyWith(id: const Value(1)));

  /// Updates fields of the existing row. No-op before onboarding.
  Future<void> update(AppSettingsCompanion changes) => (_db.update(
    _db.appSettings,
  )..where((s) => s.id.equals(1))).write(changes);

  /// Remembers the "Pay later" rule just used, offered next time. A
  /// picked date is never remembered: the rule before it stays.
  Future<void> rememberPayLaterRule(PayLaterRule rule) async {
    if (rule.kind == PayLaterRuleKind.chosenDate) return;
    await update(
      AppSettingsCompanion(
        lastPayLaterRule: Value(rule.kind),
        lastPayLaterValue: Value(rule.value),
      ),
    );
  }

  /// Switches the currency label. No conversion: shown amounts stay the
  /// same. When minor digits differ, every stored amount moves to the new
  /// base in one transaction, rounding half up; payments and recurring
  /// amounts never drop below one minor unit.
  Future<void> changeCurrency({
    required Currency from,
    required Currency to,
  }) => _db.transaction(() async {
    if (from.decimals != to.decimals) {
      int scale(int v, {int min = 0}) {
        final scaled = scaleMinor(
          v,
          fromDecimals: from.decimals,
          toDecimals: to.decimals,
        );
        return scaled < min ? min : scaled;
      }

      for (final p in await _db.select(_db.payments).get()) {
        await (_db.update(_db.payments)..where((x) => x.id.equals(p.id))).write(
          PaymentsCompanion(amountMinor: Value(scale(p.amountMinor, min: 1))),
        );
      }
      for (final r in await _db.select(_db.recurringPayments).get()) {
        await (_db.update(
          _db.recurringPayments,
        )..where((x) => x.id.equals(r.id))).write(
          RecurringPaymentsCompanion(
            amountMinor: Value(scale(r.amountMinor, min: 1)),
          ),
        );
      }
      final s = await get();
      if (s != null) {
        await update(
          AppSettingsCompanion(
            netIncomeMinor: Value(
              s.netIncomeMinor == null ? null : scale(s.netIncomeMinor!),
            ),
            tightThresholdMinor: Value(
              s.tightThresholdMinor == null
                  ? null
                  : scale(s.tightThresholdMinor!),
            ),
          ),
        );
      }
    }
    await update(AppSettingsCompanion(currencyCode: Value(to.code)));
  });
}
