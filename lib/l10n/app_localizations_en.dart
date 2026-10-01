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
  String get youLabel => 'You';

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
  String get youPaid => 'You paid';

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

  @override
  String get searchHint => 'Search expenses...';

  @override
  String get filterAll => 'All';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noMatchingExpenses => 'No matching expenses';

  @override
  String get tryClearingSearchFilter =>
      'Try clearing your search or filter options.';

  @override
  String get spendingInsights => 'Spending Overview';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get memberContributions => 'Member Contributions';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get anonymousAccount => 'Anonymous Firebase Account';

  @override
  String get copyId => 'Copy ID';

  @override
  String get membersLabel => 'members';

  @override
  String get requestToJoinButton => 'Request to Join';

  @override
  String get joinRequestSentTitle => 'Request Sent';

  @override
  String joinRequestSentSubtitle(String groupName) {
    return 'Your request to join $groupName has been submitted. You will be able to access the group once an owner approves it.';
  }

  @override
  String get joinRequestPending => 'Pending Approval';

  @override
  String get joinRequestApproved => 'Approved';

  @override
  String get joinRequestRejected => 'Rejected';

  @override
  String get joinRequestsTitle => 'Join Requests';

  @override
  String get approveButton => 'Approve';

  @override
  String get rejectButton => 'Reject';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get cancelRequestButton => 'Cancel Request';

  @override
  String get joinRequestCancelled => 'Join request cancelled';

  @override
  String get pendingApprovalCardTitle => 'Pending Approval';

  @override
  String get pendingApprovalCardSubtitle => 'Waiting for group owner approval.';

  @override
  String get invalidOrInactiveInvite => 'Invite code not found or inactive';

  @override
  String get alreadyMemberError => 'You are already a member of this group.';

  @override
  String get requestAlreadyPendingError =>
      'You already have a pending request for this group.';

  @override
  String get manageJoinRequestsTooltip => 'Manage Join Requests';

  @override
  String pendingRequestsBadge(int count) {
    return '$count pending';
  }

  @override
  String get settledBadge => 'Settled';

  @override
  String get noCategoryData => 'No category data available yet.';

  @override
  String get copyAction => 'Copy';

  @override
  String get uidCopiedSnackbar => 'UID copied to clipboard';

  @override
  String get privacyCalloutTitle =>
      'Privacy-First, Data-Minimized Architecture';

  @override
  String get privacyCalloutBody =>
      'No email, phone, or passwords collected. Only group members can view group balances.';

  @override
  String get readAction => 'Read';

  @override
  String get expensePaidByMultiple => 'Multiple people paid';

  @override
  String get expensePaidByMultipleAdvanced => 'Multiple people paid...';

  @override
  String get expenseSwitchToMultiplePayers => 'Switch to Multiple Payers';

  @override
  String get expenseSwitchToSinglePayer => 'Switch to Single Payer';

  @override
  String get expenseSplit => 'Split';

  @override
  String get expenseSplitCustomize => 'Customize';

  @override
  String expenseSplitSummaryEqually(int count) {
    return 'Equally · $count people ›';
  }

  @override
  String expenseSplitSummaryCustom(int count) {
    return 'Custom · $count people ›';
  }

  @override
  String expenseSplitSummaryPercentage(int count) {
    return 'Percentage · $count people ›';
  }

  @override
  String expenseLiveSummary(String payer, String amount, int count) {
    return '$payer paid $amount · Split among $count people';
  }

  @override
  String expenseLiveSummaryMultiple(String amount, int count) {
    return 'Multiple paid $amount · Split among $count people';
  }

  @override
  String expenseLiveSummaryRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String expenseLiveSummaryOver(String amount) {
    return '$amount over';
  }

  @override
  String get errorTooManyPayers => 'Too many payers (max 5)';

  @override
  String get errorTooManyParticipants => 'Too many participants (max 20)';

  @override
  String get errorNegativeAmount => 'Amounts must be greater than zero';

  @override
  String expenseZeroShareRemoved(int count) {
    return '$count participant(s) with 0 share removed.';
  }

  @override
  String get languageSystem => 'System Language';

  @override
  String get currency => 'Currency';

  @override
  String get memberLeftSuffix => ' (left)';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get cannotRemoveMemberBalance =>
      'Member cannot be removed before their balance is zero.';

  @override
  String get cannotLeaveGroupBalance =>
      'You cannot leave the group before your balance is zero.';
}
