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
