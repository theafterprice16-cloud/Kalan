import 'package:flutter/foundation.dart';

/// Open plans allowed on the free tier. Recurring payments do not count.
const freeOpenPlanLimit = 4;

/// What the user is allowed to do. The purchase flow will implement this
/// later; until then only debug builds can turn Pro on.
abstract interface class Entitlement {
  bool get isPro;
}

class DebugEntitlement implements Entitlement {
  const DebugEntitlement({required this.debugProSwitch});

  /// The Settings switch; ignored outside debug builds.
  final bool debugProSwitch;

  @override
  bool get isPro => kDebugMode && debugProSwitch;
}

bool canAddPlan({required int openPlans, required Entitlement entitlement}) =>
    entitlement.isPro || openPlans < freeOpenPlanLimit;
