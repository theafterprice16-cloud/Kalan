import '../date/local_date.dart';
import '../engine/period_summary.dart';
import '../money/money_format.dart' show amountMask;

/// The home screen widget (Roadmap 31) shows only what this file writes:
/// ready-made text in the app's language, one record per day for today
/// and the next [widgetDayCount] - 1 days. Native code (iOS WidgetKit,
/// Android RemoteViews) only picks the record of its own today and lays
/// the strings out; it never calculates or formats anything. Pure Dart
/// (no Flutter), so every rule here has a table test.

/// Today and the next 7 days.
const widgetDayCount = 8;

/// The version of the JSON below; native code shows the stale text for
/// any other value.
const widgetSnapshotVersion = 1;

/// At most this many upcoming payments on the medium widget.
const widgetMaxRows = 3;

/// The longest big number (in characters) the small widget shows in full;
/// a longer one (IDR, VND: 125.450.000 with the sign) shows in its short form there,
/// so it never overflows even at 60 % of its size. The medium widget,
/// twice as wide, always shows it in full.
const widgetSmallNumberMax = 11;

/// Whether the widget masks every amount (product owner's decision 1):
/// always while "Hide amounts" is on; while the app lock is on, unless
/// "Show amounts in widget" is on. Masked amounts are never formatted, so
/// they never reach the storage the widget reads.
bool widgetAmountsMasked({
  required bool hideAmounts,
  required bool appLock,
  required bool showInWidget,
}) => hideAmounts || (appLock && !showInWidget);

/// Whether the Lock Screen widget (Roadmap 32) shows what's left: only
/// with "Show what's left" on and every amount on the home screen widget
/// unmasked ("Hide amounts" off; with the app lock on, "Show amounts in
/// widget" on too). Otherwise the line is not there at all (not even
/// "•••") and what's left is never formatted for it. Payment amounts are
/// never on the Lock Screen.
bool lockScreenLeftShown({
  required bool showLeft,
  required bool hideAmounts,
  required bool appLock,
  required bool showInWidget,
}) =>
    showLeft &&
    !widgetAmountsMasked(
      hideAmounts: hideAmounts,
      appLock: appLock,
      showInWidget: showInWidget,
    );

/// The Lock Screen widget's choices as they stand (Roadmap 32).
class LockScreenOptions {
  const LockScreenOptions({this.pro = false, this.showLeft = false});

  /// Pro (decision 4): without it the Lock Screen widget shows only a calm
  /// Pro note, and no day text is written for it.
  final bool pro;

  /// [lockScreenLeftShown] (Pro aside).
  final bool showLeft;
}

/// What the Lock Screen widget counts on a day: unpaid payments, plan and
/// recurring together; nothing on hold or closed.
class LockDayCounts {
  const LockDayCounts({
    this.today = 0,
    this.pastDue = 0,
    this.nextDate,
    this.nextCount = 0,
  });

  /// Unpaid payments due on the day.
  final int today;

  /// Unpaid plan payments due before the day (as the home screen's "Past
  /// due" list: recurring payments are never past due).
  final int pastDue;

  /// The first day after it with unpaid payments, and how many.
  final LocalDate? nextDate;
  final int nextCount;

  static const none = LockDayCounts();
}

/// What the Lock Screen's circular widget shows in its middle.
enum LockCenter {
  /// A number of days ("2").
  number,

  /// A short word ("Today", "Past due").
  word,

  /// Nothing to count: the logo mark.
  logo,
}

/// What a day record shows.
enum WidgetState {
  /// Income entered, left is zero or more: "Left" and the number (accent).
  left,

  /// Income entered, spoken for exceeds it: "Left" and the negative
  /// number (negative token).
  negative,

  /// No income: "Payments this period" and their total (text token).
  noIncome,
}

/// What the whole widget shows, whatever the date.
enum WidgetMode {
  /// The day records.
  days,

  /// No plan and no recurring payment at all: "No payments yet."
  noPayments,

  /// Setup not finished: "Open Kalan to finish setup."
  setup,
}

/// One upcoming payment as the medium widget lists it.
class WidgetPayment {
  const WidgetPayment({
    required this.name,
    required this.date,
    required this.amountMinor,
  });

  final String name;
  final LocalDate date;

  /// As the home screen row shows it (installment plus its fee).
  final int amountMinor;
}

/// What the app knows about [date], as the home screen would show it on
/// that day if nothing changes until then.
class WidgetDayInput {
  const WidgetDayInput({
    required this.date,
    required this.summary,
    required this.upcoming,
    this.lock = LockDayCounts.none,
  });

  final LocalDate date;

  /// What the Lock Screen widget counts on [date] (Roadmap 32).
  final LockDayCounts lock;

  /// The pay period containing [date], seen on [date].
  final PeriodSummary summary;

  /// Unpaid payments due on [date] or later, soonest first; only the
  /// first [widgetMaxRows] are used.
  final List<WidgetPayment> upcoming;
}

/// Everything the widget needs, before text.
sealed class WidgetInput {
  const WidgetInput();
}

/// Setup is not finished (no settings yet).
class WidgetSetupInput extends WidgetInput {
  const WidgetSetupInput();
}

/// Set up, but nothing entered: no plan and no recurring payment.
class WidgetNoPaymentsInput extends WidgetInput {
  const WidgetNoPaymentsInput();
}

/// The usual case: one input per day, today first.
class WidgetDaysInput extends WidgetInput {
  const WidgetDaysInput(this.days);
  final List<WidgetDayInput> days;
}

/// The words and formats the widget needs, in the app's language; the
/// app implements it with its ARB texts, the single money path and intl.
abstract interface class WidgetTexts {
  /// "Left".
  String get leftTitle;

  /// "Payments this period".
  String get paymentsTitle;

  /// "Until Dec 14" for the period's last day.
  String until(LocalDate lastDay);

  /// "Dec 14".
  String shortDate(LocalDate date);

  /// An amount through the app's single money path. Never called while
  /// amounts are masked.
  String money(int minor);

  /// Its short form for narrow places (125,5 jt with the sign), the app's
  /// [formatMoneyShort]. Never called while amounts are masked.
  String moneyShort(int minor);

  /// What a screen reader says instead of a masked amount.
  String get amountHidden;

  String get noPayments;
  String get noUpcoming;
  String get setup;
  String get stale;

  /// "Left $1,250, until Dec 14."
  String spokenSummary({
    required String title,
    required String amount,
    required String date,
  });

  /// "Phone, Nov 22, $140."
  String spokenPayment({
    required String name,
    required String date,
    required String amount,
  });

  /// Whether the app's language reads right to left.
  bool get rightToLeft;

  // The Lock Screen widget (Roadmap 32). No payment amount in any of them.

  /// "Kalan", the app's name above the rectangular widget's line.
  String get lockTitle;

  /// "2 payments today".
  String lockToday(int count);

  /// "1 past due".
  String lockPastDue(int count);

  /// "1 payment tomorrow".
  String lockTomorrow(int count);

  /// "1 payment in 2 days" ([days] is 2 or more).
  String lockInDays({required int count, required int days});

  /// "No upcoming payments."
  String get lockNoUpcoming;

  /// The circular widget's middle: "Today", "Past due".
  String get lockTodayShort;
  String get lockPastDueShort;

  /// A number of days in the app language's digits.
  String number(int value);

  /// The circular widget's small line: "1 payment".
  String lockCount(int count);

  /// "Left $1,250" ([amount] already through the money path).
  String lockLeft(String amount);

  /// Without Pro: "With Kalan Pro" (inline) and the longer sentence.
  String get lockGateInline;
  String get lockGate;

  /// Stale or setup, inline: "Open Kalan".
  String get lockOpen;
}

/// One day's Lock Screen text (Roadmap 32); written only with Pro.
class LockDayText {
  const LockDayText({
    required this.line,
    required this.centerKind,
    required this.center,
    required this.count,
    required this.left,
  });

  /// The main line, for the inline and rectangular widgets.
  final String line;

  /// The circular widget: [center] in the middle ([LockCenter.logo]: the
  /// mark, [center] empty) and [count] below it (may be empty).
  final LockCenter centerKind;
  final String center;
  final String count;

  /// "Left $1,250" under the rectangular widget's line, or empty: then
  /// the line is not there at all.
  final String left;

  Map<String, Object> toJson() => {
    'line': line,
    'centerKind': centerKind.name,
    'center': center,
    'count': count,
    'left': left,
  };
}

/// The Lock Screen widget's day-independent text (Roadmap 32).
class LockText {
  const LockText({
    required this.pro,
    required this.title,
    required this.gateInline,
    required this.gate,
    required this.open,
    required this.stale,
    required this.message,
    required this.messageInline,
  });

  /// Without Pro only [gateInline] and [gate] (and the logo) show.
  final bool pro;

  /// "Kalan".
  final String title;
  final String gateInline;
  final String gate;

  /// Inline, when stale: "Open Kalan".
  final String open;

  /// Rectangular, when stale: "Open Kalan for the latest."
  final String stale;

  /// Setup and no payments: the only text, rectangular and inline; empty
  /// for the day records.
  final String message;
  final String messageInline;

  Map<String, Object> toJson() => {
    'pro': pro,
    'title': title,
    'gateInline': gateInline,
    'gate': gate,
    'open': open,
    'stale': stale,
    'message': message,
    'messageInline': messageInline,
  };
}

/// One payment row, as text.
class WidgetRowText {
  const WidgetRowText({
    required this.name,
    required this.date,
    required this.amount,
  });

  final String name;
  final String date;
  final String amount;

  Map<String, Object> toJson() => {
    'name': name,
    'date': date,
    'amount': amount,
  };
}

/// One day's record, as text.
class WidgetDayText {
  const WidgetDayText({
    required this.date,
    required this.state,
    required this.title,
    required this.number,
    required this.numberSmall,
    required this.until,
    required this.rows,
    required this.message,
    required this.spoken,
    this.lock,
  });

  final LocalDate date;
  final WidgetState state;

  /// The Lock Screen widget's text for the day; null without Pro.
  final LockDayText? lock;

  /// "Left" / "Payments this period".
  final String title;

  /// The big number, or [amountMask].
  final String number;

  /// The big number for the small size: [number], or its short form
  /// (12,5 jt with the rupiah sign) when [number] is longer than [widgetSmallNumberMax]
  /// characters, so it fits a small widget at 60 % of its size.
  final String numberSmall;

  /// "Until Dec 14".
  final String until;

  /// At most [widgetMaxRows] upcoming payments (medium size).
  final List<WidgetRowText> rows;

  /// Shown in place of the rows when there are none ("No upcoming
  /// payments."); empty otherwise.
  final String message;

  /// The whole record as one sentence or a few, for screen readers; a
  /// masked amount reads as "Amount hidden".
  final String spoken;

  Map<String, Object> toJson() => {
    'y': date.year,
    'm': date.month,
    'd': date.day,
    'state': state.name,
    'title': title,
    'number': number,
    'numberSmall': numberSmall,
    'until': until,
    'rows': [for (final r in rows) r.toJson()],
    'message': message,
    'spoken': spoken,
    if (lock case final lock?) 'lock': lock.toJson(),
  };
}

/// What the app writes to the storage it shares with the widget.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.mode,
    required this.message,
    required this.days,
    required this.stale,
    required this.rightToLeft,
    required this.lock,
  });

  final WidgetMode mode;

  /// The Lock Screen widget's day-independent text (Roadmap 32).
  final LockText lock;

  /// For [WidgetMode.setup] and [WidgetMode.noPayments]: the only text,
  /// on any date (never stale). Empty for [WidgetMode.days].
  final String message;

  /// Today first; empty unless [mode] is [WidgetMode.days].
  final List<WidgetDayText> days;

  /// Shown when the phone's today is after the last record (the app has
  /// not been opened for over a week): no amount.
  final String stale;

  /// Mirror the layout (Arabic).
  final bool rightToLeft;

  Map<String, Object> toJson() => {
    'v': widgetSnapshotVersion,
    'mode': mode.name,
    'message': message,
    'rtl': rightToLeft,
    'stale': stale,
    'days': [for (final d in days) d.toJson()],
    'lock': lock.toJson(),
  };
}

/// Turns [input] into the widget's text. With [masked] no amount is
/// formatted at all: every amount is [amountMask], and the screen reader
/// text says [WidgetTexts.amountHidden]; the real amounts never reach the
/// snapshot.
///
/// The Lock Screen widget (Roadmap 32) gets its own text from [lock]:
/// without Pro only the Pro note; with Pro each day's line, and what's
/// left only when [LockScreenOptions.showLeft] and nothing is [masked].
WidgetSnapshot buildWidgetSnapshot({
  required WidgetInput input,
  required bool masked,
  required WidgetTexts texts,
  LockScreenOptions lock = const LockScreenOptions(),
}) {
  final (mode, message) = switch (input) {
    WidgetSetupInput() => (WidgetMode.setup, texts.setup),
    WidgetNoPaymentsInput() => (WidgetMode.noPayments, texts.noPayments),
    WidgetDaysInput() => (WidgetMode.days, ''),
  };
  final showLeft = lock.pro && lock.showLeft && !masked;
  return WidgetSnapshot(
    mode: mode,
    message: message,
    days: [
      if (input case WidgetDaysInput(:final days))
        for (final day in days.take(widgetDayCount))
          _day(
            day,
            masked: masked,
            texts: texts,
            lock: lock.pro
                ? _lockDay(day, showLeft: showLeft, texts: texts)
                : null,
          ),
    ],
    stale: texts.stale,
    rightToLeft: texts.rightToLeft,
    lock: LockText(
      pro: lock.pro,
      title: texts.lockTitle,
      gateInline: texts.lockGateInline,
      gate: texts.lockGate,
      open: texts.lockOpen,
      stale: texts.stale,
      message: switch (mode) {
        WidgetMode.setup => texts.setup,
        WidgetMode.noPayments => texts.lockNoUpcoming,
        WidgetMode.days => '',
      },
      messageInline: switch (mode) {
        WidgetMode.setup => texts.lockOpen,
        WidgetMode.noPayments => texts.lockNoUpcoming,
        WidgetMode.days => '',
      },
    ),
  );
}

/// The Lock Screen's priority (decision 4): today's unpaid payments, then
/// past-due ones, then the next day with payments, else none.
LockDayText _lockDay(
  WidgetDayInput day, {
  required bool showLeft,
  required WidgetTexts texts,
}) {
  final c = day.lock;
  final summary = day.summary;
  // What's left only with income (a period without it has no "left"),
  // formatted only when it is shown.
  final left = showLeft && summary.status != PeriodStatus.noIncome
      ? summary.leftMinor
      : null;
  // A very long amount takes the short form, as on the small widget: the
  // Lock Screen line never shrinks or cuts.
  final leftAmount = left == null ? null : texts.money(left);
  final leftText = leftAmount == null
      ? ''
      : texts.lockLeft(
          leftAmount.runes.length <= widgetSmallNumberMax
              ? leftAmount
              : texts.moneyShort(left!),
        );
  final nextDate = c.nextDate;
  final days = nextDate == null ? 0 : day.date.daysUntil(nextDate);
  final (line, kind, center, count) = c.today > 0
      ? (
          texts.lockToday(c.today),
          LockCenter.word,
          texts.lockTodayShort,
          texts.lockCount(c.today),
        )
      : c.pastDue > 0
      ? (
          texts.lockPastDue(c.pastDue),
          LockCenter.word,
          texts.lockPastDueShort,
          texts.lockCount(c.pastDue),
        )
      : c.nextCount > 0 && days > 0
      ? (
          days == 1
              ? texts.lockTomorrow(c.nextCount)
              : texts.lockInDays(count: c.nextCount, days: days),
          LockCenter.number,
          texts.number(days),
          texts.lockCount(c.nextCount),
        )
      : (texts.lockNoUpcoming, LockCenter.logo, '', '');
  return LockDayText(
    line: line,
    centerKind: kind,
    center: center,
    count: count,
    left: leftText,
  );
}

WidgetDayText _day(
  WidgetDayInput day, {
  required bool masked,
  required WidgetTexts texts,
  LockDayText? lock,
}) {
  final summary = day.summary;
  final left = summary.leftMinor;
  final state = switch (summary.status) {
    PeriodStatus.noIncome => WidgetState.noIncome,
    PeriodStatus.negative => WidgetState.negative,
    PeriodStatus.comfortable || PeriodStatus.tight => WidgetState.left,
  };
  final title = state == WidgetState.noIncome
      ? texts.paymentsTitle
      : texts.leftTitle;
  String amount(int minor) => masked ? amountMask : texts.money(minor);
  String spokenAmount(int minor) =>
      masked ? texts.amountHidden : texts.money(minor);
  final shown = left ?? summary.spokenForMinor;
  final lastDay = summary.period.lastDay;

  final rows = [
    for (final p in day.upcoming.take(widgetMaxRows))
      (
        text: WidgetRowText(
          name: p.name,
          date: texts.shortDate(p.date),
          amount: amount(p.amountMinor),
        ),
        spoken: texts.spokenPayment(
          name: p.name,
          date: texts.shortDate(p.date),
          amount: spokenAmount(p.amountMinor),
        ),
      ),
  ];
  final number = amount(shown);
  return WidgetDayText(
    date: day.date,
    state: state,
    title: title,
    number: number,
    numberSmall: masked || number.runes.length <= widgetSmallNumberMax
        ? number
        : texts.moneyShort(shown),
    until: texts.until(lastDay),
    rows: [for (final r in rows) r.text],
    message: rows.isEmpty ? texts.noUpcoming : '',
    spoken: [
      texts.spokenSummary(
        title: title,
        amount: spokenAmount(shown),
        date: texts.shortDate(lastDay),
      ),
      if (rows.isEmpty) texts.noUpcoming,
      for (final r in rows) r.spoken,
    ].join(' '),
    lock: lock,
  );
}
