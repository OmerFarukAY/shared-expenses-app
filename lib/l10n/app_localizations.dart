import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Denk'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Shared expenses, settled simply'**
  String get appTagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Denk'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of shared expenses with friends, roommates, and family without passwords or personal data.'**
  String get welcomeSubtitle;

  /// No description provided for @chooseDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Choose your display name'**
  String get chooseDisplayName;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex, Sam, Ömer'**
  String get displayNameHint;

  /// No description provided for @displayNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name between 2 and 50 characters'**
  String get displayNameValidation;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ankara Flat, Berlin Trip, Dinner Party'**
  String get groupNameHint;

  /// No description provided for @groupCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get groupCurrencyLabel;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. DNK-7X2K'**
  String get inviteCodeHint;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @copyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Invite Code'**
  String get copyInviteCode;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard'**
  String get inviteCodeCopied;

  /// No description provided for @noGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsTitle;

  /// No description provided for @noGroupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a group or enter an invite code to start sharing expenses.'**
  String get noGroupsSubtitle;

  /// No description provided for @expensesTab.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTab;

  /// No description provided for @balancesTab.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balancesTab;

  /// No description provided for @settleTab.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleTab;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmount;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get expenseTitle;

  /// No description provided for @expenseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Groceries, Dinner, Electricity'**
  String get expenseTitleHint;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @expensePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get expensePaidBy;

  /// No description provided for @expenseSplitWith.
  ///
  /// In en, this message translates to:
  /// **'Who participated?'**
  String get expenseSplitWith;

  /// No description provided for @expenseSplitMethod.
  ///
  /// In en, this message translates to:
  /// **'Split Method'**
  String get expenseSplitMethod;

  /// No description provided for @splitEqual.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get splitEqual;

  /// No description provided for @splitCustom.
  ///
  /// In en, this message translates to:
  /// **'Exact Amounts'**
  String get splitCustom;

  /// No description provided for @splitPercentage.
  ///
  /// In en, this message translates to:
  /// **'By Percentage'**
  String get splitPercentage;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get categoryFood;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home & Rent'**
  String get categoryHome;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills & Utilities'**
  String get categoryBills;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @totalSpending.
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get totalSpending;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your Balance'**
  String get yourBalance;

  /// No description provided for @youAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get youAreOwed;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get youOwe;

  /// No description provided for @youPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get youPaid;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get allSettled;

  /// No description provided for @noExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesTitle;

  /// No description provided for @noExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first expense.'**
  String get noExpensesSubtitle;

  /// No description provided for @settlementTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Plan'**
  String get settlementTitle;

  /// No description provided for @markAsSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark as Settled'**
  String get markAsSettled;

  /// No description provided for @settlementCompleted.
  ///
  /// In en, this message translates to:
  /// **'Settlement recorded successfully'**
  String get settlementCompleted;

  /// No description provided for @settlementHistory.
  ///
  /// In en, this message translates to:
  /// **'Settlement History'**
  String get settlementHistory;

  /// No description provided for @noSettlementsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled up! No payments needed.'**
  String get noSettlementsNeeded;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Preferred Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyInfo.
  ///
  /// In en, this message translates to:
  /// **'Privacy Information'**
  String get settingsPrivacyInfo;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Local Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will remove your local anonymous identity on this device. You will lose access to groups unless invited back.'**
  String get settingsDeleteWarning;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Denk'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @expenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetailTitle;

  /// No description provided for @deleteExpenseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpenseConfirmTitle;

  /// No description provided for @deleteExpenseConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense? This will recalculate all group balances.'**
  String get deleteExpenseConfirmMessage;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @splitBetween.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get splitBetween;

  /// No description provided for @expenseNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get expenseNotes;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search expenses...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noMatchingExpenses.
  ///
  /// In en, this message translates to:
  /// **'No matching expenses'**
  String get noMatchingExpenses;

  /// No description provided for @tryClearingSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search or filter options.'**
  String get tryClearingSearchFilter;

  /// No description provided for @spendingInsights.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get spendingInsights;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @memberContributions.
  ///
  /// In en, this message translates to:
  /// **'Member Contributions'**
  String get memberContributions;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
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

  /// No description provided for @anonymousAccount.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Firebase Account'**
  String get anonymousAccount;

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get membersLabel;

  /// No description provided for @requestToJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get requestToJoinButton;

  /// No description provided for @joinRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get joinRequestSentTitle;

  /// No description provided for @joinRequestSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your request to join {groupName} has been submitted. You will be able to access the group once an owner approves it.'**
  String joinRequestSentSubtitle(String groupName);

  /// No description provided for @joinRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get joinRequestPending;

  /// No description provided for @joinRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get joinRequestApproved;

  /// No description provided for @joinRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get joinRequestRejected;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get joinRequestsTitle;

  /// No description provided for @approveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveButton;

  /// No description provided for @rejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectButton;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @cancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequestButton;

  /// No description provided for @joinRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Join request cancelled'**
  String get joinRequestCancelled;

  /// No description provided for @pendingApprovalCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApprovalCardTitle;

  /// No description provided for @pendingApprovalCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for group owner approval.'**
  String get pendingApprovalCardSubtitle;

  /// No description provided for @invalidOrInactiveInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite code not found or inactive'**
  String get invalidOrInactiveInvite;

  /// No description provided for @alreadyMemberError.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this group.'**
  String get alreadyMemberError;

  /// No description provided for @requestAlreadyPendingError.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending request for this group.'**
  String get requestAlreadyPendingError;

  /// No description provided for @manageJoinRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage Join Requests'**
  String get manageJoinRequestsTooltip;

  /// No description provided for @pendingRequestsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingRequestsBadge(int count);

  /// No description provided for @settledBadge.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settledBadge;

  /// No description provided for @noCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No category data available yet.'**
  String get noCategoryData;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @uidCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'UID copied to clipboard'**
  String get uidCopiedSnackbar;

  /// No description provided for @privacyCalloutTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy-First, Data-Minimized Architecture'**
  String get privacyCalloutTitle;

  /// No description provided for @privacyCalloutBody.
  ///
  /// In en, this message translates to:
  /// **'No email, phone, or passwords collected. Only group members can view group balances.'**
  String get privacyCalloutBody;

  /// No description provided for @readAction.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readAction;

  /// No description provided for @expensePaidByMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple people paid'**
  String get expensePaidByMultiple;

  /// No description provided for @expensePaidByMultipleAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Multiple people paid...'**
  String get expensePaidByMultipleAdvanced;

  /// No description provided for @expenseSwitchToMultiplePayers.
  ///
  /// In en, this message translates to:
  /// **'Switch to Multiple Payers'**
  String get expenseSwitchToMultiplePayers;

  /// No description provided for @expenseSwitchToSinglePayer.
  ///
  /// In en, this message translates to:
  /// **'Switch to Single Payer'**
  String get expenseSwitchToSinglePayer;

  /// No description provided for @expenseSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get expenseSplit;

  /// No description provided for @expenseSplitCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get expenseSplitCustomize;

  /// No description provided for @expenseSplitSummaryEqually.
  ///
  /// In en, this message translates to:
  /// **'Equally · {count} people ›'**
  String expenseSplitSummaryEqually(int count);

  /// No description provided for @expenseSplitSummaryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom · {count} people ›'**
  String expenseSplitSummaryCustom(int count);

  /// No description provided for @expenseSplitSummaryPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage · {count} people ›'**
  String expenseSplitSummaryPercentage(int count);

  /// No description provided for @expenseLiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{payer} paid {amount} · Split among {count} people'**
  String expenseLiveSummary(String payer, String amount, int count);

  /// No description provided for @expenseLiveSummaryMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple paid {amount} · Split among {count} people'**
  String expenseLiveSummaryMultiple(String amount, int count);

  /// No description provided for @expenseLiveSummaryRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String expenseLiveSummaryRemaining(String amount);

  /// No description provided for @expenseLiveSummaryOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String expenseLiveSummaryOver(String amount);

  /// No description provided for @errorTooManyPayers.
  ///
  /// In en, this message translates to:
  /// **'Too many payers (max 5)'**
  String get errorTooManyPayers;

  /// No description provided for @errorTooManyParticipants.
  ///
  /// In en, this message translates to:
  /// **'Too many participants (max 20)'**
  String get errorTooManyParticipants;

  /// No description provided for @errorNegativeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amounts must be greater than zero'**
  String get errorNegativeAmount;

  /// No description provided for @expenseZeroShareRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count} participant(s) with 0 share removed.'**
  String expenseZeroShareRemoved(int count);

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Language'**
  String get languageSystem;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @memberLeftSuffix.
  ///
  /// In en, this message translates to:
  /// **' (left)'**
  String get memberLeftSuffix;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @cannotRemoveMemberBalance.
  ///
  /// In en, this message translates to:
  /// **'Member cannot be removed before their balance is zero.'**
  String get cannotRemoveMemberBalance;

  /// No description provided for @cannotLeaveGroupBalance.
  ///
  /// In en, this message translates to:
  /// **'You cannot leave the group before your balance is zero.'**
  String get cannotLeaveGroupBalance;

  /// No description provided for @privacyBullet1.
  ///
  /// In en, this message translates to:
  /// **'No email, phone number, or password required.'**
  String get privacyBullet1;

  /// No description provided for @privacyBullet2.
  ///
  /// In en, this message translates to:
  /// **'No advertising identifiers or tracker SDKs.'**
  String get privacyBullet2;

  /// No description provided for @privacyBullet3.
  ///
  /// In en, this message translates to:
  /// **'No device contact book or GPS location permissions.'**
  String get privacyBullet3;

  /// No description provided for @privacyBullet4.
  ///
  /// In en, this message translates to:
  /// **'Authentication uses anonymous Firebase credentials.'**
  String get privacyBullet4;

  /// No description provided for @privacyBullet5.
  ///
  /// In en, this message translates to:
  /// **'Only group members you share your invite code with can view your group expenses.'**
  String get privacyBullet5;

  /// No description provided for @accountSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Security & Recovery'**
  String get accountSecurityTitle;

  /// No description provided for @accountSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link an account to recover your groups and balances across devices.'**
  String get accountSecuritySubtitle;

  /// No description provided for @accountSecuredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your groups and balances are backed up and recoverable across devices.'**
  String get accountSecuredSubtitle;

  /// No description provided for @accountStatusAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Guest Account (Unsecured)'**
  String get accountStatusAnonymous;

  /// No description provided for @accountStatusSecured.
  ///
  /// In en, this message translates to:
  /// **'Secured Account'**
  String get accountStatusSecured;

  /// No description provided for @linkWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Link with Google'**
  String get linkWithGoogle;

  /// No description provided for @linkWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get linkWithApple;

  /// No description provided for @linkedWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Linked with Google'**
  String get linkedWithGoogle;

  /// No description provided for @linkedWithApple.
  ///
  /// In en, this message translates to:
  /// **'Linked with Apple'**
  String get linkedWithApple;

  /// No description provided for @accountLinkingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account linked successfully!'**
  String get accountLinkingSuccess;

  /// No description provided for @accountAlreadyInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Already Exists'**
  String get accountAlreadyInUseTitle;

  /// No description provided for @accountAlreadyInUseBody.
  ///
  /// In en, this message translates to:
  /// **'This account is already associated with another Denk profile. Would you like to switch to that account on this device, or keep using your current guest account?'**
  String get accountAlreadyInUseBody;

  /// No description provided for @switchAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Switch to Existing Account'**
  String get switchAccountButton;

  /// No description provided for @keepCurrentAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Keep Guest Account'**
  String get keepCurrentAccountButton;

  /// No description provided for @accountSwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Switched to existing account.'**
  String get accountSwitchSuccess;

  /// No description provided for @accountLinkErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to link account. Please try again.'**
  String get accountLinkErrorGeneric;

  /// No description provided for @appleAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with an Apple Account in your device settings to continue with Apple.'**
  String get appleAccountRequired;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account. Groups you own with other members require ownership transfer first. This cannot be undone.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Your expense history will be preserved but your name will be anonymized. Groups where you are the sole owner will be deleted.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountOwnershipRequired.
  ///
  /// In en, this message translates to:
  /// **'Ownership Transfer Required'**
  String get deleteAccountOwnershipRequired;

  /// No description provided for @deleteAccountOwnershipRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You own the following group(s) with other members. Please transfer ownership before deleting your account.'**
  String get deleteAccountOwnershipRequiredBody;

  /// No description provided for @transferOwnershipButton.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get transferOwnershipButton;

  /// No description provided for @transferOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Group Ownership'**
  String get transferOwnershipTitle;

  /// No description provided for @transferOwnershipBody.
  ///
  /// In en, this message translates to:
  /// **'Select a member to become the new owner. You will remain a member of the group.'**
  String get transferOwnershipBody;

  /// No description provided for @transferOwnershipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ownership transferred successfully.'**
  String get transferOwnershipSuccess;

  /// No description provided for @deleteAccountReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to confirm account deletion.'**
  String get deleteAccountReauthRequired;

  /// No description provided for @deleteAccountProcessing.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deleteAccountProcessing;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @webAccountDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Web Account Deletion'**
  String get webAccountDeletionTitle;

  /// No description provided for @webAccountDeletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request account and data deletion via web if you no longer have access to the app.'**
  String get webAccountDeletionSubtitle;

  /// No description provided for @errorOpeningUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get errorOpeningUrl;

  /// No description provided for @legalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal & Compliance'**
  String get legalSectionTitle;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;
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
      <String>['en', 'es', 'fr', 'it', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
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
