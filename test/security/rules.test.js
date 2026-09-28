import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { doc, getDoc, getDocs, setDoc, updateDoc, collection } from 'firebase/firestore';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PROJECT_ID = 'denk-262c0';
let testEnv;

describe('Phase 1 Firestore Security Rules Hardening', () => {
  before(async function() {
    this.timeout(20000);
    const rulesPath = resolve(__dirname, '../../firestore.rules');
    const rules = readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async function() {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async function() {
    await testEnv.clearFirestore();

    // Seed test fixtures using admin context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const now = new Date();

      // 1. Group A created by user_alice
      await setDoc(doc(db, 'groups/group_a'), {
        id: 'group_a',
        name: 'Group A',
        defaultCurrency: 'TRY',
        inviteCode: 'DNK-ALICE1',
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
        memberCount: 2,
        memberUids: ['user_alice', 'user_bob'],
        active: true,
      });

      // Group A members: alice (owner) and bob (member)
      await setDoc(doc(db, 'groups/group_a/members/user_alice'), {
        uid: 'user_alice',
        displayName: 'Alice',
        role: 'owner',
        joinedAt: now,
      });
      await setDoc(doc(db, 'groups/group_a/members/user_bob'), {
        uid: 'user_bob',
        displayName: 'Bob',
        role: 'member',
        joinedAt: now,
      });

      // Group A expense
      await setDoc(doc(db, 'groups/group_a/expenses/exp_1'), {
        id: 'exp_1',
        groupId: 'group_a',
        title: 'Dinner',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice', 'user_bob'],
        splits: { user_alice: 5000, user_bob: 5000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      });

      // Group A settlement
      await setDoc(doc(db, 'groups/group_a/settlements/set_1'), {
        id: 'set_1',
        groupId: 'group_a',
        fromUid: 'user_bob',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_bob',
      });

      // Group A invite doc
      await setDoc(doc(db, 'invites/DNK-ALICE1'), {
        inviteCode: 'DNK-ALICE1',
        groupId: 'group_a',
        groupName: 'Group A',
        defaultCurrency: 'TRY',
        createdBy: 'user_alice',
        createdAt: now,
        active: true,
      });

      // 2. Group B created by user_charlie
      await setDoc(doc(db, 'groups/group_b'), {
        id: 'group_b',
        name: 'Group B',
        defaultCurrency: 'EUR',
        inviteCode: 'DNK-CHARL1',
        createdBy: 'user_charlie',
        createdAt: now,
        updatedAt: now,
        memberCount: 1,
        memberUids: ['user_charlie'],
        active: true,
      });

      await setDoc(doc(db, 'groups/group_b/members/user_charlie'), {
        uid: 'user_charlie',
        displayName: 'Charlie',
        role: 'owner',
        joinedAt: now,
      });

      await setDoc(doc(db, 'invites/DNK-CHARL1'), {
        inviteCode: 'DNK-CHARL1',
        groupId: 'group_b',
        groupName: 'Group B',
        defaultCurrency: 'EUR',
        createdBy: 'user_charlie',
        createdAt: now,
        active: true,
      });

      // Alice's user profile
      await setDoc(doc(db, 'users/user_alice'), {
        uid: 'user_alice',
        displayName: 'Alice',
        preferredCurrency: 'TRY',
        languageCode: 'tr',
        createdAt: now,
        updatedAt: now,
      });
    });
  });

  describe('1.1 Invite Enumeration Prevention', () => {
    it('rejects listing / querying all invites for any user', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertFails(getDocs(collection(bobDb, 'invites')));
    });

    it('allows direct document get for valid invite with known code', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertSucceeds(getDoc(doc(bobDb, 'invites/DNK-ALICE1')));
    });

    it('rejects unauthenticated user reading an invite', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(unauthDb, 'invites/DNK-ALICE1')));
    });
  });

  describe('1.2 Authentication Controls', () => {
    it('rejects unauthenticated read of any group', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(unauthDb, 'groups/group_a')));
    });

    it('rejects unauthenticated read of user profile', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(unauthDb, 'users/user_alice')));
    });

    it('rejects unauthenticated write to expenses', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(setDoc(doc(unauthDb, 'groups/group_a/expenses/exp_new'), {
        id: 'exp_new',
        groupId: 'group_a',
        title: 'Hacked',
        category: 'other',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'equal',
        payers: {},
        participants: [],
        splits: {},
        createdBy: 'anonymous',
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
    });
  });

  describe('1.3 Group Isolation & Cross-Group Rejection', () => {
    it('rejects non-member guessing groupId to read group details', async () => {
      // Charlie is not a member of Group A
      const charlieDb = testEnv.authenticatedContext('user_charlie').firestore();
      await assertFails(getDoc(doc(charlieDb, 'groups/group_a')));
    });

    it('rejects listing all groups in the database', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      await assertFails(getDocs(collection(aliceDb, 'groups')));
    });

    it('allows active group member to read group details', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertSucceeds(getDoc(doc(bobDb, 'groups/group_a')));
    });

    it('allows group creator to read group details', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      await assertSucceeds(getDoc(doc(aliceDb, 'groups/group_a')));
    });

    it('rejects cross-group expense read by non-member', async () => {
      // Charlie (Group B) cannot read Alice/Bob (Group A) expense
      const charlieDb = testEnv.authenticatedContext('user_charlie').firestore();
      await assertFails(getDoc(doc(charlieDb, 'groups/group_a/expenses/exp_1')));
    });

    it('allows group member to read group expenses', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertSucceeds(getDoc(doc(bobDb, 'groups/group_a/expenses/exp_1')));
      await assertSucceeds(getDocs(collection(bobDb, 'groups/group_a/expenses')));
    });

    it('rejects cross-group settlement read by non-member', async () => {
      const charlieDb = testEnv.authenticatedContext('user_charlie').firestore();
      await assertFails(getDoc(doc(charlieDb, 'groups/group_a/settlements/set_1')));
    });

    it('allows group member to read group settlements', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      await assertSucceeds(getDoc(doc(aliceDb, 'groups/group_a/settlements/set_1')));
      await assertSucceeds(getDocs(collection(aliceDb, 'groups/group_a/settlements')));
    });

    it('rejects cross-group expense write by non-member', async () => {
      const charlieDb = testEnv.authenticatedContext('user_charlie').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(charlieDb, 'groups/group_a/expenses/exp_cross'), {
        id: 'exp_cross',
        groupId: 'group_a',
        title: 'Intrusion',
        category: 'other',
        currency: 'TRY',
        totalMinor: 5000,
        date: now,
        splitMethod: 'equal',
        payers: { user_charlie: 5000 },
        participants: ['user_charlie'],
        splits: { user_charlie: 5000 },
        createdBy: 'user_charlie',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('rejects non-member listing member roster of another group', async () => {
      const charlieDb = testEnv.authenticatedContext('user_charlie').firestore();
      await assertFails(getDocs(collection(charlieDb, 'groups/group_a/members')));
    });

    it('allows group member to list member roster of their group', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertSucceeds(getDocs(collection(bobDb, 'groups/group_a/members')));
    });
  });

  describe('1.4 Unauthorized Writes & Profile Protection', () => {
    it('rejects user writing to another user profile', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(bobDb, 'users/user_alice'), {
        uid: 'user_alice',
        displayName: 'Impersonated',
        preferredCurrency: 'TRY',
        languageCode: 'tr',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('allows user writing to their own user profile with valid schema', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const now = new Date();
      await assertSucceeds(setDoc(doc(bobDb, 'users/user_bob'), {
        uid: 'user_bob',
        displayName: 'Bob The Builder',
        preferredCurrency: 'TRY',
        languageCode: 'en',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('rejects listing all users', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      await assertFails(getDocs(collection(bobDb, 'users')));
    });
  });

  describe('Phase 2 — Secure Group Join & Anti-Escalation Flow', () => {
    it('1. rejects joining by guessed groupId without valid invite', async () => {
      // Dave tries to join Group A just by knowing the groupId
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave Guesser',
        role: 'member',
        joinedAt: now,
      }));
    });

    it('2. rejects joining without an invite code provided', async () => {
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave NoInvite',
        role: 'member',
        joinedAt: now,
      }));
    });

    it('3. rejects joining with an invalid invite code', async () => {
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave BadCode',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-FAKE99',
      }));
    });

    it('4. rejects joining with an inactive invite code', async () => {
      // Create an inactive invite for Group A
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'invites/DNK-INACTIVE'), {
          inviteCode: 'DNK-INACTIVE',
          groupId: 'group_a',
          groupName: 'Group A',
          defaultCurrency: 'TRY',
          createdBy: 'user_alice',
          createdAt: new Date(),
          active: false,
        });
      });

      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave InactiveInvite',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-INACTIVE',
      }));
    });

    it('5. rejects joining with a wrong-group invite code', async () => {
      // Using Group B's invite (DNK-CHARL1) to join Group A
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave WrongGroup',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-CHARL1',
      }));
    });

    it('6. allows joining with a valid, active invite code for the group', async () => {
      // Dave joins Group A using Group A's active invite code DNK-ALICE1
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertSucceeds(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave Legitimate',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-ALICE1',
      }));
    });

    it('7. rejects joining using another user UID (UID spoofing)', async () => {
      // Dave tries to add a member document for Eve
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_eve'), {
        uid: 'user_eve',
        displayName: 'Eve Spoofed',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-ALICE1',
      }));
    });

    it('8. rejects owner role injection on joining an existing group', async () => {
      // Dave tries to escalate himself to 'owner' using a valid invite
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave WannaBeOwner',
        role: 'owner',
        joinedAt: now,
        inviteCode: 'DNK-ALICE1',
      }));
    });

    it('9. rejects admin role injection', async () => {
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_a/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave AdminInjection',
        role: 'admin',
        joinedAt: now,
        inviteCode: 'DNK-ALICE1',
      }));
    });

    it('10. rejects cross-group membership injection', async () => {
      // Dave tries to inject himself into Group B with Group A's invite code
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_b/members/user_dave'), {
        uid: 'user_dave',
        displayName: 'Dave CrossGroup',
        role: 'member',
        joinedAt: now,
        inviteCode: 'DNK-ALICE1',
      }));
    });
  });

  describe('Phase 4 — Expense Financial Invariants', () => {
    it('1. allows creating a valid expense with integer minor units, matching payers and splits', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_valid'), {
        id: 'exp_valid',
        groupId: 'group_a',
        title: 'Groceries',
        category: 'food',
        currency: 'TRY',
        totalMinor: 15000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 15000 },
        participants: ['user_alice', 'user_bob'],
        splits: { user_alice: 7500, user_bob: 7500 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('2. rejects floating point totalMinor', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_float'), {
        id: 'exp_float',
        groupId: 'group_a',
        title: 'Float expense',
        category: 'food',
        currency: 'TRY',
        totalMinor: 150.50,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 150.50 },
        participants: ['user_alice'],
        splits: { user_alice: 150.50 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('3. rejects zero or negative totalMinor', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_zero'), {
        id: 'exp_zero',
        groupId: 'group_a',
        title: 'Zero expense',
        category: 'food',
        currency: 'TRY',
        totalMinor: 0,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 0 },
        participants: ['user_alice'],
        splits: { user_alice: 0 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('4. rejects invalid currency format (lowercase or non-3-letter)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Lowercase 'try'
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_lower_curr'), {
        id: 'exp_lower_curr',
        groupId: 'group_a',
        title: 'Bad currency',
        category: 'food',
        currency: 'try',
        totalMinor: 1000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 1000 },
        participants: ['user_alice'],
        splits: { user_alice: 1000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));

      // 4-letter currency 'USDT'
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_4_curr'), {
        id: 'exp_4_curr',
        groupId: 'group_a',
        title: 'Bad currency',
        category: 'food',
        currency: 'USDT',
        totalMinor: 1000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 1000 },
        participants: ['user_alice'],
        splits: { user_alice: 1000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('5. rejects expense when payer sum does not match totalMinor', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_mismatch_payer'), {
        id: 'exp_mismatch_payer',
        groupId: 'group_a',
        title: 'Mismatched payer',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 8000 }, // sum 8000 != 10000
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('6. rejects expense when a payer is not a group member', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // user_charlie is in Group B, not Group A
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_foreign_payer'), {
        id: 'exp_foreign_payer',
        groupId: 'group_a',
        title: 'Foreign payer',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_charlie: 10000 },
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('7. rejects negative or zero payer amounts', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_neg_payer'), {
        id: 'exp_neg_payer',
        groupId: 'group_a',
        title: 'Negative payer',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'custom',
        payers: { user_alice: 12000, user_bob: -2000 }, // negative amount
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('8. rejects expense when split sum does not match totalMinor', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_mismatch_split'), {
        id: 'exp_mismatch_split',
        groupId: 'group_a',
        title: 'Mismatched split',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice', 'user_bob'],
        splits: { user_alice: 4000, user_bob: 4000 }, // sum 8000 != 10000
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('9. rejects expense when a split participant is not a group member', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // user_charlie is not in Group A
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_foreign_split'), {
        id: 'exp_foreign_split',
        groupId: 'group_a',
        title: 'Foreign split',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice', 'user_charlie'],
        splits: { user_alice: 5000, user_charlie: 5000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('10. rejects createdBy spoofing on new expense', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Alice tries to create expense claiming Bob created it
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_spoof_creator'), {
        id: 'exp_spoof_creator',
        groupId: 'group_a',
        title: 'Spoofed creator',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_bob',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('11. rejects modifying createdBy or groupId on expense update', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Try to mutate createdBy on existing exp_1
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_1'), {
        id: 'exp_1',
        groupId: 'group_a',
        title: 'Dinner Edited',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice', 'user_bob'],
        splits: { user_alice: 5000, user_bob: 5000 },
        createdBy: 'user_bob', // was user_alice
        createdAt: now,
        updatedAt: now,
      }));
    });
  });

  describe('Phase 5 — Settlement Integrity', () => {
    it('1. allows recording a valid settlement between group members', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const now = new Date();
      await assertSucceeds(setDoc(doc(bobDb, 'groups/group_a/settlements/set_valid'), {
        id: 'set_valid',
        groupId: 'group_a',
        fromUid: 'user_bob',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_bob',
      }));
    });

    it('2. rejects arbitrary non-member fromUid', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_bad_from'), {
        id: 'set_bad_from',
        groupId: 'group_a',
        fromUid: 'user_unknown',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('3. rejects arbitrary non-member toUid', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_bad_to'), {
        id: 'set_bad_to',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_unknown',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('4. rejects cross-group UID in settlement', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // user_charlie is in Group B, not Group A
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_cross'), {
        id: 'set_cross',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_charlie',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('5. rejects self-settlement (fromUid == toUid)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_self'), {
        id: 'set_self',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('6. rejects invalid amount (float, zero, or negative)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Float
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_float'), {
        id: 'set_float',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_bob',
        amountMinor: 50.50,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
      // Zero
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_zero'), {
        id: 'set_zero',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_bob',
        amountMinor: 0,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('7. rejects invalid currency format', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_bad_curr'), {
        id: 'set_bad_curr',
        groupId: 'group_a',
        fromUid: 'user_alice',
        toUid: 'user_bob',
        amountMinor: 5000,
        currency: 'try', // lowercase
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });

    it('8. rejects createdBy spoofing on settlement', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Alice tries to record settlement claiming Bob recorded it
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_spoofed_creator'), {
        id: 'set_spoofed_creator',
        groupId: 'group_a',
        fromUid: 'user_bob',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_bob',
      }));
    });

    it('9. rejects modifying / updating an existing settlement (immutable)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Try to mutate existing set_1
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/settlements/set_1'), {
        id: 'set_1',
        groupId: 'group_a',
        fromUid: 'user_bob',
        toUid: 'user_alice',
        amountMinor: 9999, // tampered amount
        currency: 'TRY',
        settledAt: now,
        createdBy: 'user_alice',
      }));
    });
  });

  describe('Phase 6 — Timestamp Integrity', () => {
    it('1. rejects creating an expense with future createdAt', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const futureTime = new Date(Date.now() + 60 * 60 * 1000); // 1 hour in future
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_future'), {
        id: 'exp_future',
        groupId: 'group_a',
        title: 'Future expense',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: futureTime,
        updatedAt: futureTime,
      }));
    });

    it('2. rejects creating an expense with date set far into future', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const farFutureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in future
      const now = new Date();
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_far_date'), {
        id: 'exp_far_date',
        groupId: 'group_a',
        title: 'Far future date',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: farFutureDate,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('3. allows valid past timestamp on expense creation (offline sync scenario)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const pastTime = new Date(Date.now() - 4 * 60 * 60 * 1000); // 4 hours ago (recorded offline)
      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_offline_sync'), {
        id: 'exp_offline_sync',
        groupId: 'group_a',
        title: 'Offline expense',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: pastTime,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice'],
        splits: { user_alice: 10000 },
        createdBy: 'user_alice',
        createdAt: pastTime,
        updatedAt: pastTime,
      }));
    });

    it('4. rejects modifying createdAt on expense update', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const tamperedCreatedTime = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // altered past
      await assertFails(setDoc(doc(aliceDb, 'groups/group_a/expenses/exp_1'), {
        id: 'exp_1',
        groupId: 'group_a',
        title: 'Dinner Edited',
        category: 'food',
        currency: 'TRY',
        totalMinor: 10000,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 10000 },
        participants: ['user_alice', 'user_bob'],
        splits: { user_alice: 5000, user_bob: 5000 },
        createdBy: 'user_alice',
        createdAt: tamperedCreatedTime, // changed from original seed
        updatedAt: now,
      }));
    });

    it('5. rejects recording settlement with future settledAt', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const futureTime = new Date(Date.now() + 60 * 60 * 1000);
      await assertFails(setDoc(doc(bobDb, 'groups/group_a/settlements/set_future'), {
        id: 'set_future',
        groupId: 'group_a',
        fromUid: 'user_bob',
        toUid: 'user_alice',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: futureTime,
        createdBy: 'user_bob',
      }));
    });

    it('6. rejects creating group with future createdAt', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const futureTime = new Date(Date.now() + 60 * 60 * 1000);
      await assertFails(setDoc(doc(aliceDb, 'groups/group_future'), {
        id: 'group_future',
        name: 'Future Group',
        defaultCurrency: 'TRY',
        inviteCode: 'DNK-FUTURE1',
        createdBy: 'user_alice',
        memberUids: ['user_alice'],
        createdAt: futureTime,
        updatedAt: futureTime,
        memberCount: 1,
        active: true,
      }));
    });

    it('7. rejects modifying joinedAt on member update', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const tamperedJoinedAt = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000); // 1 year ago
      await assertFails(setDoc(doc(bobDb, 'groups/group_a/members/user_bob'), {
        uid: 'user_bob',
        displayName: 'Bob Renamed',
        role: 'member',
        joinedAt: tamperedJoinedAt, // changed joinedAt
      }));
    });
  });

  describe('Phase 14 — Option B Membership Projection & 20-Participant Scale', () => {
    it('1. allows creating a new group with memberUids: [creatorUid] and memberCount: 1', async () => {
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertSucceeds(setDoc(doc(daveDb, 'groups/group_dave'), {
        id: 'group_dave',
        name: 'Dave Group',
        defaultCurrency: 'USD',
        inviteCode: 'DNK-DAVE01',
        createdBy: 'user_dave',
        memberUids: ['user_dave'],
        memberCount: 1,
        active: true,
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('2. rejects creating group with multiple or non-creator memberUids', async () => {
      const daveDb = testEnv.authenticatedContext('user_dave').firestore();
      const now = new Date();
      await assertFails(setDoc(doc(daveDb, 'groups/group_dave_bad'), {
        id: 'group_dave_bad',
        name: 'Dave Bad Group',
        defaultCurrency: 'USD',
        inviteCode: 'DNK-DAVE02',
        createdBy: 'user_dave',
        memberUids: ['user_dave', 'victim_user'], // attack: multiple initial members
        memberCount: 2,
        active: true,
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('3. allows legitimate join adding self to memberUids with valid active invite', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();
      await assertSucceeds(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['user_alice', 'user_bob', 'user_eve'],
        memberCount: 3,
        updatedAt: now,
      }));
    });

    it('4. Attack A: rejects join attempting to add self + victim UID simultaneously', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();
      await assertFails(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['user_alice', 'user_bob', 'user_eve', 'victim_uid'], // Attack A
        memberCount: 4,
        updatedAt: now,
      }));
    });

    it('5. Attack B: rejects regular member removing a victim member (unauthorized kick)', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const now = new Date();
      await assertFails(updateDoc(doc(bobDb, 'groups/group_a'), {
        memberUids: ['user_bob'], // Bob attempting to remove Alice
        memberCount: 1,
        updatedAt: now,
      }));
    });

    it('6. Attack C: rejects completely fabricated memberUids overwrite', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();
      await assertFails(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['fake_1', 'fake_2', 'user_eve'], // completely fabricated
        memberCount: 3,
        updatedAt: now,
      }));
    });

    it('7. allows member self-leave (removing self only)', async () => {
      const bobDb = testEnv.authenticatedContext('user_bob').firestore();
      const now = new Date();
      await assertSucceeds(updateDoc(doc(bobDb, 'groups/group_a'), {
        memberUids: ['user_alice'], // Bob leaves, only Alice remains
        memberCount: 1,
        updatedAt: now,
      }));
    });

    it('8. rejects creator leaving their own group', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertFails(updateDoc(doc(aliceDb, 'groups/group_a'), {
        memberUids: ['user_bob'], // Alice attempting to leave group_a
        memberCount: 1,
        updatedAt: now,
      }));
    });

    it('9. allows group creator to kick a member', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      await assertSucceeds(updateDoc(doc(aliceDb, 'groups/group_a'), {
        memberUids: ['user_alice'], // Alice kicks Bob
        memberCount: 1,
        updatedAt: now,
      }));
    });

    it('10. allows valid expense with up to 20 participants and exact split sum', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      // Setup a group with 20 members using admin context
      const members20 = Array.from({ length: 20 }, (_, i) => `user_${i + 1}`);
      members20[0] = 'user_alice';

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_20m'), {
          id: 'group_20m',
          name: 'Big Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-BIG001',
          createdBy: 'user_alice',
          memberUids: members20,
          memberCount: 20,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 20000;
      const splits = {};
      members20.forEach(uid => { splits[uid] = 1000; });

      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_20m/expenses/exp_20p'), {
        id: 'exp_20p',
        groupId: 'group_20m',
        title: 'Huge Dinner',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 20000 },
        participants: members20,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('11. rejects expense with 21 participants (exceeds safe ceiling of 20)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members21 = Array.from({ length: 21 }, (_, i) => `user_${i + 1}`);
      members21[0] = 'user_alice';

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_21m'), {
          id: 'group_21m',
          name: 'Over-limit Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-BIG002',
          createdBy: 'user_alice',
          memberUids: members21,
          memberCount: 21,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 21000;
      const splits = {};
      members21.forEach(uid => { splits[uid] = 1000; });

      await assertFails(setDoc(doc(aliceDb, 'groups/group_21m/expenses/exp_21p'), {
        id: 'exp_21p',
        groupId: 'group_21m',
        title: '21 People Dinner',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 21000 },
        participants: members21,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('12. allows multi-payer expense with 5 payers', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members5 = ['user_alice', 'user_p2', 'user_p3', 'user_p4', 'user_p5'];

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_5p'), {
          id: 'group_5p',
          name: '5 Payer Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-5PAY01',
          createdBy: 'user_alice',
          memberUids: members5,
          memberCount: 5,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 25000;
      const payers = {
        user_alice: 5000,
        user_p2: 5000,
        user_p3: 5000,
        user_p4: 5000,
        user_p5: 5000,
      };
      const splits = {};
      members5.forEach(uid => { splits[uid] = 5000; });

      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_5p/expenses/exp_5payers'), {
        id: 'exp_5payers',
        groupId: 'group_5p',
        title: 'Shared Trip Rental',
        category: 'transportation',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: payers,
        participants: members5,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('13. rejects expense with 6 payers (exceeds safe ceiling of 5)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members6 = ['user_alice', 'user_p2', 'user_p3', 'user_p4', 'user_p5', 'user_p6'];

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_6p'), {
          id: 'group_6p',
          name: '6 Payer Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-6PAY01',
          createdBy: 'user_alice',
          memberUids: members6,
          memberCount: 6,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 30000;
      const payers = {
        user_alice: 5000,
        user_p2: 5000,
        user_p3: 5000,
        user_p4: 5000,
        user_p5: 5000,
        user_p6: 5000,
      };
      const splits = {};
      members6.forEach(uid => { splits[uid] = 5000; });

      await assertFails(setDoc(doc(aliceDb, 'groups/group_6p/expenses/exp_6payers'), {
        id: 'exp_6payers',
        groupId: 'group_6p',
        title: '6 Payers Exceeded',
        category: 'transportation',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: payers,
        participants: members6,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('14. rejects 20-participant expense with 1 off-by-one kuruş arithmetic mismatch (0 bypass)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members20 = Array.from({ length: 20 }, (_, i) => `user_${i + 1}`);
      members20[0] = 'user_alice';

      const totalMinor = 20000;
      const badSplits = {};
      members20.forEach(uid => { badSplits[uid] = 1000; });
      badSplits['user_2'] = 1001; // Off by 1 kuruş -> 20001 != 20000

      await assertFails(setDoc(doc(aliceDb, 'groups/group_20m/expenses/exp_20p_bad_sum'), {
        id: 'exp_20p_bad_sum',
        groupId: 'group_20m',
        title: 'Bad Sum 20P',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 20000 },
        participants: members20,
        splits: badSplits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('15. rejects 20-participant expense with foreign non-member UID (0 bypass)', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members20 = Array.from({ length: 20 }, (_, i) => `user_${i + 1}`);
      members20[0] = 'user_alice';

      const totalMinor = 20000;
      const foreignSplits = {};
      members20.slice(0, 19).forEach(uid => { foreignSplits[uid] = 1000; });
      foreignSplits['intruder_external'] = 1000; // Foreign non-member UID

      const foreignParticipants = members20.slice(0, 19).concat(['intruder_external']);

      await assertFails(setDoc(doc(aliceDb, 'groups/group_20m/expenses/exp_20p_foreign'), {
        id: 'exp_20p_foreign',
        groupId: 'group_20m',
        title: 'Foreign Intruder in 20P',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 20000 },
        participants: foreignParticipants,
        splits: foreignSplits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('16. rejects join with memberCount mismatch (memberCount manipulation)', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();
      await assertFails(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['user_alice', 'user_bob', 'user_eve'],
        memberCount: 99, // Mismatched count
        updatedAt: now,
      }));
    });

    it('17. allows valid expense with 8 participants', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members8 = Array.from({ length: 8 }, (_, i) => `user_${i + 1}`);
      members8[0] = 'user_alice';

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_8m'), {
          id: 'group_8m',
          name: '8 Members Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-8MEM01',
          createdBy: 'user_alice',
          memberUids: members8,
          memberCount: 8,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 8000;
      const splits = {};
      members8.forEach(uid => { splits[uid] = 1000; });

      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_8m/expenses/exp_8p'), {
        id: 'exp_8p',
        groupId: 'group_8m',
        title: '8 Person Brunch',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 8000 },
        participants: members8,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('18. allows valid expense with 15 participants', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members15 = Array.from({ length: 15 }, (_, i) => `user_${i + 1}`);
      members15[0] = 'user_alice';

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_15m'), {
          id: 'group_15m',
          name: '15 Members Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-15MEM1',
          createdBy: 'user_alice',
          memberUids: members15,
          memberCount: 15,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 15000;
      const splits = {};
      members15.forEach(uid => { splits[uid] = 1000; });

      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_15m/expenses/exp_15p'), {
        id: 'exp_15p',
        groupId: 'group_15m',
        title: '15 Person Event',
        category: 'entertainment',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: { user_alice: 15000 },
        participants: members15,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('19. allows valid multi-payer expense with 3 payers', async () => {
      const aliceDb = testEnv.authenticatedContext('user_alice').firestore();
      const now = new Date();
      const members3 = ['user_alice', 'user_bob', 'user_p3'];

      await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
        await setDoc(doc(adminCtx.firestore(), 'groups/group_3p'), {
          id: 'group_3p',
          name: '3 Payer Group',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-3PAY01',
          createdBy: 'user_alice',
          memberUids: members3,
          memberCount: 3,
          active: true,
          createdAt: now,
          updatedAt: now,
        });
      });

      const totalMinor = 9000;
      const payers = {
        user_alice: 3000,
        user_bob: 3000,
        user_p3: 3000,
      };
      const splits = {
        user_alice: 3000,
        user_bob: 3000,
        user_p3: 3000,
      };

      await assertSucceeds(setDoc(doc(aliceDb, 'groups/group_3p/expenses/exp_3payers'), {
        id: 'exp_3payers',
        groupId: 'group_3p',
        title: '3 Way Bill',
        category: 'food',
        currency: 'TRY',
        totalMinor: totalMinor,
        date: now,
        splitMethod: 'equal',
        payers: payers,
        participants: members3,
        splits: splits,
        createdBy: 'user_alice',
        createdAt: now,
        updatedAt: now,
      }));
    });

    it('20. rejects stale snapshot overwrite trying to regress memberUids', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();
      // Attempting to overwrite memberUids back to 1 member while pretending to join
      await assertFails(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['user_eve'], // Discards alice and bob
        memberCount: 1,
        updatedAt: now,
      }));
    });

    it('21. sequential joins (Eve then Frank) maintain atomic projection integrity', async () => {
      const eveDb = testEnv.authenticatedContext('user_eve').firestore();
      const now = new Date();

      // Step 1: Eve joins
      await assertSucceeds(updateDoc(doc(eveDb, 'groups/group_a'), {
        memberUids: ['user_alice', 'user_bob', 'user_eve'],
        memberCount: 3,
        updatedAt: now,
      }));

      // Step 2: Frank joins group_a (with Eve already in)
      const frankDb = testEnv.authenticatedContext('user_frank').firestore();
      await assertSucceeds(updateDoc(doc(frankDb, 'groups/group_a'), {
        memberUids: ['user_alice', 'user_bob', 'user_eve', 'user_frank'],
        memberCount: 4,
        updatedAt: now,
      }));
    });
  });
});
