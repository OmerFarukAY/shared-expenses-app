import 'package:denk/core/constants/currencies.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';

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
  /// Computes the complete financial summaries for a group and its members
  /// grouped by each currency used in expenses or settlements.
  static Map<String, GroupFinancialSummary> calculateAll({
    required List<ExpenseModel> expenses,
    required List<GroupMember> members,
    required String defaultCurrency,
    List<SettlementRecord> settlements = const [],
  }) {
    final Set<String> usedCurrencies = {defaultCurrency.toUpperCase()};
    for (final exp in expenses) {
      usedCurrencies.add(exp.currency.toUpperCase());
    }
    for (final set in settlements) {
      usedCurrencies.add(set.currency.toUpperCase());
    }

    final Map<String, GroupFinancialSummary> summaries = {};

    for (final currCode in usedCurrencies) {
      final currency = Currency.fromCode(currCode);
      int totalSpending = 0;

      final Map<String, int> paidByMember = {};
      final Map<String, int> owedByMember = {};

      for (final m in members) {
        paidByMember[m.uid] = 0;
        owedByMember[m.uid] = 0;
      }

      for (final expense in expenses) {
        if (expense.currency.toUpperCase() == currCode) {
          totalSpending += expense.totalMinor;

          expense.payers.forEach((uid, paid) {
            paidByMember[uid] = (paidByMember[uid] ?? 0) + paid;
          });

          expense.splits.forEach((uid, owed) {
            owedByMember[uid] = (owedByMember[uid] ?? 0) + owed;
          });
        }
      }

      for (final settlement in settlements) {
        if (settlement.currency.toUpperCase() == currCode) {
          paidByMember[settlement.fromUid] =
              (paidByMember[settlement.fromUid] ?? 0) + settlement.amountMinor;
          owedByMember[settlement.toUid] =
              (owedByMember[settlement.toUid] ?? 0) + settlement.amountMinor;
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

      summaries[currCode] = GroupFinancialSummary(
        currencyCode: currCode,
        currency: currency,
        totalGroupSpendingMinor: totalSpending,
        memberBalances: memberBalances,
      );
    }

    return summaries;
  }
}
