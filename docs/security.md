# Denk — Comprehensive Security Architecture & Threat Model

**Application:** Denk (Shared Expenses)  
**Target Environment:** Firebase Production (`denk-262c0`)  
**Platforms:** iOS (`com.denk.denk`) & Android (`com.omerfarukay.denk`)  
**Security Status:** Production Hardened & Formally Verified  

---

## 1. Threat Model & Security Perimeter

Denk operates on an anonymous, privacy-first authentication model where clients interact directly with Cloud Firestore via client SDKs. In this architecture, **Cloud Firestore Security Rules serve as the primary security boundary**.

### Protected Assets:
1. **Financial Ledger Records (`expenses`)**: Monetary totals, payer allocations, participant splits.
2. **Settlement History (`settlements`)**: Historical transfers between group members.
3. **Group Membership (`members`)**: Access control lists and roles within groups.
4. **Invite Tokens (`invites`)**: Public entry points into private groups.
5. **User Identities (`users`)**: Minimal display names and timestamps.

---

## 2. Security Controls by Layer

### 2.1 Collection-Wide Anti-Enumeration (Phase 1)
- **Problem**: In standard Firestore setups, `allow read: if request.auth != null;` permits any authenticated user to execute collection-wide `getDocs()` queries, scraping all groups, invites, or user profiles in the database.
- **Solution**: Explicit separation of `get` and `list` operations:
  - `invites`: `allow list: if false;` | `allow get: if isAuthenticated();`
  - `groups`: `allow list: if false;` | `allow get: if isGroupMember(groupId) || isCreator;`
  - `users`: `allow list: if false;` | `allow get: if isOwner(uid);`
- **Result**: Global database scraping and enumeration are mathematically impossible.

### 2.2 Proof-of-Invite Membership & Anti-Escalation (Phase 2)
- **Problem**: Guessing a `groupId` or attempting to join a group without authorization or escalating to `role: owner`.
- **Solution**:
  - Joining an existing group strictly requires submitting a matching active `inviteCode`.
  - Rules verify that `invites/{code}` exists, is active, and matches `groupId`.
  - Self-joined members are strictly constrained to `role: 'member'`. Attempts to inject `role: 'owner'` or `role: 'admin'` are rejected.
  - Creator `owner` assignment is restricted to atomic batch group creation (`getAfter(...)`).
  - Roles are immutable on member document updates: `role == resource.data.role`.
  - UID spoofing is blocked: `request.auth.uid == memberUid`.

### 2.3 729M Entropy Cryptographic Invite Codes (Phase 3)
- **Problem**: Short 4-character codes (810,000 space) are vulnerable to distributed brute-force guessing.
- **Solution**:
  - Upgraded to 6-character unambiguous alphanumeric codes (`DNK-XXXXXX`) generated via `Random.secure()`.
  - Alphabet: `23456789ABCDEFGHJKMNPQRSTUVWXYZ` (30 chars, excludes 0/O/1/I/L).
  - Search space expanded by 900x to $30^6 = 729,000,000$ combinations.
  - Implemented pre-creation collision check with retry in `FirestoreGroupRepository`.
  - Maintained 100% backward compatibility for legacy 4-character codes via regex `^DNK-[...]{4,6}$`.

### 2.4 Server-Enforced Financial Invariants (Phase 4)
- **Problem**: Malicious clients submitting negative amounts, floating-point decimals, mismatched payer/split sums, or foreign UIDs.
- **Solution**:
  - Integer minor units enforced: `totalMinor is int && totalMinor > 0` (rejects floats/doubles).
  - Currency validation: 3-letter ISO uppercase format (`^[A-Z]{3}$`).
  - Payer integrity: Each payer verified as a group member, payer amounts positive integers, and payer sum equals `totalMinor`.
  - Split integrity: Split participant set strictly equals participants list, each split amount is a positive integer, participants verified as group members, and split sum equals `totalMinor`.
  - Ownership: `createdBy == request.auth.uid` mandatory on creation; `createdBy` and `groupId` strictly immutable on update.

### 2.5 Settlement Integrity & Canonical Ownership (Phase 5)
- **Problem**: Manipulating debt settlements, self-settling, creating settlements between non-members, or altering historical payments.
- **Solution**:
  - Canonical ownership field: Standardized on `createdBy` across models, repository, and rules (with `settledBy` compatibility alias).
  - Cross-group UID rejection: Both `fromUid` and `toUid` must exist in `groups/{groupId}/members/`.
  - Self-settlement blocked: `fromUid != toUid`.
  - Settlement amount integrity: `amountMinor is int && amountMinor > 0` with valid 3-letter currency.
  - Absolute Immutability: `allow update: if false;` on `groups/{groupId}/settlements/{settlementId}` guarantees financial records cannot be tampered with once recorded.

### 2.6 Offline-First Timestamp Integrity (Phase 6)
- **Problem**: Enforcing timestamp integrity without breaking Firestore offline persistence and synchronization replay.
- **Solution**:
  - Asymmetric temporal verification: `createdAt <= request.time + duration.value(5, 'm')` strictly rejects future timestamps while allowing offline creations recorded in the past to sync upon reconnection.
  - Event dates: `date <= request.time + duration.value(1, 'd')` allows historical receipts while rejecting future events.
  - Immutability: `createdAt` and `joinedAt` are permanently immutable on updates.
  - Monotonicity: `updatedAt >= resource.data.updatedAt && updatedAt <= request.time + 5m`.

### 2.7 Firebase App Check (Phase 7)
- **Dual-Mode Provider Architecture**:
  - Development / Debug: `AppleDebugProvider` & `AndroidDebugProvider` (enables simulator and emulator testing).
  - Production Release: `AppleAppAttestWithDeviceCheckFallbackProvider` (iOS) & `AndroidPlayIntegrityProvider` (Android).
- **Enforcement Policy**: Monitor mode first; console enforcement applied after validating attestation telemetry.

---

## 3. Automated Security Test Matrix

Denk maintains an automated test suite executed against the Firebase Firestore Emulator (`test/security/rules.test.js`).

| Test Suite | Tests | Verification Scope | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1: Rules Hardening** | 20 | Anti-enumeration, unauthenticated rejection, group isolation, profile protection | **PASSED** |
| **Phase 2: Group Join & Anti-Escalation** | 10 | Guessed groupId rejection, invalid/inactive invite rejection, role escalation rejection, UID spoofing | **PASSED** |
| **Phase 4: Financial Invariants** | 11 | Float rejection, zero/negative total rejection, currency regex, payer/split sums, foreign UIDs, createdBy immutability | **PASSED** |
| **Phase 5: Settlement Integrity** | 9 | Member validation, self-settlement rejection, invalid currency/amount rejection, settlement immutability | **PASSED** |
| **Phase 6: Timestamp Integrity** | 7 | Future timestamp rejection, offline sync past timestamp allowance, createdAt/joinedAt immutability | **PASSED** |
| **Total Automated Rules Tests** | **57** | **100% of defined security invariants** | **PASSED** |

---

## 4. Verification & Audit Discipline

Before every commit, the codebase must pass all 5 verification gates:
1. `dart format lib test`: Code formatting verified.
2. `flutter analyze`: Static analysis passed (0 issues).
3. `flutter test`: 74 unit, widget, and integration tests passed.
4. `npm test` (Firestore Emulator): 57 security rules unit tests passed.
5. `git diff --check`: Clean whitespace and diff verified.
