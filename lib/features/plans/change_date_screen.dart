import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/form_fields.dart';
import '../../core/design/haptics.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/routing/routes.dart';
import '../../core/routing/tab_messengers.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/models.dart';
import '../../data/period_totals.dart';

/// What the installment sheet offers (20).
enum PaymentChoice { changeDate, edit }

/// The note's small calendar icon, in textMuted with the note.
const moveNoteIcon = Icons.event_outlined;

/// The installment sheet: "Change date" and the existing edit. Carries
/// out "Change date" (date picker, then the preview screen) and returns
/// [PaymentChoice.edit] for the caller's own edit; null when dismissed or
/// done.
Future<PaymentChoice?> openPaymentActions(
  BuildContext context,
  WidgetRef ref,
  PlanWithPayments plan,
  PaymentRow payment,
) async {
  final choice = await showModalBottomSheet<PaymentChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PaymentActionsSheet(plan: plan, payment: payment),
  );
  if (choice != PaymentChoice.changeDate || !context.mounted) return choice;
  final today = ref.read(todayProvider);
  final picked = await pickDate(
    context,
    initial: payment.date,
    firstDate: today,
  );
  if (picked == null || !context.mounted) return null;
  await context.push(Routes.paymentDate(plan.plan.id, payment.seq, picked));
  return null;
}

class PaymentActionsSheet extends StatelessWidget {
  const PaymentActionsSheet({
    required this.plan,
    required this.payment,
    super.key,
  });

  final PlanWithPayments plan;
  final PaymentRow payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = context.longDate(payment.date);
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('payment-sheet'),
        padding: const EdgeInsets.only(bottom: KalanSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.lg,
                0,
                KalanSpace.lg,
                KalanSpace.xs,
              ),
              child: Text(
                plan.isPayLater
                    ? date
                    : l10n.paymentActionsTitle(
                        l10n.progressLabel(
                          payment.seq,
                          plan.plan.installmentCount,
                        ),
                        date,
                      ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _Option(
              choice: PaymentChoice.changeDate,
              icon: Icons.event_outlined,
              title: l10n.changeDateAction,
              hint: l10n.changeDateActionHint,
            ),
            _Option(
              choice: PaymentChoice.edit,
              icon: Icons.edit_outlined,
              title: plan.isPayLater ? l10n.planEdit : l10n.editPaymentTitle,
              hint: plan.isPayLater ? null : l10n.editPaymentActionHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.icon,
    required this.title,
    this.hint,
  });

  final PaymentChoice choice;
  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      key: ValueKey('payment-${choice.name}'),
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: KalanSpace.lg),
      leading: Icon(icon, color: colors.text),
      title: Text(title),
      subtitle: hint == null
          ? null
          : Text(hint!, style: TextStyle(color: colors.textMuted)),
      onTap: () => Navigator.pop(context, choice),
    );
  }
}

/// "Change date" (20): the new date, "Move later payments too" (off),
/// and the pay periods whose totals change, before anything is saved.
/// The preview and the save use the same rules ([movedDates],
/// [moveRejection]) and the home screen's periods and counting
/// ([dateChangePreview]).
class ChangeDateScreen extends ConsumerStatefulWidget {
  const ChangeDateScreen({
    required this.planId,
    required this.seq,
    this.initialDate,
    super.key,
  });

  final int planId;
  final int seq;

  /// The date picked in the sheet; the current date when null.
  final LocalDate? initialDate;

  /// At most this many periods are listed; the rest is one line.
  static const maxPeriods = 6;

  @override
  ConsumerState<ChangeDateScreen> createState() => _ChangeDateScreenState();
}

class _ChangeDateScreenState extends ConsumerState<ChangeDateScreen> {
  LocalDate? _date;
  bool _shiftLater = false;
  bool _saving = false;

  /// The plan as it was when "Save" was tapped: shown while the screen
  /// closes, so the saved date does not flash in as "Current date".
  PlanWithPayments? _frozen;

  Future<void> _save(PlanWithPayments plan, LocalDate date) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final tabs = ref.read(tabMessengersProvider);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _frozen = plan;
    });
    final rejected = await ref
        .read(planRepositoryProvider)
        .movePayment(
          planId: plan.plan.id,
          seq: widget.seq,
          newDate: date,
          shiftLater: _shiftLater,
          today: ref.read(todayProvider),
        );
    if (!mounted) return;
    if (rejected != null) {
      // The plan changed meanwhile: the screen shows why from the same
      // check once it rebuilds.
      setState(() {
        _saving = false;
        _frozen = null;
      });
      return;
    }
    KalanHaptics.success();
    router.popWithMessage(
      SnackBar(content: Text(l10n.changeDateDone)),
      fallback: messenger,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider);
    final plan =
        _frozen ??
        plans.value?.where((p) => p.plan.id == widget.planId).firstOrNull;
    final payment = plan?.allPayments
        .where((p) => p.seq == widget.seq)
        .firstOrNull;
    final settings = ref.watch(settingsProvider).value;
    final schedule = ref.watch(payScheduleProvider);
    if (plan == null || payment == null || schedule == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.changeDateAction)),
        body: plans.hasValue && settings != null
            ? EmptyState(l10n.planNotFound)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);
    final colors = context.colors;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final date = _date ?? widget.initialDate ?? payment.date;
    final payments = [for (final p in plan.allPayments) p.toMovable()];
    final hasLater = payments.any((p) => p.seq > widget.seq && !p.isPaid);
    final shift = hasLater && _shiftLater;
    final rejection = moveRejection(
      payments,
      seq: widget.seq,
      newDate: date,
      shiftLater: shift,
      today: today,
      status: plan.status,
      kind: plan.plan.kind,
    );
    final changes = rejection == null
        ? dateChangePreview(
            plan: plan,
            newDates: movedDates(
              payments,
              seq: widget.seq,
              newDate: date,
              shiftLater: shift,
            ),
            schedule: schedule,
            today: today,
          )
        : const <PeriodChange>[];
    final passesNext =
        rejection == null &&
        !shift &&
        passesNextPayment(payments, seq: widget.seq, newDate: date);
    const gap = SizedBox(height: KalanSpace.md);
    // Paid, put on hold or closed since the sheet opened (another screen,
    // a notification): nothing to change here any more.
    if (rejection == MoveRejection.notAllowed ||
        rejection == MoveRejection.notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.changeDateAction)),
        body: EmptyState(
          rejection == MoveRejection.notFound
              ? l10n.planNotFound
              : l10n.changeDateNotAvailable,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changeDateAction)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KalanSpace.md,
          KalanSpace.xs,
          KalanSpace.md,
          KalanSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.planName(plan),
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              [
                if (!plan.isPayLater)
                  l10n.progressLabel(payment.seq, plan.plan.installmentCount),
                ref.money(context, payment.amountMinor),
              ].join(' · '),
              style: muted,
            ),
            Text(
              l10n.changeDateCurrent(context.longDate(payment.date)),
              key: const ValueKey('change-date-current'),
              style: muted,
            ),
            gap,
            DateField(
              key: const ValueKey('change-date-field'),
              label: l10n.changeDateNewDate,
              value: date,
              format: context.longDate,
              firstDate: today,
              // The same date, or a day that passed meanwhile (a date kept
              // from the day before): a calm note, never an error.
              helperText:
                  rejection == MoveRejection.unchanged ||
                      rejection == MoveRejection.beforeToday
                  ? l10n.changeDatePickNew
                  : null,
              onChanged: (d) => setState(() => _date = d),
            ),
            if (hasLater)
              SwitchListTile.adaptive(
                key: const ValueKey('change-date-shift'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.changeDateShiftLater),
                value: _shiftLater,
                onChanged: (v) => setState(() => _shiftLater = v),
              ),
            if (rejection == null ||
                rejection == MoveRejection.laterBeforeToday) ...[
              gap,
              Text(
                l10n.changeDatePreviewTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: KalanSpace.xs),
              DateChangePreview(
                changes: changes,
                hasIncome: settings?.netIncomeMinor != null,
                passesNext: passesNext,
                laterBeforeToday: rejection == MoveRejection.laterBeforeToday,
              ),
            ],
            gap,
            FilledButton(
              key: const ValueKey('change-date-save'),
              onPressed: rejection != null || _saving
                  ? null
                  : () => _save(plan, date),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// The preview box (surfaceRaised): one line per period whose total
/// changes, the difference in ink with its sign and arrow (never color
/// alone), at most [ChangeDateScreen.maxPeriods] lines.
class DateChangePreview extends ConsumerWidget {
  const DateChangePreview({
    required this.changes,
    required this.hasIncome,
    this.passesNext = false,
    this.laterBeforeToday = false,
    super.key,
  });

  final List<PeriodChange> changes;
  final bool hasIncome;
  final bool passesNext;
  final bool laterBeforeToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyMedium?.copyWith(color: colors.text);
    final muted = textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final shown = changes.take(ChangeDateScreen.maxPeriods).toList();
    final more = changes.length - shown.length;

    Widget line(String text, {Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: KalanSpace.xxs),
      child: Text(text, key: key, style: body),
    );

    return Card(
      key: const ValueKey('change-date-preview'),
      color: colors.surfaceRaised,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KalanSpace.md,
          vertical: KalanSpace.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (laterBeforeToday)
              line(
                l10n.changeDateLaterBeforeToday,
                key: const ValueKey('change-date-later-before-today'),
              )
            else if (changes.isEmpty)
              line(
                hasIncome
                    ? l10n.changeDateSamePeriod
                    : l10n.changeDateSamePeriodCommitted,
                key: const ValueKey('change-date-same-period'),
              ),
            for (final c in shown)
              _PeriodRow(change: c, hasIncome: hasIncome, style: body),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KalanSpace.xxs),
                child: Text(l10n.changeDateMorePeriods(more), style: muted),
              ),
            if (passesNext)
              line(
                l10n.changeDatePassesNext,
                key: const ValueKey('change-date-passes-next'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodRow extends ConsumerWidget {
  const _PeriodRow({
    required this.change,
    required this.hasIncome,
    required this.style,
  });

  final PeriodChange change;
  final bool hasIncome;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final delta = hasIncome
        ? change.leftDeltaMinor
        : change.spokenForDeltaMinor;
    final amount = ref.money(context, delta.abs());
    final up = delta > 0;
    final (text, semantics) = switch ((hasIncome, up)) {
      (true, true) => (
        l10n.changeDateLeftUp(amount),
        l10n.changeDateLeftUpSemantics(amount),
      ),
      (true, false) => (
        l10n.changeDateLeftDown(amount),
        l10n.changeDateLeftDownSemantics(amount),
      ),
      (false, true) => (
        l10n.changeDateCommittedUp(amount),
        l10n.changeDateCommittedUpSemantics(amount),
      ),
      (false, false) => (
        l10n.changeDateCommittedDown(amount),
        l10n.changeDateCommittedDownSemantics(amount),
      ),
    };
    final range = l10n.periodRange(
      context.shortDate(change.period.start),
      context.shortDate(change.period.lastDay),
    );
    return Semantics(
      container: true,
      label: '$range, $semantics',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KalanSpace.xxs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(range, style: style)),
            const SizedBox(width: KalanSpace.sm),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      key: ValueKey(
                        'change-date-row-${change.period.start.epochDay}',
                      ),
                      textAlign: TextAlign.end,
                      style: style?.copyWith(
                        fontFeatures: AmountText.tabular,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: KalanSpace.xxs),
                  // The arrow with the sign: never color alone.
                  Icon(
                    up ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: context.colors.text,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The note under a moved payment in plan details: "Moved later ·
/// originally 20 November" with a small calendar icon, in textMuted. None
/// when the payment is on its original date.
class MoveNoteText extends StatelessWidget {
  const MoveNoteText({required this.payment, super.key});

  final PaymentRow payment;

  @override
  Widget build(BuildContext context) {
    final original = payment.originalDate;
    final note = moveNoteOf(date: payment.date, originalDate: original);
    if (note == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    final day = context.dayMonth(original!);
    final text = switch (note) {
      MoveNote.later => l10n.moveNoteLater(day),
      MoveNote.earlier => l10n.moveNoteEarlier(day),
    };
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.textMuted);
    return Row(
      key: const ValueKey('move-note'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(moveNoteIcon, size: 16, color: colors.textMuted),
        const SizedBox(width: KalanSpace.xxs),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
