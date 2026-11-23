import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/widgets.dart';
import '../../core/engine/engine.dart';
import '../../core/theme/kalan_theme.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/past_due.dart';
import '../home/payment_tile.dart';
import 'busy_week_view.dart';
import 'calendar_month.dart';

/// The two views of the Coming pay periods screen.
enum ComingView { chart, calendar }

/// The chosen view: "Chart" first; kept while the app runs (Karar 1).
final comingViewProvider = NotifierProvider<ComingViewController, ComingView>(
  ComingViewController.new,
);

class ComingViewController extends Notifier<ComingView> {
  @override
  ComingView build() => ComingView.chart;

  // ignore: use_setters_to_change_properties
  void set(ComingView view) => state = view;
}

/// The first day of the week (1 Monday ... 7 Sunday) from the device's
/// region (intl's locale data); the app language's Material default only
/// when intl does not know the region.
int firstWeekdayOf(BuildContext context, String? region) {
  final device = View.of(context).platformDispatcher.locale;
  final fromRegion = firstWeekdayFor(device.languageCode, region);
  if (fromRegion != null) return fromRegion;
  // Material counts from Sunday = 0.
  final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return index == 0 ? DateTime.sunday : index;
}

/// Data the calendar needs; null while it loads.
final _calendarSourceProvider =
    Provider<
      ({
        List<PlanWithPayments> plans,
        List<RecurringWithMarks> recurring,
        PaySchedule schedule,
        LocalDate today,
      })?
    >((ref) {
      final settings = ref.watch(settingsProvider).value;
      final plans = ref.watch(plansProvider).value;
      final recurring = ref.watch(recurringProvider).value;
      if (settings == null || plans == null || recurring == null) return null;
      return (
        plans: plans,
        recurring: recurring,
        schedule: payScheduleOf(settings),
        today: ref.watch(todayProvider),
      );
    });

/// Month view of payments and paydays: one mark per day, a payday ring,
/// today framed. Tapping a day opens its payments below.
class PaymentCalendar extends ConsumerStatefulWidget {
  const PaymentCalendar({super.key, this.header});

  /// Scrolls with the calendar, above the month.
  final Widget? header;

  /// Height of a day cell; with the side padding a cell is at least 48
  /// wide on phones 352 dp and wider.
  static const double cellHeight = 56;

  /// Between day frames, and between a mark's dot and its icon.
  static const double hairGap = KalanSpace.xxs / 2;

  /// The box around a day's number (and its payday ring).
  static const double numberBox = 30;

  /// The row of marks under the number.
  static const double markRow = 12;

  /// Where a busy week's line runs: in the gap right under the number,
  /// clear of the today and selected frames.
  static const double busyLineTop =
      hairGap +
      (cellHeight - (numberBox + KalanSpace.xxs + markRow)) / 2 +
      numberBox +
      (KalanSpace.xxs - _BusyLine.thickness) / 2;

  @override
  ConsumerState<PaymentCalendar> createState() => _PaymentCalendarState();
}

class _PaymentCalendarState extends ConsumerState<PaymentCalendar> {
  /// The shown month; null means today's month (it follows the day turn).
  CalendarMonth? _month;
  LocalDate? _selected;

  void _show(CalendarMonth month) => setState(() {
    _month = month;
    _selected = null;
  });

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(_calendarSourceProvider);
    if (source == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = source.today;
    final current = CalendarMonth.of(today);
    final range = calendarRange(
      plans: source.plans,
      recurring: source.recurring,
      today: today,
    );
    var month = _month ?? current;
    if (month < range.first) month = range.first;
    if (month > range.last) month = range.last;
    final days = calendarMonth(
      plans: source.plans,
      recurring: source.recurring,
      schedule: source.schedule,
      month: month,
      today: today,
    );
    final busyWeeks = calendarBusyWeeks(
      plans: source.plans,
      schedule: source.schedule,
      month: month,
    );
    BusyWeek? busyOn(LocalDate d) {
      for (final w in busyWeeks) {
        if (w.contains(d)) return w;
      }
      return null;
    }

    final canBack = month > range.first;
    final canForward = month < range.last;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final selected = _selected;

    return ListView(
      key: const ValueKey('payment-calendar'),
      padding: const EdgeInsets.only(bottom: KalanSpace.xl),
      children: [
        ?widget.header,
        // Month name, then "Today" and the arrows, on one line.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            KalanSpace.md,
            0,
            KalanSpace.xxs,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    context.monthYear(month.year, month.month),
                    key: const ValueKey('calendar-month'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('calendar-today'),
                onPressed: month == current
                    ? null
                    : () => setState(() {
                        _month = null;
                        _selected = null;
                      }),
                child: Text(l10n.calendarToday),
              ),
              IconButton(
                key: const ValueKey('calendar-previous'),
                tooltip: l10n.calendarPreviousMonth,
                onPressed: canBack ? () => _show(month.add(-1)) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('calendar-next'),
                tooltip: l10n.calendarNextMonth,
                onPressed: canForward ? () => _show(month.add(1)) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        // Swipe between months; the direction follows the reading order.
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v.abs() < 200) return;
            final forward = rtl ? v > 0 : v < 0;
            if (forward && canForward) _show(month.add(1));
            if (!forward && canBack) _show(month.add(-1));
          },
          // Side room only while seven cells still get 48 each.
          child: LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    ((constraints.maxWidth - 7 * kMinInteractiveDimension) / 2)
                        .clamp(0, KalanSpace.xs),
              ),
              child: _MonthGrid(
                month: month,
                days: days,
                today: today,
                selected: selected,
                busyOn: busyOn,
                firstWeekday: firstWeekdayOf(
                  context,
                  ref.watch(deviceRegionProvider),
                ),
                onTap: (d) => setState(() => _selected = d),
              ),
            ),
          ),
        ),
        if (selected != null)
          _DaySection(
            key: ValueKey('calendar-day-${selected.epochDay}'),
            date: selected,
            day: days[selected],
            today: today,
            busyWeek: busyOn(selected),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.days,
    required this.today,
    required this.selected,
    required this.busyOn,
    required this.firstWeekday,
    required this.onTap,
  });

  final CalendarMonth month;
  final Map<LocalDate, CalendarDay> days;
  final LocalDate today;
  final LocalDate? selected;

  /// The busy week a day is in, if any.
  final BusyWeek? Function(LocalDate) busyOn;
  final int firstWeekday;
  final ValueChanged<LocalDate> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final grid = calendarGridDays(month, firstWeekday);
    final header = ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KalanSpace.xs),
                child: Text(
                  // "Pzt" / "Mon": the first week's days give the order.
                  context.shortWeekdayName(grid[i]),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
    return Column(
      children: [
        header,
        for (var w = 0; w < grid.length ~/ 7; w++)
          Row(
            children: [
              for (final d in grid.skip(w * 7).take(7))
                Expanded(
                  child: d.month == month.month
                      ? _DayCell(
                          date: d,
                          day: days[d],
                          isToday: d == today,
                          isSelected: d == selected,
                          busyWeek: busyOn(d),
                          onTap: () => onTap(d),
                        )
                      : _OtherMonthCell(date: d),
                ),
            ],
          ),
      ],
    );
  }
}

/// A neighbouring month's day: a muted number, nothing else.
class _OtherMonthCell extends StatelessWidget {
  const _OtherMonthCell({required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: PaymentCalendar.cellHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: KalanSpace.xs),
        child: Text(
          '${date.day}',
          textAlign: TextAlign.center,
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.3),
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: context.colors.textMuted),
        ),
      ),
    ),
  );
}

/// Screen reader label of a day: "14 November, 2 payments, 1 late,
/// payday, today".
String calendarDayLabel(
  AppLocalizations l10n,
  String date,
  CalendarDay? day, {
  required bool isToday,
  bool isBusyWeek = false,
}) {
  final count = day?.payments.length ?? 0;
  return [
    date,
    l10n.calendarCellPayments(count),
    if (day != null && day.lateCount > 0)
      day.lateCount == count
          ? l10n.calendarCellAllLate
          : l10n.calendarCellSomeLate(day.lateCount),
    if (day != null && day.paidCount > 0)
      day.paidCount == count
          ? l10n.calendarCellAllPaid
          : l10n.calendarCellSomePaid(day.paidCount),
    if (day?.isPayday ?? false) l10n.calendarCellPayday,
    if (isBusyWeek) l10n.calendarCellBusyWeek,
    if (isToday) l10n.calendarCellToday,
  ].join(', ');
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    this.busyWeek,
  });

  final LocalDate date;
  final CalendarDay? day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  /// The busy week this day is in: a thin ink line joins its days under
  /// the marks, and its first day carries the busy week icon.
  final BusyWeek? busyWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final payday = day?.isPayday ?? false;
    // Selected: a thin ink frame, as the chart's selected bar. Today: the
    // border color frame.
    final frame = isSelected
        ? Border.all(color: colors.text, width: 1.5)
        : isToday
        ? Border.all(color: colors.border, width: 1.5)
        : null;
    return Semantics(
      button: true,
      selected: isSelected,
      label: calendarDayLabel(
        context.l10n,
        context.dayMonth(date),
        day,
        isToday: isToday,
        isBusyWeek: busyWeek != null,
      ),
      // The tap is read out with the label (the InkWell's own is excluded).
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('calendar-cell-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(KalanRadius.input),
        child: Stack(
          children: [
            Container(
              height: PaymentCalendar.cellHeight,
              // Inside the InkWell: frames keep apart, the tap area stays whole.
              margin: const EdgeInsets.all(PaymentCalendar.hairGap),
              decoration: BoxDecoration(
                border: frame,
                borderRadius: BorderRadius.circular(KalanRadius.input),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    key: payday
                        ? ValueKey('calendar-payday-${date.day}')
                        : null,
                    width: PaymentCalendar.numberBox,
                    height: PaymentCalendar.numberBox,
                    alignment: Alignment.center,
                    decoration: payday
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.text, width: 1.5),
                          )
                        : null,
                    child: Text(
                      '${date.day}',
                      maxLines: 1,
                      // Large text grows the number only so far: the cell keeps
                      // its size and never overflows.
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.3),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.text,
                        fontFeatures: AmountText.tabular,
                      ),
                    ),
                  ),
                  const SizedBox(height: KalanSpace.xxs),
                  SizedBox(
                    height: PaymentCalendar.markRow,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CalendarMarkView(mark: day?.mark ?? CalendarMark.none),
                        if (busyWeek?.first == date) ...[
                          if (day?.mark != CalendarMark.none)
                            const SizedBox(width: PaymentCalendar.hairGap * 2),
                          Icon(
                            busyWeekIcon,
                            key: const ValueKey('calendar-busy-icon'),
                            size: 11,
                            color: colors.text,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (busyWeek case final w?)
              PositionedDirectional(
                start: 0,
                end: 0,
                top: PaymentCalendar.busyLineTop,
                height: _BusyLine.thickness,
                child: _BusyLine(
                  isFirst: w.first == date,
                  isLast: w.last == date,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A busy week's thin ink line in one cell: from the middle of its first
/// day to the middle of its last, so the days read as joined. Follows the
/// reading direction.
class _BusyLine extends StatelessWidget {
  const _BusyLine({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  static const double thickness = 1.5;

  @override
  Widget build(BuildContext context) {
    final ink = ColoredBox(color: context.colors.text);
    // A one-day "week": a short line under its marks.
    if (isFirst && isLast) {
      return Center(
        key: const ValueKey('calendar-busy-line'),
        child: SizedBox(width: KalanSpace.md, child: ink),
      );
    }
    return Row(
      key: const ValueKey('calendar-busy-line'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: isFirst ? const SizedBox.shrink() : ink),
        Expanded(child: isLast ? const SizedBox.shrink() : ink),
      ],
    );
  }
}

/// The one mark under a day's number; each has its own shape, so the
/// color never carries the meaning alone.
class CalendarMarkView extends StatelessWidget {
  const CalendarMarkView({required this.mark, super.key});

  final CalendarMark mark;

  static const double _dot = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (mark) {
      CalendarMark.none => const SizedBox.shrink(),
      // Pending: a filled ink dot.
      CalendarMark.pending => Center(
        key: const ValueKey('mark-pending'),
        child: _Dot(fill: colors.text),
      ),
      // Paid: a hollow dot with a small check, muted.
      CalendarMark.paid => Row(
        key: const ValueKey('mark-paid'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(outline: colors.textMuted),
          const SizedBox(width: PaymentCalendar.hairGap),
          Icon(Icons.check, size: 11, color: colors.textMuted),
        ],
      ),
      // Late: a late dot with a small clock.
      CalendarMark.late => Row(
        key: const ValueKey('mark-late'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(fill: colors.late),
          const SizedBox(width: PaymentCalendar.hairGap),
          Icon(Icons.schedule, size: 11, color: colors.late),
        ],
      ),
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.fill, this.outline});

  final Color? fill;
  final Color? outline;

  @override
  Widget build(BuildContext context) => Container(
    width: CalendarMarkView._dot,
    height: CalendarMarkView._dot,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill,
      border: outline == null ? null : Border.all(color: outline!, width: 1.5),
    ),
  );
}

/// The tapped day: its payments with the home screen's rows (and their
/// "paid"), the day's total, and "Payday" on a payday.
class _DaySection extends ConsumerWidget {
  const _DaySection({
    required this.date,
    required this.day,
    required this.today,
    super.key,
    this.busyWeek,
  });

  final LocalDate date;
  final CalendarDay? day;
  final LocalDate today;

  /// The busy week the day is in: its explanation shows in the section.
  final BusyWeek? busyWeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final payments = day?.payments ?? const <CalendarPayment>[];
    final muted = theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KalanSpace.md,
        KalanSpace.md,
        KalanSpace.md,
        0,
      ),
      child: Card(
        key: const ValueKey('calendar-day-section'),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KalanSpace.md,
                KalanSpace.sm,
                KalanSpace.md,
                KalanSpace.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.dayMonthWeekday(date),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (day?.isPayday ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: KalanSpace.xxs),
                      child: Text(
                        l10n.calendarPayday,
                        key: const ValueKey('calendar-day-payday'),
                        style: muted,
                      ),
                    ),
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: KalanSpace.xxs),
                      child: Text(
                        l10n.calendarNoPayments,
                        key: const ValueKey('calendar-day-empty'),
                        style: muted,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: KalanSpace.xxs),
                      child: context.spokenText(
                        l10n.calendarDayTotal(
                          ref.money(context, day!.totalMinor),
                        ),
                        key: const ValueKey('calendar-day-total'),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  if (busyWeek case final w?)
                    Padding(
                      padding: const EdgeInsets.only(top: KalanSpace.xs),
                      child: BusyWeekNote(week: w),
                    ),
                ],
              ),
            ),
            for (final p in payments) ...[
              const Divider(height: 1),
              // A late plan payment asks "when did you pay?" as on the home
              // screen; everything else is the home screen's one-tap row.
              if (p.status == CalendarStatus.late && !p.entry.isRecurring)
                PastDueRow(entry: p.entry, today: today)
              else
                PaymentTile(
                  key: ValueKey(
                    'calendar-row-${p.entry.paymentId}-${p.entry.recurringId}',
                  ),
                  entry: p.entry,
                  showDaysAgo: p.status == CalendarStatus.late,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
