import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/data/expense_repository.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/add_expense_screen.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/l10n/l10n.dart';

class MockExpenseRepository implements ExpenseRepository {
  ExpenseModel? lastAdded;

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    lastAdded = expense;
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {}

  @override
  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
  }) async {}

  @override
  Stream<List<ExpenseModel>> watchGroupExpenses(String groupId) =>
      Stream.value([]);

  @override
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async => [];
}

void main() {
  final testGroup = GroupModel(
    id: 'grp_1',
    name: 'Ankara Flat',
    defaultCurrency: 'TRY',
    inviteCode: 'DNK-7X2K',
    createdBy: 'u1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    memberCount: 2,
  );

  final testMembers = [
    GroupMember(
      uid: 'u1',
      displayName: 'Ömer',
      role: MemberRole.owner,
      joinedAt: DateTime.now(),
    ),
    GroupMember(
      uid: 'u2',
      displayName: 'Ahmet',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
    ),
  ];

  final currentUser = UserProfile(
    uid: 'u1',
    displayName: 'Ömer',
    preferredCurrency: 'TRY',
    languageCode: 'tr',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildTestable({required MockExpenseRepository repo}) {
    return ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        userProfileControllerProvider.overrideWith(
          () => _TestProfileNotifier(currentUser),
        ),
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
        home: AddExpenseScreen(group: testGroup, members: testMembers),
      ),
    );
  }

  testWidgets(
    'AddExpenseScreen validates empty amount and creates expense on valid input',
    (tester) async {
      final repo = MockExpenseRepository();

      await tester.pumpWidget(buildTestable(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('Add Expense'),
        findsNWidgets(2),
      ); // AppBar title and bottom button
      expect(find.text('What was it for?'), findsOneWidget);
      expect(find.text('Who paid?'), findsOneWidget);
      expect(find.text('Who participated?'), findsOneWidget);

      // Tap Save without entering amount
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount.'), findsOneWidget);

      // Enter amount "100.00" (which corresponds to 10000 minor units)
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '100.00');
      await tester.pumpAndSettle();

      // Enter title "Dinner"
      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Dinner with friends');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify repository received the expense with integer minor units
      expect(repo.lastAdded, isNotNull);
      expect(repo.lastAdded!.title, 'Dinner with friends');
      expect(repo.lastAdded!.totalMinor, 10000); // ₺100.00 = 10000 minor units
      expect(repo.lastAdded!.payers['u1'], 10000); // Ömer paid all
      expect(repo.lastAdded!.participants.length, 2); // Both participated
      expect(repo.lastAdded!.splits['u1'], 5000); // ₺50.00 split
      expect(repo.lastAdded!.splits['u2'], 5000); // ₺50.00 split
    },
  );
}

class _TestProfileNotifier extends UserProfileController {
  final UserProfile _initial;
  _TestProfileNotifier(this._initial);

  @override
  Future<UserProfile?> build() async => _initial;
}
