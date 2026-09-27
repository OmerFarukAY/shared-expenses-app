import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';

void main() {
  group('Settlement Balance Integration Tests', () {
    final now = DateTime.now();

    final members = [
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

    test('Completed settlement offsets debt and restores net balance to 0', () {
      // Ömer paid ₺100 for Ömer and Ahmet (equal split)
      // Ahmet owes ₺50
      final expense = ExpenseModel(
        id: 'exp_1',
        groupId: 'grp_1',
        title: 'Lunch',
        category: ExpenseCategory.food,
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 10000},
        participants: ['user_omer', 'user_ahmet'],
        splits: {'user_omer': 5000, 'user_ahmet': 5000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      // Before settlement: Ömer is +50, Ahmet is -50
      final beforeSummary = GroupBalanceCalculator.calculate(
        expenses: [expense],
        members: members,
        defaultCurrency: 'TRY',
      );

      expect(beforeSummary.getUserNetMinor('user_omer'), 5000);
      expect(beforeSummary.getUserNetMinor('user_ahmet'), -5000);

      // Ahmet pays Ömer ₺50
      final settlement = SettlementRecord(
        id: 'set_1',
        groupId: 'grp_1',
        fromUid: 'user_ahmet',
        fromName: 'Ahmet',
        toUid: 'user_omer',
        toName: 'Ömer',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        settledBy: 'user_ahmet',
      );

      // After settlement: Both net balances should be 0
      final afterSummary = GroupBalanceCalculator.calculate(
        expenses: [expense],
        members: members,
        defaultCurrency: 'TRY',
        settlements: [settlement],
      );

      expect(afterSummary.getUserNetMinor('user_omer'), 0);
      expect(afterSummary.getUserNetMinor('user_ahmet'), 0);
      expect(afterSummary.memberBalances['user_omer']!.isSettled, isTrue);
      expect(afterSummary.memberBalances['user_ahmet']!.isSettled, isTrue);

      // Total group spending should remain ₺100 (settlement is not spending)
      expect(afterSummary.totalGroupSpendingMinor, 10000);
    });
  });
}
