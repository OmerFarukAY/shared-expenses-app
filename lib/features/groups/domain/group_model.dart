import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of a member in a shared group.
enum MemberRole { owner, member }

/// Member record stored in `groups/{groupId}/members/{uid}`.
class GroupMember {
  final String uid;
  final String displayName;
  final MemberRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? inviteCode;

  const GroupMember({
    required this.uid,
    required this.displayName,
    this.role = MemberRole.member,
    required this.joinedAt,
    this.leftAt,
    this.inviteCode,
  });

  bool get isOwner => role == MemberRole.owner;
  bool get hasLeft => leftAt != null;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'role': role == MemberRole.owner ? 'owner' : 'member',
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (leftAt != null) 'leftAt': Timestamp.fromDate(leftAt!),
      if (inviteCode != null && inviteCode!.isNotEmpty)
        'inviteCode': inviteCode,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GroupMember(
      uid: (map['uid'] as String?) ?? docId,
      displayName: (map['displayName'] as String?) ?? '',
      role: (map['role'] as String?) == 'owner'
          ? MemberRole.owner
          : MemberRole.member,
      joinedAt: parseDate(map['joinedAt']),
      leftAt: map['leftAt'] != null ? parseDate(map['leftAt']) : null,
      inviteCode: map['inviteCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          displayName == other.displayName &&
          role == other.role;

  @override
  int get hashCode => uid.hashCode ^ displayName.hashCode ^ role.hashCode;
}

/// Represents a shared group (e.g. roommates, a trip, a household, dinner party).
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String defaultCurrency;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final List<String> memberUids;
  final bool active;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.defaultCurrency,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 1,
    this.memberUids = const [],
    this.active = true,
  });

  GroupModel copyWith({
    String? name,
    String? description,
    String? defaultCurrency,
    String? inviteCode,
    DateTime? updatedAt,
    int? memberCount,
    List<String>? memberUids,
    bool? active,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      memberUids: memberUids ?? this.memberUids,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'defaultCurrency': defaultCurrency,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'memberCount': memberCount,
      'memberUids': memberUids,
      'active': active,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final createdByStr = (map['createdBy'] as String?) ?? '';
    final parsedMemberUids =
        (map['memberUids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (createdByStr.isNotEmpty ? [createdByStr] : const <String>[]);

    return GroupModel(
      id: (map['id'] as String?) ?? docId,
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      defaultCurrency: (map['defaultCurrency'] as String?) ?? 'TRY',
      inviteCode: (map['inviteCode'] as String?) ?? '',
      createdBy: createdByStr,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      memberCount:
          (map['memberCount'] as num?)?.toInt() ?? parsedMemberUids.length,
      memberUids: parsedMemberUids,
      active: (map['active'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          defaultCurrency == other.defaultCurrency &&
          inviteCode == other.inviteCode;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      defaultCurrency.hashCode ^
      inviteCode.hashCode;
}
