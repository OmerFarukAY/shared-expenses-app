import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

void main() {
  group('UserProfile Domain Model', () {
    final now = DateTime(2026, 9, 27, 12, 0, 0);

    test('serializes to Map with correct types', () {
      final profile = UserProfile(
        uid: 'user_123',
        displayName: 'Ömer',
        preferredCurrency: 'TRY',
        languageCode: 'tr',
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['uid'], 'user_123');
      expect(map['displayName'], 'Ömer');
      expect(map['preferredCurrency'], 'TRY');
      expect(map['languageCode'], 'tr');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('deserializes from Map correctly with Timestamps', () {
      final map = {
        'uid': 'user_456',
        'displayName': 'Alex',
        'preferredCurrency': 'EUR',
        'languageCode': 'en',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final profile = UserProfile.fromMap(map, 'user_456');
      expect(profile.uid, 'user_456');
      expect(profile.displayName, 'Alex');
      expect(profile.preferredCurrency, 'EUR');
      expect(profile.languageCode, 'en');
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
    });

    test('supports copyWith cleanly', () {
      final profile = UserProfile(
        uid: 'u1',
        displayName: 'Old Name',
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(displayName: 'New Name');
      expect(updated.displayName, 'New Name');
      expect(updated.uid, 'u1');
      expect(profile.displayName, 'Old Name');
    });
  });
}
