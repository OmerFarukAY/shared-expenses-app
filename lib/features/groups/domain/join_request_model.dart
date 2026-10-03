import 'package:cloud_firestore/cloud_firestore.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static JoinRequestStatus fromString(String? val) {
    if (val == null) return JoinRequestStatus.pending;
    return JoinRequestStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == val.toLowerCase(),
      orElse: () => JoinRequestStatus.pending,
    );
  }
}

/// Represents a pending or resolved membership request for a group.
///
/// Under Phase 15 security architecture, entering an invite code does not
/// grant immediate membership; it creates a [JoinRequestModel] awaiting
/// group creator/owner approval.
class JoinRequestModel {
  final String id; // document ID, matches requester's UID
  final String groupId;
  final String uid; // requester's UID
  final String displayName;
  final JoinRequestStatus status;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy; // UID of creator who approved/rejected
  final int rejectionCount;

  const JoinRequestModel({
    required this.id,
    required this.groupId,
    required this.uid,
    required this.displayName,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.rejectionCount = 0,
  });

  bool get isPending => status == JoinRequestStatus.pending;
  bool get isApproved => status == JoinRequestStatus.approved;
  bool get isRejected => status == JoinRequestStatus.rejected;
  bool get isCancelled => status == JoinRequestStatus.cancelled;
  bool get isLimitReached => rejectionCount >= 3;

  JoinRequestModel copyWith({
    String? id,
    String? groupId,
    String? uid,
    String? displayName,
    JoinRequestStatus? status,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    int? rejectionCount,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      rejectionCount: rejectionCount ?? this.rejectionCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'uid': uid,
      'displayName': displayName,
      'status': status.name,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rejectionCount': rejectionCount,
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
    };
  }

  factory JoinRequestModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return JoinRequestModel(
      id: documentId,
      groupId: (map['groupId'] as String?) ?? '',
      uid: (map['uid'] as String?) ?? documentId,
      displayName: (map['displayName'] as String?) ?? '',
      status: JoinRequestStatus.fromString(map['status'] as String?),
      inviteCode: (map['inviteCode'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      resolvedAt: map['resolvedAt'] != null
          ? parseDate(map['resolvedAt'])
          : null,
      resolvedBy: map['resolvedBy'] as String?,
      rejectionCount: (map['rejectionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
