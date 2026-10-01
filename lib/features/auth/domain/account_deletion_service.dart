import 'package:flutter/foundation.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';

/// Represents a group that is owned by the user and has other active members.
/// Ownership must be transferred before the account can be deleted.
class OwnedGroupBlock {
  final GroupModel group;
  final List<GroupMember> eligibleNewOwners;

  const OwnedGroupBlock({
    required this.group,
    required this.eligibleNewOwners,
  });
}

/// Orchestrates the multi-step account deletion flow.
///
/// ## Deletion Sequence
/// 1. Load all groups the user is part of.
/// 2. For each OWNED group with no other active members: delete the entire group.
/// 3. For each NON-OWNED group: mark member as left + anonymize display name.
/// 4. Delete users/{uid} document and subcollections.
/// 5. Delete Firebase Auth account.
///
/// ## Atomicity
/// This process is NOT fully atomic because Firebase Auth deletion cannot
/// participate in a Firestore transaction. The safe ordering is:
/// Firestore cleanup FIRST, Auth deletion LAST.
/// If Firestore cleanup succeeds but Auth deletion fails, the user can retry.
/// If Auth deletion succeeds but Firestore cleanup was partial, the orphaned
/// Firestore data will be unreachable (no auth token) and eventually
/// becomes inaccessible. This is documented as a known limitation.
///
/// ## Ownership Transfer
/// Groups owned by the user that still have other active members CANNOT be
/// deleted without an explicit ownership transfer. Call [analyzeOwnershipBlocks]
/// to identify these groups before starting deletion.
class AccountDeletionService {
  final AuthRepository authRepo;
  final GroupRepository groupRepo;

  const AccountDeletionService({
    required this.authRepo,
    required this.groupRepo,
  });

  /// Returns groups that require ownership transfer before the account can be deleted.
  Future<List<OwnedGroupBlock>> analyzeOwnershipBlocks(String uid) async {
    final ownedGroups = await groupRepo.getOwnedGroups(uid);
    final List<OwnedGroupBlock> blocks = [];
    for (final group in ownedGroups) {
      final members = await groupRepo.getGroupMembersList(group.id);
      final eligibleOwners = members
          .where((m) => m.uid != uid && m.leftAt == null)
          .toList();
      if (eligibleOwners.isNotEmpty) {
        blocks.add(OwnedGroupBlock(
          group: group,
          eligibleNewOwners: eligibleOwners,
        ));
      }
    }
    return blocks;
  }

  /// Executes the full account deletion flow.
  ///
  /// MUST be called only after all ownership blocks have been resolved.
  /// Throws [AppException] with code 'ownership-transfer-required' if blocks remain.
  /// Throws [AuthReauthRequiredException] if the session is too old for Auth deletion.
  Future<void> executeFullDeletion(String uid) async {
    // Guard: verify no ownership blocks remain
    final blocks = await analyzeOwnershipBlocks(uid);
    if (blocks.isNotEmpty) {
      throw const AppException(
        message: 'Ownership transfer required before account deletion.',
        code: 'ownership-transfer-required',
      );
    }

    // Collect all group memberships BEFORE starting deletion
    final ownedGroups = await groupRepo.getOwnedGroups(uid);
    final memberOnlyGroupIds = await groupRepo.getMemberOnlyGroupIds(uid);

    // Step 1: Delete sole-owned groups (no other active members)
    for (final group in ownedGroups) {
      try {
        await groupRepo.deleteGroup(group.id);
      } catch (e) {
        debugPrint('Warning: failed to delete owned group ${group.id}: $e');
        // Continue — partial cleanup is better than leaving user stuck
      }
    }

    // Step 2: Leave non-owned groups (anonymize member doc)
    for (final groupId in memberOnlyGroupIds) {
      try {
        await groupRepo.leaveGroupAsNonOwner(groupId: groupId, uid: uid);
      } catch (e) {
        debugPrint('Warning: failed to leave group $groupId: $e');
        // Continue
      }
      // Settlement display names not anonymized (see anonymizeUserInSettlements docs)
      await groupRepo.anonymizeUserInSettlements(groupId: groupId, uid: uid);
    }

    // Step 3: Delete user document and subcollections
    try {
      await authRepo.deleteUserDocument(uid);
    } catch (e) {
      debugPrint('Warning: user document deletion partial: $e');
    }

    // Step 4: Delete Firebase Auth account (must be last)
    // May throw AuthReauthRequiredException
    await authRepo.deleteFirebaseAuthAccount();
  }
}
