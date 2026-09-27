import 'package:denk/core/constants/currencies.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';

/// Computed financial balance overview for a single member in a group.
class MemberBalance {
  final String uid;
  final String displayName;
  final int totalPaidMinor;
  final int totalOwedMinor;

  const MemberBalance({
    required this.uid,
    required this.displayName,
    required this.totalPaidMinor,
    required this.totalOwedMinor,
  });

  /// Net balance in integer minor units.
  ///
  /// Positive (> 0): Creditor (is owed money).
  /// Negative (< 0): Debtor (owes money).
  /// Zero (== 0): Settled.
  int get netBalanceMinor => totalPaidMinor - totalOwedMinor;

  bool get isCreditor => netBalanceMinor > 0;
  bool get isDebtor => netBalanceMinor < 0;
  bool get isSettled => netBalanceMinor == 0;
}

/// Computed overall financial state of a group for a specific currency.
class GroupFinancialSummary {
  final String currencyCode;
  final Currency currency;
  final int totalGroupSpendingMinor;
  final Map<String, MemberBalance> memberBalances;

  const GroupFinancialSummary({
    required this.currencyCode,
    required this.currency,
    required this.totalGroupSpendingMinor,
    required this.memberBalances,
  });

  /// Net balance for the target user.
  int getUserNetMinor(String uid) {
    return memberBalances[uid]?.netBalanceMinor ?? 0;
  }

  /// Total amount the user is owed (sum of credits).
  int getUserTotalOwed(String uid) {
    final net = getUserNetMinor(uid);
    return net > 0 ? net : 0;
  }

  /// Total amount the user owes to others (positive integer).
  int getUserTotalDebt(String uid) {
    final net = getUserNetMinor(uid);
    return net < 0 ? net.abs() : 0;
  }
}

abstract class GroupBalanceCalculator {
  /// Computes the complete financial summary for a group and its members
  /// based on recorded expenses.
  ///
  /// All computations use strict 64-bit integer minor currency units.
  static GroupFinancialSummary calculate({
    required List<ExpenseModel> expenses,
    required List<GroupMember> members,
    required String defaultCurrency,
  }) {
    final currency = Currency.fromCode(defaultCurrency);
    int totalSpending = 0;

    final Map<String, int> paidByMember = {};
    final Map<String, int> owedByMember = {};

    for (final m in members) {
      paidByMember[m.uid] = 0;
      owedByMember[m.uid] = 0;
    }

    for (final expense in expenses) {
      // For V1, calculate per group default currency or match currency
      if (expense.currency.toUpperCase() == defaultCurrency.toUpperCase()) {
        totalSpending += expense.totalMinor;

        // Add payer contributions
        expense.payers.forEach((uid, paid) {
          paidByMember[uid] = (paidByMember[uid] ?? 0) + paid;
        });

        // Add participant owed allocations
        expense.splits.forEach((uid, owed) {
          owedByMember[uid] = (owedByMember[uid] ?? 0) + owed;
        });
      }
    }

    final Map<String, MemberBalance> memberBalances = {};
    for (final m in members) {
      memberBalances[m.uid] = MemberBalance(
        uid: m.uid,
        displayName: m.displayName,
        totalPaidMinor: paidByMember[m.uid] ?? 0,
        totalOwedMinor: owedByMember[m.uid] ?? 0,
      );
    }

    return GroupFinancialSummary(
      currencyCode: defaultCurrency,
      currency: currency,
      totalGroupSpendingMinor: totalSpending,
      memberBalances: memberBalances,
    );
  }
}
