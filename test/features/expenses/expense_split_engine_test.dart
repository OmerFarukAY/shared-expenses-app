import 'package:flutter_test/flutter_test.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/expense_split_engine.dart';

void main() {
  group('ExpenseSplitEngine (Financial Correctness & Integer Invariants)', () {
    test('100 TL / 3 kişi eşit bölüşüm toplamı tam totalMinor ve hiçbir pay 0 veya negatif değil', () {
      final splits = ExpenseSplitEngine.calculateEqualSplits(
        totalMinor: 10000,
        participantUids: ['u1', 'u2', 'u3'],
      );
      expect(splits['u1'], 3334);
      expect(splits['u2'], 3333);
      expect(splits['u3'], 3333);
      expect(splits.values.every((v) => v > 0), isTrue);
      expect(splits.values.fold(0, (a, b) => a + b), 10000);
    });

    test('Equal split with clean division', () {
      final splits = ExpenseSplitEngine.calculateEqualSplits(
        totalMinor: 300,
        participantUids: ['u1', 'u2', 'u3'],
      );

      expect(splits['u1'], 100);
      expect(splits['u2'], 100);
      expect(splits['u3'], 100);
      expect(splits.values.fold(0, (a, b) => a + b), 300);
    });

    test(
      'Equal split with indivisible remainder distributes 1 cent to first members',
      () {
        // 100 minor units / 3 members = 33 base, 1 remainder
        final splits = ExpenseSplitEngine.calculateEqualSplits(
          totalMinor: 100,
          participantUids: ['u1', 'u2', 'u3'],
        );

        expect(splits['u1'], 34);
        expect(splits['u2'], 33);
        expect(splits['u3'], 33);
        // Strict invariant: sum of splits MUST equal totalMinor
        expect(splits.values.fold(0, (a, b) => a + b), 100);
      },
    );

    test('Equal split across 7 participants preserves exact sum invariant', () {
      const int total = 10000; // ₺100.00
      final members = List.generate(7, (i) => 'member_$i');

      final splits = ExpenseSplitEngine.calculateEqualSplits(
        totalMinor: total,
        participantUids: members,
      );

      expect(splits.length, 7);
      final sum = splits.values.fold(0, (a, b) => a + b);
      expect(sum, total);
    });

    test(
      'Equal split with 1 cent among 3 participants allocates 1 cent without loss',
      () {
        final splits = ExpenseSplitEngine.calculateEqualSplits(
          totalMinor: 1,
          participantUids: ['u1', 'u2', 'u3'],
        );

        expect(splits['u1'], 1);
        expect(splits['u2'], 0);
        expect(splits['u3'], 0);
        expect(splits.values.fold(0, (a, b) => a + b), 1);
      },
    );

    test(
      'Percentage split allocates correctly and adjusts rounding discrepancy',
      () {
        final splits = ExpenseSplitEngine.calculatePercentageSplits(
          totalMinor: 10000,
          percentages: {'u1': 50.0, 'u2': 25.0, 'u3': 25.0},
        );

        expect(splits['u1'], 5000);
        expect(splits['u2'], 2500);
        expect(splits['u3'], 2500);
        expect(splits.values.fold(0, (a, b) => a + b), 10000);
      },
    );

    test(
      'Percentage split with fractional percentages ensures exact sum matches total',
      () {
        final splits = ExpenseSplitEngine.calculatePercentageSplits(
          totalMinor: 1000,
          percentages: {'u1': 33.33, 'u2': 33.33, 'u3': 33.34},
        );

        final sum = splits.values.fold(0, (a, b) => a + b);
        expect(sum, 1000);
      },
    );

    test(
      'Percentage split throws AppException when percentages do not sum to 100%',
      () {
        expect(
          () => ExpenseSplitEngine.calculatePercentageSplits(
            totalMinor: 1000,
            percentages: {'u1': 40.0, 'u2': 40.0},
          ),
          throwsA(isA<AppException>()),
        );
      },
    );

    test('Validates multi-payer contributions correctly', () {
      // Ömer: 1000, Ahmet: 600, Mehmet: 400 => Total: 2000
      expect(
        () => ExpenseSplitEngine.validatePayers(
          totalMinor: 2000,
          payers: {'omer': 1000, 'ahmet': 600, 'mehmet': 400},
        ),
        returnsNormally,
      );

      // Mismatch throws AppException
      expect(
        () => ExpenseSplitEngine.validatePayers(
          totalMinor: 2000,
          payers: {'omer': 1000, 'ahmet': 600},
        ),
        throwsA(isA<AppException>()),
      );

      // Negative amount throws AppException
      expect(
        () => ExpenseSplitEngine.validatePayers(
          totalMinor: 2000,
          payers: {'omer': 2500, 'ahmet': -500},
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates custom split allocations correctly', () {
      expect(
        () => ExpenseSplitEngine.validateCustomSplits(
          totalMinor: 1500,
          splits: {'u1': 1000, 'u2': 500},
        ),
        returnsNormally,
      );

      expect(
        () => ExpenseSplitEngine.validateCustomSplits(
          totalMinor: 1500,
          splits: {'u1': 1000, 'u2': 600},
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('Decoupled Payers and Participants Invariant', () {
    test('Payer is not a participant (buying a gift or paying on behalf)', () {
      // Ömer pays ₺500 for Ahmet and Mehmet (who split ₺250 each). Ömer is not in participants.
      final expense = ExpenseModel(
        id: 'exp_1',
        groupId: 'grp_1',
        title: 'Birthday Gift',
        category: ExpenseCategory.other,
        currency: 'TRY',
        totalMinor: 50000,
        date: DateTime.now(),
        splitMethod: SplitMethod.equal,
        payers: {'omer': 50000},
        participants: ['ahmet', 'mehmet'],
        splits: {'ahmet': 25000, 'mehmet': 25000},
        createdBy: 'omer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Ömer net: paid 50000, owed 0 => +50000
      expect(expense.getNetForUser('omer'), 50000);
      // Ahmet net: paid 0, owed 25000 => -25000
      expect(expense.getNetForUser('ahmet'), -25000);
      // Mehmet net: paid 0, owed 25000 => -25000
      expect(expense.getNetForUser('mehmet'), -25000);

      // Sum of net balances for this expense MUST be zero
      final sumNet =
          expense.getNetForUser('omer') +
          expense.getNetForUser('ahmet') +
          expense.getNetForUser('mehmet');
      expect(sumNet, 0);
    });
  });
}
