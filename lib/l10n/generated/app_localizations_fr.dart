// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Français';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionAddPlan => 'Ajouter un plan';

  @override
  String get actionMoreDetails => 'Plus de détails';

  @override
  String get navHome => 'Cette période';

  @override
  String get navPlans => 'Plans';

  @override
  String get navSettings => 'Réglages';

  @override
  String get frequencyMonthly => 'Mensuel';

  @override
  String get frequencyBiweekly => 'Toutes les deux semaines';

  @override
  String get frequencyWeekly => 'Hebdomadaire';

  @override
  String get onboardingTitle => 'On configure tout en une minute.';

  @override
  String get onboardingIntro =>
      'Dis à Kalan quand tu es payé. Tes données restent sur ce téléphone.';

  @override
  String get fieldCurrency => 'Devise';

  @override
  String get fieldPayFrequency => 'À quelle fréquence es-tu payé ?';

  @override
  String get fieldPayDay => 'Jour de paie';

  @override
  String get payDayHelp =>
      'Les mois plus courts, c’est le dernier jour qui compte.';

  @override
  String get fieldLastPayday => 'Dernier jour de paie';

  @override
  String get fieldPayWeekday => 'Jour de paie';

  @override
  String get fieldNetIncome => 'Salaire net par paie';

  @override
  String get netIncomeHelp =>
      'Facultatif. Sans lui, je n’affiche que ce qui est déjà engagé.';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get errorRequired => 'Ce champ est obligatoire.';

  @override
  String errorAmountInvalid(String example) {
    return 'Saisis le montant en chiffres, par exemple $example.';
  }

  @override
  String get errorCountInvalid => 'Saisis un nombre entre 1 et 120.';

  @override
  String get errorRemainingTooHigh =>
      'Ce nombre ne peut pas dépasser le total.';

  @override
  String get errorTotalTooSmall =>
      'Ce montant ne peut pas être réparti sur autant de paiements.';

  @override
  String get errorDayInvalid => 'Saisis un jour entre 1 et 31.';

  @override
  String get errorNameRequired => 'Saisis un nom.';

  @override
  String get errorEndBeforeStart =>
      'La date de fin ne peut pas précéder la première date.';

  @override
  String get errorDeferInvalid => 'Saisis un nombre entre 0 et 12.';

  @override
  String get errorStepInvalid => 'Saisis un nombre entre 1 et 365.';

  @override
  String get errorCardRequired => 'Choisis une carte.';

  @override
  String get homeLeftLabel => 'Il te reste';

  @override
  String get homeSpokenForLabel => 'Déjà engagé';

  @override
  String get homeIncomeLabel => 'Revenu';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements cette période. Total $total.',
      one: '1 paiement cette période. Total $total.',
      zero: 'Aucun paiement cette période.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Période serrée. Ce qu’il te reste est sous ton seuil de $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'Il manque $amount cette période.';
  }

  @override
  String get homeNoIncomeHint =>
      'Ajoute ton salaire net dans les Réglages pour voir ce qu’il te reste.';

  @override
  String get homeOverdueTitle => 'Pas encore payé';

  @override
  String get homeOverdueHelp =>
      'La date est passée et ils ne sont pas marqués comme payés.';

  @override
  String get homePaymentsTitle => 'Paiements de cette période';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor sur $income sont déjà engagés.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Paiement $seq sur $count';
  }

  @override
  String get paidLabel => 'Payé';

  @override
  String get markAsPaid => 'Marquer comme payé';

  @override
  String get markAsUnpaid => 'Marquer comme non payé';

  @override
  String get markedPaid => 'Marqué comme payé.';

  @override
  String get markedUnpaid => 'Marqué comme non payé.';

  @override
  String get recurringTag => 'Récurrent';

  @override
  String get dueToday => 'Aujourd’hui';

  @override
  String get dueTomorrow => 'Demain';

  @override
  String get plansTabOpen => 'En cours';

  @override
  String get plansTabRecurring => 'Récurrents';

  @override
  String get plansTabFinished => 'Terminés';

  @override
  String get plansEmptyOpen => 'Aucun plan en cours.';

  @override
  String get plansEmptyFinished =>
      'Aucun plan terminé. Un plan arrive ici quand tous ses paiements sont payés.';

  @override
  String get recurringEmpty =>
      'Aucun paiement récurrent. Tu peux ajouter un loyer, des factures ou des abonnements.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count payés';
  }

  @override
  String planToPay(String amount) {
    return 'Reste à payer $amount';
  }

  @override
  String planNext(String date) {
    return 'Prochain paiement $date';
  }

  @override
  String planTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Achat le $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements ont été faits avant l’ajout de ce plan.',
      one: '1 paiement a été fait avant l’ajout de ce plan.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'La version gratuite accepte jusqu’à $limit plans en cours. Tu pourras en ajouter un quand un plan sera terminé.';
  }

  @override
  String get addRecurring => 'Ajouter un paiement récurrent';

  @override
  String get kindPayIn4 => 'Paiement en 4 fois';

  @override
  String get kindMonthly => 'Mensualités';

  @override
  String get kindCard => 'Paiement en plusieurs fois par carte';

  @override
  String get kindManual => 'Personnalisé';

  @override
  String get kindMidway => 'Déjà commencé';

  @override
  String get kindCashAdvance => 'Avance d’espèces en plusieurs fois';

  @override
  String get planPaymentsTitle => 'Paiements';

  @override
  String get planDelete => 'Supprimer le plan';

  @override
  String get planDeleteConfirm =>
      'Ce plan et tous ses paiements seront supprimés.';

  @override
  String get planDeleted => 'Plan supprimé.';

  @override
  String get planNotFound => 'Ce plan n’existe plus.';

  @override
  String get editPaymentTitle => 'Corriger le paiement';

  @override
  String get editPaymentHelp =>
      'La différence est répartie sur les paiements suivants. Le total du plan ne change pas.';

  @override
  String get editRejectedPaid =>
      'Un paiement payé ne peut pas être corrigé. Marque-le d’abord comme non payé.';

  @override
  String get editRejectedNoAbsorbers =>
      'Aucun paiement suivant ne peut absorber la différence. Tu peux quand même changer la date.';

  @override
  String get editRejectedAbsorber =>
      'Ce changement ramènerait un paiement suivant à zéro. Essaie un changement plus petit.';

  @override
  String get editedTag => 'Corrigé';

  @override
  String get paymentUpdated => 'Paiement mis à jour.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Ajouter un plan';

  @override
  String get addPlanTypeLabel => 'Type de plan';

  @override
  String get fieldSource => 'Source';

  @override
  String get fieldSourceHint => 'p. ex. Klarna ou ta banque';

  @override
  String get fieldCard => 'Carte';

  @override
  String get fieldTotal => 'Montant total';

  @override
  String get fieldCount => 'Nombre de paiements';

  @override
  String get fieldFirstDate => 'Date du premier paiement';

  @override
  String get fieldPurchaseDate => 'Date d’achat';

  @override
  String get fieldIntervalStep => 'Tous les';

  @override
  String get fieldIntervalUnit => 'Unité';

  @override
  String get unitDays => 'jours';

  @override
  String get unitWeeks => 'semaines';

  @override
  String get unitMonths => 'mois';

  @override
  String get fieldTotalCount => 'Nombre total de paiements';

  @override
  String get fieldUnpaidCount => 'Paiements restants';

  @override
  String get fieldInstallment => 'Montant du paiement';

  @override
  String get fieldNextDate => 'Date du prochain paiement';

  @override
  String get fieldTitle => 'Nom du plan';

  @override
  String get fieldTitleHint => 'p. ex. Téléphone';

  @override
  String get fieldDefer => 'Reporter le premier paiement (mois)';

  @override
  String get fieldCashAdvance => 'Avance d’espèces en plusieurs fois';

  @override
  String get noCards => 'Aucune carte pour l’instant.';

  @override
  String get addCard => 'Ajouter une carte';

  @override
  String get previewTitle => 'Paiements';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements, $total au total.',
      one: '1 paiement, $total au total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Remplis les champs pour voir les paiements ici.';

  @override
  String get planSaved => 'Plan ajouté.';

  @override
  String get fieldPaymentDate => 'Date de paiement';

  @override
  String get sourcesTitle => 'Sources et cartes';

  @override
  String get sourcesEmpty =>
      'Aucune source pour l’instant. Celles que tu saisis en ajoutant un plan apparaissent ici.';

  @override
  String get addSource => 'Ajouter une source';

  @override
  String get editSource => 'Modifier la source';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldSourceKind => 'Type';

  @override
  String get sourceKindProvider => 'Service de paiement différé';

  @override
  String get sourceKindCard => 'Carte de crédit';

  @override
  String get fieldStatementDay => 'Date d’arrêté';

  @override
  String get statementDayHelp => 'Le jour du mois où ton relevé est arrêté.';

  @override
  String get fieldDueDay => 'Date d’échéance';

  @override
  String get dueDayHelp => 'Le jour du mois où le relevé doit être payé.';

  @override
  String get fieldShiftWeekend =>
      'Reporter au jour ouvré suivant si elle tombe un week-end';

  @override
  String get cardDaysChangeNote =>
      'Changer ces jours recalcule les dates des paiements non payés et non corrigés de cette carte.';

  @override
  String get sourceInUse =>
      'Des plans utilisent cette source. Supprime d’abord ces plans.';

  @override
  String get sourceDeleted => 'Source supprimée.';

  @override
  String get sourceSaved => 'Enregistré.';

  @override
  String cardSummary(int statement, int due) {
    return 'Arrêté le $statement, échéance le $due';
  }

  @override
  String get recurringNewTitle => 'Ajouter un paiement récurrent';

  @override
  String get recurringEditTitle => 'Modifier le paiement récurrent';

  @override
  String get fieldRecurringNameHint => 'p. ex. Loyer';

  @override
  String get fieldAmount => 'Montant';

  @override
  String get fieldRecurrence => 'Fréquence';

  @override
  String get recurrenceWeekly => 'Chaque semaine';

  @override
  String get recurrenceBiweekly => 'Toutes les deux semaines';

  @override
  String get recurrenceMonthly => 'Chaque mois';

  @override
  String get recurrenceYearly => 'Chaque année';

  @override
  String get fieldEndDate => 'Date de fin';

  @override
  String get noEndDate => 'Pas de date de fin';

  @override
  String get clearEndDate => 'Retirer la date de fin';

  @override
  String get recurringDeleteConfirm => 'Ce paiement récurrent sera supprimé.';

  @override
  String get recurringDeleted => 'Paiement récurrent supprimé.';

  @override
  String get recurringSaved => 'Enregistré.';

  @override
  String recurringNext(String date) {
    return 'Prochain le $date';
  }

  @override
  String get recurringEnded => 'Terminé';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsCurrencyNote =>
      'Les montants ne sont pas convertis ; seule l’étiquette de la devise change.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Livre turque',
      'USD': 'Dollar américain',
      'EUR': 'Euro',
      'GBP': 'Livre sterling',
      'BRL': 'Réal brésilien',
      'MXN': 'Peso mexicain',
      'COP': 'Peso colombien',
      'CLP': 'Peso chilien',
      'RUB': 'Rouble russe',
      'KZT': 'Tenge kazakh',
      'CNY': 'Yuan chinois',
      'SGD': 'Dollar de Singapour',
      'MYR': 'Ringgit malaisien',
      'IDR': 'Roupie indonésienne',
      'CAD': 'Dollar canadien',
      'AUD': 'Dollar australien',
      'CHF': 'Franc suisse',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Rechercher une devise';

  @override
  String get currencyNoMatch => 'Aucune devise ne correspond.';

  @override
  String get currencyChangeTitle => 'Changer de devise';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Exemple : $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Cette devise n’a pas le même nombre de décimales, les montants sont donc arrondis.';

  @override
  String get currencyChangeConfirm => 'Changer';

  @override
  String get settingsPay => 'Salaire';

  @override
  String paySummaryMonthly(int day) {
    return 'Mensuel, le $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Toutes les deux semaines, dernière paie le $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Hebdomadaire, le $weekday';
  }

  @override
  String get settingsNetIncome => 'Salaire net';

  @override
  String get notSet => 'Non défini';

  @override
  String get settingsTight => 'Seuil de période serrée';

  @override
  String get settingsTightHelp =>
      'Une période est serrée quand ce qu’il te reste passe sous ce montant. Laisse vide pour désactiver.';

  @override
  String get off => 'Désactivé';

  @override
  String get settingsSources => 'Sources et cartes';

  @override
  String get settingsRoadmap => 'Feuille de route';

  @override
  String get settingsPrivacy =>
      'Tes données restent sur ce téléphone. Pas de compte, pas de connexion bancaire, pas de pub.';

  @override
  String get settingsDebugPro => 'Pro (versions debug uniquement)';

  @override
  String get settingsSaved => 'Enregistré.';

  @override
  String get roadmapEmpty => 'Rien à partager ici pour l’instant.';

  @override
  String get roadmapError => 'Impossible de lire la feuille de route.';

  @override
  String get roadmapPlanned => 'Prévu';

  @override
  String get roadmapInProgress => 'En cours';

  @override
  String get roadmapShipped => 'Publié';

  @override
  String roadmapTarget(String version) {
    return 'Version visée $version';
  }
}
