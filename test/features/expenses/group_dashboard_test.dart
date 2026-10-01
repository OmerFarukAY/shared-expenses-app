import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential;
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/group_dashboard_screen.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/expenses/presentation/expense_detail_screen.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/l10n/l10n.dart';

void main() {
  final now = DateTime.now();

  final testGroup = GroupModel(
    id: 'grp_test',
    name: 'Ankara Flat',
    inviteCode: 'DNK-9999',
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

  final testExpense = ExpenseModel(
    id: 'exp_test_1',
    groupId: 'grp_test',
    title: 'Supermarket Groceries',
    category: ExpenseCategory.groceries,
    currency: 'TRY',
    totalMinor: 40000, // ₺400.00
    date: now,
    splitMethod: SplitMethod.equal,
    payers: {'user_omer': 40000},
    participants: ['user_omer', 'user_ahmet'],
    splits: {'user_omer': 20000, 'user_ahmet': 20000},
    createdBy: 'user_omer',
    createdAt: now,
    updatedAt: now,
  );

  Widget createDashboardWidget() {
    return ProviderScope(
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
          'grp_test',
        ).overrideWith((ref) => Stream.value(testMembers)),
        groupExpensesStreamProvider(
          'grp_test',
        ).overrideWith((ref) => Stream.value([testExpense])),
        groupSettlementsStreamProvider(
          'grp_test',
        ).overrideWith((ref) => Stream.value(<SettlementRecord>[])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: GroupDashboardScreen(group: testGroup),
      ),
    );
  }

  testWidgets(
    'GroupDashboardScreen displays group info, hero balance, and expense item',
    (tester) async {
      await tester.pumpWidget(createDashboardWidget());
      await tester.pumpAndSettle();

      // Verify Group Name & Invite Code
      expect(find.text('Ankara Flat'), findsOneWidget);
      expect(find.text('DNK-9999'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);

      // Verify Hero balance card: Ömer paid 400, share 200 -> is owed 200
      expect(find.text('You are owed'), findsOneWidget);
      expect(find.textContaining('200'), findsWidgets);

      // Verify Expense Item in Tab
      expect(find.text('Supermarket Groceries'), findsOneWidget);
      expect(find.text('You paid'), findsOneWidget);

      // Switch to Balances Tab
      await tester.tap(find.text('Balances'));
      await tester.pumpAndSettle();

      // Verify members in balances list
      expect(find.text('Ömer (You)'), findsOneWidget);
      expect(find.text('Ahmet'), findsOneWidget);

      // Switch to Settle Tab
      await tester.tap(find.textContaining('Settle'));
      await tester.pumpAndSettle();

      // Verify simplified settlement transaction
      expect(find.text('Mark as Settled'), findsOneWidget);
    },
  );

  testWidgets('ExpenseDetailScreen renders full breakdown correctly', (
    tester,
  ) async {
    final detailWidget = ProviderScope(
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
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: ExpenseDetailScreen(
          expense: testExpense,
          group: testGroup,
          members: testMembers,
        ),
      ),
    );

    await tester.pumpWidget(detailWidget);
    await tester.pumpAndSettle();

    expect(find.text('Supermarket Groceries'), findsOneWidget);
    expect(find.text('Paid by'), findsOneWidget);
    expect(find.text('Split between'), findsOneWidget);
    expect(find.text('Equally'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });
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

  @override
  Future<void> linkGoogle({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkApple({AuthProvider? customProvider}) async {}

  @override
  Future<void> switchToExistingAccount(AuthCredential credential) async {}

  @override
  Future<void> switchToExistingProvider(AuthProvider provider) async {}
}
