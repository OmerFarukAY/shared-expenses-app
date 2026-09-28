# Privacy-First, Data-Minimized Architecture

**Application:** Denk  
**Platform:** Mobile (Flutter / Firebase)

---

## 1. Principles of Data Minimization

Denk is intentionally designed from the ground up to respect user privacy:

1. **No Account Credentials Required**:
   - No email address
   - No phone number
   - No passwords
   - No third-party OAuth integrations (Google, Apple, Facebook)

2. **No Hardware or Personal Device Permissions**:
   - No contacts access
   - No GPS or approximate location access
   - No camera access (unless explicitly enabled in future versions for receipt scanning)
   - No advertising identifiers (IDFA/GAID)

3. **Minimal Identifiers**:
   - Each app installation generates an anonymous Firebase UID.
   - The user chooses a local display name (e.g., "Alex", "Ömer") so fellow group members can identify who paid for what.
   - No demographic, behavioral, or tracking profiles are created.

---

## 2. What Data Is Processed and Stored

The only data stored in the backend (Cloud Firestore) is strictly necessary to calculate shared balances:

| Data Element | Storage Location | Purpose | Retention / Deletion |
| :--- | :--- | :--- | :--- |
| **Anonymous UID** | Firebase Auth / Firestore | Authenticating requests and attributing expense contributions | Deleted on user account deletion |
| **Display Name** | `users/{uid}`, `members/{uid}` | Displaying member names in group rosters and expenses | Editable anytime by user |
| **Group Metadata** | `groups/{groupId}` | Group title, description, default currency, invite code | Maintained while group is active |
| **Expense Records** | `groups/{groupId}/expenses` | Amount (integer minor units), category, payers, participants, date | Editable/deletable by group members |
| **Settlement Records**| `groups/{groupId}/settlements`| Transferred amount, debtor UID, creditor UID, completion timestamp | Deletable by group members |
| **Invite Records** | `invites/{code}` | Invite code lookup connecting an alphanumeric token to a group ID | Active until group deleted or code reset |

---

## 3. Third-Party Infrastructure

Denk uses Google Cloud / Firebase for:
- Firebase Anonymous Authentication (session management)
- Cloud Firestore (encrypted in transit via TLS 1.3 and at rest via Google Cloud encryption)

No third-party analytics (Google Analytics, Mixpanel, Amplitude), crash tracking with personal data, or advertising networks are integrated.

---

## 4. User Rights & Data Deletion

Users have full autonomy over their data:
- **Display Name Editing**: Change your display name at any time from Settings.
- **Group Leaving / Removal**: Remove yourself from a group at any time.
- **Account Identity Deletion**: Selecting "Delete Account" deletes the local anonymous session, deletes the user record from the database, and re-initializes a clean state.
