# Backend & Security Changelog

## [Phase 20-22] - Production Hardening (Crashlytics, Firestore Read Optimization, Haptics)
**Status:** TAMAMLANDI
**Date:** 2026-10-02

### 1. Firebase Crashlytics Cross-Platform Integration (Phase 20)
- Added `firebase_crashlytics: ^5.4.0` dependency.
- Android: Added Gradle plugin `com.google.firebase.crashlytics` (`3.0.3`) in `android/settings.gradle.kts` and `android/app/build.gradle.kts`.
- iOS: Registered plugin via Swift Package Manager (`FlutterGeneratedPluginSwiftPackage`).
- Initialized in `lib/main.dart`:
  - `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;` (uncaught UI/render tree exceptions).
  - `PlatformDispatcher.instance.onError = (error, stack) { FirebaseCrashlytics.instance.recordError(error, stack, fatal: true); return true; };` (uncaught asynchronous errors).
  - Enforced zero-telemetry policy: `setCrashlyticsCollectionEnabled(!kDebugMode)` disables local/debug collection, enabling crash capture strictly for production release builds. No user tracking or non-fatal analytics collected.

### 2. Firestore Read Optimization & N+1 Read Elimination (Phase 21)
- Root Cause: `watchUserGroups(uid)` previously iterated sequentially through `users/{uid}/user_groups` snapshots, performing $N$ sequential round-trip `get()` reads to `/groups/{groupId}` ($1 + N$ reads per snapshot).
- Solution:
  - **Denormalized Summary**: `createGroup`, `joinGroupWithInvite`, and `approveJoinRequest` write essential group display fields (`name`, `defaultCurrency`, `inviteCode`, `memberCount`, `memberUids`, `createdBy`, `createdAt`, `updatedAt`, `active`) into `users/{uid}/user_groups/{groupId}`.
  - **Fast-Path**: If `doc.data()` contains `name` and `defaultCurrency`, `GroupModel.fromMap` is constructed immediately with **0 secondary reads** (reducing read amplification from $1 + N$ to 1).
  - **In-Memory Cache**: `FirestoreGroupRepository` maintains `_groupCache` populated on create/join/get, and cleanly evicted on `deleteGroup`, `leaveGroup`, `removeMember`, `transferOwnership`, and `leaveGroupAsNonOwner`.
  - **Parallel Read Fallback**: For legacy records without denormalized summaries, fetches execute in parallel via `Future.wait` (1 round trip instead of $N$).
  - **Pre-check Optimization**: `getOwnedGroups` and `getMemberOnlyGroupIds` updated to leverage denormalized data and cache first.
- Verification: Added 4 unit tests in `test/features/groups/group_repository_test.dart` verifying 0 secondary reads, cache hit behavior, legacy fallback, and cache eviction.

### 3. Restrained Haptic Feedback Architecture (Phase 22)
- Created centralized utility `lib/core/theme/app_haptics.dart` with 4 semantic methods:
  - `AppHaptics.selection()` -> `selectionClick()` (subtle chip/currency picker taps)
  - `AppHaptics.light()` -> `lightImpact()` (toggles, non-blocking confirmations)
  - `AppHaptics.medium()` -> `mediumImpact()` (positive actions: expense saved, settlement recorded, group created)
  - `AppHaptics.heavy()` -> `heavyImpact()` (destructive actions: delete expense, delete group, leave group, remove member, delete account)
- Platform & Accessibility: Automatically respects iOS and Android system-level vibration/haptics toggle; gracefully handles unsupported platforms.
- Verification: Added `test/core/app_haptics_test.dart` asserting proper platform channel calls.

### 4. Quality Gates & Release Verification
- `flutter analyze`: **0 issues found**.
- `flutter test`: **127 / 127 tests passing**.
- Android Release Build: `flutter build appbundle --release` compiling clean AAB with Crashlytics and ProGuard rules.

---

## [Phase 19] - Android Production Signing & Release Build
**Status:** TAMAMLANDI
**Date:** 2026-10-02

### 1. Release Signing Architecture & Gradle Decoupling
- Removed debug signing fallback from `buildTypes.release` in `android/app/build.gradle.kts`.
- Configured production `signingConfigs.create("release")` that dynamically reads credentials from `android/key.properties`.
- Created `android/key.properties.example` template for development and CI environments.

### 2. Keystore & Credential Security
- Added `*.jks`, `*.keystore`, and `key.properties` to `.gitignore`.
- Verified zero git tracking for `android/upload-keystore.jks` and `android/key.properties`.
- Generated 2048-bit RSA PKCS12 upload keystore (`upload`) with 10,000 days validity.

### 3. R8 / ProGuard Shrinking & Optimization
- Enabled `isMinifyEnabled = true` and `isShrinkResources = true` in `buildTypes.release`.
- Created `android/app/proguard-rules.pro` protecting Flutter engine entrypoints, Firebase SDKs, URL Launcher custom tabs, and Google Play Core SplitInstall classes.

### 4. Build & Signature Verification
- Package identifier verified: `com.omerfarukay.denk`.
- Built production Android App Bundle: `build/app/outputs/bundle/release/app-release.aab` (58.6 MB).
- Verified bundle signature with `jarsigner -verify -verbose -certs`: signed by `CN=Omer Faruk Ay, OU=Denk Mobile, O=Denk, L=Istanbul, ST=Istanbul, C=TR`.

### 5. Documentation & Firebase Setup
- Authored `docs/release-guide.md` documenting keystore generation, fingerprint extraction, Google Play App Signing, and Firebase Console integration steps.
- Public certificate fingerprints extracted:
  - **SHA-1:** `18:98:48:76:F2:0C:DB:35:6A:F9:59:12:B0:29:46:DB:B9:EC:39:99`
  - **SHA-256:** `C3:A2:C5:22:8A:E1:3E:EF:60:60:C2:A1:6B:67:C8:5E:23:87:9F:FC:41:C8:CF:F0:06:25:77:48:21:D1:F8:B9`

### 6. Tests & Analysis
- `flutter analyze`: **0 issues found**.
- `flutter test`: **119 / 119 tests passing**.

---

## [Phase 18] - Privacy Policy, Terms of Service & Web Account Deletion
**Status:** TAMAMLANDI
**Date:** 2026-10-02

### 1. Public Legal & Compliance Endpoints (Firebase Hosting)
Configured Firebase Hosting in `firebase.json` for site `denk-262c0` (`web/` root with `cleanUrls: true`) and deployed production-ready, mobile-responsive HTML pages:
- **`web/privacy.html` (`https://denk-262c0.web.app/privacy`)**:
  - Truthfully discloses anonymous Firebase authentication, optional Google/Apple account linking, and Cloud Firestore collections.
  - Documents the complete account deletion and ledger anonymization architecture implemented in Phase 17.
  - Explicitly declares zero advertising identifiers (no IDFA, no GAID), zero third-party telemetry/trackers, zero contact book access, and zero GPS tracking.
  - Documents support for international currencies (TRY, USD, EUR, GBP, JPY, CAD, AUD, CHF) and 5 languages (EN, TR, ES, FR, IT).
- **`web/terms.html` (`https://denk-262c0.web.app/terms`)**:
  - Clear shared ledger utility terms of service.
  - Non-financial institution disclaimer: Denk is NOT a bank, payment processor, or money transmitter; does not process or hold user funds; recorded settlements represent peer balance agreements with off-platform settlement.
- **`web/delete-account.html` (`https://denk-262c0.web.app/delete-account`)**:
  - Complies with Google Play Data Safety and Apple App Store Review Guidelines.
  - Outlines the instant in-app deletion process across 5 languages (EN, TR, ES, FR, IT).
  - Provides a client-side validated public web form generating structured email deletion requests to `denk@omerfarukay.com` for users who lost their device or uninstalled the app (processed within 30 days).
  - Clear data transparency audit table (deleted vs anonymized vs preserved).
- **`web/index.html` (`https://denk-262c0.web.app/`)**:
  - Central portal landing page providing quick access to all compliance documents in 5 languages.
- **Multi-Language Architecture (`web/lang.js`, `web/styles.css`)**:
  - Ultra-sleek, modern design powered by Plus Jakarta Sans and responsive CSS grid header.
  - Full native 5-language switcher (English, Türkçe, Español, Français, Italiano) with client-side persistence and zero text collision.

### 2. Client Integration & Deep Linking
- Added `url_launcher: ^6.3.2` and created `lib/core/constants/legal_urls.dart`.
- Added Android 11+ `<queries>` intents for `https`, `http`, and `mailto` in `android/app/src/main/AndroidManifest.xml`.
- Integrated Privacy Policy, Terms of Service, and Web Account Deletion links in `SettingsScreen` within the Privacy & Data card and inside the Privacy Architecture modal.

### 3. Localization Parity
- Added 7 localized keys across all 5 supported ARB files (`app_en.arb`, `app_tr.arb`, `app_es.arb`, `app_fr.arb`, `app_it.arb`):
  - `privacyPolicyTitle`, `termsOfServiceTitle`, `webAccountDeletionTitle`, `webAccountDeletionSubtitle`, `errorOpeningUrl`, `legalSectionTitle`, `openAction`.
- Regenerated localization bindings with `flutter gen-l10n`.
- Verified 100% key parity via `test/core/localization_test.dart`.

### 4. Verification & Testing
- `flutter analyze`: **0 issues found**.
- `flutter test`: **119 / 119 tests passing** (added dedicated widget test in `settings_screen_test.dart`).
- Firebase Hosting: All URLs tested and verified live with HTTP 200 OK.
- `git diff --check`: Clean whitespace.

---

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
