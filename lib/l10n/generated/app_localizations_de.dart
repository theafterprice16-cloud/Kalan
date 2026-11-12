// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Deutsch';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionAddPlan => 'Plan hinzufügen';

  @override
  String get actionMoreDetails => 'Weitere Angaben';

  @override
  String get navHome => 'Diese Periode';

  @override
  String get navPlans => 'Pläne';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get frequencyMonthly => 'Monatlich';

  @override
  String get frequencyBiweekly => 'Alle zwei Wochen';

  @override
  String get frequencyWeekly => 'Wöchentlich';

  @override
  String get onboardingTitle => 'In einer Minute eingerichtet.';

  @override
  String get onboardingIntro =>
      'Sag Kalan, wann du dein Gehalt bekommst. Deine Daten bleiben auf diesem Telefon.';

  @override
  String get fieldCurrency => 'Währung';

  @override
  String get fieldPayFrequency => 'Wie oft bekommst du Gehalt?';

  @override
  String get fieldPayDay => 'Zahltag';

  @override
  String get payDayHelp => 'In kürzeren Monaten zählt der letzte Tag.';

  @override
  String get fieldLastPayday => 'Letzter Zahltag';

  @override
  String get fieldPayWeekday => 'Zahltag';

  @override
  String get fieldNetIncome => 'Nettogehalt pro Zahlung';

  @override
  String get netIncomeHelp =>
      'Optional. Ohne Angabe zeige ich nur, was schon verplant ist.';

  @override
  String get onboardingStart => 'Los geht’s';

  @override
  String get errorRequired => 'Dieses Feld ist erforderlich.';

  @override
  String errorAmountInvalid(String example) {
    return 'Gib den Betrag in Ziffern ein, zum Beispiel $example.';
  }

  @override
  String get errorCountInvalid => 'Gib eine Zahl von 1 bis 120 ein.';

  @override
  String get errorRemainingTooHigh =>
      'Das darf nicht mehr als die Gesamtzahl sein.';

  @override
  String get errorTotalTooSmall =>
      'Dieser Betrag lässt sich nicht auf so viele Zahlungen aufteilen.';

  @override
  String get errorDayInvalid => 'Gib einen Tag von 1 bis 31 ein.';

  @override
  String get errorNameRequired => 'Gib einen Namen ein.';

  @override
  String get errorEndBeforeStart =>
      'Das Enddatum darf nicht vor dem ersten Datum liegen.';

  @override
  String get errorDeferInvalid => 'Gib eine Zahl von 0 bis 12 ein.';

  @override
  String get errorStepInvalid => 'Gib eine Zahl von 1 bis 365 ein.';

  @override
  String get errorCardRequired => 'Wähle eine Karte.';

  @override
  String get homeLeftLabel => 'Übrig';

  @override
  String get homeSpokenForLabel => 'Verplant';

  @override
  String get homeIncomeLabel => 'Einkommen';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In dieser Periode gibt es $count Zahlungen. Gesamt $total.',
      one: 'In dieser Periode gibt es 1 Zahlung. Gesamt $total.',
      zero: 'In dieser Periode gibt es keine Zahlungen.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Knappe Periode. Was übrig bleibt, liegt unter deiner Grenze von $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'In dieser Periode fehlen $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Trag dein Nettogehalt in den Einstellungen ein, dann zeige ich, was übrig bleibt.';

  @override
  String get homeOverdueTitle => 'Noch nicht bezahlt';

  @override
  String get homeOverdueHelp =>
      'Das Datum ist vorbei und sie sind nicht als bezahlt markiert.';

  @override
  String get homePaymentsTitle => 'Zahlungen dieser Periode';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor von $income sind verplant.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Zahlung $seq von $count';
  }

  @override
  String get paidLabel => 'Bezahlt';

  @override
  String get markAsPaid => 'Als bezahlt markieren';

  @override
  String get markAsUnpaid => 'Als nicht bezahlt markieren';

  @override
  String get markedPaid => 'Als bezahlt markiert.';

  @override
  String get markedUnpaid => 'Als nicht bezahlt markiert.';

  @override
  String get recurringTag => 'Fix';

  @override
  String get dueToday => 'Heute';

  @override
  String get dueTomorrow => 'Morgen';

  @override
  String get plansTabOpen => 'Offen';

  @override
  String get plansTabRecurring => 'Fix';

  @override
  String get plansTabFinished => 'Abgeschlossen';

  @override
  String get plansEmptyOpen => 'Keine offenen Pläne.';

  @override
  String get plansEmptyFinished =>
      'Noch keine abgeschlossenen Pläne. Ein Plan landet hier, wenn alle Zahlungen bezahlt sind.';

  @override
  String get recurringEmpty =>
      'Keine Fixkosten. Du kannst Miete, Rechnungen oder Abos hinzufügen.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count bezahlt';
  }

  @override
  String planToPay(String amount) {
    return 'Offen $amount';
  }

  @override
  String planNext(String date) {
    return 'Nächste Zahlung $date';
  }

  @override
  String planTotal(String amount) {
    return 'Gesamt $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Gekauft am $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen wurden vor dem Hinzufügen dieses Plans geleistet.',
      one: '1 Zahlung wurde vor dem Hinzufügen dieses Plans geleistet.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'Die kostenlose Version hat bis zu $limit offene Pläne. Du kannst einen neuen hinzufügen, sobald einer abgeschlossen ist.';
  }

  @override
  String get addRecurring => 'Fixkosten hinzufügen';

  @override
  String get kindPayIn4 => 'In 4 Raten';

  @override
  String get kindMonthly => 'Monatliche Raten';

  @override
  String get kindCard => 'Kreditkartenraten';

  @override
  String get kindManual => 'Eigene Angaben';

  @override
  String get kindMidway => 'Bereits begonnen';

  @override
  String get kindCashAdvance => 'Bargeldvorschuss in Raten';

  @override
  String get planPaymentsTitle => 'Zahlungen';

  @override
  String get planDelete => 'Plan löschen';

  @override
  String get planDeleteConfirm =>
      'Dieser Plan und alle seine Zahlungen werden gelöscht.';

  @override
  String get planDeleted => 'Plan gelöscht.';

  @override
  String get planNotFound => 'Diesen Plan gibt es nicht mehr.';

  @override
  String get editPaymentTitle => 'Zahlung korrigieren';

  @override
  String get editPaymentHelp =>
      'Die Differenz wird auf spätere Zahlungen verteilt. Die Plansumme bleibt gleich.';

  @override
  String get editRejectedPaid =>
      'Eine bezahlte Zahlung lässt sich nicht ändern. Markiere sie zuerst als nicht bezahlt.';

  @override
  String get editRejectedNoAbsorbers =>
      'Es gibt keine spätere Zahlung für die Differenz. Das Datum kannst du trotzdem ändern.';

  @override
  String get editRejectedAbsorber =>
      'Diese Änderung würde eine spätere Zahlung auf null setzen. Versuch eine kleinere Änderung.';

  @override
  String get editedTag => 'Geändert';

  @override
  String get paymentUpdated => 'Zahlung aktualisiert.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Plan hinzufügen';

  @override
  String get addPlanTypeLabel => 'Planart';

  @override
  String get fieldSource => 'Anbieter';

  @override
  String get fieldSourceHint => 'z. B. Klarna oder deine Bank';

  @override
  String get fieldCard => 'Karte';

  @override
  String get fieldTotal => 'Gesamtbetrag';

  @override
  String get fieldCount => 'Anzahl der Zahlungen';

  @override
  String get fieldFirstDate => 'Datum der ersten Zahlung';

  @override
  String get fieldPurchaseDate => 'Kaufdatum';

  @override
  String get fieldIntervalStep => 'Alle';

  @override
  String get fieldIntervalUnit => 'Einheit';

  @override
  String get unitDays => 'Tage';

  @override
  String get unitWeeks => 'Wochen';

  @override
  String get unitMonths => 'Monate';

  @override
  String get fieldTotalCount => 'Zahlungen insgesamt';

  @override
  String get fieldUnpaidCount => 'Noch offene Zahlungen';

  @override
  String get fieldInstallment => 'Betrag pro Zahlung';

  @override
  String get fieldNextDate => 'Datum der nächsten Zahlung';

  @override
  String get fieldTitle => 'Name des Plans';

  @override
  String get fieldTitleHint => 'z. B. Handy';

  @override
  String get fieldDefer => 'Erste Zahlung aufschieben (Monate)';

  @override
  String get fieldCashAdvance => 'Bargeldvorschuss in Raten';

  @override
  String get noCards => 'Noch keine Karten.';

  @override
  String get addCard => 'Karte hinzufügen';

  @override
  String get previewTitle => 'Zahlungen';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen, insgesamt $total.',
      one: '1 Zahlung, insgesamt $total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty =>
      'Füll die Felder aus, dann siehst du hier die Zahlungen.';

  @override
  String get planSaved => 'Plan hinzugefügt.';

  @override
  String get fieldPaymentDate => 'Zahlungsdatum';

  @override
  String get sourcesTitle => 'Anbieter und Karten';

  @override
  String get sourcesEmpty =>
      'Noch keine Anbieter. Die du beim Hinzufügen eines Plans eingibst, erscheinen hier.';

  @override
  String get addSource => 'Anbieter hinzufügen';

  @override
  String get editSource => 'Anbieter bearbeiten';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldSourceKind => 'Art';

  @override
  String get sourceKindProvider => 'Später-zahlen-Anbieter';

  @override
  String get sourceKindCard => 'Kreditkarte';

  @override
  String get fieldStatementDay => 'Abrechnungstag';

  @override
  String get statementDayHelp =>
      'Der Tag im Monat, an dem deine Abrechnung erstellt wird.';

  @override
  String get fieldDueDay => 'Fälligkeitstag';

  @override
  String get dueDayHelp =>
      'Der Tag im Monat, an dem die Abrechnung bezahlt sein muss.';

  @override
  String get fieldShiftWeekend =>
      'Auf den nächsten Werktag verschieben, wenn es ein Wochenende ist';

  @override
  String get cardDaysChangeNote =>
      'Wenn du diese Tage änderst, werden die Daten offener, nicht geänderter Zahlungen dieser Karte neu berechnet.';

  @override
  String get sourceInUse =>
      'Pläne nutzen diesen Anbieter. Lösch diese Pläne zuerst.';

  @override
  String get sourceDeleted => 'Anbieter gelöscht.';

  @override
  String get sourceSaved => 'Gespeichert.';

  @override
  String cardSummary(int statement, int due) {
    return 'Abrechnung am $statement., fällig am $due.';
  }

  @override
  String get recurringNewTitle => 'Fixkosten hinzufügen';

  @override
  String get recurringEditTitle => 'Fixkosten bearbeiten';

  @override
  String get fieldRecurringNameHint => 'z. B. Miete';

  @override
  String get fieldAmount => 'Betrag';

  @override
  String get fieldRecurrence => 'Wiederholung';

  @override
  String get recurrenceWeekly => 'Wöchentlich';

  @override
  String get recurrenceBiweekly => 'Alle zwei Wochen';

  @override
  String get recurrenceMonthly => 'Monatlich';

  @override
  String get recurrenceYearly => 'Jährlich';

  @override
  String get fieldEndDate => 'Enddatum';

  @override
  String get noEndDate => 'Kein Enddatum';

  @override
  String get clearEndDate => 'Enddatum entfernen';

  @override
  String get recurringDeleteConfirm => 'Diese Fixkosten werden gelöscht.';

  @override
  String get recurringDeleted => 'Fixkosten gelöscht.';

  @override
  String get recurringSaved => 'Gespeichert.';

  @override
  String recurringNext(String date) {
    return 'Nächste am $date';
  }

  @override
  String get recurringEnded => 'Beendet';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsCurrencyNote =>
      'Beträge werden nicht umgerechnet; nur die Währungsbezeichnung ändert sich.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Türkische Lira',
      'USD': 'US-Dollar',
      'EUR': 'Euro',
      'GBP': 'Britisches Pfund',
      'BRL': 'Brasilianischer Real',
      'MXN': 'Mexikanischer Peso',
      'COP': 'Kolumbianischer Peso',
      'CLP': 'Chilenischer Peso',
      'RUB': 'Russischer Rubel',
      'KZT': 'Kasachischer Tenge',
      'CNY': 'Chinesischer Yuan',
      'SGD': 'Singapur-Dollar',
      'MYR': 'Malaysischer Ringgit',
      'IDR': 'Indonesische Rupiah',
      'CAD': 'Kanadischer Dollar',
      'AUD': 'Australischer Dollar',
      'CHF': 'Schweizer Franken',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Währung suchen';

  @override
  String get currencyNoMatch => 'Keine passende Währung.';

  @override
  String get currencyChangeTitle => 'Währung ändern';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Beispiel: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Diese Währung hat eine andere Zahl an Nachkommastellen, daher werden Beträge gerundet.';

  @override
  String get currencyChangeConfirm => 'Ändern';

  @override
  String get settingsPay => 'Gehalt';

  @override
  String paySummaryMonthly(int day) {
    return 'Monatlich, am $day.';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Alle zwei Wochen, letzter Zahltag $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Wöchentlich, $weekday';
  }

  @override
  String get settingsNetIncome => 'Nettogehalt';

  @override
  String get notSet => 'Nicht angegeben';

  @override
  String get settingsTight => 'Grenze für knappe Periode';

  @override
  String get settingsTightHelp =>
      'Eine Periode gilt als knapp, wenn weniger als dieser Betrag übrig bleibt. Leer lassen zum Ausschalten.';

  @override
  String get off => 'Aus';

  @override
  String get settingsSources => 'Anbieter und Karten';

  @override
  String get settingsRoadmap => 'Roadmap';

  @override
  String get settingsPrivacy =>
      'Deine Daten bleiben auf diesem Telefon. Kein Konto, keine Bankverbindung, keine Werbung.';

  @override
  String get settingsDebugPro => 'Pro (nur Debug-Builds)';

  @override
  String get settingsSaved => 'Gespeichert.';

  @override
  String get roadmapEmpty => 'Hier gibt es noch nichts zu teilen.';

  @override
  String get roadmapError => 'Die Roadmap konnte nicht gelesen werden.';

  @override
  String get roadmapPlanned => 'Geplant';

  @override
  String get roadmapInProgress => 'In Arbeit';

  @override
  String get roadmapShipped => 'Veröffentlicht';

  @override
  String roadmapTarget(String version) {
    return 'Zielversion $version';
  }
}
