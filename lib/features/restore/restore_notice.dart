import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_summary.dart';
import '../../core/design/widgets.dart';
import '../../core/theme/kalan_theme.dart';
import '../../entitlement/entitlement.dart';
import '../../entitlement/pro_controller.dart';
import '../pro/pro_screen.dart' show restoreProPurchase;

/// What the home screen says once after a restore (Roadmap 30): set by
/// the restore screen, read by [RestoreNotice]. Lives for this run of
/// the app only.
final restoreNoticeProvider =
    NotifierProvider<RestoreNoticeController, RestoreNoticeState?>(
      RestoreNoticeController.new,
    );

class RestoreNoticeState {
  const RestoreNoticeState(this.summary, {this.shown = false});

  final BackupSummary summary;

  /// Whether the short message was shown already.
  final bool shown;
}

class RestoreNoticeController extends Notifier<RestoreNoticeState?> {
  @override
  RestoreNoticeState? build() => null;

  void restored(BackupSummary summary) => state = RestoreNoticeState(summary);

  void markShown() {
    final s = state;
    if (s != null && !s.shown) {
      state = RestoreNoticeState(s.summary, shown: true);
    }
  }
}

/// Whether the restore brought more open plans than the free version
/// allows and no new plan can be added (decision 3): then the home
/// screen offers "Restore purchase" instead of the short message. The
/// store is asked only when that button is tapped.
bool restoreNeedsProLine({
  required BackupSummary summary,
  required int openPlansNow,
  required Entitlement entitlement,
}) =>
    summary.openForLimit > freeOpenPlanLimit &&
    !canAddPlan(openPlans: openPlansNow, entitlement: entitlement);

/// On the home screen after a restore: the short message "Backup
/// restored: 12 plans, 3 recurring payments." once, or, when the free
/// version got more than four open plans, a calm line with "Restore
/// purchase" that stays until Pro is on or a plan can be added again.
class RestoreNotice extends ConsumerStatefulWidget {
  const RestoreNotice({super.key});

  @override
  ConsumerState<RestoreNotice> createState() => _RestoreNoticeState();
}

class _RestoreNoticeState extends ConsumerState<RestoreNotice> {
  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(restoreNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    final plans = ref.watch(plansProvider).value;
    if (plans == null) return const SizedBox.shrink();
    final proLine = restoreNeedsProLine(
      summary: notice.summary,
      openPlansNow: plans.where((p) => p.isOpen).length,
      entitlement: ref.watch(entitlementProvider),
    );
    if (!notice.shown) {
      // After this frame: the message belongs to the home tab's messenger.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = ref.read(restoreNoticeProvider);
        if (current == null || current.shown) return;
        ref.read(restoreNoticeProvider.notifier).markShown();
        if (proLine) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.restoreDone(
                current.summary.plans,
                current.summary.recurring,
              ),
            ),
          ),
        );
      });
    }
    if (!proLine) return const SizedBox.shrink();
    final colors = context.colors;
    final busy = ref.watch(proControllerProvider).busy != ProBusy.none;
    return Padding(
      key: const ValueKey('restore-pro-line'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        KalanSpace.md,
        KalanSpace.sm,
        KalanSpace.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusNote(
            icon: Icons.info_outline,
            color: colors.textMuted,
            textColor: colors.textMuted,
            text: context.l10n.restoreProNote,
          ),
          // Under the sentence, past the icon (20 + 8) less the button's
          // own inset.
          Padding(
            padding: const EdgeInsetsDirectional.only(start: KalanSpace.md),
            child: TextButton(
              key: const ValueKey('restore-pro-restore'),
              onPressed: busy
                  ? null
                  : () => unawaited(restoreProPurchase(context, ref)),
              child: Text(context.l10n.proRestore),
            ),
          ),
        ],
      ),
    );
  }
}
