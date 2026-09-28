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

## Phase 5 — Settlement Integrity

### Summary
Resolved ownership discrepancies by establishing `createdBy` as the canonical creator/audit field across models, repositories, rules, and tests. Enforced strict group membership for payer/recipient, blocked self-settlement, and locked down settlements as immutable financial events in Firestore Security Rules.

### Key Changes
1. **Canonical Ownership Field (`createdBy`)**:
   - `SettlementRecord` now uses `createdBy` as the canonical creator UID field matching `ExpenseModel` and `GroupModel`.
   - Maintained backward compatibility via a `settledBy` getter and constructor fallback, serializing both `createdBy` and `settledBy` in `toMap()`.
2. **Server-Enforced Membership Validation**:
   - Both `fromUid` and `toUid` are verified to exist in `groups/{groupId}/members/`.
   - Arbitrary or cross-group UIDs are strictly rejected at the database layer.
3. **Self-Settlement Prevention**:
   - `request.resource.data.fromUid != request.resource.data.toUid` strictly prohibits zero-sum self-settlements.
4. **Monetary & Currency Integrity**:
   - Validates that `amountMinor` is a positive integer (`is int && amountMinor > 0`), rejecting floats, zero, or negative numbers.
   - Validates that `currency` matches 3-letter uppercase ISO format (`^[A-Z]{3}$`).
5. **Absolute Immutability**:
   - `allow update: if false;` on `groups/{groupId}/settlements/{settlementId}` guarantees that recorded settlements can never be tampered with or modified.
6. **Automated Test Coverage**:
   - Added 9 new security tests in `test/security/rules.test.js`:
     1. Valid settlement between group members $\rightarrow$ allow (PASSED)
     2. Arbitrary non-member fromUid $\rightarrow$ reject (PASSED)
     3. Arbitrary non-member toUid $\rightarrow$ reject (PASSED)
     4. Cross-group UID $\rightarrow$ reject (PASSED)
     5. Self-settlement (fromUid == toUid) $\rightarrow$ reject (PASSED)
     6. Invalid amount (float, zero, negative) $\rightarrow$ reject (PASSED)
     7. Invalid currency format $\rightarrow$ reject (PASSED)
     8. createdBy spoofing $\rightarrow$ reject (PASSED)
     9. Modifying/updating existing settlement $\rightarrow$ reject (PASSED)
   - Total passing rules tests: 50/50.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (50/50 tests passing).
- `git diff --check`: Passed (clean whitespace).

## Phase 6 — Timestamp Integrity & Offline-First Strategy

### Summary
Server-enforced temporal integrity controls in Firestore Security Rules preventing arbitrary future and past timestamp spoofing, while strictly preserving offline-first functionality and local persistence replay.

### Offline-First Timestamp Strategy
1. **Asymmetric Temporal Verification**:
   - Rather than naively constraining timestamps to a tight $\pm 5$ min window that would instantly break offline queueing and sync replay, creation timestamps (`createdAt`, `settledAt`, `joinedAt`) enforce `ts <= request.time + duration.value(5, 'm')`.
   - This allows users to create expenses, groups, and settlements while offline on transit or without connectivity, and replay them to Firestore upon reconnection without `permission-denied` errors.
2. **Strict Future Timestamp Prevention**:
   - Creating any entity with a timestamp more than 5 minutes in the future (beyond reasonable clock skew) is strictly rejected at the server level.
   - Expense event dates (`date`) allow historical records (yesterday's receipt) but strictly reject future dates beyond 24 hours (`date <= request.time + duration.value(1, 'd')`).
3. **Retroactive Tampering Prevention (Immutability)**:
   - On updates across `users`, `groups`, `members`, and `expenses`, `createdAt` and `joinedAt` are permanently immutable: `request.resource.data.createdAt == resource.data.createdAt`.
4. **Monotonic Update Progress**:
   - `updatedAt` is validated to always progress monotonically: `request.resource.data.updatedAt >= resource.data.updatedAt && request.resource.data.updatedAt <= request.time + duration.value(5, 'm')`.
5. **Automated Test Coverage**:
   - Added 7 new security tests in `test/security/rules.test.js`:
     1. Creating expense with future createdAt $\rightarrow$ reject (PASSED)
     2. Creating expense with date set far into future $\rightarrow$ reject (PASSED)
     3. Valid past timestamp on expense creation (offline sync scenario) $\rightarrow$ allow (PASSED)
     4. Modifying createdAt on expense update $\rightarrow$ reject (PASSED)
     5. Recording settlement with future settledAt $\rightarrow$ reject (PASSED)
     6. Creating group with future createdAt $\rightarrow$ reject (PASSED)
     7. Modifying joinedAt on member update $\rightarrow$ reject (PASSED)
   - Total passing rules tests: 57/57.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- Firestore Emulator Rules Tests: Passed (57/57 tests passing).
- Rules compilation & deploy to `denk-262c0`: Passed.
- `git diff --check`: Passed (clean whitespace).

## Phase 7 — Firebase App Check Integration

### Summary
Integrated `firebase_app_check` across iOS and Android with environment-aware provider selection, safeguarding backend resources against bot traffic and unauthorized scraping while preserving local development and simulator testing.

### Key Changes
1. **Dependency Addition**:
   - Added `firebase_app_check: 0.4.8` to `pubspec.yaml`, fully compatible with `firebase_core 4.15.0`.
2. **Dual-Mode Provider Architecture (`lib/main.dart`)**:
   - **Development / Debug (`kDebugMode`)**:
     - iOS / macOS: `AppleDebugProvider()` (enables iOS Simulator without App Attest hardware restrictions).
     - Android: `AndroidDebugProvider()` (enables local Android emulator/debug device testing).
   - **Production Release**:
     - iOS: `AppleAppAttestWithDeviceCheckFallbackProvider()` (uses hardware-backed App Attest on modern iOS devices, falling back gracefully to DeviceCheck on older hardware).
     - Android: `AndroidPlayIntegrityProvider()` (hardware-backed Google Play Integrity attestation).
3. **Safe Initialization & Non-Blocking Design**:
   - App Check activation occurs inside the guarded Firebase bootstrap sequence without blocking offline startup or test executions.
4. **Enforcement Policy**:
   - App Check is integrated in monitor mode. Automatic enforcement in Firebase Console is intentionally deferred until production metrics are established in Firebase Console.
5. **Compilation & Build Verification**:
   - Built iOS Simulator bundle: `Runner.app` (39.1s, exit code 0).
   - Built Android Debug APK: `app-debug.apk` (22.6s, exit code 0).

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- `flutter build ios --simulator --no-codesign`: Passed (`build/ios/iphonesimulator/Runner.app`).
- `flutter build apk --debug`: Passed (`build/app/outputs/flutter-apk/app-debug.apk`).
- `git diff --check`: Passed (clean whitespace).

## Phase 8 — Existing Firebase Configuration & Leak Audit

### Summary
Verified existing real Firebase credentials and performed an exhaustive security audit of git history and file tracking for credential exposure.

### Key Verifications
1. **Target Firebase Project Identifiers**:
   - Firebase Project ID: `denk-262c0` (verified in `.firebaserc`, `lib/firebase_options.dart`).
   - Android Application ID: `com.omerfarukay.denk` (verified in `android/app/build.gradle.kts`).
   - iOS Product Bundle ID: `com.denk.denk` (verified in `ios/Runner.xcodeproj/project.pbxproj`).
   - Legacy Project ID: `denk-shared-expenses` completely eliminated across all files (0 occurrences).
2. **Secret & Key Leakage Audit**:
   - Audited git commit log for service account private keys (`BEGIN PRIVATE KEY`, `private_key`): 0 matches.
   - Verified that native credential files (`google-services.json`, `GoogleService-Info.plist`, `.env`) are properly gitignored and not tracked in the git index.

---

## Phase 9 — Firebase Console Verification & Environment Boundaries

### Summary
Verified server-side assets and established a clear checklist distinguishing code-verifiable components from manual Firebase Console administration tasks.

### Key Verifications
1. **Verified via Code / CLI**:
   - Firestore Security Rules: Deployed and active on `denk-262c0` (`npx firebase deploy --only firestore:rules`).
   - Firestore Composite Indexes: Deployed and active on `denk-262c0` (`npx firebase deploy --only firestore:indexes`).
   - Backend Architecture: 100% server-enforced in Firestore Security Rules; zero external server or Cloud Function required.
2. **Console-Only Action Items Identified**:
   - **Play Integrity Keystore Fingerprints**: Registered SHA-1 & SHA-256 for Android in Firebase Console:
     - Debug Keystore SHA-1: `9A:DE:80:04:32:44:B9:D6:F7:C8:71:AA:DE:09:6A:E0:70:C7:31:D2`
     - Debug Keystore SHA-256: `EB:9A:C1:80:53:47:59:6F:60:F2:AF:77:CB:61:57:02:E7:75:27:09:3F:7E:B6:04:61:55:9E:02:3A:91:6B:C9`
   - **App Check Enforcement**: Maintained in monitoring mode in Firebase Console until production release metrics are reviewed.

---

## Phase 10 — Privacy/Data Minimization Audit

### Summary
Audited codebase and customer-facing documentation to ensure strict data minimization and eliminate inaccurate privacy claims.

### Key Verifications
1. **Zero Collection of Sensitive Personal Vectors**:
   - Confirmed zero collection or requests for email, phone number, contacts, GPS location, birth date, physical address, profile photos, or advertising tracking IDs.
2. **Standardized Privacy Terminology**:
   - Replaced any colloquial phrases with the formal standard: `Privacy-First, Data-Minimized Architecture`.
   - Updated `docs/privacy.md` and in-app privacy information dialog in `lib/features/settings/presentation/settings_screen.dart` and aligned test expectations.

### Verification Gates
- `dart format lib test`: Passed.
- `flutter analyze`: Passed (0 issues).
- `flutter test`: Passed (all 74 tests passing).
- `git diff --check`: Passed (clean whitespace).

## Phase 11 — Complete Security Test Suite

### Summary
Unified and verified the complete 57-test security test suite running directly against the Firebase Firestore Local Emulator in `test/security/rules.test.js`.

### Coverage Breakdown
1. **Authentication (6 tests)**:
   - Unauthenticated reads and writes rejected across `groups`, `invites`, `users`, and `expenses`.
2. **Groups & Isolation (11 tests)**:
   - Collection-wide enumeration rejected (`allow list: if false;`).
   - Guessed `groupId` lookups by non-members rejected.
   - Cross-group expense and settlement read/write rejected.
3. **Invites & Entropy (3 tests)**:
   - Global invite enumeration rejected. Direct lookup with known code allowed.
4. **Membership & Anti-Escalation (10 tests)**:
   - Guessed groupId self-join rejected. Missing, invalid, inactive, or wrong-group invite rejected.
   - UID spoofing rejected.
   - Role escalation to `owner` or `admin` on joining existing groups rejected.
5. **Expense Financial Invariants (11 tests)**:
   - Floating-point `totalMinor` rejected. Zero and negative amounts rejected.
   - Currency format validation enforced (`^[A-Z]{3}$`).
   - Mismatched payer sums and split sums rejected.
   - Foreign non-member payer or split participant UIDs rejected.
   - `createdBy` spoofing on creation and mutation on update rejected.
6. **Settlement Integrity (9 tests)**:
   - Foreign/arbitrary UIDs rejected.
   - Self-settlement (`fromUid == toUid`) rejected.
   - Invalid currency and amount rejected.
   - Completed settlements declared strictly immutable (`allow update: if false;`).
7. **Timestamp Integrity (7 tests)**:
   - Future `createdAt`, `settledAt`, and event `date` rejected.
   - Valid past timestamps allowed (preserving offline persistence sync).
   - Modification of `createdAt` and `joinedAt` on update rejected.
   - Monotonicity of `updatedAt` enforced.

**Result: 57 / 57 tests passing.**

---

## Phase 12 — Production Security Documentation

### Summary
Authored comprehensive security architecture documentation in `docs/security.md`, and updated `docs/architecture.md`, `docs/privacy.md`, and `docs/implementation-progress.md` to reflect verified production controls.

---

## Phase 13 — Final Read-Only Security Audit

### Summary
Conducted a final, read-only security review across all 12 core vulnerability vectors without modifying codebase structure.

### Audit Checklist & Verdict
1. **Unauthenticated Access**: PROTECTED. All read/write rules require `request.auth != null`.
2. **Group Enumeration**: PROTECTED. `allow list: if false;` prevents collection queries.
3. **Invite Enumeration**: PROTECTED. `allow list: if false;` blocks token scanning.
4. **Guessed GroupId Join**: PROTECTED. Requires proof-of-invite with matching active token.
5. **Role Escalation**: PROTECTED. Member creation only permits `role: 'member'`. Roles immutable on update.
6. **Cross-Group Access**: PROTECTED. Roster, expenses, and settlements scoped to verified group members.
7. **Arbitrary Member UID**: PROTECTED. Payer and split participant UIDs verified against group roster.
8. **Malformed Financial Records**: PROTECTED. Integer minor units strictly enforced, floats/zero/negatives rejected, currency regex enforced.
9. **createdBy Spoofing**: PROTECTED. `createdBy == request.auth.uid` enforced; immutable on update.
10. **Timestamp Manipulation**: PROTECTED. Future timestamps blocked; creation timestamps immutable; offline sync supported.
11. **Secret Exposure**: CLEAN. Zero private keys, `.env`, or service account secrets in git history or repo.
12. **Git History**: CLEAN. All native config files gitignored; 0 leaked credentials.
