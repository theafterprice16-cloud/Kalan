import '../date/local_date.dart';

/// When a reminder fires relative to the payment's due date.
enum ReminderOffset {
  days7(7),
  days3(3),
  days1(1),
  sameDay(0);

  const ReminderOffset(this.days);

  /// Days before the due date.
  final int days;
}

/// Which stored payment a reminder points at. Encoded into notification
/// payloads, so the format must stay stable.
sealed class PaymentRef {
  const PaymentRef();

  /// "p:12" for a plan payment, "r:3:20405" for a recurring occurrence.
  String encode();

  static PaymentRef? decode(String? text) {
    if (text == null) return null;
    final parts = text.split(':');
    switch (parts) {
      case ['p', final id]:
        final paymentId = int.tryParse(id);
        return paymentId == null ? null : PlanPaymentRef(paymentId);
      case ['r', final id, final day]:
        final recurringId = int.tryParse(id);
        final epochDay = int.tryParse(day);
        return recurringId == null || epochDay == null
            ? null
            : RecurringRef(recurringId, epochDay);
      default:
        return null;
    }
  }
}

class PlanPaymentRef extends PaymentRef {
  const PlanPaymentRef(this.paymentId);
  final int paymentId;

  @override
  String encode() => 'p:$paymentId';

  @override
  bool operator ==(Object other) =>
      other is PlanPaymentRef && other.paymentId == paymentId;

  @override
  int get hashCode => paymentId.hashCode;
}

class RecurringRef extends PaymentRef {
  const RecurringRef(this.recurringId, this.epochDay);
  final int recurringId;
  final int epochDay;

  @override
  String encode() => 'r:$recurringId:$epochDay';

  @override
  bool operator ==(Object other) =>
      other is RecurringRef &&
      other.recurringId == recurringId &&
      other.epochDay == epochDay;

  @override
  int get hashCode => Object.hash(recurringId, epochDay);
}

/// A payment as the reminder planner sees it. The date is the real due
/// date from the calculation engine (statement, due day and weekend shift
/// already applied); the planner never computes dates of its own.
class ReminderPayment {
  const ReminderPayment({
    required this.ref,
    required this.name,
    required this.date,
    required this.amountMinor,
    this.seq,
    this.count,
    this.isPaid = false,
    this.remindersEnabled = true,
  });

  final PaymentRef ref;
  final String name;
  final LocalDate date;
  final int amountMinor;

  /// Progress ("3/4") for plan payments; null for recurring payments.
  final int? seq;
  final int? count;
  final bool isPaid;

  /// The plan's or recurring payment's own switch.
  final bool remindersEnabled;
}

/// The user's reminder settings.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.offsets = defaultOffsets,
    this.minuteOfDay = 9 * 60,
    this.hideAmounts = false,
  });

  static const defaultOffsets = {ReminderOffset.days3, ReminderOffset.sameDay};

  final bool enabled;
  final Set<ReminderOffset> offsets;

  /// Local wall-clock time, minutes after midnight (09:00 = 540).
  final int minuteOfDay;

  /// Hide amounts in notification text.
  final bool hideAmounts;
}

/// One notification to schedule: everything due on [dueDate], announced
/// [offset] days earlier at [minuteOfDay] local time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.fireDate,
    required this.minuteOfDay,
    required this.offset,
    required this.dueDate,
    required this.payments,
  });

  /// Stable per due date and offset: the same reminder is never scheduled
  /// twice, and rescheduling replaces it.
  final int id;
  final LocalDate fireDate;
  final int minuteOfDay;
  final ReminderOffset offset;
  final LocalDate dueDate;
  final List<ReminderPayment> payments;

  int get totalMinor => payments.fold(0, (sum, p) => sum + p.amountMinor);

  bool get isSummary => payments.length > 1;

  /// "Paid" action: only on the due day, and only for a single payment.
  PaymentRef? get paidAction =>
      offset == ReminderOffset.sameDay && payments.length == 1
      ? payments.single.ref
      : null;

  /// Deep link opened when the notification is tapped.
  String get route => '/day/$dueDate';

  static int idFor(LocalDate dueDate, ReminderOffset offset) =>
      dueDate.epochDay * ReminderOffset.values.length + offset.index;
}
