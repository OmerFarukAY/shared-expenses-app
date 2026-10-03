import 'package:cloud_firestore/cloud_firestore.dart';

/// A proposed settlement transaction calculated by the simplification engine.
class SettlementTransaction {
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;
  final int amountMinor;
  final String currency;

  const SettlementTransaction({
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.amountMinor,
    required this.currency,
  }) : assert(amountMinor > 0, 'Settlement amount must be positive'),
       assert(fromUid != toUid, 'Payer and recipient must differ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementTransaction &&
          runtimeType == other.runtimeType &&
          fromUid == other.fromUid &&
          toUid == other.toUid &&
          amountMinor == other.amountMinor &&
          currency == other.currency;

  @override
  int get hashCode =>
      fromUid.hashCode ^
      toUid.hashCode ^
      amountMinor.hashCode ^
      currency.hashCode;
}

/// A completed settlement record stored in Firestore under `groups/{groupId}/settlements/{id}`.
class SettlementRecord {
  final String id;
  final String groupId;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;
  final int amountMinor;
  final String currency;
  final DateTime settledAt;
  final String createdBy;
  final String? notes;

  /// Alias for backward compatibility with older UI/references.
  String get settledBy => createdBy;

  const SettlementRecord({
    required this.id,
    required this.groupId,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.amountMinor,
    required this.currency,
    required this.settledAt,
    String? createdBy,
    String? settledBy,
    this.notes,
  }) : createdBy = createdBy ?? settledBy ?? '',
       assert(amountMinor > 0, 'Settlement amount must be positive'),
       assert(fromUid != toUid, 'Payer and recipient must differ');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'toName': toName,
      'amountMinor': amountMinor,
      'currency': currency,
      'settledAt': Timestamp.fromDate(settledAt),
      'createdBy': createdBy,
      'settledBy': createdBy,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory SettlementRecord.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final creator =
        (map['createdBy'] as String?) ?? (map['settledBy'] as String?) ?? '';

    return SettlementRecord(
      id: (map['id'] as String?) ?? docId,
      groupId: (map['groupId'] as String?) ?? '',
      fromUid: (map['fromUid'] as String?) ?? '',
      fromName: (map['fromName'] as String?) ?? '',
      toUid: (map['toUid'] as String?) ?? '',
      toName: (map['toName'] as String?) ?? '',
      amountMinor: (map['amountMinor'] as num?)?.toInt() ?? 0,
      currency: (map['currency'] as String?) ?? 'TRY',
      settledAt: parseDate(map['settledAt']),
      createdBy: creator,
      notes: map['notes'] as String?,
    );
  }

  /// Generates a deterministic settlement document ID for a given debt payment.
  ///
  /// Combines the group ID, payer, recipient, currency, amount, and an activity
  /// token (e.g. latest contributing expense ID or settlement count) so that
  /// concurrent taps or multiple devices resolving the exact same debt share
  /// the identical document ID.
  ///
  /// When executed within a Firestore transaction, any duplicate/concurrent
  /// attempt targets this exact same document reference and is cleanly recognized
  /// as already existing, preventing duplicate writes and balance reversals.
  static String generateDeterministicId({
    required String groupId,
    required String fromUid,
    required String toUid,
    required String currency,
    required int amountMinor,
    String? activityToken,
  }) {
    final cleanGroup = groupId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final cleanFrom = fromUid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final cleanTo = toUid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final cleanCurr = currency.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final token = activityToken != null && activityToken.isNotEmpty
        ? activityToken.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        : 'base';

    return 'stl_${cleanGroup}_${cleanFrom}_${cleanTo}_${cleanCurr}_${amountMinor}_$token';
  }
}

