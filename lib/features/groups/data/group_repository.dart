import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/invite_code_generator.dart';

import 'package:denk/features/groups/domain/join_request_model.dart';

abstract class GroupRepository {
  Stream<List<GroupModel>> watchUserGroups(String uid);
  Future<GroupModel?> getGroup(String groupId);
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String defaultCurrency,
    required UserProfile creator,
  });
  Future<GroupModel> resolveInviteCode(String inviteCode);
  Future<void> joinGroupWithInvite({
    required String inviteCode,
    required UserProfile user,
  });
  Future<JoinRequestModel> createJoinRequest({
    required String inviteCode,
    required UserProfile user,
  });
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId);
  Stream<List<JoinRequestModel>> watchUserJoinRequests(String uid);
  Future<void> approveJoinRequest({
    required String groupId,
    required JoinRequestModel request,
    required String approvedBy,
  });
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUid,
    required String rejectedBy,
  });
  Future<void> cancelJoinRequest({
    required String groupId,
    required String uid,
  });
  Stream<List<GroupMember>> watchGroupMembers(String groupId);
  Future<void> leaveGroup({required String groupId, required String uid});
}

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<GroupModel>> watchUserGroups(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('user_groups')
        .snapshots()
        .asyncMap((snapshot) async {
          final List<GroupModel> groups = [];
          for (final doc in snapshot.docs) {
            final groupId = doc.id;
            final groupDoc = await _firestore
                .collection('groups')
                .doc(groupId)
                .get();
            if (groupDoc.exists && groupDoc.data() != null) {
              groups.add(GroupModel.fromMap(groupDoc.data()!, groupDoc.id));
            }
          }
          return groups;
        });
  }

  @override
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists || doc.data() == null) return null;
      return GroupModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String defaultCurrency,
    required UserProfile creator,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 60) {
      throw const AppException(
        message: 'Group name must be between 1 and 60 characters.',
        code: 'invalid-name',
      );
    }

    try {
      final groupId = _uuid.v4();

      // Cryptographically secure collision check with deterministic retry
      String inviteCode = InviteCodeGenerator.generate();
      for (int attempt = 0; attempt < 3; attempt++) {
        final existingInvite = await _firestore
            .collection('invites')
            .doc(inviteCode)
            .get();
        if (!existingInvite.exists) {
          break;
        }
        inviteCode = InviteCodeGenerator.generate();
      }

      final now = DateTime.now();

      final newGroup = GroupModel(
        id: groupId,
        name: trimmedName,
        description: description?.trim(),
        defaultCurrency: defaultCurrency.toUpperCase(),
        inviteCode: inviteCode,
        createdBy: creator.uid,
        createdAt: now,
        updatedAt: now,
        memberCount: 1,
        memberUids: [creator.uid],
        active: true,
      );

      final creatorMember = GroupMember(
        uid: creator.uid,
        displayName: creator.displayName,
        role: MemberRole.owner,
        joinedAt: now,
      );

      final batch = _firestore.batch();

      // 1. Create group document
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.set(groupRef, newGroup.toMap());

      // 2. Add creator to members subcollection
      final memberRef = groupRef.collection('members').doc(creator.uid);
      batch.set(memberRef, creatorMember.toMap());

      // 3. Link group in user's user_groups subcollection
      final userGroupRef = _firestore
          .collection('users')
          .doc(creator.uid)
          .collection('user_groups')
          .doc(groupId);
      batch.set(userGroupRef, {
        'groupId': groupId,
        'joinedAt': Timestamp.fromDate(now),
      });

      // 4. Create public invite resolution document
      final inviteRef = _firestore.collection('invites').doc(inviteCode);
      batch.set(inviteRef, {
        'inviteCode': inviteCode,
        'groupId': groupId,
        'groupName': trimmedName,
        'defaultCurrency': defaultCurrency.toUpperCase(),
        'createdBy': creator.uid,
        'createdAt': Timestamp.fromDate(now),
        'active': true,
      });

      await batch.commit();
      return newGroup;
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<GroupModel> resolveInviteCode(String inviteCode) async {
    final cleanCode = InviteCodeGenerator.sanitize(inviteCode);
    if (!InviteCodeGenerator.isValidFormat(cleanCode)) {
      throw const AppException(
        message: 'Invalid invite code format. Expected DNK-XXXX.',
        code: 'invalid-code-format',
      );
    }

    try {
      final inviteDoc = await _firestore
          .collection('invites')
          .doc(cleanCode)
          .get();
      if (!inviteDoc.exists || inviteDoc.data() == null) {
        throw const AppException(
          message: 'Invite code not found or expired.',
          code: 'invite-not-found',
        );
      }

      final data = inviteDoc.data()!;
      final bool isActive = data['active'] as bool? ?? true;
      if (!isActive) {
        throw const AppException(
          message: 'This invite code is no longer active.',
          code: 'invite-inactive',
        );
      }

      final String groupId = data['groupId'] as String;
      final String groupName = (data['groupName'] as String?) ?? '';
      final String defaultCurrency =
          (data['defaultCurrency'] as String?) ?? 'TRY';
      final String createdBy = (data['createdBy'] as String?) ?? '';
      final DateTime createdAt = (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      return GroupModel(
        id: groupId,
        name: groupName,
        defaultCurrency: defaultCurrency,
        inviteCode: cleanCode,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: createdAt,
        memberCount: (data['memberCount'] as int?) ?? 1,
        active: isActive,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> joinGroupWithInvite({
    required String inviteCode,
    required UserProfile user,
  }) async {
    final group = await resolveInviteCode(inviteCode);
    final now = DateTime.now();

    try {
      final memberRef = _firestore
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .doc(user.uid);

      final existingMember = await memberRef.get();
      if (existingMember.exists) {
        // Already a member
        return;
      }

      final newMember = GroupMember(
        uid: user.uid,
        displayName: user.displayName,
        role: MemberRole.member,
        joinedAt: now,
        inviteCode: group.inviteCode,
      );

      final batch = _firestore.batch();

      // 1. Add member record
      batch.set(memberRef, newMember.toMap());

      // 2. Add to user's user_groups
      final userGroupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_groups')
          .doc(group.id);
      batch.set(userGroupRef, {
        'groupId': group.id,
        'joinedAt': Timestamp.fromDate(now),
      });

      // 3. Increment group memberCount and add to memberUids projection
      final groupRef = _firestore.collection('groups').doc(group.id);
      batch.update(groupRef, {
        'memberUids': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<JoinRequestModel> createJoinRequest({
    required String inviteCode,
    required UserProfile user,
  }) async {
    final group = await resolveInviteCode(inviteCode);
    final now = DateTime.now();

    try {
      // 1. Check if user is already a member
      final memberRef = _firestore
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .doc(user.uid);
      final existingMember = await memberRef.get();
      if (existingMember.exists) {
        throw const AppException(
          message: 'You are already a member of this group.',
          code: 'already-member',
        );
      }

      // 2. Check if user has an existing pending join request
      final requestRef = _firestore
          .collection('groups')
          .doc(group.id)
          .collection('joinRequests')
          .doc(user.uid);
      final existingReq = await requestRef.get();
      if (existingReq.exists) {
        final existingModel = JoinRequestModel.fromMap(
          existingReq.data()!,
          existingReq.id,
        );
        if (existingModel.isPending) {
          throw const AppException(
            message: 'You already have a pending request for this group.',
            code: 'request-already-pending',
          );
        }
      }

      final requestModel = JoinRequestModel(
        id: user.uid,
        groupId: group.id,
        uid: user.uid,
        displayName: user.displayName,
        status: JoinRequestStatus.pending,
        inviteCode: group.inviteCode,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      // Write to groups/{groupId}/joinRequests/{uid}
      batch.set(requestRef, requestModel.toMap());

      // Write to users/{uid}/join_requests/{groupId}
      final userReqRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('join_requests')
          .doc(group.id);
      batch.set(userReqRef, {
        ...requestModel.toMap(),
        'groupName': group.name,
        'defaultCurrency': group.defaultCurrency,
      });

      await batch.commit();
      return requestModel;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<JoinRequestModel>> watchUserJoinRequests(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> approveJoinRequest({
    required String groupId,
    required JoinRequestModel request,
    required String approvedBy,
  }) async {
    final now = DateTime.now();
    try {
      final batch = _firestore.batch();

      // 1. Mark request approved in groups/{groupId}/joinRequests/{uid}
      final reqRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('joinRequests')
          .doc(request.uid);
      batch.update(reqRef, {
        'status': JoinRequestStatus.approved.name,
        'resolvedAt': Timestamp.fromDate(now),
        'resolvedBy': approvedBy,
        'updatedAt': Timestamp.fromDate(now),
      });

      // 2. Add member record in groups/{groupId}/members/{uid}
      final memberRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(request.uid);
      final member = GroupMember(
        uid: request.uid,
        displayName: request.displayName,
        role: MemberRole.member,
        joinedAt: now,
        inviteCode: request.inviteCode,
      );
      batch.set(memberRef, member.toMap());

      // 3. Update groups/{groupId}.memberUids and memberCount
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberUids': FieldValue.arrayUnion([request.uid]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      // 4. Update user's user_groups/{groupId}
      final userGroupRef = _firestore
          .collection('users')
          .doc(request.uid)
          .collection('user_groups')
          .doc(groupId);
      batch.set(userGroupRef, {
        'groupId': groupId,
        'joinedAt': Timestamp.fromDate(now),
      });

      // 5. Update user's join_requests/{groupId}
      final userReqRef = _firestore
          .collection('users')
          .doc(request.uid)
          .collection('join_requests')
          .doc(groupId);
      batch.update(userReqRef, {
        'status': JoinRequestStatus.approved.name,
        'resolvedAt': Timestamp.fromDate(now),
        'resolvedBy': approvedBy,
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUid,
    required String rejectedBy,
  }) async {
    final now = DateTime.now();
    try {
      final batch = _firestore.batch();

      final reqRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('joinRequests')
          .doc(requestUid);
      batch.update(reqRef, {
        'status': JoinRequestStatus.rejected.name,
        'resolvedAt': Timestamp.fromDate(now),
        'resolvedBy': rejectedBy,
        'updatedAt': Timestamp.fromDate(now),
      });

      final userReqRef = _firestore
          .collection('users')
          .doc(requestUid)
          .collection('join_requests')
          .doc(groupId);
      batch.update(userReqRef, {
        'status': JoinRequestStatus.rejected.name,
        'resolvedAt': Timestamp.fromDate(now),
        'resolvedBy': rejectedBy,
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> cancelJoinRequest({
    required String groupId,
    required String uid,
  }) async {
    try {
      final batch = _firestore.batch();
      final reqRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('joinRequests')
          .doc(uid);
      batch.delete(reqRef);

      final userReqRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('join_requests')
          .doc(groupId);
      batch.delete(userReqRef);

      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupMember.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    try {
      final batch = _firestore.batch();

      final memberRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(uid);
      batch.delete(memberRef);

      final userGroupRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('user_groups')
          .doc(groupId);
      batch.delete(userGroupRef);

      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberUids': FieldValue.arrayRemove([uid]),
        'memberCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }
}
