# Backend & Security Changelog

## [Phase 17] - Account Deletion, Ownership Transfer & Data Anonymization
**Status:** TAMAMLANDI
**Date:** 2026-10-02

### 1. Schema & Dependency Analysis
A full audit of all Firestore references to user UIDs was performed prior to implementation:

| Collection / Document | Field(s) | Role & Handling on Account Deletion |
| --- | --- | --- |
| `users/{uid}` | Entire document | Permanently deleted. Subcollections `user_groups` and `join_requests` deleted in chunked batches (450 docs/batch). |
| `users/{uid}/user_groups/{groupId}` | Subcollection doc | Deleted during group cleanup and `leaveGroupAsNonOwner`. |
| `users/{uid}/join_requests/{groupId}` | Subcollection doc | Deleted during user document cleanup. |
| `groups/{groupId}` | `createdBy` | **Ownership lifecycle**: If user is sole member, group is deleted. If group has >1 active members, **explicit ownership transfer is required** before deletion can proceed. |
| `groups/{groupId}` | `memberUids[]` | Removed from array via `FieldValue.arrayRemove([uid])`; `memberCount` decremented via `FieldValue.increment(-1)`. |
| `groups/{groupId}/members/{uid}` | Member doc | Anonymized: `displayName` set to `"Deleted User"`, `leftAt` set to current timestamp. Preserves group membership history for ledger readability. |
| `groups/{groupId}/expenses/{expenseId}` | `createdBy`, `payers{}`, `splits{}`, `participants[]` | **Strictly preserved**: Financial records and accounting amounts are never altered or rewritten. Preserves balance calculations and auditability. |
| `groups/{groupId}/settlements/{settlementId}` | `fromUid`, `toUid`, `createdBy`, `fromName`, `toName` | **Preserved**: Settlements remain immutable per `allow update: if false;` security rule. Display names and UIDs within closed groups are accessible only by active group members. |
| `invites/{inviteCode}` | `createdBy` | Cleaned up atomically when sole-owned group is deleted. If ownership transferred, invite remains intact. |

---

### 2. Deletion Sequence
1. **Pre-flight Ownership Analysis**: `AccountDeletionService.analyzeOwnershipBlocks(uid)` checks all groups where `createdBy == uid`. If any owned group has other active members, deletion is blocked until ownership is explicitly transferred.
2. **Sole-Owned Groups Deletion**: For all groups where user is creator and sole member, all subcollections (`members`, `expenses`, `settlements`, `joinRequests`), `invites`, and the group doc are deleted via chunked batches.
3. **Non-Owned Groups Leave & Anonymization**: For each group where user is a regular member, `leaveGroupAsNonOwner` updates member doc (`displayName: 'Deleted User'`, `leftAt: now`), deletes `users/{uid}/user_groups/{groupId}`, and removes the UID from `groups/{groupId}.memberUids`.
4. **User Document & Subcollections Cleanup**: `deleteUserDocument(uid)` wipes `users/{uid}`, `user_groups`, and `join_requests`.
5. **Firebase Auth Account Deletion**: `deleteFirebaseAuthAccount()` deletes the Auth credential last. If Firebase throws `requires-recent-login`, an `AuthReauthRequiredException` is surfaced to prompt re-authentication.

---

### 3. Ownership Transfer Behavior
- Groups owned by the user with other active members **cannot be silently orphaned or arbitrarily assigned**.
- `transferOwnership(groupId, currentOwnerUid, newOwnerUid, newOwnerDisplayName)` performs an atomic batch:
  1. `groups/{groupId}`: `createdBy` set to `newOwnerUid`, `updatedAt` updated.
  2. `groups/{groupId}/members/{newOwnerUid}`: `role` elevated to `'owner'`.
  3. `groups/{groupId}/members/{currentOwnerUid}`: `role` demoted to `'member'` (user remains a member until account deletion).
- The transfer is fully validated by server security rules (Case 5 in `groups` rules and Case 4 in `members` rules).

---

### 4. Anonymization Strategy
- When a user deletes their account, their active identity is dissociated from shared groups:
  - `groups/{groupId}/members/{uid}.displayName` becomes `"Deleted User"`.
  - `groups/{groupId}/members/{uid}.leftAt` records the timestamp of departure.
- Historical expense ledger amounts (`totalMinor`, `payers`, `splits`, `participants`) remain completely unchanged to ensure mathematical ledger integrity for remaining members.
- No new PII is introduced.

---

### 5. Firestore Security Rule Changes
The following updates were applied to `firestore.rules` without weakening existing access barriers:

1. **`groups/{groupId}` Updates (Case 5 added)**:
   - Permitted group creators to reassign `createdBy` to an active member (`createdBy in resource.data.memberUids`).
   - Verified that the target member is atomically elevated to `role == 'owner'` and the old creator is set to `role == 'member'`.
2. **`groups/{groupId}/members/{memberUid}` Updates (Case 4 added)**:
   - Permitted group creator to promote an active member from `role == 'member'` to `role == 'owner'` during ownership transfer.
   - Permitted creator to update their own role to `'member'` during ownership transfer.
3. **Member Leave Anonymization**:
   - Expanded affected keys on leave to include `displayName`, allowing it to be set to `'Deleted User'` while preventing arbitrary name changes on leave.

---

### 6. Failure Recovery & Known Limitations
- **Non-Atomic Auth Deletion**: Firebase Auth user deletion cannot participate in a Firestore transaction. The safe ordering is **Firestore cleanup FIRST, Auth deletion LAST**.
  - If Firestore cleanup succeeds but Auth deletion fails (e.g., `requires-recent-login`), the app prompts re-authentication and allows retry.
  - If Auth deletion succeeds but Firestore was partially cleaned, the orphaned Firestore documents are inaccessible to client-side enumeration because list operations are disallowed.
- **Settlement Immutability**: Historical settlement documents under `groups/{groupId}/settlements` retain the denormalized display name at the time of settlement because `allow update: if false;` is strictly enforced to protect financial immutability. Only active group members can view these records.

---

### 7. Verification & Automated Test Coverage
- **Unit & Service Tests** (`test/features/auth/account_deletion_test.dart`):
  - Ownership analysis with 0 groups, sole-member groups, multi-member groups, and left members.
  - Deletion blocked on active multi-member owned groups (`ownership-transfer-required`).
  - Sole-owned group complete deletion.
  - Non-owner leave with display name anonymization.
  - `AuthReauthRequiredException` mapping and propagation.
  - Partial failure resilience.
- **Widget & UI Tests**:
  - Delete Account button confirmation modal.
  - Ownership transfer required dialog displaying blocked groups.
  - Ownership transfer selection and resolution.
  - Execution of deletion on confirmed action.
- **Suite Verification**:
  - `flutter analyze`: **0 issues found** (clean analysis).
  - `flutter test`: **118 / 118 tests passing**.
  - `localization_test.dart`: 100% key parity across EN, TR, ES, FR, IT.
  - `security_rules_test.dart`: Invariant rules passed.
  - `git diff --check`: Clean whitespace.
