import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';

enum SplitMethod {
  equal,
  custom,
  percentage;

  static SplitMethod fromString(String? val) {
    if (val == null) return SplitMethod.equal;
    return SplitMethod.values.firstWhere(
      (m) => m.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SplitMethod.equal,
    );
  }
}

/// Represents an expense recorded within a group.
///
/// All monetary values are strictly represented in integer minor units.
/// Payers and participants are completely decoupled.
class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final String? notes;
  final ExpenseCategory category;
  final String currency;
  final int totalMinor;
  final DateTime date;
  final SplitMethod splitMethod;
  final Map<String, int> payers; // uid -> amountMinor paid
  final List<String> participants; // uids of participants
  final Map<String, int> splits; // uid -> amountMinor owed
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.notes,
    required this.category,
    required this.currency,
    required this.totalMinor,
    required this.date,
    required this.splitMethod,
    required this.payers,
    required this.participants,
    required this.splits,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Amount paid by the given user for this expense in minor units.
  int getPayerPaid(String uid) => payers[uid] ?? 0;

  /// Amount owed by the given user for this expense in minor units.
  int getParticipantOwed(String uid) => splits[uid] ?? 0;

  /// Net balance delta for the given user in minor units: paid - owed.
  int getNetForUser(String uid) => getPayerPaid(uid) - getParticipantOwed(uid);

  bool isPayer(String uid) => payers.containsKey(uid) && (payers[uid] ?? 0) > 0;

  bool isParticipant(String uid) => participants.contains(uid);

  ExpenseModel copyWith({
    String? title,
    String? notes,
    ExpenseCategory? category,
    String? currency,
    int? totalMinor,
    DateTime? date,
    SplitMethod? splitMethod,
    Map<String, int>? payers,
    List<String>? participants,
    Map<String, int>? splits,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      totalMinor: totalMinor ?? this.totalMinor,
      date: date ?? this.date,
      splitMethod: splitMethod ?? this.splitMethod,
      payers: payers ?? this.payers,
      participants: participants ?? this.participants,
      splits: splits ?? this.splits,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'category': category.name,
      'currency': currency,
      'totalMinor': totalMinor,
      'date': Timestamp.fromDate(date),
      'splitMethod': splitMethod.name,
      'payers': payers,
      'participants': participants,
      'splits': splits,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, int> parseMinorMap(dynamic raw) {
      if (raw is! Map) return {};
      final result = <String, int>{};
      raw.forEach((k, v) {
        if (k is String && v is num) {
          result[k] = v.toInt();
        }
      });
      return result;
    }

    List<String> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<String>().toList();
    }

    return ExpenseModel(
      id: (map['id'] as String?) ?? docId,
      groupId: (map['groupId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      notes: map['notes'] as String?,
      category: ExpenseCategory.fromString(map['category'] as String?),
      currency: (map['currency'] as String?) ?? 'TRY',
      totalMinor: (map['totalMinor'] as num?)?.toInt() ?? 0,
      date: parseDate(map['date']),
      splitMethod: SplitMethod.fromString(map['splitMethod'] as String?),
      payers: parseMinorMap(map['payers']),
      participants: parseList(map['participants']),
      splits: parseMinorMap(map['splits']),
      createdBy: (map['createdBy'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          groupId == other.groupId &&
          title == other.title &&
          totalMinor == other.totalMinor &&
          currency == other.currency;

  @override
  int get hashCode =>
      id.hashCode ^
      groupId.hashCode ^
      title.hashCode ^
      totalMinor.hashCode ^
      currency.hashCode;
}
