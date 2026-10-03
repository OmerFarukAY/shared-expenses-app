import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';

void main() {
  group('JoinRequestModel', () {
    test('creates and serializes correctly', () {
      final now = DateTime.now();
      final model = JoinRequestModel(
        id: 'user_123',
        groupId: 'group_abc',
        uid: 'user_123',
        displayName: 'Test User',
        status: JoinRequestStatus.pending,
        inviteCode: 'DNK-7X2K99',
        createdAt: now,
        updatedAt: now,
      );

      expect(model.isPending, isTrue);
      expect(model.isApproved, isFalse);
      expect(model.isRejected, isFalse);
      expect(model.isCancelled, isFalse);

      final map = model.toMap();
      expect(map['id'], 'user_123');
      expect(map['groupId'], 'group_abc');
      expect(map['uid'], 'user_123');
      expect(map['displayName'], 'Test User');
      expect(map['status'], 'pending');
      expect(map['inviteCode'], 'DNK-7X2K99');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map.containsKey('resolvedAt'), isFalse);
      expect(map.containsKey('resolvedBy'), isFalse);

      final deserialized = JoinRequestModel.fromMap(map, 'user_123');
      expect(deserialized.id, 'user_123');
      expect(deserialized.groupId, 'group_abc');
      expect(deserialized.uid, 'user_123');
      expect(deserialized.displayName, 'Test User');
      expect(deserialized.status, JoinRequestStatus.pending);
      expect(deserialized.inviteCode, 'DNK-7X2K99');
    });

    test('deserializes approved request with resolvedAt and resolvedBy', () {
      final now = DateTime.now();
      final model = JoinRequestModel(
        id: 'user_123',
        groupId: 'group_abc',
        uid: 'user_123',
        displayName: 'Test User',
        status: JoinRequestStatus.approved,
        inviteCode: 'DNK-7X2K99',
        createdAt: now,
        updatedAt: now,
        resolvedAt: now,
        resolvedBy: 'owner_999',
      );

      expect(model.isApproved, isTrue);
      expect(model.isPending, isFalse);

      final map = model.toMap();
      expect(map['status'], 'approved');
      expect(map['resolvedBy'], 'owner_999');
      expect(map['resolvedAt'], isA<Timestamp>());

      final deserialized = JoinRequestModel.fromMap(map, 'user_123');
      expect(deserialized.status, JoinRequestStatus.approved);
      expect(deserialized.resolvedBy, 'owner_999');
      expect(deserialized.resolvedAt, isNotNull);
    });

    test('JoinRequestStatus.fromString handles fallback safely', () {
      expect(JoinRequestStatus.fromString(null), JoinRequestStatus.pending);
      expect(
        JoinRequestStatus.fromString('unknown'),
        JoinRequestStatus.pending,
      );
      expect(
        JoinRequestStatus.fromString('approved'),
        JoinRequestStatus.approved,
      );
      expect(
        JoinRequestStatus.fromString('APPROVED'),
        JoinRequestStatus.approved,
      );
      expect(
        JoinRequestStatus.fromString('rejected'),
        JoinRequestStatus.rejected,
      );
      expect(
        JoinRequestStatus.fromString('cancelled'),
        JoinRequestStatus.cancelled,
      );
    });

    test('rejectionCount defaults to 0 and tracks limit reached correctly', () {
      final now = DateTime.now();
      final modelDefault = JoinRequestModel(
        id: 'u1',
        groupId: 'g1',
        uid: 'u1',
        displayName: 'User 1',
        status: JoinRequestStatus.pending,
        inviteCode: 'CODE1',
        createdAt: now,
        updatedAt: now,
      );

      expect(modelDefault.rejectionCount, 0);
      expect(modelDefault.isLimitReached, isFalse);

      final modelAtLimit = modelDefault.copyWith(rejectionCount: 3);
      expect(modelAtLimit.rejectionCount, 3);
      expect(modelAtLimit.isLimitReached, isTrue);

      final modelOverLimit = modelDefault.copyWith(rejectionCount: 5);
      expect(modelOverLimit.isLimitReached, isTrue);

      final map = modelAtLimit.toMap();
      expect(map['rejectionCount'], 3);

      final deserialized = JoinRequestModel.fromMap(map, 'u1');
      expect(deserialized.rejectionCount, 3);
      expect(deserialized.isLimitReached, isTrue);
    });
  });
}
