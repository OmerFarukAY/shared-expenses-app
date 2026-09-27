import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal, privacy-first user profile model.
///
/// In accordance with the application's data-minimization philosophy,
/// contains only the anonymous UID, local display name, and preferences.
class UserProfile {
  final String uid;
  final String displayName;
  final String preferredCurrency;
  final String languageCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.preferredCurrency = 'TRY',
    this.languageCode = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? displayName,
    String? preferredCurrency,
    String? languageCode,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'preferredCurrency': preferredCurrency,
      'languageCode': languageCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserProfile(
      uid: (map['uid'] as String?) ?? docId,
      displayName: (map['displayName'] as String?) ?? '',
      preferredCurrency: (map['preferredCurrency'] as String?) ?? 'TRY',
      languageCode: (map['languageCode'] as String?) ?? 'en',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          displayName == other.displayName &&
          preferredCurrency == other.preferredCurrency &&
          languageCode == other.languageCode;

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      preferredCurrency.hashCode ^
      languageCode.hashCode;

  @override
  String toString() =>
      'UserProfile(uid: $uid, displayName: $displayName, currency: $preferredCurrency)';
}
