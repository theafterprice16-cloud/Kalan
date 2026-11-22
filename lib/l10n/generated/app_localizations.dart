import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('de', 'CH'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('es', '419'),
    Locale('fr'),
    Locale('fr', 'CA'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('pt', 'PT'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
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
  /// **'There\'s no later payment to take the difference, so this amount can\'t change on its own.'**
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

  /// Source type: a bank account automatic payments are taken from (for example a salary account). Kalan never connects to it and never asks for its balance.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get sourceKindAccount;

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

  /// Small muted note beside a language in the language picker whose translation has not yet been read by a native speaker. One word.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get languageDraft;

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
  /// **'{count, plural, one{Show all ({count})} other{Show all ({count})}}'**
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

  /// Plan type: one payment on a set day after the purchase. 'Pay later' is a general way of paying (buy now, pay once later), not a company or brand name.
  ///
  /// In en, this message translates to:
  /// **'Pay later'**
  String get kindPayLater;

  /// Muted line under the plan types when 'Pay later' is chosen. 'Pay later' is a general way of paying (buy now, pay once later), not a company or brand name.
  ///
  /// In en, this message translates to:
  /// **'One payment, on a set day'**
  String get kindPayLaterHint;

  /// Pay later form: the amount to pay (required).
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get payLaterAmount;

  /// Pay later form: where the purchase was made; may be left empty.
  ///
  /// In en, this message translates to:
  /// **'Store name (optional)'**
  String get payLaterStore;

  /// Pay later form: who it is paid to or with (provider or card), for information only.
  ///
  /// In en, this message translates to:
  /// **'Source (optional)'**
  String get payLaterSource;

  /// Pay later form: title of the due date choices.
  ///
  /// In en, this message translates to:
  /// **'When will you pay?'**
  String get payLaterWhen;

  /// Pay later choice chip: the due date is the purchase date plus this many days (14 or 30).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String payLaterDaysChip(int days);

  /// Pay later choice chip before a day is entered: a given day of the next month.
  ///
  /// In en, this message translates to:
  /// **'Next month on day …'**
  String get payLaterNextMonthChip;

  /// Pay later rule: the given day of the month after the purchase (the month's last day when shorter). Written without an ending on the number on purpose.
  ///
  /// In en, this message translates to:
  /// **'Next month on day {day}'**
  String payLaterNextMonthDay(int day);

  /// Pay later choice chip and field: the user types the number of days (1-180).
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get payLaterCustomDays;

  /// Pay later field: the day of next month (1-31).
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get payLaterDayOfMonth;

  /// Pay later choice chip: the user picks the due date.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get payLaterPickDate;

  /// Pay later: label of the picked due date field.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get payLaterDueDate;

  /// Pay later form and plan detail: the day of the purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get payLaterPurchaseDate;

  /// Pay later form: the purchase date when it is today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get payLaterToday;

  /// Pay later: the due date line (form, plan list, plan detail). Calm, no exclamation.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}'**
  String payLaterDueOn(String date);

  /// Pay later: days until the due date, under the due date. Calm, no urgency.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Due today} =1{In 1 day} other{In {days} days}}'**
  String payLaterDaysLeft(int days);

  /// Name of a Pay later plan saved without a store name, with its short due date. 'Pay later' is a general way of paying (buy now, pay once later), not a company or brand name.
  ///
  /// In en, this message translates to:
  /// **'Pay later · {date}'**
  String payLaterAutoName(String date);

  /// Plan detail: the rule that gave the due date, a number of days after the purchase.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day later} other{{days} days later}}'**
  String payLaterRuleDays(int days);

  /// Plan detail: the due date was picked by hand.
  ///
  /// In en, this message translates to:
  /// **'Chosen date'**
  String get payLaterRuleChosen;

  /// Plan detail: the rule that gave the due date, e.g. 30 days later.
  ///
  /// In en, this message translates to:
  /// **'When to pay: {rule}'**
  String payLaterRuleLine(String rule);

  /// Pay later form: validation of the number of days.
  ///
  /// In en, this message translates to:
  /// **'Number of days must be between 1 and 180.'**
  String get errorPayLaterDays;

  /// Pay later form: validation of the day of next month.
  ///
  /// In en, this message translates to:
  /// **'Day must be between 1 and 31.'**
  String get errorPayLaterDay;

  /// Pay later plan detail: the optional source, for information only.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String payLaterSourceLine(String name);

  /// Add/edit plan: how often the installments repeat (Monthly installments, Pay in 4).
  ///
  /// In en, this message translates to:
  /// **'Payment interval'**
  String get fieldPaymentInterval;

  /// Payment interval choice: the same day of every month (31st falls on the month's last day in short months).
  ///
  /// In en, this message translates to:
  /// **'Same day each month'**
  String get intervalSameDay;

  /// Payment interval choice: every 30 days.
  ///
  /// In en, this message translates to:
  /// **'Every 30 days'**
  String get intervalEvery30Days;

  /// Payment interval choice: every 14 days.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get intervalBiweekly;

  /// Payment interval choice: every 7 days.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get intervalWeekly;

  /// Payment interval choice: every N days, N typed in a field below. Not 'Custom', which is a plan type.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get intervalCustom;

  /// Number field shown when the 'Other' payment interval is chosen (1-365).
  ///
  /// In en, this message translates to:
  /// **'Days between payments'**
  String get fieldIntervalDays;

  /// Plan preview: calm note listing months that hold two or more payments.
  ///
  /// In en, this message translates to:
  /// **'Months with more than one payment: {months}.'**
  String previewSameMonth(String months);

  /// One month in previewSameMonth: month name with year, and how many payments fall in it.
  ///
  /// In en, this message translates to:
  /// **'{month} ({count})'**
  String previewSameMonthItem(String month, int count);

  /// Separator between months in previewSameMonth.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get previewMonthSeparator;

  /// Plan edit: note below the payment interval choice.
  ///
  /// In en, this message translates to:
  /// **'Only unpaid installments get new dates.'**
  String get intervalEditHint;

  /// Add plan: screen reader label of the choice between typing the total and typing one installment.
  ///
  /// In en, this message translates to:
  /// **'Which amount do you know?'**
  String get amountEntryLabel;

  /// Add plan: choice to type the plan's total amount. Short: one of two segments.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get amountEntryTotal;

  /// Add plan: choice to type one installment's amount. Short: one of two segments.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get amountEntryInstallment;

  /// Add plan: amount field label when the user types one installment.
  ///
  /// In en, this message translates to:
  /// **'Installment amount'**
  String get fieldInstallmentAmount;

  /// Add plan, below the total: each installment, worked out by the app. Calm note, no warning.
  ///
  /// In en, this message translates to:
  /// **'Installment {amount} · calculated'**
  String amountComputedInstallment(String amount);

  /// Add plan, below the total, when it does not divide evenly: the first installment carries the leftover minor units.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{First installment {first}, the other one {others} · calculated} other{First installment {first}, the other {count} {others} each · calculated}}'**
  String amountComputedSplit(int count, String first, String others);

  /// Add plan, below the installment amount: the plan's total, worked out by the app.
  ///
  /// In en, this message translates to:
  /// **'Total {amount} · calculated'**
  String amountComputedTotal(String amount);

  /// Amount field error: a well-formed amount with more digits than the app takes.
  ///
  /// In en, this message translates to:
  /// **'This amount is too large.'**
  String get errorAmountTooLarge;

  /// Add plan, installment amount field: installment times the count is more than the app takes.
  ///
  /// In en, this message translates to:
  /// **'The total gets too large. Lower the installment or the number of payments.'**
  String get errorTotalTooLarge;

  /// Notification body with a sentence for the payment method after it (ahead and on-day reminders whose payments share one method).
  ///
  /// In en, this message translates to:
  /// **'{body}. {note}'**
  String reminderWithNote(String body, String note);

  /// Sentence after a reminder for payments taken automatically. Calm, no exclamation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It\'s taken automatically; keep the amount in your account.} other{They\'re taken automatically; keep the amount in your account.}}'**
  String reminderNoteAutomatic(int count);

  /// Sentence after a reminder for payments the user pays themselves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You make this payment yourself.} other{You make these payments yourself.}}'**
  String reminderNoteManual(int count);

  /// Plan field: how the plan's payments are paid.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// Payment method: taken from a card or account automatically. Also the screen reader label of its icon on home.
  ///
  /// In en, this message translates to:
  /// **'Taken automatically'**
  String get paymentMethodAutomatic;

  /// Payment method: the user goes and pays (store, transfer, ATM). Also the screen reader label of its icon on home.
  ///
  /// In en, this message translates to:
  /// **'Paid manually'**
  String get paymentMethodManual;

  /// Payment method not chosen: reminders as before.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get paymentMethodNotSet;

  /// Under the payment method choice when 'Taken automatically' is selected.
  ///
  /// In en, this message translates to:
  /// **'Reminders tell you to keep the amount in your account.'**
  String get paymentMethodAutomaticHint;

  /// Under the payment method choice when 'You pay it' is selected.
  ///
  /// In en, this message translates to:
  /// **'Reminders come a day earlier, so there\'s time to go and pay.'**
  String get paymentMethodManualHint;

  /// Optional: the source or card an automatic payment is taken from.
  ///
  /// In en, this message translates to:
  /// **'Taken from'**
  String get chargeSourceLabel;

  /// 'Taken from' left empty.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get chargeSourceNone;

  /// Plan details: the payment method and where it is taken from.
  ///
  /// In en, this message translates to:
  /// **'{method} · {source}'**
  String paymentMethodFrom(String method, String source);

  /// Payday summary notification on the first day of a pay period. Numbers only, no advice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{A new pay period has started. No payments this period.} =1{A new pay period has started. 1 payment this period, {total} in total.} other{A new pay period has started. {count} payments this period, {total} in total.}}'**
  String reminderPayday(int count, String total);

  /// reminderPayday with amounts hidden in notifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{A new pay period has started. No payments this period.} =1{A new pay period has started. 1 payment this period.} other{A new pay period has started. {count} payments this period.}}'**
  String reminderPaydayHidden(int count);

  /// Payday summary with an income: what is left after the period's payments.
  ///
  /// In en, this message translates to:
  /// **'{body} {left} left.'**
  String reminderPaydayLeft(String body, String left);

  /// Payday summary when the payments are more than the income. It is sent on the first day of the period, so the period is the current one: the same sentence as the home screen (homeNegative). Durum bildirir; 'risk', 'tehlike', 'dikkat' gibi kelimeler kullanma. 'kalıyor' (bu dönem, kesin) ile 'görünüyor' (gelecek, tahmine dayalı değil ama henüz gelmemiş) farkını koru.
  ///
  /// In en, this message translates to:
  /// **'{body} This period is {amount} short.'**
  String reminderPaydayShort(String body, String amount);

  /// Settings switch: one notification on payday with the period's payments.
  ///
  /// In en, this message translates to:
  /// **'Payday summary'**
  String get reminderPaydayToggle;

  /// Under the payday summary switch.
  ///
  /// In en, this message translates to:
  /// **'On payday, at your reminder time: this period\'s payments, total and what\'s left.'**
  String get reminderPaydayToggleHint;

  /// Pro screen title and the Settings row. Product name, not translated.
  ///
  /// In en, this message translates to:
  /// **'Kalan Pro'**
  String get proTitle;

  /// No description provided for @proIntro.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{The free version keeps up to 1 open plan. Pro removes the limit and adds:} other{The free version keeps up to {limit} open plans. Pro removes the limit and adds:}}'**
  String proIntro(int limit);

  /// One line in the list of what Pro adds.
  ///
  /// In en, this message translates to:
  /// **'Unlimited open plans'**
  String get proFeatureUnlimitedPlans;

  /// price comes from the store, already formatted.
  ///
  /// In en, this message translates to:
  /// **'{price} · pay once. No subscription, nothing renews.'**
  String proPriceLine(String price);

  /// No description provided for @proPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The price couldn\'t be loaded right now.'**
  String get proPriceUnavailable;

  /// No description provided for @proRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get proRetry;

  /// No description provided for @proBuy.
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get proBuy;

  /// No description provided for @proRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get proRestore;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro is on. Thank you.'**
  String get proActive;

  /// No description provided for @proPending.
  ///
  /// In en, this message translates to:
  /// **'The payment is waiting for approval. Pro turns on once it\'s approved.'**
  String get proPending;

  /// After a purchase or a restore that found Pro.
  ///
  /// In en, this message translates to:
  /// **'Pro is on.'**
  String get proTurnedOn;

  /// No description provided for @proRestoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'No Pro purchase found on this store account.'**
  String get proRestoreNotFound;

  /// No description provided for @proStoreUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the store right now. Try again later.'**
  String get proStoreUnreachable;

  /// No description provided for @proPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Try again later.'**
  String get proPurchaseFailed;

  /// No description provided for @settingsProFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsProFree;

  /// No description provided for @settingsProOn.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get settingsProOn;

  /// No description provided for @settingsProPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get settingsProPending;

  /// No description provided for @limitSheetBody.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{The free version keeps up to 1 open plan. You can add a new one when a plan finishes, or with Pro.} other{The free version keeps up to {limit} open plans. You can add a new one when a plan finishes, or with Pro.}}'**
  String limitSheetBody(int limit);

  /// No description provided for @limitSheetSeePro.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get limitSheetSeePro;

  /// No description provided for @limitSheetNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get limitSheetNotNow;

  /// Title of the chart of the next 6 pay periods (home strip and its screen).
  ///
  /// In en, this message translates to:
  /// **'Coming pay periods'**
  String get comingPeriodsTitle;

  /// Summary of the selected pay period when income is set and nothing is short. total: spoken for; left: income minus spoken for.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments this period. {left} left.} =1{1 payment this period. {total} in total. {left} left.} other{{count} payments this period. {total} in total. {left} left.}}'**
  String comingPeriodsSummary(int count, String total, String left);

  /// Summary of the selected pay period without the left amount (no income set, or the period is short).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments this period.} =1{1 payment this period. {total} in total.} other{{count} payments this period. {total} in total.}}'**
  String comingPeriodsSummaryNoLeft(int count, String total);

  /// Under a bar and in the summary when spoken for exceeds income. amount is negative and carries its minus sign, e.g. -1,200.
  ///
  /// In en, this message translates to:
  /// **'{amount} short'**
  String comingPeriodsShort(String amount);

  /// Link shown when no income is set; opens the income field.
  ///
  /// In en, this message translates to:
  /// **'Add your income to see what\'s left in each period.'**
  String get comingPeriodsIncomeInvite;

  /// Shown instead of the chart when no period has a payment.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{No payments in the next pay period.} other{No payments in the next {count} pay periods.}}'**
  String comingPeriodsEmpty(int count);

  /// Screen reader text of one bar. range: e.g. December 15 – January 14.
  ///
  /// In en, this message translates to:
  /// **'{range}: {spokenFor} spoken for, {left} left.'**
  String comingPeriodsBarLabel(String range, String spokenFor, String left);

  /// Screen reader text of one bar when no income is set.
  ///
  /// In en, this message translates to:
  /// **'{range}: {spokenFor} spoken for.'**
  String comingPeriodsBarLabelNoIncome(String range, String spokenFor);

  /// Summary of a coming pay period (not the current one) when its payments exceed income. amount is positive, without a minus sign; the minus icon sits beside the sentence. The current period uses homeNegative ('This period is {amount} short.'). States a fact; do not use words like 'risk', 'danger' or 'warning'. Keep the difference between 'is short' (this period, certain) and 'looks short' (a coming period: not a guess, but not here yet). Durum bildirir; 'risk', 'tehlike', 'dikkat' gibi kelimeler kullanma. 'kalıyor' (bu dönem, kesin) ile 'görünüyor' (gelecek, tahmine dayalı değil ama henüz gelmemiş) farkını koru.
  ///
  /// In en, this message translates to:
  /// **'This period looks {amount} short.'**
  String comingPeriodsShortAhead(String amount);

  /// Screen reader text of the current period's bar when its payments exceed income. amount is positive, without a minus sign. States a fact; do not use words like 'risk', 'danger' or 'warning'. Keep the difference between 'is short' (this period, certain) and 'looks short' (a coming period: not a guess, but not here yet). Durum bildirir; 'risk', 'tehlike', 'dikkat' gibi kelimeler kullanma. 'kalıyor' (bu dönem, kesin) ile 'görünüyor' (gelecek, tahmine dayalı değil ama henüz gelmemiş) farkını koru.
  ///
  /// In en, this message translates to:
  /// **'{range}: {spokenFor} spoken for, {amount} short.'**
  String comingPeriodsBarLabelShortNow(
    String range,
    String spokenFor,
    String amount,
  );

  /// Screen reader text of a coming period's bar when its payments exceed income. amount is positive, without a minus sign. States a fact; do not use words like 'risk', 'danger' or 'warning'. Keep the difference between 'is short' (this period, certain) and 'looks short' (a coming period: not a guess, but not here yet). Durum bildirir; 'risk', 'tehlike', 'dikkat' gibi kelimeler kullanma. 'kalıyor' (bu dönem, kesin) ile 'görünüyor' (gelecek, tahmine dayalı değil ama henüz gelmemiş) farkını koru.
  ///
  /// In en, this message translates to:
  /// **'{range}: {spokenFor} spoken for, looks {amount} short.'**
  String comingPeriodsBarLabelShortAhead(
    String range,
    String spokenFor,
    String amount,
  );

  /// Label of the Chart | Calendar choice on the Coming pay periods screen. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get comingViewLabel;

  /// Segment that shows the bar chart of coming pay periods. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get comingViewChart;

  /// Segment that shows the month calendar of payments. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get comingViewCalendar;

  /// Button that returns the calendar to the current month. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Tooltip of the button that shows the previous month. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// Tooltip of the button that shows the next month. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// Total of the selected day's payments, paid or not. amount: formatted money. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String calendarDayTotal(String amount);

  /// Row in the selected day's section when a pay period starts that day. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'Payday'**
  String get calendarPayday;

  /// Shown when the tapped day has no payments. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'No payments on this day.'**
  String get calendarNoPayments;

  /// Screen reader: how many payments a calendar day has. First part of the day's label, after the date. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments} =1{1 payment} other{{count} payments}}'**
  String calendarCellPayments(int count);

  /// Screen reader: every payment of the day is late. Joined after the payment count with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get calendarCellAllLate;

  /// Screen reader: some of the day's payments are late. Joined after the payment count with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} late} other{{count} late}}'**
  String calendarCellSomeLate(int count);

  /// Screen reader: every payment of the day is paid. Joined after the payment count with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get calendarCellAllPaid;

  /// Screen reader: some of the day's payments are paid. Joined after the payment count with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} paid} other{{count} paid}}'**
  String calendarCellSomePaid(int count);

  /// Screen reader: a pay period starts this day. Joined with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'payday'**
  String get calendarCellPayday;

  /// Screen reader: the day is today. Joined with a comma. Takvim etiketi; kısa ve sakin.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get calendarCellToday;

  /// One word beside a small icon under a bar of the coming pay periods chart: plan payments pile up in one week of that period. Never written on the bar. Gözlem bildirir, uyarı değildir. 'Sıkışık dönem' ile karıştırma.
  ///
  /// In en, this message translates to:
  /// **'busy'**
  String get busyWeekTag;

  /// One line in the period summary and on the calendar: the days where plan payments pile up, how many and their total. range: 'Dec 17–21'; amount: formatted money. Gözlem bildirir, uyarı değildir. 'Sıkışık dönem' ile karıştırma.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Busy week: {range} · 1 payment · {amount}} other{Busy week: {range} · {count} payments · {amount}}}'**
  String busyWeekSummary(String range, int count, String amount);

  /// Days of a busy week within one month: 'Dec 17–21'. month: short month name; startDay, endDay: day numbers. Gözlem bildirir, uyarı değildir. 'Sıkışık dönem' ile karıştırma.
  ///
  /// In en, this message translates to:
  /// **'{month} {startDay}–{endDay}'**
  String busyWeekRangeSameMonth(String month, String startDay, String endDay);

  /// Screen reader: the day is inside a busy week of plan payments. Joined with a comma. Gözlem bildirir, uyarı değildir. 'Sıkışık dönem' ile karıştırma.
  ///
  /// In en, this message translates to:
  /// **'busy week'**
  String get calendarCellBusyWeek;

  /// Sources and cards screen, heading of a card's coming statements. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get cardStatementsTitle;

  /// A card statement named by its statement (closing) date, e.g. 'Nov 14 statement'. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'{date} statement'**
  String cardStatementTitle(String date);

  /// Beside a statement whose statement date has passed but is not due yet (the bank has cut it). Calm note, not a warning. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get cardStatementClosed;

  /// Statement row: how many Kalan installments are on it and its due date. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 installment} other{{count} installments}} · Due {date}'**
  String cardStatementCountDue(int count, String date);

  /// Statement row without installments; no total is shown. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'No installments · Due {date}'**
  String cardStatementEmptyDue(String date);

  /// Under a card's statements: the totals are not the card's whole balance, only the installments entered in Kalan. 'Kalan' is the app name; do not translate it. Calm, factual.
  ///
  /// In en, this message translates to:
  /// **'Only installments you added to Kalan.'**
  String get cardStatementsNote;

  /// Statement detail: the statement (closing) date. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'Statement date {date}'**
  String cardStatementCutOn(String date);

  /// Statement detail: the statement's due date. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String cardStatementDueOn(String date);

  /// Statement detail: how many Kalan installments are on the statement and their total. Not the card balance. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 installment} other{{count} installments}} · {amount}'**
  String cardStatementCountTotal(int count, String amount);

  /// Statement detail without installments. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura / fechamento / vencimento, es-419 Mexico estado de cuenta / fecha de corte / fecha límite de pago.)
  ///
  /// In en, this message translates to:
  /// **'No installments'**
  String get cardStatementEmpty;

  /// Statement detail opened for a statement that is no longer one of the six coming ones (or a removed card). Calm, factual. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan. (Card statement term: use the market's banking word, e.g. pt-BR fatura, es-419 Mexico estado de cuenta.)
  ///
  /// In en, this message translates to:
  /// **'This statement is not among your card\'s coming statements.'**
  String get cardStatementNotComing;

  /// Card settings switch: a notification some days before the card's statement date (hesap kesim). Off by default. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan (e.g. pt-BR fatura / fechamento, es-419 Mexico fecha de corte). Yalnızca bilgi; alışverişe teşvik etme, aciliyet ifadesi kullanma. (Information only: do not encourage spending, no urgency.)
  ///
  /// In en, this message translates to:
  /// **'Statement closing reminder'**
  String get statementReminderToggle;

  /// Under the statement closing reminder switch, muted. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan (e.g. pt-BR fatura / fechamento, es-419 Mexico fecha de corte). Yalnızca bilgi; alışverişe teşvik etme, aciliyet ifadesi kullanma. (Information only: do not encourage spending, no urgency.)
  ///
  /// In en, this message translates to:
  /// **'A notification before the statement date, at your reminder time.'**
  String get statementReminderToggleHint;

  /// Card settings: label above the 1 / 2 days choice of the statement closing reminder (the choices reuse reminderLeadDaysValue). Yalnızca bilgi; alışverişe teşvik etme, aciliyet ifadesi kullanma. (Information only: do not encourage spending, no urgency.)
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get statementReminderDays;

  /// Statement closing reminder notification. No amount, no button; a tap opens the card's statements. 'After that' means purchases after the statement date. Kart ekstresi terimi; pazarın bankacılık karşılığını kullan (e.g. pt-BR fatura / fechamento, es-419 Mexico fecha de corte). Yalnızca bilgi; alışverişe teşvik etme, aciliyet ifadesi kullanma. (Information only: do not encourage spending, no urgency.)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Your {card} statement closes in 1 day, on {date}. Installments after that go on the {next} statement.} other{Your {card} statement closes in {days} days, on {date}. Installments after that go on the {next} statement.}}'**
  String reminderStatementClosing(
    int days,
    String card,
    String date,
    String next,
  );

  /// Section title on a bank account in Sources and cards: the automatic payments that will be taken from it this pay period, so the money should be there. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Keep in account'**
  String get chargeTitleAccount;

  /// Section title on a credit card in Sources and cards: other plans charged automatically to this card (not the card's own installments, which are on its statements). Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Coming to this card'**
  String get chargeTitleCard;

  /// Section title on a pay later provider chosen as where automatic payments are taken from. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Coming out of this source'**
  String get chargeTitleProvider;

  /// The next day automatic payments come out of this source and that day's total. Shown larger and bolder, never in a warning colour. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Next withdrawal: {date} · {amount}'**
  String chargeNext(String date, String amount);

  /// Running total: everything that comes out of this source from the start of the pay period up to and including this day. Avoid grammar that changes with the date (no Turkish 'a/'e suffix). Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'By {date} · {amount}'**
  String chargeBy(String date, String amount);

  /// A row of the day-by-day list; the running total (everything that comes out of this source from the start of the pay period up to and including this day) is shown at the end of the row. Avoid grammar that changes with the date (no Turkish 'a/'e suffix). Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String chargeByDate(String date);

  /// A day whose automatic payments are already marked paid: shown muted with a tick and that day's sum at the end of the row; not added to the running total. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'{date} · paid'**
  String chargePaidOn(String date);

  /// Screen reader label of the clock icon on today's row when an unpaid payment past its due date is counted today. Calm, no urgency. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Includes a payment past its due date'**
  String get chargePastDue;

  /// Opens or closes the day-by-day list of this pay period's automatic payments. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get chargeDetails;

  /// Collapsed row; opens the same list for the next pay period (next payday to the one after). Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get chargeNextPeriod;

  /// One calm line when nothing automatic is left to come out of this source in the current pay period. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'No automatic payments to come out of this source this period.'**
  String get chargeEmpty;

  /// Shown when the next pay period list is opened and it is empty. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'No automatic payments from this source next period.'**
  String get chargeNextEmpty;

  /// Title of a separate card listing automatic plans whose account or card was not chosen. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Automatic payments without a source'**
  String get chargeUnassignedTitle;

  /// Under a plan's name in the card of automatic payments without a source: its next unpaid payment. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'Next: {date} · {amount}'**
  String chargeUnassignedRow(String date, String amount);

  /// Note under the list of automatic payments without a source. Informal 'you' in Turkish (sen). Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'You can choose where each is taken from in its plan details.'**
  String get chargeUnassignedNote;

  /// Added to the reminder before a payment when every payment in it is taken automatically from the same bank account and amounts are shown. Replaces the general 'taken automatically' note. The account name is as the user typed it, so the Turkish text uses no case suffix on it. Bu, bakiye uyarısı değil; çıkacak tutarı gösteren sakin bir hatırlatmadır. (This is not a balance warning; it is a calm reminder of the amount that will come out. Kalan never knows a balance.)
  ///
  /// In en, this message translates to:
  /// **'It\'s taken automatically. Keep {amount} in {account}.'**
  String reminderNoteAccount(String account, String amount);

  /// Plan details: the one entry point for 'Put on hold', 'Adjust amount' and 'Close' (19). Also the title of the sheet it opens. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Return or cancellation'**
  String get refundAction;

  /// Option in the 'Return or cancellation' sheet: leaves the remaining payments out while the user waits. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Put on hold'**
  String get holdOption;

  /// Explanation under 'Put on hold'. The only place 'dispute' (itiraz) may appear, as a neutral side clause. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'While you wait for a return, cancellation or dispute, remaining payments are left out.'**
  String get holdOptionHint;

  /// Undoes 'Put on hold'; shown only on a plan on hold. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenOption;

  /// Explanation under 'Reopen'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Remaining payments come back on their own dates.'**
  String get reopenOptionHint;

  /// Option in the 'Return or cancellation' sheet and title of its screen: lowers the plan total after a partial return. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Adjust amount'**
  String get adjustOption;

  /// Explanation under 'Adjust amount'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'If you returned part of it, remaining payments are split to match the new total.'**
  String get adjustOptionHint;

  /// Option in the 'Return or cancellation' sheet and in the 30-day line; also the confirm button of the close dialog. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeOption;

  /// Explanation under 'Close'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'The plan moves to the archive. What you paid stays in your history.'**
  String get closeOptionHint;

  /// Label of a plan on hold (plan list, plan details) and of each payment on hold. Always shown with a pause icon; never in the error color. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get planOnHold;

  /// Plan details of a plan on hold, under the amounts. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment on hold, left out of totals and reminders.} other{{count} payments on hold, left out of totals and reminders.}}'**
  String planOnHoldNote(int count);

  /// Line on a plan that has been on hold for 30 days, shown only when the plan is opened. No notification. Options: Close / Reopen / Keep on hold. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Still waiting on the return?'**
  String get holdCheckTitle;

  /// Under 'Still waiting on the return?'. Turkish: the date takes no case suffix of its own ('tarihinden'). Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'On hold since {date}.'**
  String holdCheckSince(String date);

  /// Option in the 30-day line: the plan stays on hold and asks again 30 days later. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Keep on hold'**
  String get keepOnHold;

  /// Plan details after 'Reopen', while payments whose date passed during the hold are unpaid. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment\'s date passed while it was on hold. If you paid it, you can mark it.} other{{count} payments\' dates passed while they were on hold. If you paid them, you can mark them.}}'**
  String passedWhileHeld(int count);

  /// Snackbar after 'Put on hold'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Plan is on hold.'**
  String get planHeldDone;

  /// Snackbar after 'Reopen'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Plan reopened.'**
  String get planReopenedDone;

  /// Snackbar after closing a plan. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Plan closed.'**
  String get planClosedDone;

  /// Snackbar after 'Keep on hold'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Plan stays on hold.'**
  String get planKeptOnHold;

  /// Snackbar after 'Adjust amount' is saved. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Amount adjusted.'**
  String get amountAdjustedDone;

  /// Title of the close dialog; also the button offered when an adjustment would leave no payment. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Close plan'**
  String get closeTitle;

  /// Body of the close dialog. Closing is not deleting. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Unpaid payments leave your totals and reminders. What you paid stays in your history. A closed plan can\'t be reopened.'**
  String get closeBody;

  /// Heading above the two reasons in the close dialog. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get closeReasonTitle;

  /// Close reason: the item was returned. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get closeReasonRefund;

  /// Close reason: the purchase was cancelled. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get closeReasonCancel;

  /// Label of a closed plan in the archive and its details. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'{reason, select, refund{Closed · Return} other{Closed · Cancellation}}'**
  String closedWithReason(String reason);

  /// Closed plan in the archive: what was paid (screen reader label of the amount). Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String planPaidAmount(String amount);

  /// Amount field on the 'Adjust amount' screen. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'New total'**
  String get adjustNewTotal;

  /// 'Adjust amount' screen, above the field. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Current total {amount}'**
  String adjustCurrentTotal(String amount);

  /// 'Adjust amount' screen, above the field. Paid before Kalan included. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'You\'ve paid {amount}'**
  String adjustPaidSoFar(String amount);

  /// 'Adjust amount' screen, under the field. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'Paid payments don\'t change. What\'s left is split evenly across unpaid payments; dates stay the same.'**
  String get adjustHint;

  /// Heading of the preview list on the 'Adjust amount' screen, shown before saving. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'New payments'**
  String get adjustPreviewTitle;

  /// Validation on the 'Adjust amount' screen; nothing is saved. Turkish: the amount is in parentheses so it needs no case suffix. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'The new total can\'t be less than what you\'ve paid ({amount}).'**
  String adjustBelowPaid(String amount);

  /// Validation on the 'Adjust amount' screen: an adjustment only lowers the total. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'The new total can\'t be more than the current total ({amount}).'**
  String adjustAboveTotal(String amount);

  /// Note on the 'Adjust amount' screen when the typed total equals the current one; nothing to save. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'That\'s the current total.'**
  String get adjustUnchanged;

  /// Validation on the 'Adjust amount' screen: each payment needs at least the smallest unit of the currency. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This amount can\'t be split into 1 payment.} other{This amount can\'t be split into {count} payments.}}'**
  String adjustCannotSplit(int count);

  /// 'Adjust amount' screen when the new total equals what is paid. Offers 'Close plan'. Sakin ve yargısız ton. İade bir hata değil; hukuki ya da gergin kelime kullanma. (Calm, non-judgmental tone. A return is not a mistake; use no legal or tense words.)
  ///
  /// In en, this message translates to:
  /// **'No payments would be left. Do you want to close the plan?'**
  String get adjustNothingLeft;

  /// Title of the sheet that opens when an installment is tapped in plan details: its number and its date. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'{position} · {date}'**
  String paymentActionsTitle(String position, String date);

  /// Option in the installment sheet and title of its screen: records a new date the provider set for this one installment. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDateAction;

  /// Explanation under 'Change date' in the installment sheet. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Record the new date your provider gave you.'**
  String get changeDateActionHint;

  /// Explanation under 'Edit payment' in the installment sheet: changes the amount only (dates change with 'Change date'). Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Fix the amount. The difference is spread over later payments.'**
  String get editPaymentActionHint;

  /// 'Change date' screen: the installment's date before the change. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Current date: {date}'**
  String changeDateCurrent(String date);

  /// 'Change date' screen: label of the date field. Earliest date is today. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get changeDateNewDate;

  /// 'Change date' screen: under the date field while it still shows the current date. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Pick a new date.'**
  String get changeDatePickNew;

  /// 'Change date' screen: switch, off by default. On: every later unpaid installment moves by the same number of days. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Move later payments too'**
  String get changeDateShiftLater;

  /// 'Change date' screen: heading of the preview of which pay periods change. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Effect on your pay periods'**
  String get changeDatePreviewTitle;

  /// Preview row: what is left in this pay period goes up by the amount. The sign and an arrow icon next to it carry the meaning, not color. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Left +{amount}'**
  String changeDateLeftUp(String amount);

  /// Preview row: what is left in this pay period goes down by the amount. The sign and an arrow icon next to it carry the meaning, not color. Use a real minus sign. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Left −{amount}'**
  String changeDateLeftDown(String amount);

  /// Preview row when no income is entered: the amount committed in this pay period goes up. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Committed +{amount}'**
  String changeDateCommittedUp(String amount);

  /// Preview row when no income is entered: the amount committed in this pay period goes down. Use a real minus sign. An arrow icon follows. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Committed −{amount}'**
  String changeDateCommittedDown(String amount);

  /// Screen reader text for 'Left +{amount} ↑'. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Left goes up by {amount}'**
  String changeDateLeftUpSemantics(String amount);

  /// Screen reader text for 'Left −{amount} ↓'. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Left goes down by {amount}'**
  String changeDateLeftDownSemantics(String amount);

  /// Screen reader text for 'Committed +{amount} ↑'. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Committed goes up by {amount}'**
  String changeDateCommittedUpSemantics(String amount);

  /// Screen reader text for 'Committed −{amount} ↓'. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Committed goes down by {amount}'**
  String changeDateCommittedDownSemantics(String amount);

  /// Preview when no pay period total changes (income entered). Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Same period; what\'s left stays the same.'**
  String get changeDateSamePeriod;

  /// Preview when no pay period total changes (no income entered). Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Same period; what\'s committed stays the same.'**
  String get changeDateSamePeriodCommitted;

  /// Last preview line when more than 6 pay periods change. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more period} other{and {count} more periods}}'**
  String changeDateMorePeriods(int count);

  /// Calm info line on the 'Change date' screen when the new date is after the next installment (allowed; numbers stay). Not a warning. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'This date is after the next payment.'**
  String get changeDatePassesNext;

  /// Calm note when moving later payments too would put one before today; saving is not possible then. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'A later payment would fall before today. You can turn the switch off or pick another date.'**
  String get changeDateLaterBeforeToday;

  /// Snackbar after saving a changed installment date. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Date saved.'**
  String get changeDateDone;

  /// Muted note under an installment whose date was changed to a later day, with its original date. A record, not a judgment. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Moved later · originally {date}'**
  String moveNoteLater(String date);

  /// Muted note under an installment whose date was changed to an earlier day, with its original date. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'Moved earlier · originally {date}'**
  String moveNoteEarlier(String date);

  /// 'Change date' screen when the payment was paid, or its plan put on hold or closed, after the screen opened. Calm, no error tone. Kalan yalnızca kayıt tutar; sağlayıcıda değişiklik yapmaz. Erteleme önerir gibi yazma. (Kalan only keeps a record; it changes nothing at the provider. Never word it as a suggestion to postpone.)
  ///
  /// In en, this message translates to:
  /// **'This payment\'s date can\'t be changed here any more.'**
  String get changeDateNotAvailable;

  /// Action on a payment: record a one-off fee the provider added. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Add extra fee'**
  String get extraFeeAdd;

  /// Action on a payment that already has an extra fee: change or delete it. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Edit extra fee'**
  String get extraFeeEdit;

  /// Hint under 'Add extra fee' in the payment's action sheet. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Record a fee your provider added.'**
  String get extraFeeAddHint;

  /// Under a payment in the plan details: the fee recorded on it. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Extra fee: {amount}'**
  String extraFeeLine(String amount);

  /// Plan summary line: all extra fees recorded on this plan's payments. Not a yearly total or a statistic. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Extra fees: {amount}'**
  String extraFeesTotal(String amount);

  /// Small note under a payment row: the fee recorded on top of the payment's own amount. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'+ {amount} extra fee'**
  String extraFeeRowNote(String amount);

  /// Title of the sheet where the fee is entered. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Extra fee'**
  String get extraFeeSheetTitle;

  /// Short explanation in the extra fee sheet. Calm; Kalan only keeps the user's record. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Kalan doesn\'t calculate fees. Enter the amount from your provider; it counts in the same period as the payment.'**
  String get extraFeeSheetHint;

  /// Label of the optional short note field in the extra fee sheet. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get extraFeeNoteLabel;

  /// Short message after saving an extra fee. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Extra fee saved.'**
  String get extraFeeSaved;

  /// Short message after deleting an extra fee, shown with 'Undo'. Calm, not a warning. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'Extra fee removed.'**
  String get extraFeeRemoved;

  /// When the payment's plan was closed or put on hold meanwhile. Calm, no error tone. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'An extra fee can\'t be added to this payment.'**
  String get extraFeeNotAllowed;

  /// Under the note field when it is too long. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'{max, plural, =1{The note can be up to 1 character.} other{The note can be up to {max} characters.}}'**
  String extraFeeNoteTooLong(int max);

  /// Screen reader label of a past-due row with an extra fee. Calm: a fact, not a warning. Nötr bir kayıt etiketi. 'Ceza' ya da suçlayıcı bir kelime kullanma; ücreti gecikmeye bağlayan bir ifade de kullanma. (A neutral record label. Never 'penalty' or a blaming word; never tie the fee to being late.)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{{plan}, {amount}, plus {fee} extra fee, due 1 day ago} other{{plan}, {amount}, plus {fee} extra fee, due {days} days ago}}'**
  String pastDueRowFeeSemantics(
    String plan,
    String amount,
    String fee,
    int days,
  );

  /// Optional amount field under 'More details' on the add and edit plan screens: a fixed fee the plan charges with its payments. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'Fee per payment'**
  String get installmentFeeLabel;

  /// Helper text under the fee per payment field. Kalan never calculates or suggests it. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'A fixed fee your provider charges with payments. Leave empty for none.'**
  String get installmentFeeHelper;

  /// Heading of the choice of which payments take the fee per payment. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'Charged on'**
  String get installmentFeeScopeLabel;

  /// Choice: the fee per payment is added to every payment (default). Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'On every payment'**
  String get installmentFeeScopeEvery;

  /// Choice: the fee per payment is added to payment number 1 only. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'First payment only'**
  String get installmentFeeScopeFirst;

  /// Muted note under an installment amount that includes the plan's fee per payment. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'Includes {fee} payment fee'**
  String installmentFeeIncluded(String fee);

  /// Plan summary row label: the plan's amount without fees per payment. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'Plan amount'**
  String get planAmountLabel;

  /// Plan summary row label: the fees per payment of all the plan's payments. Not a statistic or a warning. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'Payment fees'**
  String get installmentFeesLabel;

  /// Plan summary row label: every payment of the plan (paid, unpaid and paid before Kalan) with its fees per payment; extra fees added later are not in it. The one total row of the plan summary (22, 23). Display only; a plain number, never a judgement or a comparison. Never use the word 'interest'. (Yalnızca gösterim; hüküm ya da karşılaştırma yok. 'Faiz' kelimesini kullanma.)
  ///
  /// In en, this message translates to:
  /// **'Total you repay'**
  String get planTotalLabel;

  /// Calm line on the edit plan screen when the fee per payment change touches unpaid payments; paid payments never change. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This changes 1 unpaid payment.} other{This changes {count} unpaid payments.}}'**
  String installmentFeeAffects(int count);

  /// Calm line on the edit plan screen: 'First payment only' is chosen but the first payment is already paid, so no payment takes the fee. Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma. (A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word.)
  ///
  /// In en, this message translates to:
  /// **'The first payment is already paid, so no fee is added.'**
  String get installmentFeeFirstPaid;

  /// Collapsed section on the edit plan screen holding the fee per payment (22). Closed by default; open when the plan has a fee. A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word. (Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma.)
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Muted line in the 'Edit payment' dialog: the amount typed is the installment without the plan's fee per payment, which is added on top. A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word. (Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma.)
  ///
  /// In en, this message translates to:
  /// **'The {fee} payment fee is added on top.'**
  String installmentFeeOnTop(String fee);

  /// Muted line on the 'Adjust amount' screen (19) of a plan with fees per payment (22): the new total changes installment amounts only; the fees stay. A fixed fee of the plan, known from the start. A neutral field name; never a blaming or warning word. (Planın baştan bilinen, sabit ücreti. Nötr bir alan adı; suçlayıcı ya da uyarı veren bir kelime kullanma.)
  ///
  /// In en, this message translates to:
  /// **'Payment fees ({fees}) stay the same.'**
  String adjustFeesStay(String fees);

  /// Optional field under 'More details' / 'More options' of monthly, card and manual plans: the cash price of what was bought (23). Also a plan summary row label. Display only; a plain number, never a judgement or a comparison. Never use the word 'interest'. (Yalnızca gösterim; hüküm ya da karşılaştırma yok. 'Faiz' kelimesini kullanma.)
  ///
  /// In en, this message translates to:
  /// **'Product price'**
  String get productPriceLabel;

  /// Muted helper under the 'Product price' field (23): the price if paid in one go, at purchase. Display only; a plain number, never a judgement or a comparison. Never use the word 'interest'. (Yalnızca gösterim; hüküm ya da karşılaştırma yok. 'Faiz' kelimesini kullanma.)
  ///
  /// In en, this message translates to:
  /// **'What you\'d have paid up front.'**
  String get productPriceHelper;

  /// Toplam geri ödeme ile peşin fiyat arasındaki fark. 'Faiz' kelimesini kullanma; nötr bir kelime seç. Arapça gibi bazı pazarlarda 'faiz' hassas olabilir. (The difference between the total repaid and the cash price. Never use the word 'interest'; pick a neutral word. In some markets, such as Arabic ones, 'interest' can be sensitive.)
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get priceDifferenceLabel;

  /// Plan ekleme: plan türlerinin altındaki bölümün başlığı; sağlayıcı adına dokununca form bilinen kalıpla dolar. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Add plan: heading of the section under the plan types; tapping a provider fills the form with its usual pattern. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'Start from a provider'**
  String get providerStartTitle;

  /// Plan ekleme: bölüm başlığının altındaki kısa not. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Add plan: short note under the section heading. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'Fills the number of payments and the dates; you can change all of them.'**
  String get providerStartHint;

  /// Sağlayıcı kalıbı: her ay aynı gün ödenen taksitler. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider pattern: payments on the same day every month. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment · monthly} other{{count} payments · monthly}}'**
  String providerVariantSameDay(int count);

  /// Sağlayıcı kalıbı: belli gün aralığıyla ödenen taksitler (ör. 30 günde bir). Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider pattern: payments a set number of days apart (e.g. every 30 days). Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}} · {days, plural, =1{every day} other{every {days} days}}'**
  String providerVariantEveryDays(int count, int days);

  /// Sağlayıcı kalıbı: iki haftada bir ödenen taksitler. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider pattern: payments every two weeks. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment · every 2 weeks} other{{count} payments · every 2 weeks}}'**
  String providerVariantBiweekly(int count);

  /// Sağlayıcı kalıbı: alışverişten belli gün sonra tek ödeme. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider pattern: one payment a number of days after the purchase. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{One payment · 1 day later} other{One payment · {days} days later}}'**
  String providerVariantPayLaterDays(int days);

  /// Sağlayıcı kalıbı: alışverişten sonraki ayın belli gününde tek ödeme. {day} ayın günüdür (1-31), sayma değildir. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider pattern: one payment on a day of the month after the purchase. {day} is a day of the month (1-31), not a count. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'One payment · next month on day {day}'**
  String providerVariantPayLaterNextMonth(int day);

  /// Sağlayıcı satırı: birden çok kalıbı olan sağlayıcının altında; dokununca seçenekler açılır. Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Provider row: under a provider with several patterns; tapping opens them. Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 option} other{{count} options}}'**
  String providerVariantOptions(int count);

  /// Plan ekleme formunun altında, sağlayıcıdan başlanınca. {date} ay ve yıldır (ör. Kas 2026). Sağlayıcı adını çevirme. Şablon bir öneri ya da taahhüt değil, yalnızca başlangıç değeridir; övgü ya da tavsiye içeren bir dil kullanma. (Under the add plan form after starting from a provider. {date} is a month and year (e.g. Nov 2026). Do not translate the provider name. A template is not a suggestion or a promise, only a starting value; use no praising or advising language.)
  ///
  /// In en, this message translates to:
  /// **'Starting values for {provider} · Last checked: {date}. Change them if your terms differ.'**
  String providerTemplateNote(String provider, String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'nl',
    'pl',
    'pt',
    'ru',
    'sv',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'de':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsDeCh();
        }
        break;
      }
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
        }
        break;
      }
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'CA':
            return AppLocalizationsFrCa();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
