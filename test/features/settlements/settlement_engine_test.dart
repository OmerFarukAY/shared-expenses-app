import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/settlements/domain/settlement_engine.dart';

void main() {
  group('SettlementEngine Tests', () {
    final memberNames = {
      'user_omer': 'Ömer',
      'user_ahmet': 'Ahmet',
      'user_mehmet': 'Mehmet',
      'user_can': 'Can',
    };

    test('Canonical example: Ömer +800, Ahmet -400, Mehmet -400', () {
      final netBalances = {
        'user_omer': 80000,
        'user_ahmet': -40000,
        'user_mehmet': -40000,
      };

      final txs = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'TRY',
      );

      expect(txs.length, 2);

      // Verify all transactions pay Ömer
      for (final tx in txs) {
        expect(tx.toUid, 'user_omer');
        expect(tx.toName, 'Ömer');
        expect(tx.amountMinor, 40000);
        expect(tx.currency, 'TRY');
      }

      final payers = txs.map((t) => t.fromUid).toSet();
      expect(payers, containsAll(['user_ahmet', 'user_mehmet']));
    });

    test('Two parties: Alice owes Bob ₺250.50', () {
      final netBalances = {'user_ahmet': -25050, 'user_omer': 25050};

      final txs = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'TRY',
      );

      expect(txs.length, 1);
      expect(txs.first.fromUid, 'user_ahmet');
      expect(txs.first.toUid, 'user_omer');
      expect(txs.first.amountMinor, 25050);
    });

    test('All already settled: zero transactions returned', () {
      final netBalances = {'user_omer': 0, 'user_ahmet': 0, 'user_mehmet': 0};

      final txs = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'EUR',
      );

      expect(txs, isEmpty);
    });

    test(
      'Circular debt simplification: A->B 100, B->C 100, C->A 100 net to 0',
      () {
        final netBalances = {'user_omer': 0, 'user_ahmet': 0, 'user_mehmet': 0};

        final txs = SettlementEngine.simplifyDebts(
          netBalances: netBalances,
          memberNames: memberNames,
          currency: 'TRY',
        );

        expect(txs, isEmpty);
      },
    );

    test('Multi-party asymmetric debt simplification', () {
      // Ömer: +1,500 (150000)
      // Ahmet: -700 (-70000)
      // Mehmet: -500 (-50000)
      // Can: -300 (-30000)
      final netBalances = {
        'user_omer': 150000,
        'user_ahmet': -70000,
        'user_mehmet': -50000,
        'user_can': -30000,
      };

      final txs = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'TRY',
      );

      // Total settled must be 150,000
      final totalSettled = txs.fold<int>(0, (sum, tx) => sum + tx.amountMinor);
      expect(totalSettled, 150000);

      // Max number of transactions for N=4 is at most N-1 = 3
      expect(txs.length, lessThanOrEqualTo(3));

      // Invariant: every transaction amount must be positive
      for (final tx in txs) {
        expect(tx.amountMinor, greaterThan(0));
      }
    });

    test('Determinism: same inputs always produce identical transactions', () {
      final netBalances = {
        'user_omer': 12345,
        'user_ahmet': -5000,
        'user_mehmet': -7345,
      };

      final txs1 = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'TRY',
      );

      final txs2 = SettlementEngine.simplifyDebts(
        netBalances: netBalances,
        memberNames: memberNames,
        currency: 'TRY',
      );

      expect(txs1, equals(txs2));
    });
  });
}
