// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionUndo => 'Undo';

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
      'There\'s no later payment to take the difference, so this amount can\'t change on its own.';

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
  String get sourceKindAccount => 'Bank account';

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
  String get languageDraft => 'Draft';

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
  String get reminderActionPaid => 'Paid';

  @override
  String get reminderActionAllPaid => 'All paid';

  @override
  String get reminderActionRemindTonight => 'Remind tonight';

  @override
  String get reminderActionRemindTomorrow => 'Remind tomorrow';

  @override
  String get debugTestReminderActions =>
      'Test reminder with buttons (in 10 seconds)';

  @override
  String get testReminderNoPayment => 'No unpaid payment to try it with.';

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

  @override
  String get underwayToggle => 'This plan is already underway';

  @override
  String get underwayHint =>
      'No need to enter the installments you\'ve already paid.';

  @override
  String get fieldTotalInstallments => 'Total installments';

  @override
  String get fieldPaidInstallments => 'Installments paid';

  @override
  String get fieldNextPaymentDate => 'Next payment date';

  @override
  String get underwayCardSuggested =>
      'Suggested from your card\'s statement date.';

  @override
  String get errorPaidAll =>
      'If every installment is paid, there\'s no need to add this plan.';

  @override
  String get errorPaidMin =>
      'Enter how many installments you\'ve paid, at least 1.';

  @override
  String errorPaidMax(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'This can be at most $maxString here.',
      one: 'This can be at most 1 here.',
    );
    return '$_temp0';
  }

  @override
  String paidBeforeSummary(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString installments paid before Kalan',
      one: '1 installment paid before Kalan',
    );
    return '$_temp0 · $amount';
  }

  @override
  String progressPaidOfSemantics(int paid, int total) {
    final intl.NumberFormat paidNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String paidString = paidNumberFormat.format(paid);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalString installments',
      one: '1 installment',
    );
    return '$paidString of $_temp0 paid';
  }

  @override
  String planPaidOf(int paid, int count) {
    final intl.NumberFormat paidNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String paidString = paidNumberFormat.format(paid);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$paidString/$countString paid';
  }

  @override
  String numberValue(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString';
  }

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planUpdated => 'Plan updated.';

  @override
  String underwayRevert(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString installments will come back as unpaid.',
      one: '1 installment will come back as unpaid.',
    );
    return '$_temp0';
  }

  @override
  String get underwayRevertConfirm => 'Continue';

  @override
  String get resizeHint =>
      'The plan total stays the same; unpaid installments are split again.';

  @override
  String errorCountMin(int min) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);

    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other:
          'This can\'t be less than $minString here: paid installments stay.',
      one: 'This can\'t be less than 1 here.',
    );
    return '$_temp0';
  }

  @override
  String pastDueTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString past-due payments',
      one: '1 past-due payment',
    );
    return '$_temp0';
  }

  @override
  String pastDueDaysAgo(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get pastDueDeducted =>
      'Unpaid ones are deducted from this period\'s remaining amount.';

  @override
  String get pastDueMarkPaid => 'Paid';

  @override
  String pastDueShowAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show all ($countString)',
      one: 'Show all ($countString)',
    );
    return '$_temp0';
  }

  @override
  String pastDueRowSemantics(String plan, String amount, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$plan, $amount, due $daysString days ago',
      one: '$plan, $amount, due 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get paidWhenTitle => 'When did you pay?';

  @override
  String get paidWhenToday => 'Today';

  @override
  String get paidWhenTodayHint => 'Stays in this period.';

  @override
  String paidWhenOnDue(String date) {
    return 'On the due date, $date';
  }

  @override
  String get paidWhenOnDueHint => 'Counted in that period.';

  @override
  String reminderOverdue(
    int count,
    String date,
    String month,
    String name,
    String total,
  ) {
    String _temp0 = intl.Intl.selectLogic(month, {'other': '$date'});
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments aren\'t marked paid yet, $total in total',
      one: '1 payment from $_temp0 isn\'t marked paid yet: $name, $total',
    );
    return '$_temp1';
  }

  @override
  String reminderOverdueHidden(
    int count,
    String date,
    String month,
    String name,
  ) {
    String _temp0 = intl.Intl.selectLogic(month, {'other': '$date'});
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments aren\'t marked paid yet',
      one: '1 payment from $_temp0 isn\'t marked paid yet: $name',
    );
    return '$_temp1';
  }

  @override
  String get repeatReminders => 'Repeat reminders';

  @override
  String get repeatModeOff => 'Off';

  @override
  String get repeatModeEvening => 'Once more in the evening';

  @override
  String get repeatModeDaily => 'Every day';

  @override
  String repeatModeGeneral(String mode) {
    return 'Default ($mode)';
  }

  @override
  String get repeatRemindersHelp =>
      'Reminds you again at calm intervals until you mark it paid. Stops at most 7 days after the due date.';

  @override
  String repeatDailyHint(String time) {
    return 'At your reminder time and at $time.';
  }

  @override
  String get repeatRemindersOn => 'Repeat reminders on';

  @override
  String get debugRepeatTest => 'Repeat test (3 notifications, 1 minute apart)';

  @override
  String get kindPayLater => 'Pay later';

  @override
  String get kindPayLaterHint => 'One payment, on a set day';

  @override
  String get payLaterAmount => 'Amount';

  @override
  String get payLaterStore => 'Store name (optional)';

  @override
  String get payLaterSource => 'Source (optional)';

  @override
  String get payLaterWhen => 'When will you pay?';

  @override
  String payLaterDaysChip(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get payLaterNextMonthChip => 'Next month on day …';

  @override
  String payLaterNextMonthDay(int day) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);

    return 'Next month on day $dayString';
  }

  @override
  String get payLaterCustomDays => 'Number of days';

  @override
  String get payLaterDayOfMonth => 'Day of the month';

  @override
  String get payLaterPickDate => 'Pick a date';

  @override
  String get payLaterDueDate => 'Due date';

  @override
  String get payLaterPurchaseDate => 'Purchase date';

  @override
  String get payLaterToday => 'Today';

  @override
  String payLaterDueOn(String date) {
    return 'Due on $date';
  }

  @override
  String payLaterDaysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $daysString days',
      one: 'In 1 day',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String payLaterAutoName(String date) {
    return 'Pay later · $date';
  }

  @override
  String payLaterRuleDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days later',
      one: '1 day later',
    );
    return '$_temp0';
  }

  @override
  String get payLaterRuleChosen => 'Chosen date';

  @override
  String payLaterRuleLine(String rule) {
    return 'When to pay: $rule';
  }

  @override
  String get errorPayLaterDays => 'Number of days must be between 1 and 180.';

  @override
  String get errorPayLaterDay => 'Day must be between 1 and 31.';

  @override
  String payLaterSourceLine(String name) {
    return 'Source: $name';
  }

  @override
  String get fieldPaymentInterval => 'Payment interval';

  @override
  String get intervalSameDay => 'Same day each month';

  @override
  String get intervalEvery30Days => 'Every 30 days';

  @override
  String get intervalBiweekly => 'Every 2 weeks';

  @override
  String get intervalWeekly => 'Every week';

  @override
  String get intervalCustom => 'Other';

  @override
  String get fieldIntervalDays => 'Days between payments';

  @override
  String previewSameMonth(String months) {
    return 'Months with more than one payment: $months.';
  }

  @override
  String previewSameMonthItem(String month, int count) {
    return '$month ($count)';
  }

  @override
  String get previewMonthSeparator => ', ';

  @override
  String get intervalEditHint => 'Only unpaid installments get new dates.';

  @override
  String get amountEntryLabel => 'Which amount do you know?';

  @override
  String get amountEntryTotal => 'Total';

  @override
  String get amountEntryInstallment => 'Installment';

  @override
  String get fieldInstallmentAmount => 'Installment amount';

  @override
  String amountComputedInstallment(String amount) {
    return 'Installment $amount · calculated';
  }

  @override
  String amountComputedSplit(int count, String first, String others) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'First installment $first, the other $countString $others each · calculated',
      one: 'First installment $first, the other one $others · calculated',
    );
    return '$_temp0';
  }

  @override
  String amountComputedTotal(String amount) {
    return 'Total $amount · calculated';
  }

  @override
  String get errorAmountTooLarge => 'This amount is too large.';

  @override
  String get errorTotalTooLarge =>
      'The total gets too large. Lower the installment or the number of payments.';

  @override
  String reminderWithNote(String body, String note) {
    return '$body. $note';
  }

  @override
  String reminderNoteAutomatic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'They\'re taken automatically; keep the amount in your account.',
      one: 'It\'s taken automatically; keep the amount in your account.',
    );
    return '$_temp0';
  }

  @override
  String reminderNoteManual(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You make these payments yourself.',
      one: 'You make this payment yourself.',
    );
    return '$_temp0';
  }

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get paymentMethodAutomatic => 'Taken automatically';

  @override
  String get paymentMethodManual => 'Paid manually';

  @override
  String get paymentMethodNotSet => 'Not set';

  @override
  String get paymentMethodAutomaticHint =>
      'Reminders tell you to keep the amount in your account.';

  @override
  String get paymentMethodManualHint =>
      'Reminders come a day earlier, so there\'s time to go and pay.';

  @override
  String get chargeSourceLabel => 'Taken from';

  @override
  String get chargeSourceNone => 'Not chosen';

  @override
  String paymentMethodFrom(String method, String source) {
    return '$method · $source';
  }

  @override
  String reminderPayday(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'A new pay period has started. $count payments this period, $total in total.',
      one:
          'A new pay period has started. 1 payment this period, $total in total.',
      zero: 'A new pay period has started. No payments this period.',
    );
    return '$_temp0';
  }

  @override
  String reminderPaydayHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A new pay period has started. $count payments this period.',
      one: 'A new pay period has started. 1 payment this period.',
      zero: 'A new pay period has started. No payments this period.',
    );
    return '$_temp0';
  }

  @override
  String reminderPaydayLeft(String body, String left) {
    return '$body $left left.';
  }

  @override
  String reminderPaydayShort(String body, String amount) {
    return '$body This period is $amount short.';
  }

  @override
  String get reminderPaydayToggle => 'Payday summary';

  @override
  String get reminderPaydayToggleHint =>
      'On payday, at your reminder time: this period\'s payments, total and what\'s left.';

  @override
  String get proTitle => 'Kalan Pro';

  @override
  String proIntro(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'The free version keeps up to $limit open plans. Pro removes the limit and adds:',
      one: 'The free version keeps up to 1 open plan. Pro removes the limit and adds:',
    );
    return '$_temp0';
  }

  @override
  String get proFeatureUnlimitedPlans => 'Unlimited open plans';

  @override
  String proPriceLine(String price) {
    return '$price · pay once. No subscription, nothing renews.';
  }

  @override
  String get proPriceUnavailable => 'The price couldn\'t be loaded right now.';

  @override
  String get proRetry => 'Try again';

  @override
  String get proBuy => 'Get Pro';

  @override
  String get proRestore => 'Restore purchase';

  @override
  String get proActive => 'Pro is on. Thank you.';

  @override
  String get proPending =>
      'The payment is waiting for approval. Pro turns on once it\'s approved.';

  @override
  String get proTurnedOn => 'Pro is on.';

  @override
  String get proRestoreNotFound =>
      'No Pro purchase found on this store account.';

  @override
  String get proStoreUnreachable =>
      'Couldn\'t reach the store right now. Try again later.';

  @override
  String get proPurchaseFailed =>
      'The purchase didn\'t go through. Try again later.';

  @override
  String get settingsProFree => 'Free';

  @override
  String get settingsProOn => 'Pro';

  @override
  String get settingsProPending => 'Waiting for approval';

  @override
  String limitSheetBody(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'The free version keeps up to $limit open plans. You can add a new one when a plan finishes, or with Pro.',
      one: 'The free version keeps up to 1 open plan. You can add a new one when a plan finishes, or with Pro.',
    );
    return '$_temp0';
  }

  @override
  String get limitSheetSeePro => 'See Pro';

  @override
  String get limitSheetNotNow => 'Not now';

  @override
  String get comingPeriodsTitle => 'Coming pay periods';

  @override
  String comingPeriodsSummary(int count, String total, String left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments this period. $total in total. $left left.',
      one: '1 payment this period. $total in total. $left left.',
      zero: 'No payments this period. $left left.',
    );
    return '$_temp0';
  }

  @override
  String comingPeriodsSummaryNoLeft(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments this period. $total in total.',
      one: '1 payment this period. $total in total.',
      zero: 'No payments this period.',
    );
    return '$_temp0';
  }

  @override
  String comingPeriodsShort(String amount) {
    return '$amount short';
  }

  @override
  String get comingPeriodsIncomeInvite =>
      'Add your income to see what\'s left in each period.';

  @override
  String comingPeriodsEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No payments in the next $count pay periods.',
      one: 'No payments in the next pay period.',
    );
    return '$_temp0';
  }

  @override
  String comingPeriodsBarLabel(String range, String spokenFor, String left) {
    return '$range: $spokenFor spoken for, $left left.';
  }

  @override
  String comingPeriodsBarLabelNoIncome(String range, String spokenFor) {
    return '$range: $spokenFor spoken for.';
  }

  @override
  String comingPeriodsShortAhead(String amount) {
    return 'This period looks $amount short.';
  }

  @override
  String comingPeriodsBarLabelShortNow(
    String range,
    String spokenFor,
    String amount,
  ) {
    return '$range: $spokenFor spoken for, $amount short.';
  }

  @override
  String comingPeriodsBarLabelShortAhead(
    String range,
    String spokenFor,
    String amount,
  ) {
    return '$range: $spokenFor spoken for, looks $amount short.';
  }

  @override
  String get comingViewLabel => 'View';

  @override
  String get comingViewChart => 'Chart';

  @override
  String get comingViewCalendar => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarDayTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String get calendarPayday => 'Payday';

  @override
  String get calendarNoPayments => 'No payments on this day.';

  @override
  String calendarCellPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
      zero: 'No payments',
    );
    return '$_temp0';
  }

  @override
  String get calendarCellAllLate => 'late';

  @override
  String calendarCellSomeLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late',
      one: '$count late',
    );
    return '$_temp0';
  }

  @override
  String get calendarCellAllPaid => 'paid';

  @override
  String calendarCellSomePaid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paid',
      one: '$count paid',
    );
    return '$_temp0';
  }

  @override
  String get calendarCellPayday => 'payday';

  @override
  String get calendarCellToday => 'today';

  @override
  String get busyWeekTag => 'busy';

  @override
  String busyWeekSummary(String range, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Busy week: $range · $count payments · $amount',
      one: 'Busy week: $range · 1 payment · $amount',
    );
    return '$_temp0';
  }

  @override
  String busyWeekRangeSameMonth(String month, String startDay, String endDay) {
    return '$month $startDay–$endDay';
  }

  @override
  String get calendarCellBusyWeek => 'busy week';

  @override
  String get cardStatementsTitle => 'Statements';

  @override
  String cardStatementTitle(String date) {
    return '$date statement';
  }

  @override
  String get cardStatementClosed => 'Closed';

  @override
  String cardStatementCountDue(int count, String date) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString installments',
      one: '1 installment',
    );
    return '$_temp0 · Due $date';
  }

  @override
  String cardStatementEmptyDue(String date) {
    return 'No installments · Due $date';
  }

  @override
  String get cardStatementsNote => 'Only installments you added to Kalan.';

  @override
  String cardStatementCutOn(String date) {
    return 'Statement date $date';
  }

  @override
  String cardStatementDueOn(String date) {
    return 'Due $date';
  }

  @override
  String cardStatementCountTotal(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString installments',
      one: '1 installment',
    );
    return '$_temp0 · $amount';
  }

  @override
  String get cardStatementEmpty => 'No installments';

  @override
  String get cardStatementNotComing =>
      'This statement is not among your card\'s coming statements.';

  @override
  String get statementReminderToggle => 'Statement closing reminder';

  @override
  String get statementReminderToggleHint =>
      'A notification before the statement date, at your reminder time.';

  @override
  String get statementReminderDays => 'Days before';

  @override
  String reminderStatementClosing(
    int days,
    String card,
    String date,
    String next,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Your $card statement closes in $days days, on $date. Installments after that go on the $next statement.',
      one:
          'Your $card statement closes in 1 day, on $date. Installments after that go on the $next statement.',
    );
    return '$_temp0';
  }

  @override
  String get chargeTitleAccount => 'Keep in account';

  @override
  String get chargeTitleCard => 'Coming to this card';

  @override
  String get chargeTitleProvider => 'Coming out of this source';

  @override
  String chargeNext(String date, String amount) {
    return 'Next withdrawal: $date · $amount';
  }

  @override
  String chargeBy(String date, String amount) {
    return 'By $date · $amount';
  }

  @override
  String chargeByDate(String date) {
    return 'By $date';
  }

  @override
  String chargePaidOn(String date) {
    return '$date · paid';
  }

  @override
  String get chargePastDue => 'Includes a payment past its due date';

  @override
  String get chargeDetails => 'Details';

  @override
  String get chargeNextPeriod => 'Next period';

  @override
  String get chargeEmpty =>
      'No automatic payments to come out of this source this period.';

  @override
  String get chargeNextEmpty =>
      'No automatic payments from this source next period.';

  @override
  String get chargeUnassignedTitle => 'Automatic payments without a source';

  @override
  String chargeUnassignedRow(String date, String amount) {
    return 'Next: $date · $amount';
  }

  @override
  String get chargeUnassignedNote =>
      'You can choose where each is taken from in its plan details.';

  @override
  String reminderNoteAccount(String account, String amount) {
    return 'It\'s taken automatically. Keep $amount in $account.';
  }

  @override
  String get refundAction => 'Return or cancellation';

  @override
  String get holdOption => 'Put on hold';

  @override
  String get holdOptionHint =>
      'While you wait for a return, cancellation or dispute, remaining payments are left out.';

  @override
  String get reopenOption => 'Reopen';

  @override
  String get reopenOptionHint =>
      'Remaining payments come back on their own dates.';

  @override
  String get adjustOption => 'Adjust amount';

  @override
  String get adjustOptionHint =>
      'If you returned part of it, remaining payments are split to match the new total.';

  @override
  String get closeOption => 'Close';

  @override
  String get closeOptionHint =>
      'The plan moves to the archive. What you paid stays in your history.';

  @override
  String get planOnHold => 'On hold';

  @override
  String planOnHoldNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments on hold, left out of totals and reminders.',
      one: '1 payment on hold, left out of totals and reminders.',
    );
    return '$_temp0';
  }

  @override
  String get holdCheckTitle => 'Still waiting on the return?';

  @override
  String holdCheckSince(String date) {
    return 'On hold since $date.';
  }

  @override
  String get keepOnHold => 'Keep on hold';

  @override
  String passedWhileHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments\' dates passed while they were on hold. If you paid them, you can mark them.',
      one: '1 payment\'s date passed while it was on hold. If you paid it, you can mark it.',
    );
    return '$_temp0';
  }

  @override
  String get planHeldDone => 'Plan is on hold.';

  @override
  String get planReopenedDone => 'Plan reopened.';

  @override
  String get planClosedDone => 'Plan closed.';

  @override
  String get planKeptOnHold => 'Plan stays on hold.';

  @override
  String get amountAdjustedDone => 'Amount adjusted.';

  @override
  String get closeTitle => 'Close plan';

  @override
  String get closeBody =>
      'Unpaid payments leave your totals and reminders. What you paid stays in your history. A closed plan can\'t be reopened.';

  @override
  String get closeReasonTitle => 'Reason';

  @override
  String get closeReasonRefund => 'Return';

  @override
  String get closeReasonCancel => 'Cancellation';

  @override
  String closedWithReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'refund': 'Closed · Return',
      'other': 'Closed · Cancellation',
    });
    return '$_temp0';
  }

  @override
  String planPaidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String get adjustNewTotal => 'New total';

  @override
  String adjustCurrentTotal(String amount) {
    return 'Current total $amount';
  }

  @override
  String adjustPaidSoFar(String amount) {
    return 'You\'ve paid $amount';
  }

  @override
  String get adjustHint =>
      'Paid payments don\'t change. What\'s left is split evenly across unpaid payments; dates stay the same.';

  @override
  String get adjustPreviewTitle => 'New payments';

  @override
  String adjustBelowPaid(String amount) {
    return 'The new total can\'t be less than what you\'ve paid ($amount).';
  }

  @override
  String adjustAboveTotal(String amount) {
    return 'The new total can\'t be more than the current total ($amount).';
  }

  @override
  String get adjustUnchanged => 'That\'s the current total.';

  @override
  String adjustCannotSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This amount can\'t be split into $count payments.',
      one: 'This amount can\'t be split into 1 payment.',
    );
    return '$_temp0';
  }

  @override
  String get adjustNothingLeft =>
      'No payments would be left. Do you want to close the plan?';

  @override
  String paymentActionsTitle(String position, String date) {
    return '$position · $date';
  }

  @override
  String get changeDateAction => 'Change date';

  @override
  String get changeDateActionHint =>
      'Record the new date your provider gave you.';

  @override
  String get editPaymentActionHint =>
      'Fix the amount. The difference is spread over later payments.';

  @override
  String changeDateCurrent(String date) {
    return 'Current date: $date';
  }

  @override
  String get changeDateNewDate => 'New date';

  @override
  String get changeDatePickNew => 'Pick a new date.';

  @override
  String get changeDateShiftLater => 'Move later payments too';

  @override
  String get changeDatePreviewTitle => 'Effect on your pay periods';

  @override
  String changeDateLeftUp(String amount) {
    return 'Left +$amount';
  }

  @override
  String changeDateLeftDown(String amount) {
    return 'Left −$amount';
  }

  @override
  String changeDateCommittedUp(String amount) {
    return 'Committed +$amount';
  }

  @override
  String changeDateCommittedDown(String amount) {
    return 'Committed −$amount';
  }

  @override
  String changeDateLeftUpSemantics(String amount) {
    return 'Left goes up by $amount';
  }

  @override
  String changeDateLeftDownSemantics(String amount) {
    return 'Left goes down by $amount';
  }

  @override
  String changeDateCommittedUpSemantics(String amount) {
    return 'Committed goes up by $amount';
  }

  @override
  String changeDateCommittedDownSemantics(String amount) {
    return 'Committed goes down by $amount';
  }

  @override
  String get changeDateSamePeriod =>
      'Same period; what\'s left stays the same.';

  @override
  String get changeDateSamePeriodCommitted =>
      'Same period; what\'s committed stays the same.';

  @override
  String changeDateMorePeriods(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more periods',
      one: 'and 1 more period',
    );
    return '$_temp0';
  }

  @override
  String get changeDatePassesNext => 'This date is after the next payment.';

  @override
  String get changeDateLaterBeforeToday =>
      'A later payment would fall before today. You can turn the switch off or pick another date.';

  @override
  String get changeDateDone => 'Date saved.';

  @override
  String moveNoteLater(String date) {
    return 'Moved later · originally $date';
  }

  @override
  String moveNoteEarlier(String date) {
    return 'Moved earlier · originally $date';
  }

  @override
  String get changeDateNotAvailable =>
      'This payment\'s date can\'t be changed here any more.';

  @override
  String get extraFeeAdd => 'Add extra fee';

  @override
  String get extraFeeEdit => 'Edit extra fee';

  @override
  String get extraFeeAddHint => 'Record a fee your provider added.';

  @override
  String extraFeeLine(String amount) {
    return 'Extra fee: $amount';
  }

  @override
  String extraFeesTotal(String amount) {
    return 'Extra fees: $amount';
  }

  @override
  String extraFeeRowNote(String amount) {
    return '+ $amount extra fee';
  }

  @override
  String get extraFeeSheetTitle => 'Extra fee';

  @override
  String get extraFeeSheetHint =>
      'Kalan doesn\'t calculate fees. Enter the amount from your provider; it counts in the same period as the payment.';

  @override
  String get extraFeeNoteLabel => 'Note (optional)';

  @override
  String get extraFeeSaved => 'Extra fee saved.';

  @override
  String get extraFeeRemoved => 'Extra fee removed.';

  @override
  String get extraFeeNotAllowed =>
      'An extra fee can\'t be added to this payment.';

  @override
  String extraFeeNoteTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'The note can be up to $maxString characters.',
      one: 'The note can be up to 1 character.',
    );
    return '$_temp0';
  }

  @override
  String pastDueRowFeeSemantics(
    String plan,
    String amount,
    String fee,
    int days,
  ) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$plan, $amount, plus $fee extra fee, due $daysString days ago',
      one: '$plan, $amount, plus $fee extra fee, due 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get installmentFeeLabel => 'Fee per payment';

  @override
  String get installmentFeeHelper =>
      'A fixed fee your provider charges with payments. Leave empty for none.';

  @override
  String get installmentFeeScopeLabel => 'Charged on';

  @override
  String get installmentFeeScopeEvery => 'On every payment';

  @override
  String get installmentFeeScopeFirst => 'First payment only';

  @override
  String installmentFeeIncluded(String fee) {
    return 'Includes $fee payment fee';
  }

  @override
  String get planAmountLabel => 'Plan amount';

  @override
  String get installmentFeesLabel => 'Payment fees';

  @override
  String get planTotalLabel => 'Total you repay';

  @override
  String installmentFeeAffects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This changes $count unpaid payments.',
      one: 'This changes 1 unpaid payment.',
    );
    return '$_temp0';
  }

  @override
  String get installmentFeeFirstPaid =>
      'The first payment is already paid, so no fee is added.';

  @override
  String get moreOptions => 'More options';

  @override
  String installmentFeeOnTop(String fee) {
    return 'The $fee payment fee is added on top.';
  }

  @override
  String adjustFeesStay(String fees) {
    return 'Payment fees ($fees) stay the same.';
  }

  @override
  String get productPriceLabel => 'Product price';

  @override
  String get productPriceHelper => 'What you\'d have paid up front.';

  @override
  String get priceDifferenceLabel => 'Difference';

  @override
  String get providerStartTitle => 'Start from a provider';

  @override
  String get providerStartHint =>
      'Fills the number of payments and the dates; you can change all of them.';

  @override
  String providerVariantSameDay(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString payments · monthly',
      one: '1 payment · monthly',
    );
    return '$_temp0';
  }

  @override
  String providerVariantEveryDays(int count, int days) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString payments',
      one: '1 payment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'every $daysString days',
      one: 'every day',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String providerVariantBiweekly(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString payments · every 2 weeks',
      one: '1 payment · every 2 weeks',
    );
    return '$_temp0';
  }

  @override
  String providerVariantPayLaterDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'One payment · $daysString days later',
      one: 'One payment · 1 day later',
    );
    return '$_temp0';
  }

  @override
  String providerVariantPayLaterNextMonth(int day) {
    return 'One payment · next month on day $day';
  }

  @override
  String providerVariantOptions(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString options',
      one: '1 option',
    );
    return '$_temp0';
  }

  @override
  String providerTemplateNote(String provider, String date) {
    return 'Starting values for $provider · Last checked: $date. Change them if your terms differ.';
  }

  @override
  String get fieldShiftHolidays => 'Move for public holidays';

  @override
  String holidayListUntil(int year) {
    return 'Holiday list covers up to the end of $year. App updates renew it.';
  }

  @override
  String get holidayNoCountry =>
      'No holiday country chosen. You can pick one in Settings.';

  @override
  String get holidayMovedNote => 'Moved for a public holiday';

  @override
  String get settingsHolidayCountry => 'Holiday country';

  @override
  String get holidayCountryNone => 'None';

  @override
  String get holidayCountryNote =>
      'Card installment due dates move for this country\'s weekend and public holidays.';

  @override
  String holidayCountryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AR': 'Argentina',
      'BR': 'Brazil',
      'CA': 'Canada',
      'CH': 'Switzerland',
      'CL': 'Chile',
      'CN': 'China',
      'CO': 'Colombia',
      'DE': 'Germany',
      'ES': 'Spain',
      'FR': 'France',
      'GB': 'United Kingdom',
      'ID': 'Indonesia',
      'IT': 'Italy',
      'JP': 'Japan',
      'MX': 'Mexico',
      'NL': 'Netherlands',
      'PL': 'Poland',
      'PT': 'Portugal',
      'RU': 'Russia',
      'SE': 'Sweden',
      'TR': 'Türkiye',
      'TW': 'Taiwan',
      'US': 'United States',
      'VN': 'Vietnam',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'Kalan asks for your face, fingerprint or phone passcode when it opens.';

  @override
  String get appLockRelock => 'Lock again';

  @override
  String get appLockRelockHelp =>
      'Kalan locks again once it has been in the background this long.';

  @override
  String get appLockRelockImmediately => 'Immediately';

  @override
  String get appLockAmountsVisible =>
      'Amounts show in notifications. Tap to hide them.';

  @override
  String get appLockNeedsScreenLock =>
      'This needs a screen lock on your phone.';

  @override
  String get appLockTurnedOff =>
      'App lock was turned off because your phone has no screen lock.';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockReason => 'Confirm it\'s you to open Kalan.';

  @override
  String get appLockEnableReason => 'Confirm it\'s you to turn on app lock.';

  @override
  String get appLockPromptTitle => 'Unlock Kalan';

  @override
  String get appLockPromptHint => 'Face, fingerprint or phone passcode';

  @override
  String get appLockFaceIdUsage =>
      'To confirm it\'s you when Kalan opens. Your face data stays on your phone; Kalan never sees it.';

  @override
  String appLockRelockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'After $minutes minutes',
      one: 'After 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get appLockTurnedOffUnavailable =>
      'App lock was turned off because your phone couldn\'t check it\'s you just now. You can turn it on again.';

  @override
  String get appLockEnablePromptTitle => 'Turn on app lock';

  @override
  String get amountsHide => 'Hide amounts';

  @override
  String get amountsShow => 'Show amounts';

  @override
  String get amountsHideHint =>
      'Amounts are hidden on screens and in notifications, but not while you type one.';

  @override
  String get amountHidden => 'Amount hidden';
}
