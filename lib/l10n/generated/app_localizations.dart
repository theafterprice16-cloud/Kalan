import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kalan'**
  String get appTitle;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Snackbar action that takes back "paid". Calm, no judgement.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAddPlan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get actionAddPlan;

  /// No description provided for @actionMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get actionMoreDetails;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get navHome;

  /// No description provided for @navPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navPlans;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks'**
  String get frequencyBiweekly;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up in a minute.'**
  String get onboardingTitle;

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell Kalan when you get paid. Your data stays on this phone.'**
  String get onboardingIntro;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldPayFrequency.
  ///
  /// In en, this message translates to:
  /// **'How often do you get paid?'**
  String get fieldPayFrequency;

  /// No description provided for @fieldPayDay.
  ///
  /// In en, this message translates to:
  /// **'Payday'**
  String get fieldPayDay;

  /// No description provided for @payDayHelp.
  ///
  /// In en, this message translates to:
  /// **'In shorter months, the last day counts.'**
  String get payDayHelp;

  /// No description provided for @fieldLastPayday.
  ///
  /// In en, this message translates to:
  /// **'Last payday'**
  String get fieldLastPayday;

  /// No description provided for @fieldPayWeekday.
  ///
  /// In en, this message translates to:
  /// **'Payday'**
  String get fieldPayWeekday;

  /// No description provided for @fieldNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Take-home pay per paycheck'**
  String get fieldNetIncome;

  /// No description provided for @netIncomeHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Without it, I\'ll only show what\'s spoken for.'**
  String get netIncomeHelp;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorRequired;

  /// No description provided for @errorAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount in numbers, like {example}.'**
  String errorAmountInvalid(String example);

  /// No description provided for @errorCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 120.'**
  String get errorCountInvalid;

  /// No description provided for @errorTotalTooSmall.
  ///
  /// In en, this message translates to:
  /// **'This amount can\'t be split into that many payments.'**
  String get errorTotalTooSmall;

  /// No description provided for @errorDayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a day from 1 to 31.'**
  String get errorDayInvalid;

  /// No description provided for @errorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorNameRequired;

  /// No description provided for @errorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date can\'t be before the first date.'**
  String get errorEndBeforeStart;

  /// No description provided for @errorDeferInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 12.'**
  String get errorDeferInvalid;

  /// No description provided for @errorStepInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 365.'**
  String get errorStepInvalid;

  /// No description provided for @errorCardRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a card.'**
  String get errorCardRequired;

  /// No description provided for @homeLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get homeLeftLabel;

  /// No description provided for @homeSpokenForLabel.
  ///
  /// In en, this message translates to:
  /// **'Spoken for'**
  String get homeSpokenForLabel;

  /// No description provided for @homeIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get homeIncomeLabel;

  /// No description provided for @periodRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String periodRange(String start, String end);

  /// No description provided for @homeSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments this period.} =1{1 payment this period. Total {total}.} other{{count} payments this period. Total {total}.}}'**
  String homeSummary(int count, String total);

  /// No description provided for @homeTight.
  ///
  /// In en, this message translates to:
  /// **'Tight period. What\'s left is below your {threshold} threshold.'**
  String homeTight(String threshold);

  /// No description provided for @homeNegative.
  ///
  /// In en, this message translates to:
  /// **'This period is {amount} short.'**
  String homeNegative(String amount);

  /// No description provided for @homeNoIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'Add your take-home pay in Settings to see what\'s left.'**
  String get homeNoIncomeHint;

  /// No description provided for @homePaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'This period\'s payments'**
  String get homePaymentsTitle;

  /// No description provided for @homeBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Spoken for {spokenFor} of {income}.'**
  String homeBarLabel(String spokenFor, String income);

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'{seq}/{count}'**
  String progressLabel(int seq, int count);

  /// No description provided for @progressSemantics.
  ///
  /// In en, this message translates to:
  /// **'Payment {seq} of {count}'**
  String progressSemantics(int seq, int count);

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as not paid'**
  String get markAsUnpaid;

  /// No description provided for @markedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid.'**
  String get markedPaid;

  /// No description provided for @markedUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as not paid.'**
  String get markedUnpaid;

  /// No description provided for @recurringTag.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTag;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueTomorrow;

  /// No description provided for @plansTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get plansTabOpen;

  /// No description provided for @plansTabRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get plansTabRecurring;

  /// No description provided for @plansTabFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get plansTabFinished;

  /// No description provided for @plansEmptyOpen.
  ///
  /// In en, this message translates to:
  /// **'No open plans.'**
  String get plansEmptyOpen;

  /// No description provided for @plansEmptyFinished.
  ///
  /// In en, this message translates to:
  /// **'No finished plans yet. A plan moves here when every payment is paid.'**
  String get plansEmptyFinished;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring payments. You can add rent, bills or subscriptions.'**
  String get recurringEmpty;

  /// No description provided for @planToPay.
  ///
  /// In en, this message translates to:
  /// **'To pay {amount}'**
  String planToPay(String amount);

  /// No description provided for @planNext.
  ///
  /// In en, this message translates to:
  /// **'Next payment {date}'**
  String planNext(String date);

  /// No description provided for @planTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String planTotal(String amount);

  /// No description provided for @planPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchased {date}'**
  String planPurchaseDate(String date);

  /// No description provided for @planStartedMidway.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment was made before you added this plan.} other{{count} payments were made before you added this plan.}}'**
  String planStartedMidway(int count);

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'The free version holds up to {limit} open plans. You can add a new one when a plan finishes.'**
  String freeLimitReached(int limit);

  /// No description provided for @addRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add recurring payment'**
  String get addRecurring;

  /// No description provided for @kindPayIn4.
  ///
  /// In en, this message translates to:
  /// **'Pay in 4'**
  String get kindPayIn4;

  /// No description provided for @kindMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly installments'**
  String get kindMonthly;

  /// No description provided for @kindCard.
  ///
  /// In en, this message translates to:
  /// **'Card installments'**
  String get kindCard;

  /// No description provided for @kindManual.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get kindManual;

  /// No description provided for @kindCashAdvance.
  ///
  /// In en, this message translates to:
  /// **'Cash advance in installments'**
  String get kindCashAdvance;

  /// No description provided for @planPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get planPaymentsTitle;

  /// No description provided for @planDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get planDelete;

  /// No description provided for @planDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This plan and all its payments will be deleted.'**
  String get planDeleteConfirm;

  /// No description provided for @planDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted.'**
  String get planDeleted;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'This plan no longer exists.'**
  String get planNotFound;

  /// No description provided for @editPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get editPaymentTitle;

  /// No description provided for @editPaymentHelp.
  ///
  /// In en, this message translates to:
  /// **'The difference is spread over later payments. The plan total stays the same.'**
  String get editPaymentHelp;

  /// No description provided for @editRejectedPaid.
  ///
  /// In en, this message translates to:
  /// **'A paid payment can\'t be edited. Mark it as not paid first.'**
  String get editRejectedPaid;

  /// No description provided for @editRejectedNoAbsorbers.
  ///
  /// In en, this message translates to:
  /// **'There\'s no later payment to take the difference. You can still change the date.'**
  String get editRejectedNoAbsorbers;

  /// No description provided for @editRejectedAbsorber.
  ///
  /// In en, this message translates to:
  /// **'This change would bring a later payment to zero. Try a smaller change.'**
  String get editRejectedAbsorber;

  /// No description provided for @editedTag.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedTag;

  /// No description provided for @paymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment updated.'**
  String get paymentUpdated;

  /// No description provided for @paymentRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {amount}, {date}'**
  String paymentRowSemantics(String name, String amount, String date);

  /// No description provided for @addPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get addPlanTitle;

  /// No description provided for @addPlanTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan type'**
  String get addPlanTypeLabel;

  /// No description provided for @fieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fieldSource;

  /// No description provided for @fieldSourceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Klarna or your bank'**
  String get fieldSourceHint;

  /// No description provided for @fieldCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get fieldCard;

  /// No description provided for @fieldTotal.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get fieldTotal;

  /// No description provided for @fieldCount.
  ///
  /// In en, this message translates to:
  /// **'Number of payments'**
  String get fieldCount;

  /// No description provided for @fieldFirstDate.
  ///
  /// In en, this message translates to:
  /// **'First payment date'**
  String get fieldFirstDate;

  /// No description provided for @fieldPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get fieldPurchaseDate;

  /// No description provided for @fieldIntervalStep.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get fieldIntervalStep;

  /// No description provided for @fieldIntervalUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldIntervalUnit;

  /// No description provided for @unitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDays;

  /// No description provided for @unitWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get unitWeeks;

  /// No description provided for @unitMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get unitMonths;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get fieldTitle;

  /// No description provided for @fieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Phone'**
  String get fieldTitleHint;

  /// No description provided for @fieldDefer.
  ///
  /// In en, this message translates to:
  /// **'Defer first payment (months)'**
  String get fieldDefer;

  /// No description provided for @fieldCashAdvance.
  ///
  /// In en, this message translates to:
  /// **'Cash advance in installments'**
  String get fieldCashAdvance;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards yet.'**
  String get noCards;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get previewTitle;

  /// No description provided for @previewSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment, {total} in total.} other{{count} payments, {total} in total.}}'**
  String previewSummary(int count, String total);

  /// No description provided for @previewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fill in the fields to see the payments here.'**
  String get previewEmpty;

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan added.'**
  String get planSaved;

  /// No description provided for @fieldPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get fieldPaymentDate;

  /// No description provided for @sourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources and cards'**
  String get sourcesTitle;

  /// No description provided for @sourcesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sources yet. Sources you type while adding a plan appear here.'**
  String get sourcesEmpty;

  /// No description provided for @addSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSource;

  /// No description provided for @editSource.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get editSource;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldSourceKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldSourceKind;

  /// No description provided for @sourceKindProvider.
  ///
  /// In en, this message translates to:
  /// **'Pay later provider'**
  String get sourceKindProvider;

  /// No description provided for @sourceKindCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get sourceKindCard;

  /// No description provided for @fieldStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement date'**
  String get fieldStatementDay;

  /// No description provided for @statementDayHelp.
  ///
  /// In en, this message translates to:
  /// **'The day of the month your statement is cut.'**
  String get statementDayHelp;

  /// No description provided for @fieldDueDay.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get fieldDueDay;

  /// No description provided for @dueDayHelp.
  ///
  /// In en, this message translates to:
  /// **'The day of the month the statement must be paid.'**
  String get dueDayHelp;

  /// No description provided for @fieldShiftWeekend.
  ///
  /// In en, this message translates to:
  /// **'Move to the next business day if it falls on a weekend'**
  String get fieldShiftWeekend;

  /// No description provided for @cardDaysChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Changing these days moves the dates of unpaid, unedited payments on this card.'**
  String get cardDaysChangeNote;

  /// No description provided for @sourceInUse.
  ///
  /// In en, this message translates to:
  /// **'Plans use this source. Delete those plans first.'**
  String get sourceInUse;

  /// No description provided for @sourceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Source deleted.'**
  String get sourceDeleted;

  /// No description provided for @sourceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get sourceSaved;

  /// No description provided for @cardSummary.
  ///
  /// In en, this message translates to:
  /// **'Statement date {statement}, due date {due}'**
  String cardSummary(int statement, int due);

  /// No description provided for @recurringNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Add recurring payment'**
  String get recurringNewTitle;

  /// No description provided for @recurringEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring payment'**
  String get recurringEditTitle;

  /// No description provided for @fieldRecurringNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent'**
  String get fieldRecurringNameHint;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get fieldRecurrence;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks'**
  String get recurrenceBiweekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @fieldEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get fieldEndDate;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @clearEndDate.
  ///
  /// In en, this message translates to:
  /// **'Remove end date'**
  String get clearEndDate;

  /// No description provided for @recurringDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This recurring payment will be deleted.'**
  String get recurringDeleteConfirm;

  /// No description provided for @recurringDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring payment deleted.'**
  String get recurringDeleted;

  /// No description provided for @recurringSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get recurringSaved;

  /// No description provided for @recurringNext.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get recurringEnded;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'Amounts aren\'t converted; only the currency label changes.'**
  String get settingsCurrencyNote;

  /// Currency name by ISO code. Add a branch when adding a currency.
  ///
  /// In en, this message translates to:
  /// **'{code, select, TRY{Turkish lira} USD{US dollar} EUR{Euro} GBP{British pound} BRL{Brazilian real} MXN{Mexican peso} COP{Colombian peso} CLP{Chilean peso} RUB{Russian ruble} KZT{Kazakhstani tenge} CNY{Chinese yuan} SGD{Singapore dollar} MYR{Malaysian ringgit} IDR{Indonesian rupiah} CAD{Canadian dollar} AUD{Australian dollar} CHF{Swiss franc} NZD{New Zealand dollar} ZAR{South African rand} ARS{Argentine peso} PEN{Peruvian sol} UYU{Uruguayan peso} PYG{Paraguayan guaraní} BOB{Bolivian boliviano} VES{Venezuelan bolívar} CRC{Costa Rican colón} GTQ{Guatemalan quetzal} HNL{Honduran lempira} NIO{Nicaraguan córdoba} DOP{Dominican peso} PAB{Panamanian balboa} AOA{Angolan kwanza} MZN{Mozambican metical} XOF{West African CFA franc} XAF{Central African CFA franc} BYN{Belarusian ruble} KGS{Kyrgyzstani som} UZS{Uzbekistani som} TWD{New Taiwan dollar} HKD{Hong Kong dollar} MOP{Macanese pataca} SAR{Saudi riyal} AED{UAE dirham} QAR{Qatari riyal} KWD{Kuwaiti dinar} BHD{Bahraini dinar} OMR{Omani rial} EGP{Egyptian pound} JOD{Jordanian dinar} IQD{Iraqi dinar} MAD{Moroccan dirham} DZD{Algerian dinar} TND{Tunisian dinar} LBP{Lebanese pound} LYD{Libyan dinar} INR{Indian rupee} PKR{Pakistani rupee} NGN{Nigerian naira} PHP{Philippine peso} KES{Kenyan shilling} CDF{Congolese franc} GNF{Guinean franc} HTG{Haitian gourde} MGA{Malagasy ariary} SRD{Surinamese dollar} TJS{Tajikistani somoni} SDG{Sudanese pound} YER{Yemeni rial} SYP{Syrian pound} MRU{Mauritanian ouguiya} ILS{Israeli new shekel} PLN{Polish złoty} SEK{Swedish krona} JPY{Japanese yen} VND{Vietnamese dong} other{{code}}}'**
  String currencyName(String code);

  /// No description provided for @currencySearch.
  ///
  /// In en, this message translates to:
  /// **'Search currency'**
  String get currencySearch;

  /// No description provided for @currencyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No currency matches.'**
  String get currencyNoMatch;

  /// Currency picker section: currencies for the device region (or the app language).
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get currencySuggested;

  /// Currency picker section: every currency.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get currencyAll;

  /// No description provided for @currencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change currency'**
  String get currencyChangeTitle;

  /// No description provided for @currencyChangePreview.
  ///
  /// In en, this message translates to:
  /// **'Example: {before} → {after}'**
  String currencyChangePreview(String before, String after);

  /// No description provided for @currencyChangeRounding.
  ///
  /// In en, this message translates to:
  /// **'This currency uses a different number of decimals, so amounts are rounded.'**
  String get currencyChangeRounding;

  /// No description provided for @currencyChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get currencyChangeConfirm;

  /// No description provided for @settingsPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get settingsPay;

  /// No description provided for @paySummaryMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly, day {day}'**
  String paySummaryMonthly(int day);

  /// No description provided for @paySummaryBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks, last payday {date}'**
  String paySummaryBiweekly(String date);

  /// No description provided for @paySummaryWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly, {weekday}'**
  String paySummaryWeekly(String weekday);

  /// No description provided for @settingsNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Take-home pay'**
  String get settingsNetIncome;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @settingsTight.
  ///
  /// In en, this message translates to:
  /// **'Tight period threshold'**
  String get settingsTight;

  /// No description provided for @settingsTightHelp.
  ///
  /// In en, this message translates to:
  /// **'A period counts as tight when what\'s left drops below this amount. Leave empty to turn it off.'**
  String get settingsTightHelp;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @settingsSources.
  ///
  /// In en, this message translates to:
  /// **'Sources and cards'**
  String get settingsSources;

  /// No description provided for @settingsRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Roadmap'**
  String get settingsRoadmap;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this phone. No account, no bank connection, no ads.'**
  String get settingsPrivacy;

  /// No description provided for @settingsDebugPro.
  ///
  /// In en, this message translates to:
  /// **'Pro (debug builds only)'**
  String get settingsDebugPro;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get settingsSaved;

  /// No description provided for @roadmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to share here yet.'**
  String get roadmapEmpty;

  /// No description provided for @roadmapError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the roadmap.'**
  String get roadmapError;

  /// No description provided for @roadmapPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get roadmapPlanned;

  /// No description provided for @roadmapInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get roadmapInProgress;

  /// No description provided for @roadmapShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get roadmapShipped;

  /// No description provided for @roadmapTarget.
  ///
  /// In en, this message translates to:
  /// **'Target version {version}'**
  String roadmapTarget(String version);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Android notification channel name (system settings).
  ///
  /// In en, this message translates to:
  /// **'Payment reminders'**
  String get reminderChannelName;

  /// Android notification channel description (system settings).
  ///
  /// In en, this message translates to:
  /// **'Short reminders before a payment is due.'**
  String get reminderChannelDescription;

  /// Title of the permission sheet shown once after the first plan is saved.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderPromptTitle;

  /// Bottom sheet shown once after the first plan is saved, before the system permission dialog.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know before a payment is due. Reminders are set up only on this phone.'**
  String get reminderPromptBody;

  /// Permission sheet button; opens the system notification permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get reminderPromptAccept;

  /// Permission sheet button; closes the sheet, the app never asks again.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get reminderPromptLater;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// Settings > Reminders: the master switch. Off cancels every pending reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersEnabled;

  /// Settings > Reminders: the time reminders arrive (local time).
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// Settings > Reminders: calm status line when the system blocks Kalan's notifications.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off'**
  String get remindersPermissionOff;

  /// Button next to the permission status line; opens the phone's notification settings for Kalan.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openPhoneSettings;

  /// Settings > Reminders: opens the help page.
  ///
  /// In en, this message translates to:
  /// **'Not getting reminders?'**
  String get remindersHelpLink;

  /// Help page intro.
  ///
  /// In en, this message translates to:
  /// **'Your phone can hold reminders back. These are the usual reasons.'**
  String get remindersHelpIntro;

  /// Help page heading.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get remindersHelpPermissionTitle;

  /// Help page text.
  ///
  /// In en, this message translates to:
  /// **'Open phone settings, find Kalan and turn notifications on.'**
  String get remindersHelpPermissionBody;

  /// Help page heading (iPhone only).
  ///
  /// In en, this message translates to:
  /// **'iPhone: Focus'**
  String get remindersHelpIosTitle;

  /// Help page text (iPhone only).
  ///
  /// In en, this message translates to:
  /// **'A Focus such as Do Not Disturb or Sleep can silence reminders. In Settings > Focus, choose the Focus and add Kalan under Allowed Apps.'**
  String get remindersHelpIosBody;

  /// Help page heading (Android only).
  ///
  /// In en, this message translates to:
  /// **'Android: battery saving'**
  String get remindersHelpAndroidTitle;

  /// Help page text (Android only).
  ///
  /// In en, this message translates to:
  /// **'Battery saving can delay reminders. In Settings > Apps > Kalan > Battery, choose Unrestricted. Reminders may still arrive a few minutes late.'**
  String get remindersHelpAndroidBody;

  /// Settings > Reminders on the web build, where notifications are off.
  ///
  /// In en, this message translates to:
  /// **'This works on your phone.'**
  String get remindersWebOnly;

  /// Debug builds only: schedules a sample notification.
  ///
  /// In en, this message translates to:
  /// **'Test notification (in 10 seconds)'**
  String get debugTestNotification;

  /// Debug builds only: snackbar after the test button.
  ///
  /// In en, this message translates to:
  /// **'A test notification arrives in 10 seconds.'**
  String get testNotificationScheduled;

  /// Debug builds only: body of the sample notification.
  ///
  /// In en, this message translates to:
  /// **'Test: reminders work on this phone.'**
  String get testNotificationText;

  /// Notification button: marks the one payment in the reminder as paid. Shown on a small system button: keep it very short (1-2 words), calm, no exclamation mark; other languages may run longer, so prefer the shortest natural form.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get reminderActionPaid;

  /// Notification button on a reminder with several payments: marks all of them as paid. System button: keep it very short (1-2 words), calm, no exclamation mark.
  ///
  /// In en, this message translates to:
  /// **'All paid'**
  String get reminderActionAllPaid;

  /// Notification button on the on-the-day reminder: the same reminder again at 20:00 today. System button: keep it very short (1-2 words), calm.
  ///
  /// In en, this message translates to:
  /// **'Remind tonight'**
  String get reminderActionRemindTonight;

  /// Notification button on the days-before reminder: the same reminder again tomorrow at the same time. System button: keep it very short (1-2 words), calm.
  ///
  /// In en, this message translates to:
  /// **'Remind tomorrow'**
  String get reminderActionRemindTomorrow;

  /// Debug builds only: schedules the on-the-day reminder of the nearest unpaid payment, with its buttons.
  ///
  /// In en, this message translates to:
  /// **'Test reminder with buttons (in 10 seconds)'**
  String get debugTestReminderActions;

  /// Debug builds only: snackbar when there is no unpaid payment for the test reminder.
  ///
  /// In en, this message translates to:
  /// **'No unpaid payment to try it with.'**
  String get testReminderNoPayment;

  /// Subtitle under the master reminders switch.
  ///
  /// In en, this message translates to:
  /// **'Before a payment is due and on the day'**
  String get remindersEnabledHint;

  /// Notification body some days before payments due on one date. Amounts shown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment on {date}: {name}, {total}} other{{count} payments on {date}, {total} in total}}'**
  String reminderAhead(int count, String date, String name, String total);

  /// Same as reminderAhead with amounts hidden for lock-screen privacy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment on {date}: {name}} other{{count} payments on {date}}}'**
  String reminderAheadHidden(int count, String date, String name);

  /// Notification body when one early reminder gathers payments due on different dates (plans with different 'days before'). date is the earliest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment from {date}, {total} in total} other{{count} payments from {date}, {total} in total}}'**
  String reminderAheadMixed(int count, String date, String total);

  /// Same as reminderAheadMixed with amounts hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment from {date}} other{{count} payments from {date}}}'**
  String reminderAheadMixedHidden(int count, String date);

  /// Notification body on the due day. Amounts shown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment today: {name}, {total}} other{{count} payments today, {total} in total}}'**
  String reminderToday(int count, String name, String total);

  /// Same as reminderToday with amounts hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment today: {name}} other{{count} payments today}}'**
  String reminderTodayHidden(int count, String name);

  /// Expanded notification (Android big text, iOS long body): the body, then the plan names on a new line.
  ///
  /// In en, this message translates to:
  /// **'{body}\n{names}'**
  String reminderExpanded(String body, String names);

  /// Joins plan names in an expanded notification (a comma and a space).
  ///
  /// In en, this message translates to:
  /// **', '**
  String get reminderNameSeparator;

  /// Settings > Reminders: row that opens the 'days before' choice.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get reminderLeadDays;

  /// A 'days before' value (1, 2, 3, 5 or 7) in lists and subtitles.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day before} other{{days} days before}}'**
  String reminderLeadDaysValue(int days);

  /// Screen reader label of the 'days before' row.
  ///
  /// In en, this message translates to:
  /// **'Days before, now {days, plural, =1{1 day} other{{days} days}}'**
  String reminderLeadDaysSemantics(int days);

  /// Settings > Reminders switch; off hides amounts on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Show amount in notifications'**
  String get reminderShowAmount;

  /// Plan and recurring payment detail: row with this item's reminder choice.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get planReminder;

  /// Reminder choice that follows Settings; shows the current global days before.
  ///
  /// In en, this message translates to:
  /// **'General setting ({days, plural, =1{1 day before} other{{days} days before}})'**
  String planReminderGeneral(int days);

  /// Reminder choice: no reminders for this plan.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get planReminderOff;

  /// Reminder choice: this plan uses its own days before (picked next).
  ///
  /// In en, this message translates to:
  /// **'Different day'**
  String get planReminderCustom;

  /// Add/edit plan switch: the plan started before it was added to the app; earlier installments are counted as paid.
  ///
  /// In en, this message translates to:
  /// **'This plan is already underway'**
  String get underwayToggle;

  /// Muted help text under the 'already underway' switch.
  ///
  /// In en, this message translates to:
  /// **'No need to enter the installments you\'ve already paid.'**
  String get underwayHint;

  /// Field label: all installments of the plan, including paid ones.
  ///
  /// In en, this message translates to:
  /// **'Total installments'**
  String get fieldTotalInstallments;

  /// Field label: installments already paid before adding the plan.
  ///
  /// In en, this message translates to:
  /// **'Installments paid'**
  String get fieldPaidInstallments;

  /// Field label: the date of the next unpaid installment.
  ///
  /// In en, this message translates to:
  /// **'Next payment date'**
  String get fieldNextPaymentDate;

  /// Muted note under the next payment date of a card plan: the date was filled in from the card's statement and due days.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your card\'s statement date.'**
  String get underwayCardSuggested;

  /// Validation under 'Installments paid' when it equals or exceeds the total.
  ///
  /// In en, this message translates to:
  /// **'If every installment is paid, there\'s no need to add this plan.'**
  String get errorPaidAll;

  /// Validation under 'Installments paid' when empty or below 1.
  ///
  /// In en, this message translates to:
  /// **'Enter how many installments you\'ve paid, at least 1.'**
  String get errorPaidMin;

  /// Validation under 'Installments paid' when editing a plan: payments marked paid in the app cannot be counted.
  ///
  /// In en, this message translates to:
  /// **'{max, plural, =1{This can be at most 1 here.} other{This can be at most {max} here.}}'**
  String errorPaidMax(int max);

  /// Plan detail, one line above the payments: installments paid before the plan was added. 'Kalan' is the app name; do not translate it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 installment paid before Kalan} other{{count} installments paid before Kalan}} · {amount}'**
  String paidBeforeSummary(int count, String amount);

  /// Screen reader label of the plan progress (e.g. 3/10).
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total, plural, =1{1 installment} other{{total} installments}} paid'**
  String progressPaidOfSemantics(int paid, int total);

  /// Plan progress as on card statements (installments paid / all installments, e.g. 3/10), in the plan list and plan detail.
  ///
  /// In en, this message translates to:
  /// **'{paid}/{count} paid'**
  String planPaidOf(int paid, int count);

  /// A plain number for choice chips (e.g. installments paid: 1, 2, 3), formatted for the language.
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String numberValue(int value);

  /// Plan detail action and the title of the plan edit screen.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get planEdit;

  /// Snackbar after saving the plan edit screen.
  ///
  /// In en, this message translates to:
  /// **'Plan updated.'**
  String get planUpdated;

  /// Confirmation when lowering 'Installments paid' or switching 'already underway' off.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 installment will come back as unpaid.} other{{count} installments will come back as unpaid.}}'**
  String underwayRevert(int count);

  /// Button in the confirmation that brings installments back as unpaid.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get underwayRevertConfirm;

  /// Help under 'Total installments' on the plan edit screen.
  ///
  /// In en, this message translates to:
  /// **'The plan total stays the same; unpaid installments are split again.'**
  String get resizeHint;

  /// Validation under 'Total installments' when the new count would drop a paid installment.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{This can\'t be less than 1 here.} other{This can\'t be less than {min} here: paid installments stay.}}'**
  String errorCountMin(int min);

  /// Home, section title above unpaid payments whose due date has passed. Calm and non-judgmental: a fact, not a warning. No exclamation marks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 past-due payment} other{{count} past-due payments}}'**
  String pastDueTitle(int count);

  /// Note next to a clock icon: how many days ago the due date passed. Calm and non-judgmental: a fact, not a warning. No exclamation marks.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String pastDueDaysAgo(int days);

  /// Muted line under the past-due title when a payment comes from an earlier pay period. Calm and non-judgmental: a fact, not a warning. No exclamation marks.
  ///
  /// In en, this message translates to:
  /// **'Unpaid ones are deducted from this period\'s remaining amount.'**
  String get pastDueDeducted;

  /// Text button on a past-due row; opens 'When did you pay?'.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get pastDueMarkPaid;

  /// Expands the past-due section when it has more than 3 payments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Show all ({count})}}'**
  String pastDueShowAll(int count);

  /// Screen reader label of a past-due row. Calm and non-judgmental: a fact, not a warning. No exclamation marks.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{{plan}, {amount}, due 1 day ago} other{{plan}, {amount}, due {days} days ago}}'**
  String pastDueRowSemantics(String plan, String amount, int days);

  /// Title of the sheet shown when a past-due payment is marked paid.
  ///
  /// In en, this message translates to:
  /// **'When did you pay?'**
  String get paidWhenTitle;

  /// Option: the payment was made today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get paidWhenToday;

  /// Muted line under 'Today': the amount stays in the current pay period.
  ///
  /// In en, this message translates to:
  /// **'Stays in this period.'**
  String get paidWhenTodayHint;

  /// Option: it was paid on its due date.
  ///
  /// In en, this message translates to:
  /// **'On the due date, {date}'**
  String paidWhenOnDue(String date);

  /// Muted line under 'On the due date': the amount moves back to its own pay period.
  ///
  /// In en, this message translates to:
  /// **'Counted in that period.'**
  String get paidWhenOnDueHint;

  /// Repeat reminder after the due date, amounts shown. Not marked paid yet: the user may have paid and only not marked it, so it must not blame. Repeated reminders keep exactly the tone of the first one: calm, no blame, no urgency, no exclamation marks or capitals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment from {month, select, other{{date}}} isn\'t marked paid yet: {name}, {total}} other{{count} payments aren\'t marked paid yet, {total} in total}}'**
  String reminderOverdue(
    int count,
    String date,
    String month,
    String name,
    String total,
  );

  /// Same as reminderOverdue with amounts hidden. Repeated reminders keep exactly the tone of the first one: calm, no blame, no urgency, no exclamation marks or capitals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment from {month, select, other{{date}}} isn\'t marked paid yet: {name}} other{{count} payments aren\'t marked paid yet}}'**
  String reminderOverdueHidden(
    int count,
    String date,
    String month,
    String name,
  );

  /// Settings and plan detail: row for repeat reminders (reminding again until marked paid). Repeated reminders keep exactly the tone of the first one: calm, no blame, no urgency, no exclamation marks or capitals.
  ///
  /// In en, this message translates to:
  /// **'Repeat reminders'**
  String get repeatReminders;

  /// Repeat reminders choice: no repeats (the default).
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get repeatModeOff;

  /// Repeat reminders choice: on the days with a reminder, one more at 8 PM.
  ///
  /// In en, this message translates to:
  /// **'Once more in the evening'**
  String get repeatModeEvening;

  /// Repeat reminders choice: every day from the first reminder until marked paid, twice a day.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatModeDaily;

  /// Plan detail: repeat reminders follow Settings; shows the current global choice.
  ///
  /// In en, this message translates to:
  /// **'Default ({mode})'**
  String repeatModeGeneral(String mode);

  /// Muted help under the repeat reminders row. Repeated reminders keep exactly the tone of the first one: calm, no blame, no urgency, no exclamation marks or capitals.
  ///
  /// In en, this message translates to:
  /// **'Reminds you again at calm intervals until you mark it paid. Stops at most 7 days after the due date.'**
  String get repeatRemindersHelp;

  /// Muted line under repeat reminders when Every day is chosen.
  ///
  /// In en, this message translates to:
  /// **'At your reminder time and at {time}.'**
  String repeatDailyHint(String time);

  /// Screen reader label of the small repeat icon on a plan.
  ///
  /// In en, this message translates to:
  /// **'Repeat reminders on'**
  String get repeatRemindersOn;

  /// Debug builds only: three repeat reminders 1, 2 and 3 minutes later.
  ///
  /// In en, this message translates to:
  /// **'Repeat test (3 notifications, 1 minute apart)'**
  String get debugRepeatTest;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
