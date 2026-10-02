# Privacy-First, Data-Minimized Architecture

**Application:** Denk
**Platform:** Mobile (Flutter / Firebase) &amp; Web Hosting (`https://denk-262c0.web.app`)
**Last Updated:** October 2, 2026 (Phase 18)

---

## 1. Principles of Data Minimization

Denk is intentionally designed from the ground up to respect user privacy:

1. **Anonymous-First Onboarding**:
   - Zero mandatory credentials upon app installation.
   - No email address, phone number, or password required.
   - Each app installation generates an anonymous Firebase UID.

2. **Optional Account Linking &amp; Recovery (Phase 16)**:
   - Users may optionally link their Apple ID (*Sign in with Apple*) or Google Account (*Google Sign-In*) through Settings to preserve groups and balances across device changes.
   - Account linking preserves the existing Firebase Auth `uid` without mutating Firestore user collections.
   - Credentials are handled directly by Firebase Authentication; Denk never sees or stores external account passwords.

3. **No Hardware or Personal Device Permissions**:
   - No address book or contacts access (invitation via high-entropy voluntary invite codes `DNK-XXXXXX`).
   - No GPS or location permissions.
   - No camera or microphone access.
   - No advertising identifiers (IDFA/GAID) and no tracker SDKs.

4. **Minimal Identifiers**:
   - The user chooses a local display name (e.g., "Alex", "Ömer") so fellow group members can identify who paid for what.
   - No demographic, behavioral, or tracking profiles are created.

---

## 2. What Data Is Processed and Stored

The only data stored in the backend (Cloud Firestore) is strictly necessary to calculate shared balances:

| Data Element | Storage Location | Purpose | Retention / Deletion |
| :--- | :--- | :--- | :--- |
| **User Identifier (UID)** | Firebase Auth / Firestore | Authenticating requests and attributing expense contributions | Deleted on user account deletion |
| **Display Name** | `users/{uid}`, `members/{uid}` | Displaying member names in group rosters and expenses | Editable anytime by user; anonymized on deletion |
| **Group Metadata** | `groups/{groupId}` | Group title, description, default currency, invite code | Maintained while group is active; deleted if sole owner deletes account |
| **Expense Records** | `groups/{groupId}/expenses` | Integer minor currency amounts, category, payers, participants, date | Preserved to maintain mathematical group balance integrity |
| **Settlement Records** | `groups/{groupId}/settlements`| Transferred amount, debtor UID, creditor UID, completion timestamp | Immutable ledger records |
| **Invite Records** | `invites/{code}` | High-entropy 6-character alphanumeric code mapping to a group ID | Active until group deleted or code reset |

---

## 3. Third-Party Infrastructure &amp; Security

Denk uses Google Cloud / Firebase for:
- **Firebase Authentication**: Anonymous sessions and optional Google/Apple provider linking.
- **Cloud Firestore**: Database encrypted in transit via TLS 1.3 and at rest via Google Cloud AES-256.
- **Firebase App Check**: Hardware-backed attestation (Apple DeviceCheck / App Attest on iOS, Google Play Integrity on Android) to block bot traffic.
- **Firebase Hosting**: Public hosting for legal and compliance documents.

No third-party advertising SDKs, marketing trackers (e.g., Meta Pixel, AppsFlyer), or user-profiling analytics are integrated.

---

## 4. User Rights, Account Deletion &amp; Anonymization (Phase 17 &amp; 18)

Users maintain complete sovereignty over their data:

1. **In-App Account Deletion (Immediate)**:
   - Available under **Settings &rarr; Privacy &amp; Data &rarr; Delete Account**.
   - **Sole-Owned Groups**: Completely wiped (group doc, subcollections, expenses, settlements, and invite codes).
   - **Multi-Member Groups &amp; Ownership Transfer**: If a user owns a group with other active members, ownership must be transferred to a peer before deletion can proceed.
   - **Anonymization**: The member document in shared groups is updated with `displayName: "Deleted User"` and `leftAt: [timestamp]`. Financial expense amounts, payers, and splits are strictly preserved so remaining peers' balance calculations remain mathematically intact.
   - **Profile Purge**: User document (`users/{uid}`), subcollections (`user_groups`, `join_requests`), and Firebase Auth credential are permanently deleted.

2. **Public Web Deletion Request (Phase 18)**:
   - For users who uninstalled the app or lost their device, a public web deletion request portal is available at:
     **`https://denk-262c0.web.app/delete-account`**
   - Verified requests are executed within 30 days pursuant to Google Play Data Safety policies and GDPR Article 17.

---

## 5. Live Public Legal Endpoints

All legal and compliance documentation is deployed on Firebase Hosting:
- **Privacy Policy**: `https://denk-262c0.web.app/privacy`
- **Terms of Service**: `https://denk-262c0.web.app/terms`
- **Account Deletion Portal**: `https://denk-262c0.web.app/delete-account`
- **Portal Landing**: `https://denk-262c0.web.app/`
