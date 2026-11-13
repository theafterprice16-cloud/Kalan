// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAddPlan => 'Add plan';

  @override
  String get actionMoreDetails => 'More details';

  @override
  String get navHome => 'This period';

  @override
  String get navPlans => 'Plans';

  @override
  String get navSettings => 'Settings';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyBiweekly => 'Every two weeks';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get onboardingTitle => 'Let\'s set up in a minute.';

  @override
  String get onboardingIntro =>
      'Tell Kalan when you get paid. Your data stays on this phone.';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldPayFrequency => 'How often do you get paid?';

  @override
  String get fieldPayDay => 'Payday';

  @override
  String get payDayHelp => 'In shorter months, the last day counts.';

  @override
  String get fieldLastPayday => 'Last payday';

  @override
  String get fieldPayWeekday => 'Payday';

  @override
  String get fieldNetIncome => 'Take-home pay per paycheck';

  @override
  String get netIncomeHelp =>
      'Optional. Without it, I\'ll only show what\'s spoken for.';

  @override
  String get onboardingStart => 'Start';

  @override
  String get errorRequired => 'This field is required.';

  @override
  String errorAmountInvalid(String example) {
    return 'Enter the amount in numbers, like $example.';
  }

  @override
  String get errorCountInvalid => 'Enter a number from 1 to 120.';

  @override
  String get errorRemainingTooHigh => 'This can\'t be more than the total.';

  @override
  String get errorTotalTooSmall =>
      'This amount can\'t be split into that many payments.';

  @override
  String get errorDayInvalid => 'Enter a day from 1 to 31.';

  @override
  String get errorNameRequired => 'Enter a name.';

  @override
  String get errorEndBeforeStart =>
      'The end date can\'t be before the first date.';

  @override
  String get errorDeferInvalid => 'Enter a number from 0 to 12.';

  @override
  String get errorStepInvalid => 'Enter a number from 1 to 365.';

  @override
  String get errorCardRequired => 'Choose a card.';

  @override
  String get homeLeftLabel => 'Left';

  @override
  String get homeSpokenForLabel => 'Spoken for';

  @override
  String get homeIncomeLabel => 'Income';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments this period. Total $total.',
      one: '1 payment this period. Total $total.',
      zero: 'No payments this period.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Tight period. What\'s left is below your $threshold threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'This period is $amount short.';
  }

  @override
  String get homeNoIncomeHint =>
      'Add your take-home pay in Settings to see what\'s left.';

  @override
  String get homeOverdueTitle => 'Not paid yet';

  @override
  String get homeOverdueHelp =>
      'The date has passed and these aren\'t marked as paid.';

  @override
  String get homePaymentsTitle => 'This period\'s payments';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return 'Spoken for $spokenFor of $income.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Payment $seq of $count';
  }

  @override
  String get paidLabel => 'Paid';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get markAsUnpaid => 'Mark as not paid';

  @override
  String get markedPaid => 'Marked as paid.';

  @override
  String get markedUnpaid => 'Marked as not paid.';

  @override
  String get recurringTag => 'Recurring';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get plansTabOpen => 'Open';

  @override
  String get plansTabRecurring => 'Recurring';

  @override
  String get plansTabFinished => 'Finished';

  @override
  String get plansEmptyOpen => 'No open plans.';

  @override
  String get plansEmptyFinished =>
      'No finished plans yet. A plan moves here when every payment is paid.';

  @override
  String get recurringEmpty =>
      'No recurring payments. You can add rent, bills or subscriptions.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count paid';
  }

  @override
  String planToPay(String amount) {
    return 'To pay $amount';
  }

  @override
  String planNext(String date) {
    return 'Next payment $date';
  }

  @override
  String planTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Purchased $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments were made before you added this plan.',
      one: '1 payment was made before you added this plan.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'The free version holds up to $limit open plans. You can add a new one when a plan finishes.';
  }

  @override
  String get addRecurring => 'Add recurring payment';

  @override
  String get kindPayIn4 => 'Pay in 4';

  @override
  String get kindMonthly => 'Monthly installments';

  @override
  String get kindCard => 'Card installments';

  @override
  String get kindManual => 'Custom';

  @override
  String get kindMidway => 'Already started';

  @override
  String get kindCashAdvance => 'Cash advance in installments';

  @override
  String get planPaymentsTitle => 'Payments';

  @override
  String get planDelete => 'Delete plan';

  @override
  String get planDeleteConfirm =>
      'This plan and all its payments will be deleted.';

  @override
  String get planDeleted => 'Plan deleted.';

  @override
  String get planNotFound => 'This plan no longer exists.';

  @override
  String get editPaymentTitle => 'Edit payment';

  @override
  String get editPaymentHelp =>
      'The difference is spread over later payments. The plan total stays the same.';

  @override
  String get editRejectedPaid =>
      'A paid payment can\'t be edited. Mark it as not paid first.';

  @override
  String get editRejectedNoAbsorbers =>
      'There\'s no later payment to take the difference. You can still change the date.';

  @override
  String get editRejectedAbsorber =>
      'This change would bring a later payment to zero. Try a smaller change.';

  @override
  String get editedTag => 'Edited';

  @override
  String get paymentUpdated => 'Payment updated.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Add plan';

  @override
  String get addPlanTypeLabel => 'Plan type';

  @override
  String get fieldSource => 'Source';

  @override
  String get fieldSourceHint => 'e.g. Klarna or your bank';

  @override
  String get fieldCard => 'Card';

  @override
  String get fieldTotal => 'Total amount';

  @override
  String get fieldCount => 'Number of payments';

  @override
  String get fieldFirstDate => 'First payment date';

  @override
  String get fieldPurchaseDate => 'Purchase date';

  @override
  String get fieldIntervalStep => 'Every';

  @override
  String get fieldIntervalUnit => 'Unit';

  @override
  String get unitDays => 'days';

  @override
  String get unitWeeks => 'weeks';

  @override
  String get unitMonths => 'months';

  @override
  String get fieldTotalCount => 'Total payments';

  @override
  String get fieldUnpaidCount => 'Payments not yet paid';

  @override
  String get fieldInstallment => 'Payment amount';

  @override
  String get fieldNextDate => 'Next payment date';

  @override
  String get fieldTitle => 'Plan name';

  @override
  String get fieldTitleHint => 'e.g. Phone';

  @override
  String get fieldDefer => 'Defer first payment (months)';

  @override
  String get fieldCashAdvance => 'Cash advance in installments';

  @override
  String get noCards => 'No cards yet.';

  @override
  String get addCard => 'Add card';

  @override
  String get previewTitle => 'Payments';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments, $total in total.',
      one: '1 payment, $total in total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Fill in the fields to see the payments here.';

  @override
  String get planSaved => 'Plan added.';

  @override
  String get fieldPaymentDate => 'Payment date';

  @override
  String get sourcesTitle => 'Sources and cards';

  @override
  String get sourcesEmpty =>
      'No sources yet. Sources you type while adding a plan appear here.';

  @override
  String get addSource => 'Add source';

  @override
  String get editSource => 'Edit source';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldSourceKind => 'Type';

  @override
  String get sourceKindProvider => 'Pay later provider';

  @override
  String get sourceKindCard => 'Credit card';

  @override
  String get fieldStatementDay => 'Statement date';

  @override
  String get statementDayHelp => 'The day of the month your statement is cut.';

  @override
  String get fieldDueDay => 'Due date';

  @override
  String get dueDayHelp => 'The day of the month the statement must be paid.';

  @override
  String get fieldShiftWeekend =>
      'Move to the next business day if it falls on a weekend';

  @override
  String get cardDaysChangeNote =>
      'Changing these days moves the dates of unpaid, unedited payments on this card.';

  @override
  String get sourceInUse => 'Plans use this source. Delete those plans first.';

  @override
  String get sourceDeleted => 'Source deleted.';

  @override
  String get sourceSaved => 'Saved.';

  @override
  String cardSummary(int statement, int due) {
    return 'Statement date $statement, due date $due';
  }

  @override
  String get recurringNewTitle => 'Add recurring payment';

  @override
  String get recurringEditTitle => 'Edit recurring payment';

  @override
  String get fieldRecurringNameHint => 'e.g. Rent';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldRecurrence => 'Repeats';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceBiweekly => 'Every two weeks';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get fieldEndDate => 'End date';

  @override
  String get noEndDate => 'No end date';

  @override
  String get clearEndDate => 'Remove end date';

  @override
  String get recurringDeleteConfirm =>
      'This recurring payment will be deleted.';

  @override
  String get recurringDeleted => 'Recurring payment deleted.';

  @override
  String get recurringSaved => 'Saved.';

  @override
  String recurringNext(String date) {
    return 'Next $date';
  }

  @override
  String get recurringEnded => 'Ended';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsCurrencyNote =>
      'Amounts aren\'t converted; only the currency label changes.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Turkish lira',
      'USD': 'US dollar',
      'EUR': 'Euro',
      'GBP': 'British pound',
      'BRL': 'Brazilian real',
      'MXN': 'Mexican peso',
      'COP': 'Colombian peso',
      'CLP': 'Chilean peso',
      'RUB': 'Russian ruble',
      'KZT': 'Kazakhstani tenge',
      'CNY': 'Chinese yuan',
      'SGD': 'Singapore dollar',
      'MYR': 'Malaysian ringgit',
      'IDR': 'Indonesian rupiah',
      'CAD': 'Canadian dollar',
      'AUD': 'Australian dollar',
      'CHF': 'Swiss franc',
      'NZD': 'New Zealand dollar',
      'ZAR': 'South African rand',
      'ARS': 'Argentine peso',
      'PEN': 'Peruvian sol',
      'UYU': 'Uruguayan peso',
      'PYG': 'Paraguayan guaraní',
      'BOB': 'Bolivian boliviano',
      'VES': 'Venezuelan bolívar',
      'CRC': 'Costa Rican colón',
      'GTQ': 'Guatemalan quetzal',
      'HNL': 'Honduran lempira',
      'NIO': 'Nicaraguan córdoba',
      'DOP': 'Dominican peso',
      'PAB': 'Panamanian balboa',
      'AOA': 'Angolan kwanza',
      'MZN': 'Mozambican metical',
      'XOF': 'West African CFA franc',
      'XAF': 'Central African CFA franc',
      'BYN': 'Belarusian ruble',
      'KGS': 'Kyrgyzstani som',
      'UZS': 'Uzbekistani som',
      'TWD': 'New Taiwan dollar',
      'HKD': 'Hong Kong dollar',
      'MOP': 'Macanese pataca',
      'SAR': 'Saudi riyal',
      'AED': 'UAE dirham',
      'QAR': 'Qatari riyal',
      'KWD': 'Kuwaiti dinar',
      'BHD': 'Bahraini dinar',
      'OMR': 'Omani rial',
      'EGP': 'Egyptian pound',
      'JOD': 'Jordanian dinar',
      'IQD': 'Iraqi dinar',
      'MAD': 'Moroccan dirham',
      'DZD': 'Algerian dinar',
      'TND': 'Tunisian dinar',
      'LBP': 'Lebanese pound',
      'LYD': 'Libyan dinar',
      'INR': 'Indian rupee',
      'PKR': 'Pakistani rupee',
      'NGN': 'Nigerian naira',
      'PHP': 'Philippine peso',
      'KES': 'Kenyan shilling',
      'CDF': 'Congolese franc',
      'GNF': 'Guinean franc',
      'HTG': 'Haitian gourde',
      'MGA': 'Malagasy ariary',
      'SRD': 'Surinamese dollar',
      'TJS': 'Tajikistani somoni',
      'SDG': 'Sudanese pound',
      'YER': 'Yemeni rial',
      'SYP': 'Syrian pound',
      'MRU': 'Mauritanian ouguiya',
      'ILS': 'Israeli new shekel',
      'PLN': 'Polish złoty',
      'SEK': 'Swedish krona',
      'JPY': 'Japanese yen',
      'VND': 'Vietnamese dong',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Search currency';

  @override
  String get currencyNoMatch => 'No currency matches.';

  @override
  String get currencySuggested => 'Suggested';

  @override
  String get currencyAll => 'All currencies';

  @override
  String get currencyChangeTitle => 'Change currency';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Example: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'This currency uses a different number of decimals, so amounts are rounded.';

  @override
  String get currencyChangeConfirm => 'Change';

  @override
  String get settingsPay => 'Pay';

  @override
  String paySummaryMonthly(int day) {
    return 'Monthly, day $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Every two weeks, last payday $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Weekly, $weekday';
  }

  @override
  String get settingsNetIncome => 'Take-home pay';

  @override
  String get notSet => 'Not set';

  @override
  String get settingsTight => 'Tight period threshold';

  @override
  String get settingsTightHelp =>
      'A period counts as tight when what\'s left drops below this amount. Leave empty to turn it off.';

  @override
  String get off => 'Off';

  @override
  String get settingsSources => 'Sources and cards';

  @override
  String get settingsRoadmap => 'Roadmap';

  @override
  String get settingsPrivacy =>
      'Your data stays on this phone. No account, no bank connection, no ads.';

  @override
  String get settingsDebugPro => 'Pro (debug builds only)';

  @override
  String get settingsSaved => 'Saved.';

  @override
  String get roadmapEmpty => 'Nothing to share here yet.';

  @override
  String get roadmapError => 'Couldn\'t read the roadmap.';

  @override
  String get roadmapPlanned => 'Planned';

  @override
  String get roadmapInProgress => 'In progress';

  @override
  String get roadmapShipped => 'Shipped';

  @override
  String roadmapTarget(String version) {
    return 'Target version $version';
  }

  @override
  String get overdueBadge => 'Overdue';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get reminderChannelName => 'Payment reminders';

  @override
  String get reminderChannelDescription =>
      'Short reminders before a payment is due.';

  @override
  String get reminderPromptTitle => 'Reminders';

  @override
  String get reminderPromptBody =>
      'We\'ll let you know before a payment is due. Reminders are set up only on this phone.';

  @override
  String get reminderPromptAccept => 'Turn on reminders';

  @override
  String get reminderPromptLater => 'Not now';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get remindersEnabled => 'Reminders';

  @override
  String get reminderTime => 'Time';

  @override
  String get remindersPermissionOff => 'Notification permission is off';

  @override
  String get openPhoneSettings => 'Open settings';

  @override
  String get remindersHelpLink => 'Not getting reminders?';

  @override
  String get remindersHelpIntro =>
      'Your phone can hold reminders back. These are the usual reasons.';

  @override
  String get remindersHelpPermissionTitle => 'Notification permission';

  @override
  String get remindersHelpPermissionBody =>
      'Open phone settings, find Kalan and turn notifications on.';

  @override
  String get remindersHelpIosTitle => 'iPhone: Focus';

  @override
  String get remindersHelpIosBody =>
      'A Focus such as Do Not Disturb or Sleep can silence reminders. In Settings > Focus, choose the Focus and add Kalan under Allowed Apps.';

  @override
  String get remindersHelpAndroidTitle => 'Android: battery saving';

  @override
  String get remindersHelpAndroidBody =>
      'Battery saving can delay reminders. In Settings > Apps > Kalan > Battery, choose Unrestricted. Reminders may still arrive a few minutes late.';

  @override
  String get remindersWebOnly => 'This works on your phone.';

  @override
  String get debugTestNotification => 'Test notification (in 10 seconds)';

  @override
  String get testNotificationScheduled =>
      'A test notification arrives in 10 seconds.';

  @override
  String get testNotificationText => 'Test: reminders work on this phone.';

  @override
  String get remindersEnabledHint => 'Before a payment is due and on the day';

  @override
  String reminderAhead(int count, String date, String name, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments on $date, $total in total',
      one: '1 payment on $date: $name, $total',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadHidden(int count, String date, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments on $date',
      one: '1 payment on $date: $name',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadMixed(int count, String date, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments from $date, $total in total',
      one: '1 payment from $date, $total in total',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadMixedHidden(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments from $date',
      one: '1 payment from $date',
    );
    return '$_temp0';
  }

  @override
  String reminderToday(int count, String name, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments today, $total in total',
      one: '1 payment today: $name, $total',
    );
    return '$_temp0';
  }

  @override
  String reminderTodayHidden(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments today',
      one: '1 payment today: $name',
    );
    return '$_temp0';
  }

  @override
  String reminderExpanded(String body, String names) {
    return '$body\n$names';
  }

  @override
  String get reminderNameSeparator => ', ';

  @override
  String get reminderLeadDays => 'Days before';

  @override
  String reminderLeadDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String reminderLeadDaysSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Days before, now $_temp0';
  }

  @override
  String get reminderShowAmount => 'Show amount in notifications';

  @override
  String get planReminder => 'Reminder';

  @override
  String planReminderGeneral(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
    );
    return 'General setting ($_temp0)';
  }

  @override
  String get planReminderOff => 'Off';

  @override
  String get planReminderCustom => 'Different day';
}
