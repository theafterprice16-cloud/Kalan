/// The exported spreadsheet (Roadmap 29): one file, one row per payment
/// (plan payments and the recorded, paid occurrences of recurring
/// payments). Headers and words are in the app language; every value is
/// written the same in every language, so any spreadsheet program reads
/// it: days as yyyy-MM-dd, amounts with a dot and the currency's own
/// digits, true/false, the currency as "COL$ · COP".
///
/// RFC 4180: UTF-8 with a byte order mark (so spreadsheet programs read
/// non-ASCII letters right), comma separated, CRLF line ends, a field
/// quoted when it holds a comma, a quote or a line break. A text cell
/// that starts with =, +, -, @, a tab or a carriage return gets a leading
/// apostrophe, so a spreadsheet never runs it as a formula.
///
/// Pure Dart; the texts come through [CsvTexts].
library;

import '../date/local_date.dart';
import '../engine/plan_draft.dart';
import '../engine/plan_status.dart';
import '../money/currency.dart';
import '../money/money_format.dart';
import 'backup_data.dart';
import 'backup_json.dart';

/// A row's "Status" column.
enum ExportStatus { open, onHold, closed, archived }

/// The words of the spreadsheet, in the app language.
abstract interface class CsvTexts {
  /// The 12 column headers, in order: name, type, status, source, payment
  /// number, due date, amount, extra fee, fee per payment, paid, paid on,
  /// currency.
  List<String> get headers;

  String planKind(PlanKind kind, {required bool cashAdvance});

  /// "Type" of a recurring payment's row.
  String get recurringKind;

  String status(ExportStatus status);

  /// The name of an untitled "Pay later" plan ("Pay later · Dec 14").
  String payLaterName(LocalDate due);
}

/// A plan's status in the spreadsheet: closed, else in the archive when
/// every payment is paid ([planIsOpen]), else on hold or open.
ExportStatus planExportStatus(BackupPlan plan) {
  if (plan.status == PlanStatus.closed) return ExportStatus.closed;
  final open = planIsOpen(
    plan.status,
    anyUnpaid: plan.payments.any((p) => p.paidAt == null),
  );
  if (!open) return ExportStatus.archived;
  return plan.status == PlanStatus.onHold
      ? ExportStatus.onHold
      : ExportStatus.open;
}

/// A recurring payment is in the archive once its end date has passed.
ExportStatus recurringExportStatus(BackupRecurring r, LocalDate today) =>
    r.endDate != null && r.endDate!.compareTo(today) < 0
    ? ExportStatus.archived
    : ExportStatus.open;

/// The spreadsheet's text (the byte order mark included; encode as
/// UTF-8). [today] decides which recurring payments have ended.
String buildCsv(BackupData data, CsvTexts texts, {required LocalDate today}) {
  final currency = Currency.fromCode(data.settings.currency);
  final label = currency.pickerLabel;
  final sources = {for (final s in data.sources) s.id: s.name};
  String money(int? minor) =>
      minor == null ? '' : formatMinorPlain(minor, currency);

  final lines = <String>[_line(texts.headers.map(_cell))];
  for (final plan in data.plans) {
    final title = plan.title?.trim();
    final name = title != null && title.isNotEmpty
        ? title
        : plan.kind == PlanKind.payLater && plan.payments.isNotEmpty
        ? texts.payLaterName(plan.payments.first.dueDate)
        : sources[plan.sourceId] ?? '';
    final kind = texts.planKind(plan.kind, cashAdvance: plan.isCashAdvance);
    final status = texts.status(planExportStatus(plan));
    final source = sources[plan.sourceId] ?? '';
    for (final p in plan.payments) {
      final paidOn = p.paidBeforeKalan
          // Saved as paid when the plan was added: the real day is not
          // known.
          ? null
          : p.paidOn ??
                (p.paidAt == null
                    ? null
                    : LocalDate.fromDateTime(p.paidAt!.toLocal()));
      lines.add(
        _line([
          _text(name),
          _text(kind),
          _text(status),
          _text(source),
          '${p.seq}',
          formatDay(p.dueDate),
          money(p.amount),
          money(p.extraFee),
          money(p.installmentFee),
          '${p.paidAt != null}',
          paidOn == null ? '' : formatDay(paidOn),
          _text(label),
        ]),
      );
    }
  }
  for (final r in data.recurringPayments) {
    final status = texts.status(recurringExportStatus(r, today));
    for (final o in r.paidOccurrences) {
      lines.add(
        _line([
          _text(r.name),
          _text(texts.recurringKind),
          _text(status),
          '',
          '',
          formatDay(o.date),
          // Occurrences keep no amount of their own: today's amount.
          money(r.amount),
          '',
          '',
          'true',
          formatDay(LocalDate.fromDateTime(o.paidAt.toLocal())),
          _text(label),
        ]),
      );
    }
  }
  return '﻿${lines.join()}';
}

String _line(Iterable<String> cells) => '${cells.join(',')}\r\n';

/// A text cell: formula guard, then quoting.
String _text(String value) => _cell(
  value.isNotEmpty && '=+-@\t\r'.contains(value[0]) ? "'$value" : value,
);

/// RFC 4180 quoting.
String _cell(String value) =>
    value.contains(RegExp('[",\r\n]'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;
