import 'dart:math';
import 'package:denk/features/settlements/domain/settlement_model.dart';

class _PartyBalance {
  final String uid;
  final String displayName;
  int amountMinor;

  _PartyBalance({
    required this.uid,
    required this.displayName,
    required this.amountMinor,
  });
}

abstract class SettlementEngine {
  /// Deterministically computes the minimal list of settlement transactions
  /// required to settle all debts in a group for a single currency.
  ///
  /// Uses a greedy bipartite matching algorithm.
  /// All calculations use strictly integer minor currency units.
  static List<SettlementTransaction> simplifyDebts({
    required Map<String, int> netBalances,
    required Map<String, String> memberNames,
    required String currency,
  }) {
    final List<_PartyBalance> debtors = [];
    final List<_PartyBalance> creditors = [];

    netBalances.forEach((uid, netMinor) {
      final name = memberNames[uid] ?? 'Member';
      if (netMinor < 0) {
        debtors.add(
          _PartyBalance(
            uid: uid,
            displayName: name,
            amountMinor: netMinor.abs(),
          ),
        );
      } else if (netMinor > 0) {
        creditors.add(
          _PartyBalance(uid: uid, displayName: name, amountMinor: netMinor),
        );
      }
    });

    final List<SettlementTransaction> transactions = [];

    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      // Sort debtors descending by amount, tie-break by UID for strict determinism
      debtors.sort((a, b) {
        final cmp = b.amountMinor.compareTo(a.amountMinor);
        return cmp != 0 ? cmp : a.uid.compareTo(b.uid);
      });

      // Sort creditors descending by amount, tie-break by UID
      creditors.sort((a, b) {
        final cmp = b.amountMinor.compareTo(a.amountMinor);
        return cmp != 0 ? cmp : a.uid.compareTo(b.uid);
      });

      final debtor = debtors.first;
      final creditor = creditors.first;

      final settleAmount = min(debtor.amountMinor, creditor.amountMinor);

      if (settleAmount > 0) {
        transactions.add(
          SettlementTransaction(
            fromUid: debtor.uid,
            fromName: debtor.displayName,
            toUid: creditor.uid,
            toName: creditor.displayName,
            amountMinor: settleAmount,
            currency: currency,
          ),
        );

        debtor.amountMinor -= settleAmount;
        creditor.amountMinor -= settleAmount;
      }

      if (debtor.amountMinor == 0) {
        debtors.removeAt(0);
      }
      if (creditor.amountMinor == 0) {
        creditors.removeAt(0);
      }
    }

    return transactions;
  }
}
