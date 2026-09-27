import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';

void main() {
  group('GroupBalanceCalculator Tests', () {
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
      GroupMember(
        uid: 'user_mehmet',
        displayName: 'Mehmet',
        role: MemberRole.member,
        joinedAt: now,
      ),
    ];

    test('Single payer, equal split across 3 members', () {
      final expense = ExpenseModel(
        id: 'exp_1',
        groupId: 'grp_1',
        title: 'Dinner',
        category: ExpenseCategory.food,
        currency: 'TRY',
        totalMinor: 90000, // ₺900.00
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 90000},
        participants: ['user_omer', 'user_ahmet', 'user_mehmet'],
        splits: {'user_omer': 30000, 'user_ahmet': 30000, 'user_mehmet': 30000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      final summary = GroupBalanceCalculator.calculate(
        expenses: [expense],
        members: members,
        defaultCurrency: 'TRY',
      );

      expect(summary.totalGroupSpendingMinor, 90000);
      expect(summary.currencyCode, 'TRY');

      // Ömer: paid 900, owed 300 -> net = +600
      final omer = summary.memberBalances['user_omer']!;
      expect(omer.totalPaidMinor, 90000);
      expect(omer.totalOwedMinor, 30000);
      expect(omer.netBalanceMinor, 60000);
      expect(omer.isCreditor, isTrue);
      expect(omer.isDebtor, isFalse);

      // Ahmet: paid 0, owed 300 -> net = -300
      final ahmet = summary.memberBalances['user_ahmet']!;
      expect(ahmet.totalPaidMinor, 0);
      expect(ahmet.totalOwedMinor, 30000);
      expect(ahmet.netBalanceMinor, -30000);
      expect(ahmet.isDebtor, isTrue);

      // Mehmet: paid 0, owed 300 -> net = -300
      final mehmet = summary.memberBalances['user_mehmet']!;
      expect(mehmet.totalPaidMinor, 0);
      expect(mehmet.totalOwedMinor, 30000);
      expect(mehmet.netBalanceMinor, -30000);

      // Invariant: sum of net balances must equal 0
      final sumNet = summary.memberBalances.values
          .map((b) => b.netBalanceMinor)
          .fold(0, (a, b) => a + b);
      expect(sumNet, 0);
    });

    test('Multiple payers, custom split', () {
      // Ömer paid ₺1,000, Ahmet paid ₺600, Mehmet paid ₺400 (Total ₺2,000)
      // Custom allocations: Ömer owes ₺800, Ahmet owes ₺600, Mehmet owes ₺600
      final expense = ExpenseModel(
        id: 'exp_2',
        groupId: 'grp_1',
        title: 'Electricity & Gas',
        category: ExpenseCategory.bills,
        currency: 'TRY',
        totalMinor: 200000, // ₺2,000.00
        date: now,
        splitMethod: SplitMethod.custom,
        payers: {
          'user_omer': 100000,
          'user_ahmet': 60000,
          'user_mehmet': 40000,
        },
        participants: ['user_omer', 'user_ahmet', 'user_mehmet'],
        splits: {'user_omer': 80000, 'user_ahmet': 60000, 'user_mehmet': 60000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      final summary = GroupBalanceCalculator.calculate(
        expenses: [expense],
        members: members,
        defaultCurrency: 'TRY',
      );

      expect(summary.totalGroupSpendingMinor, 200000);

      // Ömer: paid 1,000, owed 800 -> +200
      expect(summary.getUserNetMinor('user_omer'), 20000);
      expect(summary.getUserTotalOwed('user_omer'), 20000);
      expect(summary.getUserTotalDebt('user_omer'), 0);

      // Ahmet: paid 600, owed 600 -> 0 (settled)
      expect(summary.getUserNetMinor('user_ahmet'), 0);
      expect(summary.memberBalances['user_ahmet']!.isSettled, isTrue);

      // Mehmet: paid 400, owed 600 -> -200
      expect(summary.getUserNetMinor('user_mehmet'), -20000);
      expect(summary.getUserTotalOwed('user_mehmet'), 0);
      expect(summary.getUserTotalDebt('user_mehmet'), 20000);
    });

    test('Multiple expenses accumulate properly', () {
      final exp1 = ExpenseModel(
        id: 'e1',
        groupId: 'grp_1',
        title: 'Groceries',
        category: ExpenseCategory.groceries,
        currency: 'TRY',
        totalMinor: 15000, // ₺150
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 15000},
        participants: ['user_omer', 'user_ahmet', 'user_mehmet'],
        splits: {'user_omer': 5000, 'user_ahmet': 5000, 'user_mehmet': 5000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      final exp2 = ExpenseModel(
        id: 'e2',
        groupId: 'grp_1',
        title: 'Snacks',
        category: ExpenseCategory.food,
        currency: 'TRY',
        totalMinor: 9000, // ₺90
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_ahmet': 9000},
        participants: ['user_omer', 'user_ahmet', 'user_mehmet'],
        splits: {'user_omer': 3000, 'user_ahmet': 3000, 'user_mehmet': 3000},
        createdBy: 'user_ahmet',
        createdAt: now,
        updatedAt: now,
      );

      final summary = GroupBalanceCalculator.calculate(
        expenses: [exp1, exp2],
        members: members,
        defaultCurrency: 'TRY',
      );

      expect(summary.totalGroupSpendingMinor, 24000);

      // Ömer: paid 150, owed (50+30)=80 -> +70 (7000 minor)
      expect(summary.getUserNetMinor('user_omer'), 7000);

      // Ahmet: paid 90, owed (50+30)=80 -> +10 (1000 minor)
      expect(summary.getUserNetMinor('user_ahmet'), 1000);

      // Mehmet: paid 0, owed (50+30)=80 -> -80 (-8000 minor)
      expect(summary.getUserNetMinor('user_mehmet'), -8000);
    });

    test('Different currency is excluded from default currency summary', () {
      final expTRY = ExpenseModel(
        id: 'e1',
        groupId: 'grp_1',
        title: 'TRY Expense',
        category: ExpenseCategory.food,
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 10000},
        participants: ['user_omer'],
        splits: {'user_omer': 10000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      final expUSD = ExpenseModel(
        id: 'e2',
        groupId: 'grp_1',
        title: 'USD Expense',
        category: ExpenseCategory.entertainment,
        currency: 'USD',
        totalMinor: 5000,
        date: now,
        splitMethod: SplitMethod.equal,
        payers: {'user_omer': 5000},
        participants: ['user_omer'],
        splits: {'user_omer': 5000},
        createdBy: 'user_omer',
        createdAt: now,
        updatedAt: now,
      );

      final summary = GroupBalanceCalculator.calculate(
        expenses: [expTRY, expUSD],
        members: members,
        defaultCurrency: 'TRY',
      );

      // USD should not be added into TRY spending
      expect(summary.totalGroupSpendingMinor, 10000);
    });
  });
}
