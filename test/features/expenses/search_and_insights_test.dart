import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/group_dashboard_screen.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/expenses/presentation/group_insights_sheet.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/l10n/l10n.dart';

void main() {
  final now = DateTime.now();

  final testGroup = GroupModel(
    id: 'grp_insights',
    name: 'Household',
    inviteCode: 'DNK-1234',
    defaultCurrency: 'TRY',
    createdBy: 'user_omer',
    createdAt: now,
    updatedAt: now,
    memberCount: 2,
  );

  final testMembers = [
    GroupMember(
      uid: 'user_omer',
      displayName: 'Ömer',
      role: MemberRole.owner,
      joinedAt: now,
    ),
    GroupMember(
      uid: 'user_ahmet',
      displayName: 'Ahmet',
      role: MemberRole.member,
      joinedAt: now,
    ),
  ];

  final testExpenses = [
    ExpenseModel(
      id: 'e1',
      groupId: 'grp_insights',
      title: 'Groceries Supermarket',
      category: ExpenseCategory.groceries,
      currency: 'TRY',
      totalMinor: 60000, // ₺600.00
      date: now,
      splitMethod: SplitMethod.equal,
      payers: {'user_omer': 60000},
      participants: ['user_omer', 'user_ahmet'],
      splits: {'user_omer': 30000, 'user_ahmet': 30000},
      createdBy: 'user_omer',
      createdAt: now,
      updatedAt: now,
    ),
    ExpenseModel(
      id: 'e2',
      groupId: 'grp_insights',
      title: 'Internet Fiber Bill',
      category: ExpenseCategory.bills,
      currency: 'TRY',
      totalMinor: 40000, // ₺400.00
      date: now,
      splitMethod: SplitMethod.equal,
      payers: {'user_ahmet': 40000},
      participants: ['user_omer', 'user_ahmet'],
      splits: {'user_omer': 20000, 'user_ahmet': 20000},
      createdBy: 'user_ahmet',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  testWidgets('GroupInsightsSheet renders category and member statistics', (
    tester,
  ) async {
    final summary = GroupBalanceCalculator.calculateAll(
      expenses: testExpenses,
      members: testMembers,
      defaultCurrency: 'TRY',
    )['TRY']!;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: Scaffold(
          body: GroupInsightsSheet(
            group: testGroup,
            members: testMembers,
            expenses: testExpenses,
            summary: summary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Total spending (600 + 400 = 1000)
    expect(find.textContaining('1000'), findsWidgets);

    // Verify Category breakdown
    expect(find.text('Spending by Category'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Bills & Utilities'), findsOneWidget);

    // Verify Member Contributions
    expect(find.text('Member Contributions'), findsOneWidget);
    expect(find.text('Ömer'), findsOneWidget);
    expect(find.text('Ahmet'), findsOneWidget);
  });

  testWidgets(
    'Expenses list search and category filtering works interactively',
    (tester) async {
      final widget = ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(
            () => _FakeUserProfileController(
              UserProfile(
                uid: 'user_omer',
                displayName: 'Ömer',
                createdAt: now,
                updatedAt: now,
              ),
            ),
          ),
          groupMembersStreamProvider(
            'grp_insights',
          ).overrideWith((ref) => Stream.value(testMembers)),
          groupExpensesStreamProvider(
            'grp_insights',
          ).overrideWith((ref) => Stream.value(testExpenses)),
          groupSettlementsStreamProvider(
            'grp_insights',
          ).overrideWith((ref) => Stream.value(<SettlementRecord>[])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: GroupDashboardScreen(group: testGroup),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Both expenses are visible initially
      expect(find.text('Groceries Supermarket'), findsOneWidget);
      expect(find.text('Internet Fiber Bill'), findsOneWidget);

      // Search for "Fiber"
      await tester.enterText(find.byType(TextField).first, 'Fiber');
      await tester.pumpAndSettle();

      expect(find.text('Internet Fiber Bill'), findsOneWidget);
      expect(find.text('Groceries Supermarket'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Groceries Supermarket'), findsOneWidget);
      expect(find.text('Internet Fiber Bill'), findsOneWidget);
    },
  );
}

class _FakeUserProfileController extends AsyncNotifier<UserProfile?>
    implements UserProfileController {
  final UserProfile? _profile;
  _FakeUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;

  @override
  Future<void> setDisplayName(
    String name, {
    String? preferredCurrency,
    String? languageCode,
  }) async {}

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> deleteAccount() async {}
}
