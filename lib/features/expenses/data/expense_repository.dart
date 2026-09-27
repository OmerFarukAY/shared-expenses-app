import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/expense_split_engine.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
  });
  Stream<List<ExpenseModel>> watchGroupExpenses(String groupId);
  Future<List<ExpenseModel>> getGroupExpenses(String groupId);
}

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirestoreExpenseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    // Validate financial invariants before sending to Firestore
    ExpenseSplitEngine.validatePayers(
      totalMinor: expense.totalMinor,
      payers: expense.payers,
    );

    if (expense.splitMethod == SplitMethod.custom) {
      ExpenseSplitEngine.validateCustomSplits(
        totalMinor: expense.totalMinor,
        splits: expense.splits,
      );
    }

    try {
      await _firestore
          .collection('groups')
          .doc(expense.groupId)
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    ExpenseSplitEngine.validatePayers(
      totalMinor: expense.totalMinor,
      payers: expense.payers,
    );

    if (expense.splitMethod == SplitMethod.custom) {
      ExpenseSplitEngine.validateCustomSplits(
        totalMinor: expense.totalMinor,
        splits: expense.splits,
      );
    }

    try {
      await _firestore
          .collection('groups')
          .doc(expense.groupId)
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Stream<List<ExpenseModel>> watchGroupExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }
}
