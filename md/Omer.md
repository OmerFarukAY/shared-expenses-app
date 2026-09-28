# Denk — Security Hardening Log

## Phase 1 — Firebase Security Rules Hardening

### Summary
Comprehensive audit and hardening of Firestore Security Rules to close collection enumeration, group isolation bypasses, and unauthenticated access vectors.

### Key Changes
1. **Invite Enumeration Closed (Phase 1.1)**:
   - Split `read` into `get` and `list`.
   - `allow list: if false;` on `/invites` prevents global collection queries, prefix searches, or brute-force enumeration of existing invite codes.
   - `allow get: if isAuthenticated();` permits direct document lookup only when a user holds the exact invite code.
2. **Authentication Controls (Phase 1.2)**:
   - Anonymous and authenticated users strictly segregated from unauthenticated traffic.
   - All read and write operations on `groups`, `members`, `expenses`, `settlements`, `users`, and `invites` require `request.auth != null`.
3. **Group Isolation Enforced (Phase 1.3)**:
   - `allow list: if false;` on `/groups` prevents enumeration of all groups in the database.
   - `allow get: if isGroupMember(groupId) || (isAuthenticated() && request.auth.uid == resource.data.createdBy);` prevents arbitrary users from reading group details by guessing a `groupId`.
   - Subcollections `/members`, `/expenses`, and `/settlements` strictly require `isGroupMember(groupId)`.
   - Refactored `GroupRepository.resolveInviteCode` to build preview metadata directly from `/invites/{code}` without exposing `/groups/{groupId}` to non-members.
4. **Automated Emulator Test Suite (Phase 1.4)**:
   - Added Node/Mocha test runner in `test/security/rules.test.js` using `@firebase/rules-unit-testing`.
   - Executed all 20 security test cases against Firestore Emulator:
     - Unauthenticated access rejection (invites, groups, users, expenses).
     - Authenticated non-member access rejection.
     - Group member access validation.
     - Cross-group access rejection.
     - Guessed groupId rejection.
     - Invite collection listing rejection.
     - Direct invite lookup allowance.
     - Profile impersonation rejection.
   - 20/20 test cases passing.
5. **Production Deployment**:
   - Deployed updated `firestore.rules` and `firestore.indexes.json` to project `denk-262c0`.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (20/20 tests passing).
- `git diff --check`: Passed (clean whitespace).
