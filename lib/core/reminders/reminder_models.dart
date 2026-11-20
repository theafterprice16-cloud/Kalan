import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

import '../date/local_date.dart';
import '../engine/extra_fee.dart';
import '../engine/payment_method.dart';
import '../engine/schedule.dart' show CardTerms;

export '../engine/payment_method.dart' show PaymentMethod;

/// The two notifications every payment gets.
enum ReminderKind {
  /// Some days before the due date ("lead days").
  ahead,

  /// On the due date itself.
  onDay,

  /// After the due date, unpaid: repeat reminders only.
  overdue,
}

/// Repeat reminders ("Israrlı hatırlatma"): how often an unpaid payment
/// is reminded again. Only ever at the reminder time and at 20:00.
enum ReminderRepeat {
  /// Only the "ahead" and "on day" reminders (the default).
  off,

  /// The days with a reminder also get one at 20:00.
  evening,

  /// From the "ahead" day until paid, at most 7 days past the due date:
  /// at the reminder time and at 20:00 every day.
  daily,
}

/// How long repeats go on after the due date.
const repeatDaysAfterDue = 7;

/// "How many days before" choices offered in Settings and per plan.
const leadDayChoices = [1, 2, 3, 5, 7];

/// The initial global "days before". Some providers take the money a day
/// early, so two days leaves room.
const initialLeadDays = 2;

/// A plan's (or recurring payment's) own reminder choice.
class ReminderChoice {
  /// Its own "days before"; the time still comes from the global setting.
  factory ReminderChoice.days(int leadDays) {
    assert(leadDayChoices.contains(leadDays), 'unsupported: $leadDays');
    return ReminderChoice._(off: false, leadDays: leadDays);
  }

  const ReminderChoice._({required this.off, this.leadDays});

  /// Follows the global setting (the default).
  static const general = ReminderChoice._(off: false);

  /// No reminders at all for this plan.
  static const disabled = ReminderChoice._(off: true);

  final bool off;

  /// Null when the global setting applies.
  final int? leadDays;

  bool get isGeneral => !off && leadDays == null;

  @override
  bool operator ==(Object other) =>
      other is ReminderChoice && other.off == off && other.leadDays == leadDays;

  @override
  int get hashCode => Object.hash(off, leadDays);

  @override
  String toString() => off
      ? 'ReminderChoice.disabled'
      : leadDays == null
      ? 'ReminderChoice.general'
      : 'ReminderChoice.days($leadDays)';
}

/// A payment as the planner sees it. [date] is the effective due date the
/// calculation engine stored (statement, due day and weekend shift already
/// applied), the same day the screens show. The planner never computes
/// payment dates.
class ReminderPayment {
  const ReminderPayment({
    required this.name,
    required this.date,
    required this.amountMinor,
    this.isPaid = false,
    this.choice = ReminderChoice.general,
    this.ref,
    this.repeat,
    this.method,
    this.account,
    this.extraFeeMinor,
    this.installmentFeeMinor,
  });

  final String name;
  final LocalDate date;

  /// The payment's own amount, its fees left out.
  final int amountMinor;

  /// The fee per payment (22) this payment took; null when none.
  final int? installmentFeeMinor;

  /// The payment's extra fee (21), typed by the user; null when none.
  final int? extraFeeMinor;

  /// What the reminder says is due: the amount plus the fee per payment
  /// (22) plus the extra fee (21). The one rule for every reminder total;
  /// without fees, exactly the amount, as before.
  int get dueMinor => spokenForAmount(
    amountMinor: amountMinor,
    installmentFeeMinor: installmentFeeMinor,
    extraFeeMinor: extraFeeMinor,
  );

  final bool isPaid;
  final ReminderChoice choice;

  /// Which stored payment this is, so a notification action can mark it.
  /// Without one the reminder carries no actions.
  final PaymentRef? ref;

  /// The plan's own repeat mode; null follows the global setting.
  final ReminderRepeat? repeat;

  /// How the plan is paid; null is "not set" (recurring payments too):
  /// the reminders are exactly as before payment methods existed.
  final PaymentMethod? method;

  /// The bank account an automatic payment is taken from (18); null for
  /// cards, providers, no source, other methods and recurring payments.
  final ChargeAccount? account;
}

/// A bank account by id (two accounts may share a name) and name.
class ChargeAccount {
  const ChargeAccount(this.id, this.name);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ChargeAccount && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// A stored payment a notification points at: a plan payment by id, or a
/// recurring payment's occurrence on a day. Written into the
/// notification's payload as a short key ("p12", "r3.20406").
sealed class PaymentRef {
  const PaymentRef();

  /// Null for anything that is not a key [key] produced.
  static PaymentRef? parse(String key) {
    if (key.startsWith('p')) {
      final id = int.tryParse(key.substring(1));
      return id == null || id < 0 ? null : PlanPaymentRef(id);
    }
    if (key.startsWith('r')) {
      final parts = key.substring(1).split('.');
      if (parts.length != 2) return null;
      final id = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (id == null || day == null || id < 0) return null;
      return RecurringRef(id, LocalDate.fromEpochDay(day));
    }
    return null;
  }

  String get key;

  @override
  bool operator ==(Object other) => other is PaymentRef && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

final class PlanPaymentRef extends PaymentRef {
  const PlanPaymentRef(this.paymentId);

  final int paymentId;

  @override
  String get key => 'p$paymentId';
}

final class RecurringRef extends PaymentRef {
  const RecurringRef(this.recurringId, this.date);

  final int recurringId;
  final LocalDate date;

  @override
  String get key => 'r$recurringId.${date.epochDay}';
}

/// The user's global reminder settings.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.leadDays = initialLeadDays,
    this.minuteOfDay = 9 * 60,
    this.showAmounts = true,
    this.repeatMode = ReminderRepeat.off,
    this.paydaySummary = true,
  });

  /// Master switch; off cancels every pending reminder.
  final bool enabled;

  /// Global "days before" (one of [leadDayChoices]).
  final int leadDays;

  /// Local wall-clock time, minutes after midnight (09:00 = 540).
  final int minuteOfDay;

  /// Amounts in notification text (off for lock-screen privacy).
  final bool showAmounts;

  /// Global repeat mode; plans can choose their own.
  final ReminderRepeat repeatMode;

  /// The payday summary notification ([PaydaySummary]); the master switch
  /// [enabled] turns it off too.
  final bool paydaySummary;

  /// A 20:00 reminder only when the reminder time is 18:00 or earlier
  /// (as "Remind tonight"): never two reminders close together, never at
  /// night.
  bool get eveningAllowed => minuteOfDay <= latestMinuteForRemindTonight;
}

/// The repeat mode that actually runs for [payment]: its own or the
/// global one; none when its reminders are off; "once more in the
/// evening" does nothing when the reminder time is after 18:00.
ReminderRepeat repeatModeFor(
  ReminderPayment payment,
  ReminderSettings settings,
) {
  if (payment.choice.off) return ReminderRepeat.off;
  final mode = payment.repeat ?? settings.repeatMode;
  if (mode == ReminderRepeat.evening && !settings.eveningAllowed) {
    return ReminderRepeat.off;
  }
  return mode;
}

/// "Days before" for a plan paid by [method] that follows the global
/// setting. The one place that decides it (screens show it too):
///
/// - automatic and not set: the global setting;
/// - manual: one day earlier, to leave time to go and pay.
///
/// A plan's own choice (off, a different day) always wins ([leadDaysFor]).
int defaultLeadDaysFor(PaymentMethod? method, ReminderSettings settings) =>
    switch (method) {
      PaymentMethod.manual => settings.leadDays + 1,
      PaymentMethod.automatic || null => settings.leadDays,
    };

/// "Days before" that applies to [payment].
int leadDaysFor(ReminderPayment payment, ReminderSettings settings) {
  final days =
      payment.choice.leadDays ?? defaultLeadDaysFor(payment.method, settings);
  // Never on the due day itself: that is the on-day reminder.
  return days < 1 ? 1 : days;
}

/// Notification text in the app language. Implemented next to the
/// localizations; the planner stays pure Dart.
abstract interface class ReminderTexts {
  /// The notification title (the app name).
  String get title;

  /// The short button name of [action] ("Paid", "Remind tonight").
  String actionTitle(ReminderAction action);

  /// Text for [payments] due on [dueDates] (one date unless an "ahead"
  /// notification gathers payments with different lead days).
  ///
  /// With a [method] ([reminderMethodOf]) the text says what that method
  /// needs: the money in the account, or going to pay. Null: the text as
  /// before payment methods existed. With an [account] ([reminderAccountOf])
  /// the automatic note names it and the total ("Keep {amount} in ..."),
  /// only while amounts are shown.
  ReminderText describe({
    required ReminderKind kind,
    required List<ReminderPayment> payments,
    required List<LocalDate> dueDates,
    required bool showAmounts,
    PaymentMethod? method,
    String? account,
  });

  /// Text of the payday summary. Without [showAmounts] only the number of
  /// payments.
  ReminderText payday(PaydaySummary summary, {required bool showAmounts});

  /// Text of a statement closing reminder: [card]'s statement is cut in
  /// [days] days, on [date]; what comes after goes on the [next]
  /// statement. Information only: no amount, no limit, no button.
  String statementClosing({
    required String card,
    required int days,
    required LocalDate date,
    required LocalDate next,
  });
}

/// "How many days before" choices of the statement closing reminder.
const statementLeadDayChoices = [1, 2];

/// The statement closing reminder's initial "days before".
const initialStatementLeadDays = 2;

/// How many coming statements of a card get a closing reminder (a year);
/// the 60 limit keeps only the soonest that fit anyway.
const statementClosingHorizon = 12;

/// A card whose statement closing reminder is on ("Hesap kesim
/// hatırlatması"), as the planner sees it.
class StatementCard {
  const StatementCard({
    required this.id,
    required this.name,
    required this.terms,
    this.leadDays = initialStatementLeadDays,
  });

  /// The card's source id: the notification opens its statements.
  final int id;
  final String name;

  /// The card's days; its statement dates come from the engine
  /// ([CardTerms.statementFor], [CardTerms.statementInMonth]).
  final CardTerms terms;

  /// 1 or 2 ([statementLeadDayChoices]); anything else counts as 2.
  final int leadDays;
}

/// What a tapped statement closing reminder opens: card [cardId]'s
/// statements.
String cardStatementPayload(int cardId) => 'card:$cardId';

/// The card a [cardStatementPayload] points at; null for anything else
/// (payment reminders, the payday summary, a damaged payload).
int? cardIdOfPayload(String? payload) {
  if (payload == null || !payload.startsWith('card:')) return null;
  final id = int.tryParse(payload.substring(5));
  return id == null || id < 0 ? null : id;
}

/// The payment method a notification's text speaks for: the one every
/// payment in it shares, only for "ahead" and "on day". Null (the text as
/// before) when they differ, when one is not set, and for overdue ones.
PaymentMethod? reminderMethodOf(
  ReminderKind kind,
  List<ReminderPayment> payments,
) {
  if (kind == ReminderKind.overdue || payments.isEmpty) return null;
  final method = payments.first.method;
  return payments.every((p) => p.method == method) ? method : null;
}

/// The bank account a notification's "keep the amount there" sentence
/// names (18): only for an "ahead" reminder with amounts shown, one due
/// date, and every payment taken automatically from that same account.
/// Null otherwise: the text stays as before. Never a new notification.
ChargeAccount? reminderAccountOf(
  ReminderKind kind,
  List<ReminderPayment> payments, {
  required bool showAmounts,
}) {
  if (kind != ReminderKind.ahead || !showAmounts || payments.isEmpty) {
    return null;
  }
  final account = payments.first.account;
  final date = payments.first.date;
  if (account == null) return null;
  final same = payments.every(
    (p) =>
        p.account == account &&
        p.date == date &&
        p.method == PaymentMethod.automatic,
  );
  return same ? account : null;
}

/// What the home screen will show for the pay period starting on [date],
/// worked out by the same calculation, as seen that morning. Only known
/// payments; [leftMinor] is null without an income.
class PaydaySummary {
  const PaydaySummary({
    required this.date,
    required this.paymentCount,
    required this.totalMinor,
    this.leftMinor,
  });

  /// The first day of the period (the payday, never moved).
  final LocalDate date;
  final int paymentCount;
  final int totalMinor;

  /// Income minus [totalMinor]; negative when the period is short.
  final int? leftMinor;

  @override
  bool operator ==(Object other) =>
      other is PaydaySummary &&
      other.date == date &&
      other.paymentCount == paymentCount &&
      other.totalMinor == totalMinor &&
      other.leftMinor == leftMinor;

  @override
  int get hashCode => Object.hash(date, paymentCount, totalMinor, leftMinor);

  @override
  String toString() =>
      'PaydaySummary($date, $paymentCount, $totalMinor, $leftMinor)';
}

/// The short body and the expanded body (body plus the names).
class ReminderText {
  const ReminderText({required this.body, required this.expanded});

  final String body;
  final String expanded;
}

/// What a tapped reminder opens: the home screen.
const reminderPayload = 'home';

/// Buttons on a reminder. At most two per notification.
enum ReminderAction {
  /// Marks the one payment in the notification as paid.
  paid,

  /// Marks every payment in a merged notification as paid.
  allPaid,

  /// "On the day" only: the same notification again at 20:00.
  remindTonight,

  /// "Ahead" only: the same notification again the next day, same time.
  remindTomorrow;

  bool get marksPaid => this == paid || this == allPaid;
}

/// "Remind tonight" fires at 20:00 ...
const remindTonightMinute = 20 * 60;

/// ... and is offered only when the reminder time is 18:00 or earlier.
const latestMinuteForRemindTonight = 18 * 60;

/// A button with its name in the app language.
class ReminderButton {
  const ReminderButton(this.action, this.title);

  final ReminderAction action;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is ReminderButton && other.action == action && other.title == title;

  @override
  int get hashCode => Object.hash(action, title);

  @override
  String toString() => 'ReminderButton($action, $title)';
}

/// A "remind me later" the user chose from a notification, stored so a
/// full reschedule keeps it. It fires once, with the text of the
/// notification it came from ([kind]) and only a "paid" button.
///
/// With [skipsDay] it is the "Remind tomorrow" of a payment with repeat
/// reminders: the repeats on the day before [fireDate] are skipped and
/// the payment is reminded at [fireDate], [minuteOfDay] (the reminder
/// time) if nothing else reminds it then. Repeats go on as usual after.
class ReminderSnooze {
  const ReminderSnooze({
    required this.id,
    required this.kind,
    required this.fireDate,
    required this.minuteOfDay,
    required this.refs,
    this.skipsDay = false,
  });

  final int id;

  /// The kind of the notification it was snoozed from (its text).
  final ReminderKind kind;
  final LocalDate fireDate;
  final int minuteOfDay;
  final List<PaymentRef> refs;
  final bool skipsDay;
}

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.fireDate,
    required this.fireAt,
    required this.payments,
    required this.dueDates,
    required this.title,
    required this.body,
    required this.expandedBody,
    this.payload = reminderPayload,
    this.buttons = const [],
    this.data,
    this.isPaydaySummary = false,
    this.isStatementClosing = false,
  });

  /// Stable per fire day and kind, so rescheduling replaces a reminder
  /// instead of adding a second one.
  final int id;
  final ReminderKind kind;
  final LocalDate fireDate;

  /// The real moment: [fireDate] at the chosen local time.
  final tz.TZDateTime fireAt;
  final List<ReminderPayment> payments;

  /// Distinct due dates of [payments], earliest first.
  final List<LocalDate> dueDates;
  final String title;
  final String body;
  final String expandedBody;

  /// What a tap opens (always the home screen).
  final String payload;

  /// Its buttons, at most two; empty when a payment has no [PaymentRef].
  final List<ReminderButton> buttons;

  /// What the buttons act on; written into the notification's payload.
  /// Null when there are no buttons.
  final ReminderPayload? data;

  bool get isSnoozed => data?.snoozed ?? false;

  /// The payday summary ([paydayReminder]): no payments, no buttons, its
  /// own id; [kind] is "on day" (its day is the payday). Never merged
  /// with payment reminders.
  final bool isPaydaySummary;

  /// A statement closing reminder ([statementClosingReminders]): no
  /// payments, no buttons, its own id; [payload] opens the card's
  /// statements. Never merged with any other reminder.
  final bool isStatementClosing;

  /// What the reminder's payments come to, extra fees included (21).
  int get totalMinor => payments.fold(0, (sum, p) => sum + p.dueMinor);

  /// "Ahead" and "on day" at the reminder time: fire day × 2 + kind,
  /// unchanged since the first reminders.
  static int idFor(LocalDate fireDate, ReminderKind kind) {
    assert(kind != ReminderKind.overdue, 'use idForRepeat');
    return fireDate.epochDay * 2 + kind.index;
  }

  /// Repeat reminders that are not an [idFor] slot: the 20:00 ones of any
  /// kind and the "overdue" ones at the reminder time. 2^29 + fire day ×
  /// 4 + slot, between [idFor] ids and snoozed ones.
  static int idForRepeat(
    LocalDate fireDate,
    ReminderKind kind, {
    required bool evening,
  }) => repeatIdBase + fireDate.epochDay * 4 + (evening ? kind.index : 3);

  static const repeatIdBase = 1 << 29;

  /// Snoozed reminders: far from [idFor] (fire day × 2 + kind, about
  /// 40,000 today) and from the debug test notification.
  static int idForSnooze(int snoozeId) => snoozeIdBase + snoozeId;

  static const snoozeIdBase = 1 << 30;

  /// The payday summary: 3 × 2^28 + its day, between repeat ids (2^29 +
  /// day × 4 + slot) and snoozed ones (2^30 + snooze id).
  static int idForPayday(LocalDate date) => paydayIdBase + date.epochDay;

  static const paydayIdBase = 3 << 28;

  /// A statement closing reminder: 2^28 + card × 1024 + fire day mod
  /// 1024, below repeat ids (2^29 + ...). Unique per card and fire day
  /// within 1024 days (statements are scheduled a year ahead at most) and
  /// for the first 2^18 cards.
  static int idForStatementClosing(int cardId, LocalDate fireDate) =>
      statementIdBase + (cardId % (1 << 18)) * 1024 + fireDate.epochDay % 1024;

  static const statementIdBase = 1 << 28;
}

/// What a notification's buttons act on, carried in its payload: the
/// notification's kind, whether it is a snoozed one, when it fired and
/// the payments in it. Decoding never throws: anything unreadable (an old
/// "home" payload, a damaged string) is null and the action does nothing.
class ReminderPayload {
  const ReminderPayload({
    required this.kind,
    required this.fireDate,
    required this.minuteOfDay,
    required this.refs,
    this.snoozed = false,
    this.repeating = false,
  });

  /// The text's kind; for a snoozed reminder, the kind it came from.
  final ReminderKind kind;
  final bool snoozed;

  /// A payment in it has repeat reminders: "Remind tomorrow" then skips
  /// the rest of today instead of adding a reminder.
  final bool repeating;
  final LocalDate fireDate;
  final int minuteOfDay;
  final List<PaymentRef> refs;

  static const _version = 1;

  String encode() => jsonEncode({
    'v': _version,
    't': snoozed ? 'snoozed' : kind.name,
    'k': kind.name,
    'd': fireDate.epochDay,
    'm': minuteOfDay,
    'r': [for (final r in refs) r.key],
    if (repeating) 'x': true,
  });

  static ReminderPayload? decode(String? raw) {
    if (raw == null || !raw.startsWith('{')) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?> || map['v'] != _version) return null;
      final type = map['t'];
      final kind = ReminderKind.values.asNameMap()[map['k']];
      final day = map['d'];
      final minute = map['m'];
      final keys = map['r'];
      final repeating = map['x'] ?? false;
      if (kind == null ||
          repeating is! bool ||
          type is! String ||
          day is! int ||
          minute is! int ||
          minute < 0 ||
          minute >= 24 * 60 ||
          keys is! List) {
        return null;
      }
      final snoozed = type == 'snoozed';
      if (!snoozed && type != kind.name) return null;
      final refs = <PaymentRef>[];
      for (final key in keys) {
        final ref = key is String ? PaymentRef.parse(key) : null;
        if (ref == null) return null;
        refs.add(ref);
      }
      if (refs.isEmpty) return null;
      return ReminderPayload(
        kind: kind,
        snoozed: snoozed,
        fireDate: LocalDate.fromEpochDay(day),
        minuteOfDay: minute,
        refs: List.unmodifiable(refs),
        repeating: repeating,
      );
    } on FormatException {
      return null;
    }
  }
}
