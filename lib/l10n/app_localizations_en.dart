// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Denk';

  @override
  String get appTagline => 'Shared expenses, settled simply';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get navGroups => 'Groups';

  @override
  String get navActivity => 'Activity';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeTitle => 'Welcome to Denk';

  @override
  String get welcomeSubtitle =>
      'Keep track of shared expenses with friends, roommates, and family without passwords or personal data.';

  @override
  String get chooseDisplayName => 'Choose your display name';

  @override
  String get displayNameHint => 'e.g. Alex, Sam, Ömer';

  @override
  String get displayNameValidation =>
      'Please enter a name between 2 and 50 characters';

  @override
  String get getStarted => 'Get Started';

  @override
  String get createGroup => 'Create Group';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get groupNameLabel => 'Group Name';

  @override
  String get groupNameHint => 'e.g. Ankara Flat, Berlin Trip, Dinner Party';

  @override
  String get groupCurrencyLabel => 'Currency';

  @override
  String get inviteCodeLabel => 'Invite Code';

  @override
  String get inviteCodeHint => 'e.g. DNK-7X2K';

  @override
  String get joinButton => 'Join';

  @override
  String get copyInviteCode => 'Copy Invite Code';

  @override
  String get inviteCodeCopied => 'Invite code copied to clipboard';

  @override
  String get noGroupsTitle => 'No groups yet';

  @override
  String get noGroupsSubtitle =>
      'Create a group or enter an invite code to start sharing expenses.';

  @override
  String get expensesTab => 'Expenses';

  @override
  String get balancesTab => 'Balances';

  @override
  String get settleTab => 'Settle Up';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get expenseTitle => 'What was it for?';

  @override
  String get expenseTitleHint => 'e.g. Groceries, Dinner, Electricity';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensePaidBy => 'Who paid?';

  @override
  String get expenseSplitWith => 'Who participated?';

  @override
  String get expenseSplitMethod => 'Split Method';

  @override
  String get splitEqual => 'Equally';

  @override
  String get splitCustom => 'Exact Amounts';

  @override
  String get splitPercentage => 'By Percentage';

  @override
  String get categoryFood => 'Food & Dining';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHome => 'Home & Rent';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryBills => 'Bills & Utilities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryOther => 'Other';

  @override
  String get totalSpending => 'Total Spending';

  @override
  String get yourBalance => 'Your Balance';

  @override
  String get youAreOwed => 'You are owed';

  @override
  String get youOwe => 'You owe';

  @override
  String get allSettled => 'All settled up';

  @override
  String get noExpensesTitle => 'No expenses yet';

  @override
  String get noExpensesSubtitle =>
      'Tap the button below to add your first expense.';

  @override
  String get settlementTitle => 'Settlement Plan';

  @override
  String get markAsSettled => 'Mark as Settled';

  @override
  String get settlementCompleted => 'Settlement recorded successfully';

  @override
  String get settlementHistory => 'Settlement History';

  @override
  String get noSettlementsNeeded =>
      'Everyone is settled up! No payments needed.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Preferred Currency';

  @override
  String get settingsPrivacy => 'Privacy & Data';

  @override
  String get settingsPrivacyInfo => 'Privacy Information';

  @override
  String get settingsDeleteAccount => 'Delete Local Account';

  @override
  String get settingsDeleteWarning =>
      'This will remove your local anonymous identity on this device. You will lose access to groups unless invited back.';

  @override
  String get settingsAbout => 'About Denk';

  @override
  String get settingsVersion => 'Version';

  @override
  String get expenseDetailTitle => 'Expense Details';

  @override
  String get deleteExpenseConfirmTitle => 'Delete Expense';

  @override
  String get deleteExpenseConfirmMessage =>
      'Are you sure you want to delete this expense? This will recalculate all group balances.';

  @override
  String get paidBy => 'Paid by';

  @override
  String get splitBetween => 'Split between';

  @override
  String get expenseNotes => 'Notes';
}
