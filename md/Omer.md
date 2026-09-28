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

## Phase 2 — Secure Group Join / Anti-Escalation Flow

### Summary
Server-enforced group joining and anti-escalation security in Firestore Security Rules without requiring external backend servers or Cloud Functions.

### Key Changes
1. **Guessed GroupId Self-Join Blocked**:
   - An attacker attempting to join `groups/{groupId}/members/{uid}` without possessing the group's active `inviteCode` is rejected.
2. **Anti-Escalation & Role Enforcement**:
   - `role: 'owner'` is strictly restricted to group creators during group creation in an atomic batch (`getAfter(...).data.createdBy == request.auth.uid`).
   - Any user joining an existing group can ONLY receive `role: 'member'`.
   - Any injection attempt with `role: 'owner'` or `role: 'admin'` is rejected.
   - Member updates enforce immutable role: `request.resource.data.role == resource.data.role`.
3. **Active Invite Validation in Rules**:
   - Rules verify that the supplied `inviteCode`:
     - Matches `groups/{groupId}.data.inviteCode`.
     - Exists in `/invites/{inviteCode}` with `active == true`.
     - Matches `invites/{inviteCode}.data.groupId == groupId`.
4. **UID Spoofing Prevention**:
   - Enforces `request.auth.uid == memberUid` and `request.resource.data.uid == memberUid`.
5. **Cross-Group Membership Blocked**:
   - Users cannot use an invite code from Group A to join Group B.
6. **Automated Test Coverage**:
   - Added 10 dedicated security test cases in `test/security/rules.test.js`:
     1. guessed groupId $\rightarrow$ reject (PASSED)
     2. no invite $\rightarrow$ reject (PASSED)
     3. invalid invite $\rightarrow$ reject (PASSED)
     4. inactive invite $\rightarrow$ reject (PASSED)
     5. wrong-group invite $\rightarrow$ reject (PASSED)
     6. valid invite $\rightarrow$ allow (PASSED)
     7. another UID $\rightarrow$ reject (PASSED)
     8. owner role injection $\rightarrow$ reject (PASSED)
     9. admin role injection $\rightarrow$ reject (PASSED)
     10. cross-group membership $\rightarrow$ reject (PASSED)
   - Total passing rules tests: 30/30.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (30/30 tests passing).
- `git diff --check`: Passed (clean whitespace).
- Rules deployed to `denk-262c0`.

## Phase 3 — Invite Code Security & Entropy Upgrade

### Summary
Upgraded invite code generation from 4 characters to 6 characters, increasing combination entropy by 900x while ensuring deterministic collision safety, collision retry, and complete backward compatibility.

### Key Changes
1. **High-Entropy Generation**:
   - `InviteCodeGenerator.generate()` produces `DNK-XXXXXX` using `Random.secure()` across a 30-character unambiguous alphabet (`23456789ABCDEFGHJKMNPQRSTUVWXYZ`).
   - Entropy expanded from $30^4 = 810,000$ to $30^6 = 729,000,000$ combinations (a 900x increase).
   - Ambiguous characters (0, O, 1, I, L) remain strictly excluded.
2. **Backward Compatibility**:
   - `InviteCodeGenerator.isValidFormat` and `sanitize` accept both new 6-character codes (`DNK-XXXXXX`) and legacy 4-character codes (`DNK-XXXX`) via `RegExp(r'^DNK-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4,6}$')`.
3. **Collision Safety & Deterministic Retry**:
   - In `FirestoreGroupRepository.createGroup`, added an automated pre-creation check against `invites/{code}` with a 3-attempt retry loop, guaranteeing zero document overwrites.
4. **Rate Limiting Note**:
   - Documented that client-side rate limiting is not treated as a security boundary; brute-force protection is enforced by high entropy ($729\times 10^6$ space) and App Check.
5. **Automated Test Coverage**:
   - Updated `test/features/groups/group_model_test.dart` to verify 6-character format, length 10, sanitization, legacy compatibility, and rejection of invalid characters/lengths.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (30/30 tests passing).
- `git diff --check`: Passed (clean whitespace).

## Phase 4 — Expense Financial Invariants

### Summary
Server-enforced monetary and financial invariants on Firestore expenses subcollection, eliminating reliance on client-only validation for core accounting rules.

### Key Changes
1. **Integer Minor Currency Invariants**:
   - `totalMinor is int && totalMinor > 0` strictly blocks floating-point values, zero, or negative expenses in Firestore Rules.
   - Verified via unit test that `totalMinor: 150.50` and `totalMinor: 0` are rejected.
2. **Currency Validation**:
   - `isValidCurrency(curr)` enforces 3-letter ISO uppercase format via `curr.matches('^[A-Z]{3}$')`. Rejects lowercase or non-3-letter codes.
3. **Payer Accounting Integrity**:
   - Validates that every payer in `data.payers` is an existing member of the group.
   - Enforces that each payer contribution is a positive integer (`is int && > 0`).
   - Mathematically verifies that the sum of payer contributions strictly equals `totalMinor`.
4. **Split Accounting Integrity**:
   - Validates that participants in `data.participants` and keys in `data.splits` are identical sets.
   - Validates that each split allocation is a positive integer (`is int && > 0`).
   - Validates that participants exist in the group membership roster.
   - Mathematically verifies that the sum of split amounts equals `totalMinor` across equal, custom, or percentage allocations.
5. **Ownership & Immutability**:
   - `createdBy == request.auth.uid` mandatory on expense creation (blocks creator spoofing).
   - On expense updates, `createdBy`, `groupId`, and `id` are strictly immutable (`request.resource.data.createdBy == resource.data.createdBy`).
6. **Automated Test Coverage**:
   - Added 11 new security tests in `test/security/rules.test.js`:
     1. Valid expense with integer minor units, matching payers and splits $\rightarrow$ allow (PASSED)
     2. Floating point totalMinor $\rightarrow$ reject (PASSED)
     3. Zero or negative totalMinor $\rightarrow$ reject (PASSED)
     4. Invalid currency format $\rightarrow$ reject (PASSED)
     5. Payer sum mismatch $\rightarrow$ reject (PASSED)
     6. Foreign payer UID $\rightarrow$ reject (PASSED)
     7. Negative/zero payer amount $\rightarrow$ reject (PASSED)
     8. Split sum mismatch $\rightarrow$ reject (PASSED)
     9. Foreign split participant UID $\rightarrow$ reject (PASSED)
     10. createdBy spoofing on new expense $\rightarrow$ reject (PASSED)
     11. Modifying createdBy or groupId on expense update $\rightarrow$ reject (PASSED)
   - Total passing rules tests: 41/41.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (41/41 tests passing).
- `git diff --check`: Passed (clean whitespace).

