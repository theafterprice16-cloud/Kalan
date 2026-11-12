// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Italiano';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionEdit => 'Modifica';

  @override
  String get actionAddPlan => 'Aggiungi piano';

  @override
  String get actionMoreDetails => 'Altri dettagli';

  @override
  String get navHome => 'Questo periodo';

  @override
  String get navPlans => 'Piani';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get frequencyMonthly => 'Mensile';

  @override
  String get frequencyBiweekly => 'Ogni due settimane';

  @override
  String get frequencyWeekly => 'Settimanale';

  @override
  String get onboardingTitle => 'Configuriamo tutto in un minuto.';

  @override
  String get onboardingIntro =>
      'Di’ a Kalan quando ricevi lo stipendio. I tuoi dati restano su questo telefono.';

  @override
  String get fieldCurrency => 'Valuta';

  @override
  String get fieldPayFrequency => 'Ogni quanto ricevi lo stipendio?';

  @override
  String get fieldPayDay => 'Giorno di paga';

  @override
  String get payDayHelp => 'Nei mesi più corti conta l’ultimo giorno.';

  @override
  String get fieldLastPayday => 'Ultimo giorno di paga';

  @override
  String get fieldPayWeekday => 'Giorno di paga';

  @override
  String get fieldNetIncome => 'Stipendio netto per paga';

  @override
  String get netIncomeHelp =>
      'Facoltativo. Senza, mostro solo ciò che è già impegnato.';

  @override
  String get onboardingStart => 'Inizia';

  @override
  String get errorRequired => 'Questo campo è obbligatorio.';

  @override
  String errorAmountInvalid(String example) {
    return 'Scrivi l’importo in cifre, per esempio $example.';
  }

  @override
  String get errorCountInvalid => 'Scrivi un numero da 1 a 120.';

  @override
  String get errorRemainingTooHigh => 'Non può superare il totale.';

  @override
  String get errorTotalTooSmall =>
      'Questo importo non si può dividere in così tanti pagamenti.';

  @override
  String get errorDayInvalid => 'Scrivi un giorno da 1 a 31.';

  @override
  String get errorNameRequired => 'Scrivi un nome.';

  @override
  String get errorEndBeforeStart =>
      'La data di fine non può precedere la prima data.';

  @override
  String get errorDeferInvalid => 'Scrivi un numero da 0 a 12.';

  @override
  String get errorStepInvalid => 'Scrivi un numero da 1 a 365.';

  @override
  String get errorCardRequired => 'Scegli una carta.';

  @override
  String get homeLeftLabel => 'Ti resta';

  @override
  String get homeSpokenForLabel => 'Già impegnato';

  @override
  String get homeIncomeLabel => 'Entrate';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamenti in questo periodo. Totale $total.',
      one: '1 pagamento in questo periodo. Totale $total.',
      zero: 'Nessun pagamento in questo periodo.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Periodo stretto. Quello che ti resta è sotto la tua soglia di $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'In questo periodo mancano $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Aggiungi lo stipendio netto nelle Impostazioni per vedere quanto ti resta.';

  @override
  String get homeOverdueTitle => 'Non ancora pagati';

  @override
  String get homeOverdueHelp =>
      'La data è passata e non sono segnati come pagati.';

  @override
  String get homePaymentsTitle => 'Pagamenti di questo periodo';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor su $income sono già impegnati.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Pagamento $seq di $count';
  }

  @override
  String get paidLabel => 'Pagato';

  @override
  String get markAsPaid => 'Segna come pagato';

  @override
  String get markAsUnpaid => 'Segna come non pagato';

  @override
  String get markedPaid => 'Segnato come pagato.';

  @override
  String get markedUnpaid => 'Segnato come non pagato.';

  @override
  String get recurringTag => 'Fisso';

  @override
  String get dueToday => 'Oggi';

  @override
  String get dueTomorrow => 'Domani';

  @override
  String get plansTabOpen => 'Aperti';

  @override
  String get plansTabRecurring => 'Fissi';

  @override
  String get plansTabFinished => 'Conclusi';

  @override
  String get plansEmptyOpen => 'Nessun piano aperto.';

  @override
  String get plansEmptyFinished =>
      'Ancora nessun piano concluso. Un piano arriva qui quando tutti i pagamenti sono pagati.';

  @override
  String get recurringEmpty =>
      'Nessun pagamento fisso. Puoi aggiungere affitto, bollette o abbonamenti.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count pagati';
  }

  @override
  String planToPay(String amount) {
    return 'Da pagare $amount';
  }

  @override
  String planNext(String date) {
    return 'Prossimo pagamento $date';
  }

  @override
  String planTotal(String amount) {
    return 'Totale $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Acquisto del $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pagamenti sono stati fatti prima di aggiungere questo piano.',
      one: '1 pagamento è stato fatto prima di aggiungere questo piano.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'La versione gratuita consente fino a $limit piani aperti. Potrai aggiungerne uno quando un piano finisce.';
  }

  @override
  String get addRecurring => 'Aggiungi pagamento fisso';

  @override
  String get kindPayIn4 => 'Pagamento in 4 rate';

  @override
  String get kindMonthly => 'Rate mensili';

  @override
  String get kindCard => 'Rate con carta';

  @override
  String get kindManual => 'Personalizzato';

  @override
  String get kindMidway => 'Già iniziato';

  @override
  String get kindCashAdvance => 'Anticipo contanti a rate';

  @override
  String get planPaymentsTitle => 'Pagamenti';

  @override
  String get planDelete => 'Elimina piano';

  @override
  String get planDeleteConfirm =>
      'Questo piano e tutti i suoi pagamenti verranno eliminati.';

  @override
  String get planDeleted => 'Piano eliminato.';

  @override
  String get planNotFound => 'Questo piano non esiste più.';

  @override
  String get editPaymentTitle => 'Correggi pagamento';

  @override
  String get editPaymentHelp =>
      'La differenza viene distribuita sui pagamenti successivi. Il totale del piano non cambia.';

  @override
  String get editRejectedPaid =>
      'Un pagamento pagato non si può correggere. Prima segnalo come non pagato.';

  @override
  String get editRejectedNoAbsorbers =>
      'Non c’è un pagamento successivo che assorba la differenza. Puoi comunque cambiare la data.';

  @override
  String get editRejectedAbsorber =>
      'Questa modifica azzererebbe un pagamento successivo. Prova una modifica più piccola.';

  @override
  String get editedTag => 'Corretto';

  @override
  String get paymentUpdated => 'Pagamento aggiornato.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Aggiungi piano';

  @override
  String get addPlanTypeLabel => 'Tipo di piano';

  @override
  String get fieldSource => 'Fonte';

  @override
  String get fieldSourceHint => 'es. Klarna o la tua banca';

  @override
  String get fieldCard => 'Carta';

  @override
  String get fieldTotal => 'Importo totale';

  @override
  String get fieldCount => 'Numero di pagamenti';

  @override
  String get fieldFirstDate => 'Data del primo pagamento';

  @override
  String get fieldPurchaseDate => 'Data di acquisto';

  @override
  String get fieldIntervalStep => 'Ogni';

  @override
  String get fieldIntervalUnit => 'Unità';

  @override
  String get unitDays => 'giorni';

  @override
  String get unitWeeks => 'settimane';

  @override
  String get unitMonths => 'mesi';

  @override
  String get fieldTotalCount => 'Pagamenti totali';

  @override
  String get fieldUnpaidCount => 'Pagamenti non ancora pagati';

  @override
  String get fieldInstallment => 'Importo del pagamento';

  @override
  String get fieldNextDate => 'Data del prossimo pagamento';

  @override
  String get fieldTitle => 'Nome del piano';

  @override
  String get fieldTitleHint => 'es. Telefono';

  @override
  String get fieldDefer => 'Rimanda il primo pagamento (mesi)';

  @override
  String get fieldCashAdvance => 'Anticipo contanti a rate';

  @override
  String get noCards => 'Ancora nessuna carta.';

  @override
  String get addCard => 'Aggiungi carta';

  @override
  String get previewTitle => 'Pagamenti';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamenti, $total in totale.',
      one: '1 pagamento, $total in totale.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Compila i campi per vedere qui i pagamenti.';

  @override
  String get planSaved => 'Piano aggiunto.';

  @override
  String get fieldPaymentDate => 'Data di pagamento';

  @override
  String get sourcesTitle => 'Fonti e carte';

  @override
  String get sourcesEmpty =>
      'Ancora nessuna fonte. Quelle che scrivi aggiungendo un piano compaiono qui.';

  @override
  String get addSource => 'Aggiungi fonte';

  @override
  String get editSource => 'Modifica fonte';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldSourceKind => 'Tipo';

  @override
  String get sourceKindProvider => 'Servizio paga dopo';

  @override
  String get sourceKindCard => 'Carta di credito';

  @override
  String get fieldStatementDay => 'Giorno di chiusura';

  @override
  String get statementDayHelp =>
      'Il giorno del mese in cui si chiude l’estratto conto.';

  @override
  String get fieldDueDay => 'Scadenza';

  @override
  String get dueDayHelp =>
      'Il giorno del mese entro cui va pagato l’estratto conto.';

  @override
  String get fieldShiftWeekend =>
      'Sposta al giorno lavorativo successivo se cade nel weekend';

  @override
  String get cardDaysChangeNote =>
      'Cambiando questi giorni si ricalcolano le date dei pagamenti non pagati e non corretti di questa carta.';

  @override
  String get sourceInUse =>
      'Alcuni piani usano questa fonte. Elimina prima quei piani.';

  @override
  String get sourceDeleted => 'Fonte eliminata.';

  @override
  String get sourceSaved => 'Salvato.';

  @override
  String cardSummary(int statement, int due) {
    return 'Chiusura il $statement, scadenza il $due';
  }

  @override
  String get recurringNewTitle => 'Aggiungi pagamento fisso';

  @override
  String get recurringEditTitle => 'Modifica pagamento fisso';

  @override
  String get fieldRecurringNameHint => 'es. Affitto';

  @override
  String get fieldAmount => 'Importo';

  @override
  String get fieldRecurrence => 'Si ripete';

  @override
  String get recurrenceWeekly => 'Ogni settimana';

  @override
  String get recurrenceBiweekly => 'Ogni due settimane';

  @override
  String get recurrenceMonthly => 'Ogni mese';

  @override
  String get recurrenceYearly => 'Ogni anno';

  @override
  String get fieldEndDate => 'Data di fine';

  @override
  String get noEndDate => 'Nessuna data di fine';

  @override
  String get clearEndDate => 'Rimuovi data di fine';

  @override
  String get recurringDeleteConfirm =>
      'Questo pagamento fisso verrà eliminato.';

  @override
  String get recurringDeleted => 'Pagamento fisso eliminato.';

  @override
  String get recurringSaved => 'Salvato.';

  @override
  String recurringNext(String date) {
    return 'Prossimo il $date';
  }

  @override
  String get recurringEnded => 'Terminato';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageSystem => 'Lingua di sistema';

  @override
  String get settingsCurrency => 'Valuta';

  @override
  String get settingsCurrencyNote =>
      'Gli importi non vengono convertiti; cambia solo l’etichetta della valuta.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Lira turca',
      'USD': 'Dollaro statunitense',
      'EUR': 'Euro',
      'GBP': 'Sterlina britannica',
      'BRL': 'Real brasiliano',
      'MXN': 'Peso messicano',
      'COP': 'Peso colombiano',
      'CLP': 'Peso cileno',
      'RUB': 'Rublo russo',
      'KZT': 'Tenge kazako',
      'CNY': 'Yuan cinese',
      'SGD': 'Dollaro di Singapore',
      'MYR': 'Ringgit malese',
      'IDR': 'Rupia indonesiana',
      'CAD': 'Dollaro canadese',
      'AUD': 'Dollaro australiano',
      'CHF': 'Franco svizzero',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Cerca valuta';

  @override
  String get currencyNoMatch => 'Nessuna valuta corrisponde.';

  @override
  String get currencyChangeTitle => 'Cambia valuta';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Esempio: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Questa valuta ha un numero diverso di decimali, quindi gli importi vengono arrotondati.';

  @override
  String get currencyChangeConfirm => 'Cambia';

  @override
  String get settingsPay => 'Stipendio';

  @override
  String paySummaryMonthly(int day) {
    return 'Mensile, il giorno $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Ogni due settimane, ultimo stipendio $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Settimanale, $weekday';
  }

  @override
  String get settingsNetIncome => 'Stipendio netto';

  @override
  String get notSet => 'Non impostato';

  @override
  String get settingsTight => 'Soglia periodo stretto';

  @override
  String get settingsTightHelp =>
      'Un periodo è stretto quando ciò che ti resta scende sotto questo importo. Lascia vuoto per disattivare.';

  @override
  String get off => 'Disattivato';

  @override
  String get settingsSources => 'Fonti e carte';

  @override
  String get settingsRoadmap => 'Roadmap';

  @override
  String get settingsPrivacy =>
      'I tuoi dati restano su questo telefono. Niente account, niente collegamento alla banca, niente pubblicità.';

  @override
  String get settingsDebugPro => 'Pro (solo build di debug)';

  @override
  String get settingsSaved => 'Salvato.';

  @override
  String get roadmapEmpty => 'Per ora non c’è niente da condividere qui.';

  @override
  String get roadmapError => 'Impossibile leggere la roadmap.';

  @override
  String get roadmapPlanned => 'Pianificato';

  @override
  String get roadmapInProgress => 'In corso';

  @override
  String get roadmapShipped => 'Pubblicato';

  @override
  String roadmapTarget(String version) {
    return 'Versione prevista $version';
  }
}
