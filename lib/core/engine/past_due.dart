import '../date/local_date.dart';

/// A payment is past due when its effective due date (the stored date,
/// card statement and weekend shift already applied) is before [today]
/// and it is not paid. On the due date itself it is not past due yet.
/// Payments paid before the plan was added to Kalan are paid, so never.
bool isPastDue({
  required LocalDate dueDate,
  required bool isPaid,
  required LocalDate today,
}) => !isPaid && dueDate < today;

/// Calendar days from [dueDate] to [today] ("4 days ago").
int daysPastDue({required LocalDate dueDate, required LocalDate today}) =>
    dueDate.daysUntil(today);

/// The day whose pay period a payment's amount counts in. The one rule
/// for every period total:
///
/// - unpaid and past due: today, so it counts in the current period
///   however old it is (that money still has to come out of this pay);
/// - paid with [paidOn] after the due date (marked "paid today" from the
///   past-due list): the day it was paid;
/// - everything else: the due date, as before.
///
/// [paidOn] is only set by the past-due flow; payments marked paid
/// elsewhere keep counting on their due date.
LocalDate countingDate({
  required LocalDate dueDate,
  required bool isPaid,
  required LocalDate today,
  LocalDate? paidOn,
}) {
  if (isPastDue(dueDate: dueDate, isPaid: isPaid, today: today)) return today;
  if (isPaid && paidOn != null && paidOn > dueDate) return paidOn;
  return dueDate;
}
