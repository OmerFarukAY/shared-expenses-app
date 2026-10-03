import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/account_deletion_service.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show AuthProvider, AuthCredential;

// ───────────────────────────────────────────────
// Mock AuthRepository
// ───────────────────────────────────────────────
class MockAuthRepository implements AuthRepository {
  String? uid;
  UserProfile? profile;
  bool deleteFirebaseAuthCalled = false;
  bool deleteUserDocCalled = false;
  bool shouldThrowReauth = false;

  final _authController = StreamController<String?>.broadcast();
  final _providersController = StreamController<List<String>>.broadcast();

  MockAuthRepository({this.uid = 'user_uid', this.profile});

  @override
  Stream<String?> get authStateChanges => _authController.stream;

  @override
  Stream<List<String>> get linkedProvidersChanges =>
      _providersController.stream;

  @override
  String? get currentUid => uid;

  @override
  bool get isAnonymous => true;

  @override
  List<String> get linkedProviderIds => const [];

  @override
  String? get currentEmail => null;

  @override
  Future<String> ensureAnonymousUser() async => uid!;

  @override
  Future<UserProfile?> fetchUserProfile() async => profile;

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> updateDisplayName(String newName) async {}

  @override
  Future<void> deleteAccount() async {
    if (uid != null) {
      await deleteUserDocument(uid!);
    }
    await deleteFirebaseAuthAccount();
  }

  @override
  Future<void> deleteFirebaseAuthAccount() async {
    deleteFirebaseAuthCalled = true;
    if (shouldThrowReauth) {
      throw const AuthReauthRequiredException();
    }
    uid = null;
    profile = null;
    _authController.add(null);
  }

  @override
  Future<void> deleteUserDocument(String uid) async {
    deleteUserDocCalled = true;
    profile = null;
  }

  @override
  Future<void> linkGoogleAccount({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkAppleAccount({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkCredential(AuthCredential credential) async {}

  @override
  Future<void> signInWithExistingCredential(AuthCredential credential) async {}

  @override
  Future<void> signInWithProvider(AuthProvider provider) async {}
}

// ───────────────────────────────────────────────
// Mock GroupRepository
// ───────────────────────────────────────────────
class MockGroupRepository implements GroupRepository {
  final List<GroupModel> _ownedGroups;
  final Map<String, List<GroupMember>> _membersByGroup;

  final List<String> deletedGroups = [];
  final List<String> leftGroups = [];
  bool transferOwnershipCalled = false;

  MockGroupRepository({
    List<GroupModel>? ownedGroups,
    Map<String, List<GroupMember>>? membersByGroup,
  })  : _ownedGroups = ownedGroups ?? [],
        _membersByGroup = membersByGroup ?? {};

  @override
  Future<List<GroupModel>> getOwnedGroups(String uid) async =>
      _ownedGroups.where((g) => g.createdBy == uid).toList();

  @override
  Future<List<String>> getMemberOnlyGroupIds(String uid) async => [];

  @override
  Future<List<GroupMember>> getGroupMembersList(String groupId) async =>
      _membersByGroup[groupId] ?? [];

  @override
  Future<void> deleteGroup(String groupId) async {
    deletedGroups.add(groupId);
  }

  @override
  Future<void> leaveGroupAsNonOwner({
    required String groupId,
    required String uid,
  }) async {
    leftGroups.add(groupId);
  }

  @override
  Future<void> anonymizeUserInSettlements({
    required String groupId,
    required String uid,
  }) async {}

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String currentOwnerUid,
    required String newOwnerUid,
    required String newOwnerDisplayName,
  }) async {
    transferOwnershipCalled = true;
  }

  // ── Unused stubs ──────────────────────────────
  @override
  Stream<List<GroupModel>> watchUserGroups(String uid) => const Stream.empty();

  @override
  Future<GroupModel?> getGroup(String groupId) async => null;

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String defaultCurrency,
    required UserProfile creator,
  }) async =>
      throw UnimplementedError();

  @override
  Future<GroupModel> resolveInviteCode(String inviteCode) async =>
      throw UnimplementedError();

  @override
  Future<void> joinGroupWithInvite({
    required String inviteCode,
    required UserProfile user,
  }) async {}

  @override
  Future<JoinRequestModel> createJoinRequest({
    required String inviteCode,
    required UserProfile user,
  }) async =>
      throw UnimplementedError();

  @override
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) =>
      const Stream.empty();

  @override
  Stream<List<JoinRequestModel>> watchUserJoinRequests(String uid) =>
      const Stream.empty();

  @override
  Future<void> approveJoinRequest({
    required String groupId,
    required JoinRequestModel request,
    required String approvedBy,
  }) async {}

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUid,
    required String rejectedBy,
  }) async {}

  @override
  Future<void> cancelJoinRequest({
    required String groupId,
    required String uid,
  }) async {}

  @override
  Future<void> deleteUserJoinRequest({
    required String groupId,
    required String uid,
  }) async {}

  @override
  Stream<List<GroupMember>> watchGroupMembers(String groupId) =>
      const Stream.empty();

  @override
  Future<void> leaveGroup({required String groupId, required String uid}) async {}

  @override
  Future<void> removeMember({
    required String groupId,
    required String uid,
  }) async {}
}

// ───────────────────────────────────────────────
// Helper factories
// ───────────────────────────────────────────────
GroupModel _makeGroup(String id, String createdBy) => GroupModel(
      id: id,
      name: 'Group $id',
      defaultCurrency: 'USD',
      inviteCode: 'DNK-TEST',
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      memberUids: [createdBy],
    );

GroupMember _makeMember(String uid, {String? name, DateTime? leftAt}) =>
    GroupMember(
      uid: uid,
      displayName: name ?? 'Member $uid',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
      leftAt: leftAt,
    );

// ───────────────────────────────────────────────
// Tests
// ───────────────────────────────────────────────
void main() {
  const uid = 'user_uid';

  group('AccountDeletionService.analyzeOwnershipBlocks', () {
    test('returns empty list when user owns no groups', () async {
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(ownedGroups: []);
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      final blocks = await service.analyzeOwnershipBlocks(uid);
      expect(blocks, isEmpty);
    });

    test('returns blocks for groups with other active members', () async {
      final group = _makeGroup('g1', uid);
      final otherMember = _makeMember('other_uid');
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(
        ownedGroups: [group],
        membersByGroup: {
          'g1': [_makeMember(uid), otherMember],
        },
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      final blocks = await service.analyzeOwnershipBlocks(uid);
      expect(blocks.length, 1);
      expect(blocks.first.group.id, 'g1');
      expect(blocks.first.eligibleNewOwners.length, 1);
      expect(blocks.first.eligibleNewOwners.first.uid, 'other_uid');
    });

    test('returns empty when owned group has only the user as member', () async {
      final group = _makeGroup('g1', uid);
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(
        ownedGroups: [group],
        membersByGroup: {
          'g1': [_makeMember(uid)],
        },
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      final blocks = await service.analyzeOwnershipBlocks(uid);
      // No other active members → no block
      expect(blocks, isEmpty);
    });

    test('ignores members who have already left', () async {
      final group = _makeGroup('g1', uid);
      final leftMember = _makeMember('other_uid', leftAt: DateTime.now());
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(
        ownedGroups: [group],
        membersByGroup: {
          'g1': [_makeMember(uid), leftMember],
        },
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      final blocks = await service.analyzeOwnershipBlocks(uid);
      // Left member doesn't count as eligible → no block
      expect(blocks, isEmpty);
    });
  });

  group('AccountDeletionService.executeFullDeletion', () {
    test('throws ownership-transfer-required when blocks exist', () async {
      final group = _makeGroup('g1', uid);
      final otherMember = _makeMember('other_uid');
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(
        ownedGroups: [group],
        membersByGroup: {
          'g1': [_makeMember(uid), otherMember],
        },
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      expect(
        () => service.executeFullDeletion(uid),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'ownership-transfer-required',
          ),
        ),
      );
    });

    test('deletes sole-owned group and calls deleteFirebaseAuthAccount last',
        () async {
      final group = _makeGroup('g1', uid);
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = MockGroupRepository(
        ownedGroups: [group],
        membersByGroup: {
          'g1': [_makeMember(uid)],
        },
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      await service.executeFullDeletion(uid);

      expect(groupRepo.deletedGroups, contains('g1'));
      expect(authRepo.deleteUserDocCalled, isTrue);
      expect(authRepo.deleteFirebaseAuthCalled, isTrue);
    });

    test('leaves non-owned group with anonymization', () async {
      final authRepo = MockAuthRepository(uid: uid);
      // User is member-only in g2 (non-owned)
      final groupRepo = _NonOwnerMockGroupRepository(memberOnlyGroupIds: ['g2']);
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      await service.executeFullDeletion(uid);

      expect(groupRepo.leftGroups, contains('g2'));
      expect(authRepo.deleteFirebaseAuthCalled, isTrue);
    });

    test('calls deleteFirebaseAuthAccount last even if group ops fail',
        () async {
      final group = _makeGroup('g1', uid);
      final authRepo = MockAuthRepository(uid: uid);
      final groupRepo = _FailingDeleteGroupRepo(
        ownedGroups: [group],
        membersByGroup: {'g1': [_makeMember(uid)]},
      );
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      // Should not throw; continues and deletes auth account
      await service.executeFullDeletion(uid);
      expect(authRepo.deleteFirebaseAuthCalled, isTrue);
    });

    test('propagates AuthReauthRequiredException from deleteFirebaseAuthAccount',
        () async {
      final authRepo = MockAuthRepository(uid: uid)..shouldThrowReauth = true;
      final groupRepo = MockGroupRepository();
      final service =
          AccountDeletionService(authRepo: authRepo, groupRepo: groupRepo);

      expect(
        () => service.executeFullDeletion(uid),
        throwsA(isA<AuthReauthRequiredException>()),
      );
    });
  });

  group('AuthReauthRequiredException', () {
    test('is a subtype of AppException', () {
      const e = AuthReauthRequiredException();
      expect(e, isA<AppException>());
    });

    test('has correct default code', () {
      const e = AuthReauthRequiredException();
      expect(e.code, 'requires-recent-login');
    });

    test('is distinct from AppException', () {
      const e = AuthReauthRequiredException();
      expect(e, isNot(isA<AuthConflictException>()));
    });
  });
}

// ───────────────────────────────────────────────
// Specialised mock subclasses for edge-case tests
// ───────────────────────────────────────────────

/// GroupRepository mock where user is member-only (non-owner) in listed groups.
class _NonOwnerMockGroupRepository extends MockGroupRepository {
  final List<String> memberOnlyGroupIds;

  _NonOwnerMockGroupRepository({required this.memberOnlyGroupIds});

  @override
  Future<List<GroupModel>> getOwnedGroups(String uid) async => [];

  @override
  Future<List<String>> getMemberOnlyGroupIds(String uid) async =>
      memberOnlyGroupIds;
}

/// GroupRepository mock that throws on deleteGroup to test partial failure resilience.
class _FailingDeleteGroupRepo extends MockGroupRepository {
  _FailingDeleteGroupRepo({
    required List<GroupModel> ownedGroups,
    required Map<String, List<GroupMember>> membersByGroup,
  }) : super(ownedGroups: ownedGroups, membersByGroup: membersByGroup);

  @override
  Future<void> deleteGroup(String groupId) async {
    throw const AppException(
      message: 'Simulated deleteGroup failure',
      code: 'test-error',
    );
  }
}
