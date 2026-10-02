import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential;
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/domain/account_deletion_service.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/groups_list_screen.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E2E Complete User Journey Integration Test', () {
    final now = DateTime.now();

    final testProfile = UserProfile(
      uid: 'user_omer',
      displayName: 'Ömer',
      preferredCurrency: 'TRY',
      languageCode: 'en',
      createdAt: now,
      updatedAt: now,
    );

    final testGroup = GroupModel(
      id: 'grp_ankara',
      name: 'Ankara Flat',
      inviteCode: 'DNK-7X2K',
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
        id: 'exp_1',
        groupId: 'grp_ankara',
        title: 'Electricity & Internet Bill',
        category: ExpenseCategory.bills,
        currency: 'TRY',
        totalMinor: 100000, // ₺1000.00
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 100000},
        participants: ['user_omer', 'user_ahmet'],
        splits: {'user_omer': 50000, 'user_ahmet': 50000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    Widget buildTestApp({required Widget home}) {
      final fakeController = _MockUserProfileController(testProfile);

      return ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(() => fakeController),
          userGroupsStreamProvider.overrideWith(
            (ref) => Stream.value([testGroup]),
          ),
          groupMembersStreamProvider(
            testGroup.id,
          ).overrideWith((ref) => Stream.value(testMembers)),
          groupExpensesStreamProvider(
            testGroup.id,
          ).overrideWith((ref) => Stream.value(testExpenses)),
          groupSettlementsStreamProvider(
            testGroup.id,
          ).overrideWith((ref) => Stream.value(<SettlementRecord>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: home,
        ),
      );
    }

    testWidgets(
      'Full flow: Groups list -> Dashboard -> Settle Up tab -> Search filter -> Settings',
      (tester) async {
        // Step 1: Render Groups list
        await tester.pumpWidget(buildTestApp(home: const GroupsListScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(DenkLogo), findsOneWidget);
        expect(find.text('Ankara Flat'), findsOneWidget);
        expect(find.text('Invite Code: DNK-7X2K'), findsOneWidget);

        // Step 2: Tap group card to navigate to GroupDashboardScreen
        await tester.tap(find.text('Ankara Flat'));
        await tester.pumpAndSettle();

        // Step 3: Verify GroupDashboardScreen header and hero balance
        expect(find.text('Ankara Flat'), findsWidgets);
        expect(find.text('You are owed'), findsOneWidget);
        expect(
          find.text('+₺500.00'),
          findsWidgets,
        ); // Both hero card and expense item show +₺500.00
        expect(find.text('Electricity & Internet Bill'), findsOneWidget);

        // Step 4: Switch to "Settle Up" tab
        final settleTabFinder = find.text('Settle Up (1)');
        expect(settleTabFinder, findsOneWidget);
        await tester.tap(settleTabFinder);
        await tester.pumpAndSettle();

        expect(find.text('Settlement Plan'), findsOneWidget);
        expect(find.text('Ahmet'), findsWidgets);
        expect(find.text('You'), findsWidgets);
        expect(find.text('₺500.00'), findsWidgets);
        expect(find.text('Mark as Settled'), findsOneWidget);

        // Step 5: Switch back to Expenses tab and test live search
        final expensesTabFinder = find.text('Expenses (1)');
        await tester.tap(expensesTabFinder);
        await tester.pumpAndSettle();

        final searchInput = find.byType(TextField);
        expect(searchInput, findsOneWidget);

        // Search non-existent term
        await tester.enterText(searchInput, 'Coffee');
        await tester.pumpAndSettle();
        expect(find.text('No matching expenses'), findsOneWidget);

        // Clear search
        final clearButton = find.byIcon(Icons.clear_rounded);
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
        expect(find.text('Electricity & Internet Bill'), findsOneWidget);

        // Step 6: Navigate back to Groups List, then to Settings
        await tester.pageBack();
        await tester.pumpAndSettle();

        final settingsButton = find.byTooltip('Settings');
        expect(settingsButton, findsOneWidget);
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Step 7: Verify SettingsScreen rendered with user and privacy details
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Ömer'), findsOneWidget);
        expect(find.text('Anonymous Firebase Account'), findsOneWidget);
        expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Privacy Information'), findsOneWidget);
        expect(find.text('Delete Account'), findsWidgets);

        // Step 8: Open Privacy Information modal
        await tester.ensureVisible(find.text('Read'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Read'));
        await tester.pumpAndSettle();

        expect(
          find.text('Privacy-First, Data-Minimized Architecture'),
          findsOneWidget,
        );
        expect(find.text('Done'), findsOneWidget);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(
          find.text('Privacy-First, Data-Minimized Architecture'),
          findsNothing,
        );
      },
    );
  });
}

class _MockUserProfileController extends AsyncNotifier<UserProfile?>
    implements UserProfileController {
  final UserProfile? _profile;
  bool deleteCalled = false;
  String? updatedName;

  _MockUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;

  @override
  Future<void> setDisplayName(
    String name, {
    String? preferredCurrency,
    String? languageCode,
  }) async {}

  @override
  Future<void> updateDisplayName(String name) async {
    updatedName = name;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalled = true;
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> linkGoogle({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkApple({AuthProvider? customProvider}) async {}

  @override
  Future<void> switchToExistingAccount(AuthCredential credential) async {}

  @override
  Future<void> switchToExistingProvider(AuthProvider provider) async {}

  @override
  Future<List<OwnedGroupBlock>> analyzeOwnershipBlocks() async => const [];

  @override
  Future<void> transferGroupOwnership({
    required String groupId,
    required String currentOwnerUid,
    required String newOwnerUid,
    required String newOwnerDisplayName,
  }) async {}

  @override
  Future<void> deleteAccountFull() async {
    deleteCalled = true;
    state = const AsyncValue.data(null);
  }
}
