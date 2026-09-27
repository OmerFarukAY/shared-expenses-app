import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/expense_item_tile.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility & UX Polish Suite', () {
    testWidgets('DenkButton satisfies 48dp minimum touch target height', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: DenkButton(label: 'Submit Payment', onPressed: () {}),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(DenkButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
        reason: 'Touch target height must be >= 48dp for accessibility',
      );
    });

    testWidgets('DenkButton has semantic button node and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: DenkButton(label: 'Add Expense', onPressed: () {}),
            ),
          ),
        ),
      );

      final buttonSemantics = find.bySemanticsLabel('Add Expense');
      expect(buttonSemantics, findsOneWidget);
      expect(
        tester.getSemantics(buttonSemantics),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Add Expense',
        ),
      );
    });

    testWidgets('DenkBalancePill has rich semantic labels for screen readers', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(
              children: [
                DenkBalancePill(
                  balanceMinor: 25000,
                  currency: Currency.tryCurrency,
                ),
                DenkBalancePill(
                  balanceMinor: -15000,
                  currency: Currency.tryCurrency,
                ),
                DenkBalancePill(
                  balanceMinor: 0,
                  currency: Currency.tryCurrency,
                ),
              ],
            ),
          ),
        ),
      );

      final pills = find.byType(DenkBalancePill);
      expect(pills, findsNWidgets(3));

      // Positive balance semantics
      expect(
        tester.getSemantics(pills.at(0)),
        matchesSemantics(label: 'Positive balance +₺250.00'),
      );

      // Negative balance semantics
      expect(
        tester.getSemantics(pills.at(1)),
        matchesSemantics(label: 'Negative balance -₺150.00'),
      );

      // Settled balance semantics
      expect(
        tester.getSemantics(pills.at(2)),
        matchesSemantics(label: 'Settled balance ₺0.00'),
      );
    });

    testWidgets(
      'ExpenseItemTile has rich semantics and handles 1.5x font scale',
      (tester) async {
        final expense = ExpenseModel(
          id: 'exp-1',
          groupId: 'grp-1',
          title: 'Weekly Groceries at Migros',
          totalMinor: 120000,
          currency: 'TRY',
          category: ExpenseCategory.groceries,
          date: DateTime(2026, 9, 27),
          createdBy: 'user-1',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
          payers: {'user-1': 120000},
          participants: ['user-1', 'user-2'],
          splitMethod: SplitMethod.equal,
          splits: {'user-1': 60000, 'user-2': 60000},
        );

        final members = [
          GroupMember(
            uid: 'user-1',
            displayName: 'Ömer',
            role: MemberRole.owner,
            joinedAt: DateTime(2026, 1, 1),
          ),
          GroupMember(
            uid: 'user-2',
            displayName: 'Ahmet',
            role: MemberRole.member,
            joinedAt: DateTime(2026, 1, 2),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: ListView(
                  children: [
                    ExpenseItemTile(
                      expense: expense,
                      members: members,
                      currentUserId: 'user-1',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ExpenseItemTile), findsOneWidget);

        expect(
          tester.getSemantics(find.byType(ExpenseItemTile)),
          matchesSemantics(
            isButton: true,
            label:
                'Weekly Groceries at Migros, total ₺1200.00, You paid, you are owed ₺600.00',
          ),
        );
      },
    );
  });
}
