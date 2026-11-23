import '../../app/format.dart' show payLaterAutoName;
import '../../core/backup/backup_csv.dart';
import '../../core/date/local_date.dart';
import '../../core/engine/plan_draft.dart';
import '../../l10n/generated/app_localizations.dart';
import '../plans/plan_labels.dart';

/// The spreadsheet's words in the app language (Roadmap 29).
class ExportTexts implements CsvTexts {
  const ExportTexts(this.l10n);

  final AppLocalizations l10n;

  @override
  List<String> get headers => [
    l10n.csvName,
    l10n.csvKind,
    l10n.csvStatus,
    l10n.csvSource,
    l10n.csvSeq,
    l10n.csvDueDate,
    l10n.csvAmount,
    l10n.csvExtraFee,
    l10n.csvInstallmentFee,
    l10n.csvPaid,
    l10n.csvPaidOn,
    l10n.csvCurrency,
  ];

  @override
  String planKind(PlanKind kind, {required bool cashAdvance}) =>
      planKindLabelIn(l10n, kind, cashAdvance: cashAdvance);

  @override
  String get recurringKind => l10n.csvKindRecurring;

  @override
  String status(ExportStatus status) => switch (status) {
    ExportStatus.open => l10n.csvStatusOpen,
    ExportStatus.onHold => l10n.csvStatusOnHold,
    ExportStatus.closed => l10n.csvStatusClosed,
    ExportStatus.archived => l10n.csvStatusArchived,
  };

  @override
  String payLaterName(LocalDate due) => payLaterAutoName(l10n, due);
}
