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
  final String settledBy;
  final String? notes;

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
    required this.settledBy,
    this.notes,
  }) : assert(amountMinor > 0, 'Settlement amount must be positive'),
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
      'settledBy': settledBy,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory SettlementRecord.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

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
      settledBy: (map['settledBy'] as String?) ?? '',
      notes: map['notes'] as String?,
    );
  }
}
