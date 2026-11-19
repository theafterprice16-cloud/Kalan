import 'package:flutter/foundation.dart';

import 'pro_rules.dart';

/// Open plans allowed on the free tier. Recurring payments do not count;
/// a single "Pay later" payment does.
const freeOpenPlanLimit = 4;

/// What the user is allowed to do.
abstract interface class Entitlement {
  bool get isPro;
}

/// Pro from the store, as last saved on the device. The Settings test
/// switch only works in debug builds.
class KalanEntitlement implements Entitlement {
  const KalanEntitlement({
    required this.status,
    required this.debugProSwitch,
    this.debugBuild = kDebugMode,
  });

  final ProStatus status;

  /// The Settings switch; ignored outside debug builds.
  final bool debugProSwitch;
  final bool debugBuild;

  @override
  bool get isPro => status == ProStatus.pro || (debugBuild && debugProSwitch);
}

bool canAddPlan({required int openPlans, required Entitlement entitlement}) =>
    entitlement.isPro || openPlans < freeOpenPlanLimit;
