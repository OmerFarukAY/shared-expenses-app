import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { doc, getDoc, getDocs, setDoc, collection } from 'firebase/firestore';

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
});
