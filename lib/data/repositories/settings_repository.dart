import 'package:drift/drift.dart';

import '../../core/engine/amount_entry.dart';
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

  /// Remembers which amount was typed for the plan just added (total or
  /// installment); the add form opens with it next time.
  Future<void> rememberAmountEntry(AmountEntry entry) =>
      update(AppSettingsCompanion(lastAmountEntry: Value(entry)));

  /// Switches the currency label. No conversion: shown amounts stay the
  /// same. When minor digits differ, every stored amount moves to the new
  /// base in one transaction, rounding half up; payments, their extra
  /// fees and recurring amounts never drop below one minor unit.
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
          PaymentsCompanion(
            amountMinor: Value(scale(p.amountMinor, min: 1)),
            // An extra fee (21) moves with its payment; never below 1.
            extraFeeMinor: Value(
              p.extraFeeMinor == null ? null : scale(p.extraFeeMinor!, min: 1),
            ),
            // So does a fee per payment (22).
            installmentFeeMinor: Value(
              p.installmentFeeMinor == null
                  ? null
                  : scale(p.installmentFeeMinor!, min: 1),
            ),
          ),
        );
      }
      // The plan's fee per payment scales the same way, so its unpaid
      // payments still match it (22).
      // A product price (23) too, never below 1.
      for (final p in await _db.select(_db.plans).get()) {
        if (p.installmentFeeMinor == null && p.productPriceMinor == null) {
          continue;
        }
        await (_db.update(_db.plans)..where((x) => x.id.equals(p.id))).write(
          PlansCompanion(
            installmentFeeMinor: Value(
              p.installmentFeeMinor == null
                  ? null
                  : scale(p.installmentFeeMinor!, min: 1),
            ),
            productPriceMinor: Value(
              p.productPriceMinor == null
                  ? null
                  : scale(p.productPriceMinor!, min: 1),
            ),
          ),
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
