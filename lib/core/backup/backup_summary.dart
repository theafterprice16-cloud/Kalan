/// What a backup holds, counted for the restore summary (Roadmap 30).
/// Pure Dart.
library;

import '../engine/plan_status.dart';
import 'backup_data.dart';

class BackupSummary {
  const BackupSummary({
    required this.plans,
    required this.open,
    required this.onHold,
    required this.archived,
    required this.recurring,
    required this.sources,
    required this.cards,
  });

  /// Counted the way the app lists them: open, on hold, and in the
  /// archive (closed, or every payment paid; [planIsOpen]).
  factory BackupSummary.of(BackupData data) {
    var open = 0;
    var onHold = 0;
    for (final p in data.plans) {
      final isOpen = planIsOpen(
        p.status,
        anyUnpaid: p.payments.any((pay) => pay.paidAt == null),
      );
      if (!isOpen) continue;
      if (p.status == PlanStatus.onHold) {
        onHold++;
      } else {
        open++;
      }
    }
    final cards = data.sources.where((s) => s.kind == 'card').length;
    return BackupSummary(
      plans: data.plans.length,
      open: open,
      onHold: onHold,
      archived: data.plans.length - open - onHold,
      recurring: data.recurringPayments.length,
      sources: data.sources.length - cards,
      cards: cards,
    );
  }

  final int plans;
  final int open;
  final int onHold;
  final int archived;
  final int recurring;

  /// Providers and bank accounts.
  final int sources;
  final int cards;

  /// Plans that count toward the free limit: open and on hold, as when a
  /// plan is added (`canAddPlan`).
  int get openForLimit => open + onHold;
}
