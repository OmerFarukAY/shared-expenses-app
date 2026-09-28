# Architecture & Technical Design Document

**Product Name:** Denk  
**Tagline:** Privacy-first, real-time shared expenses  
**Platform:** Flutter (iOS & Android)  
**Backend:** Firebase (Authentication, Cloud Firestore, Security Rules)

---

## 1. Product Mental Model

The central financial model of Denk is built on three distinct questions:
1. **Who paid?** (One or multiple payers contributing specific minor currency amounts).
2. **Who participated?** (One or multiple members who benefit from the expense).
3. **How is the expense split?** (Equal, exact amounts, or percentage).

Payers and participants are completely decoupled. A person can pay for an expense they do not participate in (e.g. buying a gift for a roommate), or participate without paying directly.

---

## 2. Privacy-First Architecture

Denk eliminates unnecessary data collection:
- **No Email, Phone, or Password**: Uses Firebase Anonymous Authentication (`signInAnonymously()`).
- **No Social Logins or Third-Party Trackers**: Zero Facebook, Google, or Apple login SDK requirements.
- **No Contacts, Location, or Camera Permissions Required**: Only standard network access.
- **Display Name Only**: Users choose a friendly display name stored with their anonymous UID.
- **Data Minimization**: Database schema contains only group membership, expense records, and settlement records.

---

## 3. Data Model & Firestore Architecture

### 3.1 Collections Hierarchy

```
users/{uid}
  - uid: string
  - displayName: string
  - preferredCurrency: string (ISO 4217, e.g. "TRY", "EUR", "USD")
  - languageCode: string (e.g. "en", "tr", "es", "fr", "it")
  - createdAt: timestamp
  - updatedAt: timestamp

groups/{groupId}
  - id: string
  - name: string
  - description: string (optional)
  - defaultCurrency: string (ISO 4217)
  - inviteCode: string (uppercase alphanumeric, e.g. "DNK-XXXXXX", 729M entropy)
  - createdBy: string (uid)
  - createdAt: timestamp
  - updatedAt: timestamp
  - memberCount: int
  - active: bool

groups/{groupId}/members/{uid}
  - uid: string
  - displayName: string
  - role: "owner" | "member"
  - joinedAt: timestamp

groups/{groupId}/expenses/{expenseId}
  - id: string
  - groupId: string
  - title: string
  - notes: string (optional)
  - category: string ("food", "groceries", "transport", "home", "entertainment", "travel", "bills", "shopping", "other")
  - currency: string (ISO 4217)
  - totalMinor: int (integer minor units, e.g. 2000 = 20.00)
  - date: timestamp (expense occurrence date)
  - splitMethod: "equal" | "custom" | "percentage"
  - payers: Map<String, int> (uid -> amountMinor paid)
  - participants: List<String> (uids of participants)
  - splits: Map<String, int> (uid -> amountMinor allocated owed)
  - createdBy: string (uid)
  - createdAt: timestamp
  - updatedAt: timestamp

groups/{groupId}/settlements/{settlementId}
  - id: string
  - groupId: string
  - fromUid: string (debtor who paid)
  - toUid: string (creditor who received)
  - amountMinor: int (settlement amount)
  - currency: string
  - settledAt: timestamp
  - createdBy: string
  - notes: string (optional)

invites/{inviteCode}
  - inviteCode: string
  - groupId: string
  - groupName: string
  - defaultCurrency: string
  - createdBy: string
  - createdAt: timestamp
  - active: bool
```

---

## 4. Financial Calculation Engine

### 4.1 Strict Integer Minor Units
All calculations are performed using 64-bit integer values (`int`).
- ₺20.00 = `2000`
- $5.50 = `550`
- €100.00 = `10000`
- ¥500 = `500` (currencies with 0 decimal places like JPY have exponent 0)

Floating-point numbers (`double`) are NEVER used for storing or computing balances.

### 4.2 Split Logic & Remainder Distribution
When splitting `totalMinor` among $N$ participants:
- **Equal Split**:
  $$\text{base} = \lfloor \text{totalMinor} / N \rfloor, \quad \text{remainder} = \text{totalMinor} \pmod N$$
  The first $\text{remainder}$ participants receive $\text{base} + 1$, and remaining receive $\text{base}$.
  Sum of splits is guaranteed to exactly equal $\text{totalMinor}$.
- **Custom Split**:
  Each participant's allocation in minor units is validated such that:
  $$\sum \text{splits}[u] = \text{totalMinor}$$
- **Percentage Split**:
  Users assign percentages (stored in basis points $0-10000$ or percentage integers).
  Exact rounding distributes any minor rounding cent to preserve the sum constraint.

### 4.3 Deterministic Debt Simplification
For a given currency within a group:
1. Compute member net balance:
   $$\text{net}[u] = \sum_{\text{expenses}} \text{paid}[u] - \sum_{\text{expenses}} \text{owed}[u] + \sum_{\text{settlements where } u = \text{from}} \text{amount} - \sum_{\text{settlements where } u = \text{to}} \text{amount}$$
2. Verify invariant: $\sum_u \text{net}[u] == 0$.
3. Partition members into Debtors ($\text{net} < 0$) and Creditors ($\text{net} > 0$).
4. Sort debtors ascending by amount, creditors descending by amount. Ties broken deterministically by member UID.
5. In each step:
   $$\text{transfer} = \min(|\text{debtor.balance}|, \text{creditor.balance})$$
   Create transaction: $\text{debtor} \to \text{creditor} : \text{transfer}$.
   Update balances and repeat until all balances are zero.

---

## 5. Security Rules Model

- Authentication required on every read and write (`request.auth != null`).
- Group membership is mandatory for reading group details, member rosters, expenses, and settlements.
- Writing expenses requires the authenticated user to be an active member of `groups/{groupId}/members`.
- Expense data validation enforces:
  - Valid string lengths for titles (1 to 100 characters).
  - Positive integer minor totals (`totalMinor > 0`).
  - Valid ISO currency codes (3 uppercase letters).
  - Correct split summation: sum of payers must equal `totalMinor`, sum of participant allocations must equal `totalMinor`.
- Users cannot modify or delete other users' identities.
- Invites are strictly read-only for lookup and can only be created by group members.

---

## 6. State Management & Offline Resilience

- **Riverpod 2.x**: StateNotifier / AsyncNotifier providers for auth state, active group, realtime expense stream, balance calculation, and settings.
- **Offline Persistence**: Firestore offline cache enabled by default. UI optimistic updates and cache indicators provide clear status to the user.
- **Real-time Sync**: Firestore snapshot listeners ensure instant synchronization across all member devices when expenses or settlements are added.

---

## 7. Visual Language, Design System & Iconography Standards

### 7.1 Non-Negotiable Rule: Zero Decorative Emojis
Decorative emojis are strictly forbidden throughout the entire application UI and localized copy.
- Never use emojis (e.g. food, home, travel, fire, heart, money, or faces) as substitutes for icons, navigation items, category indicators, empty-state illustrations, buttons, or badges.
- All iconography must use coherent, professional vector symbols (Material Rounded vector icons, custom vector SVGs, or custom Flutter `CustomPainter` widgets like `DenkLogo`).
- User Content Isolation: Emojis are only permitted if explicitly typed by an end-user into their own user-generated text content (such as a custom group name or expense title). The application runtime itself will never inject or present decorative emojis.
- Automated Testing: Enforced continuously via CI tests in `test/core/zero_decorative_emojis_test.dart` scanning all source code and ARB translation catalogs.

