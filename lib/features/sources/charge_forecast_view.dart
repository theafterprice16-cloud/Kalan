import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/engine/engine.dart';
import '../../data/models.dart';

/// "Keep in account" (18): the forecast with the periods it was made for.
class ChargeForecastView {
  const ChargeForecastView({
    required this.forecast,
    required this.current,
    required this.next,
    required this.today,
  });

  final ChargeForecast forecast;

  /// The home screen's current pay period and the one after it.
  final PayPeriod current;
  final PayPeriod next;
  final LocalDate today;

  SourceCharges of(int sourceId) => forecast.of(sourceId, current, next);
}

/// Every stored plan payment as the forecast sees it, on the date the
/// engine stored. Only plans: recurring payments have no payment method
/// or source (decision 4).
List<ChargeItem> chargeItemsOf(Iterable<PlanWithPayments> plans) => [
  for (final p in plans)
    for (final pay in p.payments)
      ChargeItem(
        planId: p.plan.id,
        paymentId: pay.id,
        name: p.ownName,
        sourceId: p.chargeSourceId,
        method: p.plan.paymentMethod,
        dueDate: pay.date,
        amountMinor: pay.amountMinor,
        isPaid: pay.isPaid,
        paidOn: pay.paidOnDay == null
            ? null
            : LocalDate.fromEpochDay(pay.paidOnDay!),
        paidBeforeKalan: pay.paidBeforeKalan,
        // A card plan taken from its own card: on its statements (16).
        isOwnCardInstallment:
            p.ownCardId != null && p.chargeSourceId == p.ownCardId,
      ),
];

/// [chargeForecast] for the home screen's period and the next one,
/// following plans, payments, the payday and the day. Null while data
/// loads or before onboarding.
final chargeForecastProvider = Provider<ChargeForecastView?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final plans = ref.watch(plansProvider).value;
  if (settings == null || plans == null) return null;
  final today = ref.watch(todayProvider);
  final schedule = payScheduleOf(settings);
  final current = schedule.periodContaining(today);
  final next = schedule.next(current);
  return ChargeForecastView(
    forecast: chargeForecast(
      items: chargeItemsOf(plans),
      current: current,
      next: next,
      today: today,
    ),
    current: current,
    next: next,
    today: today,
  );
});
