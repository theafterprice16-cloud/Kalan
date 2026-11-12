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

  /// No description provided for @currencyLira.
  ///
  /// In en, this message translates to:
  /// **'Turkish lira (TRY)'**
  String get currencyLira;

  /// No description provided for @currencyDollar.
  ///
  /// In en, this message translates to:
  /// **'US dollar (USD)'**
  String get currencyDollar;

  /// No description provided for @currencyPound.
  ///
  /// In en, this message translates to:
  /// **'British pound (GBP)'**
  String get currencyPound;

  /// No description provided for @currencyEuro.
  ///
  /// In en, this message translates to:
  /// **'Euro (EUR)'**
  String get currencyEuro;

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
  /// **'Enter the amount in numbers, like 1250.50.'**
  String get errorAmountInvalid;

  /// No description provided for @errorCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 120.'**
  String get errorCountInvalid;

  /// No description provided for @errorRemainingTooHigh.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be more than the total.'**
  String get errorRemainingTooHigh;

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

  /// No description provided for @homeOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get homeOverdueTitle;

  /// No description provided for @homeOverdueHelp.
  ///
  /// In en, this message translates to:
  /// **'The date has passed and these aren\'t marked as paid.'**
  String get homeOverdueHelp;

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

  /// No description provided for @planPaidOf.
  ///
  /// In en, this message translates to:
  /// **'{paid}/{count} paid'**
  String planPaidOf(int paid, int count);

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

  /// No description provided for @kindMidway.
  ///
  /// In en, this message translates to:
  /// **'Already started'**
  String get kindMidway;

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

  /// No description provided for @fieldTotalCount.
  ///
  /// In en, this message translates to:
  /// **'Total payments'**
  String get fieldTotalCount;

  /// No description provided for @fieldUnpaidCount.
  ///
  /// In en, this message translates to:
  /// **'Payments not yet paid'**
  String get fieldUnpaidCount;

  /// No description provided for @fieldInstallment.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get fieldInstallment;

  /// No description provided for @fieldNextDate.
  ///
  /// In en, this message translates to:
  /// **'Next payment date'**
  String get fieldNextDate;

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
  /// **'Amounts aren\'t converted. Only the currency changes.'**
  String get settingsCurrencyNote;

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
