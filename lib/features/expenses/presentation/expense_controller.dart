import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/features/expenses/data/expense_repository.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';

/// Provider for the singleton [ExpenseRepository].
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirestoreExpenseRepository();
});

/// Stream provider for all expenses in a group sorted by date descending.
final groupExpensesStreamProvider =
    StreamProvider.family<List<ExpenseModel>, String>((ref, groupId) {
      final repo = ref.watch(expenseRepositoryProvider);
      return repo.watchGroupExpenses(groupId);
    });

/// Controller handling expense write operations.
class ExpenseController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addExpense(ExpenseModel expense) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.addExpense(expense);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.updateExpense(expense);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.deleteExpense(groupId: groupId, expenseId: expenseId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final expenseControllerProvider =
    AsyncNotifierProvider<ExpenseController, void>(ExpenseController.new);
