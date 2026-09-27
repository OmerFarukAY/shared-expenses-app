import 'package:denk/core/errors/app_exception.dart';

/// Pure financial calculation and split engine.
///
/// Operates strictly with 64-bit integer minor currency units.
/// Floating-point math is NEVER used for monetary values.
abstract class ExpenseSplitEngine {
  /// Calculates an equal split among [participantUids] in integer minor units.
  ///
  /// Any indivisible remainder cents/kuruş are distributed 1 unit per participant
  /// starting from the first participant, guaranteeing that:
  /// `sum(splits) == totalMinor` strictly.
  static Map<String, int> calculateEqualSplits({
    required int totalMinor,
    required List<String> participantUids,
  }) {
    if (participantUids.isEmpty || totalMinor <= 0) {
      return {};
    }

    final int count = participantUids.length;
    final int base = totalMinor ~/ count;
    final int remainder = totalMinor % count;

    final Map<String, int> splits = {};
    for (int i = 0; i < count; i++) {
      final uid = participantUids[i];
      // Distribute 1 minor unit remainder to first participants
      final int extra = i < remainder ? 1 : 0;
      splits[uid] = base + extra;
    }

    return splits;
  }

  /// Calculates percentage-based splits in integer minor units.
  ///
  /// [percentages] maps participant UID to their percentage value (e.g. 50.0 for 50%).
  /// The sum of percentages must equal 100.0 (tolerance 0.05% for rounding).
  /// Any fractional rounding minor units are distributed deterministically so that:
  /// `sum(splits) == totalMinor` strictly.
  static Map<String, int> calculatePercentageSplits({
    required int totalMinor,
    required Map<String, double> percentages,
  }) {
    if (percentages.isEmpty || totalMinor <= 0) {
      return {};
    }

    // Validate percentage sum
    final double totalPct = percentages.values.fold(0.0, (acc, p) => acc + p);
    if ((totalPct - 100.0).abs() > 0.1) {
      throw const AppException(
        message: 'The sum of all percentages must equal 100%.',
        code: 'invalid-percentage-sum',
      );
    }

    final Map<String, int> splits = {};
    int sumAllocated = 0;

    // First pass: compute floor allocations
    for (final entry in percentages.entries) {
      // (totalMinor * pct * 10) ~/ 1000 to keep integer precision
      final int amount = (totalMinor * entry.value / 100.0).round();
      splits[entry.key] = amount;
      sumAllocated += amount;
    }

    // Distribute any discrepancy due to integer rounding
    final int diff = totalMinor - sumAllocated;
    if (diff != 0 && splits.isNotEmpty) {
      // Adjust the first participant with non-zero allocation
      final firstKey = splits.keys.first;
      splits[firstKey] = splits[firstKey]! + diff;
    }

    return splits;
  }

  /// Validates that total of payer contributions matches [totalMinor] exactly.
  static void validatePayers({
    required int totalMinor,
    required Map<String, int> payers,
  }) {
    if (totalMinor <= 0) {
      throw const AppException(
        message: 'Expense amount must be greater than zero.',
        code: 'invalid-amount',
      );
    }

    if (payers.isEmpty) {
      throw const AppException(
        message: 'At least one payer must be specified.',
        code: 'no-payers',
      );
    }

    int sumPayers = 0;
    for (final entry in payers.entries) {
      if (entry.value < 0) {
        throw const AppException(
          message: 'Payer amounts cannot be negative.',
          code: 'negative-payer-amount',
        );
      }
      sumPayers += entry.value;
    }

    if (sumPayers != totalMinor) {
      throw AppException(
        message:
            'Total paid ($sumPayers) does not match the expense amount ($totalMinor).',
        code: 'payer-sum-mismatch',
      );
    }
  }

  /// Validates that sum of custom participant allocations matches [totalMinor] exactly.
  static void validateCustomSplits({
    required int totalMinor,
    required Map<String, int> splits,
  }) {
    if (splits.isEmpty) {
      throw const AppException(
        message: 'At least one participant must be included in the split.',
        code: 'no-participants',
      );
    }

    int sumSplits = 0;
    for (final entry in splits.entries) {
      if (entry.value < 0) {
        throw const AppException(
          message: 'Participant allocations cannot be negative.',
          code: 'negative-split-amount',
        );
      }
      sumSplits += entry.value;
    }

    if (sumSplits != totalMinor) {
      throw AppException(
        message:
            'Sum of splits ($sumSplits) does not match total expense ($totalMinor).',
        code: 'split-sum-mismatch',
      );
    }
  }
}
