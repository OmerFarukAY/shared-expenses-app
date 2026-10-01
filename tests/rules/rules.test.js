const { readFileSync } = require('fs');
const { resolve } = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'denk-rules-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('Denk Firestore Rules', () => {
  
  const setupGroup = async (groupId, creatorUid) => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await adminDb.collection('users').doc(creatorUid).set({
        uid: creatorUid,
        displayName: 'Creator',
        preferredCurrency: 'TRY',
        languageCode: 'tr',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      await adminDb.collection('groups').doc(groupId).set({
        id: groupId,
        name: 'Test Group',
        defaultCurrency: 'TRY',
        inviteCode: 'INVITE',
        createdBy: creatorUid,
        memberUids: [creatorUid],
        memberCount: 1,
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      await adminDb.collection('groups').doc(groupId).collection('members').doc(creatorUid).set({
        uid: creatorUid,
        displayName: 'Creator',
        role: 'owner',
        joinedAt: new Date(),
      });
    });
  };

  const addMembers = async (groupId, memberUids) => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      const docSnap = await adminDb.collection('groups').doc(groupId).get();
      const currentUids = docSnap.data().memberUids || [];
      const newUids = [...new Set([...currentUids, ...memberUids])];
      await adminDb.collection('groups').doc(groupId).update({
        memberUids: newUids,
        memberCount: newUids.length,
      });
      for (const uid of memberUids) {
        await adminDb.collection('groups').doc(groupId).collection('members').doc(uid).set({
          uid: uid,
          displayName: `Member ${uid}`,
          role: 'member',
          joinedAt: new Date(),
        });
      }
    });
  };

  it('(a) Üye kendi rolünü owner yapamaz', async () => {
    await setupGroup('groupA', 'user1');
    await addMembers('groupA', ['user2']);

    const db = testEnv.authenticatedContext('user2').firestore();
    const doc = db.collection('groups').doc('groupA').collection('members').doc('user2');
    
    // First read the doc to get the exact data (timestamp matching)
    const snapshot = await doc.get();
    const currentData = snapshot.data();

    // Deny: Changing role to owner
    await assertFails(
      doc.update({
        ...currentData,
        role: 'owner',
      })
    );

    // Allow: Changing display name (valid update)
    await assertSucceeds(
      doc.update({
        ...currentData,
        displayName: 'New Name',
      })
    );
  });

  it('(b) Üye olmayan grup/harcama okuyamaz ve yazamaz', async () => {
    await setupGroup('groupB', 'user1');
    
    // Setup a real expense first
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await adminDb.collection('groups').doc('groupB').collection('expenses').doc('realExp').set({
        id: 'realExp',
        groupId: 'groupB',
        title: 'Dinner',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'equal',
        payers: { user1: 1000 },
        participants: ['user1'],
        splits: { user1: 1000 },
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const db = testEnv.authenticatedContext('hacker99').firestore();

    // Deny: get group
    await assertFails(db.collection('groups').doc('groupB').get());

    // Deny: create expense
    await assertFails(
      db.collection('groups').doc('groupB').collection('expenses').doc('exp1').set({
        id: 'exp1',
        groupId: 'groupB',
        title: 'Hacked',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'equal',
        payers: { hacker99: 1000 },
        participants: ['hacker99'],
        splits: { hacker99: 1000 },
        createdBy: 'hacker99',
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
    
    // Deny: get expense
    await assertFails(db.collection('groups').doc('groupB').collection('expenses').doc('realExp').get());
    
    // Deny: update expense
    await assertFails(db.collection('groups').doc('groupB').collection('expenses').doc('realExp').update({ title: 'Hacked!' }));

    // Deny: delete expense
    await assertFails(db.collection('groups').doc('groupB').collection('expenses').doc('realExp').delete());
  });

  it('(c) groups ve invites üzerinde list sorgusu reddedilir', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(db.collection('groups').get());
    await assertFails(db.collection('invites').get());
  });

  it('(d) settlement update reddedilir, sadece create ve delete çalışır', async () => {
    await setupGroup('groupC', 'user1');
    await addMembers('groupC', ['user2']);

    const db = testEnv.authenticatedContext('user1').firestore();
    const settlementDoc = db.collection('groups').doc('groupC').collection('settlements').doc('set1');

    await assertSucceeds(
      settlementDoc.set({
        id: 'set1',
        groupId: 'groupC',
        fromUid: 'user2',
        toUid: 'user1',
        amountMinor: 5000,
        currency: 'TRY',
        settledAt: new Date(),
        createdBy: 'user1',
      })
    );

    // Deny: Update
    await assertFails(
      settlementDoc.update({
        amountMinor: 10000,
      })
    );

    // Allow: Delete
    await assertSucceeds(settlementDoc.delete());
  });

  it('(e) geçersiz split/payer toplamı olan harcama reddedilir', async () => {
    await setupGroup('groupE', 'user1');
    await addMembers('groupE', ['user2']);

    const db = testEnv.authenticatedContext('user1').firestore();
    
    const baseData = {
        groupId: 'groupE',
        title: 'Dinner',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 3000,
        date: new Date(),
        splitMethod: 'equal',
        payers: { user1: 3000 },
        participants: ['user1', 'user2'],
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
    };

    const expenseDoc = db.collection('groups').doc('groupE').collection('expenses').doc('exp1');
    // Allow: valid split sum (1500 + 1500 = 3000)
    await assertSucceeds(expenseDoc.set({ ...baseData, id: 'exp1', splits: { user1: 1500, user2: 1500 } }));

    // Deny: invalid split sum (1500 + 1000 != 3000)
    const invalidDoc = db.collection('groups').doc('groupE').collection('expenses').doc('exp2');
    await assertFails(invalidDoc.set({ ...baseData, id: 'exp2', splits: { user1: 1500, user2: 1000 } }));
  });

  it('(f) kimliği doğrulanmamış kullanıcı hiçbir şeye erişemez', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection('users').doc('user1').get());
    await assertFails(db.collection('groups').doc('groupA').get());
    await assertFails(db.collection('invites').doc('INVITE').get());
  });

  describe('1000-expression limit check for different participant sizes', () => {
    const sizes = [2, 5, 10, 15, 20];

    for (const size of sizes) {
      it(`Allows expense creation with ${size} participants`, async () => {
        const uids = Array.from({length: size}, (_, i) => `u${i}`);
        await setupGroup(`grp_${size}`, 'user1'); 
        await addMembers(`grp_${size}`, uids); 

        const db = testEnv.authenticatedContext('user1').firestore();
        const docRef = db.collection('groups').doc(`grp_${size}`).collection('expenses').doc('exp');

        // user1 + uids, we just use uids subset of exact size to make splits equal to total
        const testParticipants = uids.slice(0, size);
        
        const splits = {};
        for (const u of testParticipants) splits[u] = 100;

        await assertSucceeds(docRef.set({
          id: 'exp',
          groupId: `grp_${size}`,
          title: `Size ${size}`,
          category: 'Food',
          currency: 'TRY',
          totalMinor: 100 * size,
          date: new Date(),
          splitMethod: 'equal',
          payers: { 'u0': 100 * size }, // 1 payer
          participants: testParticipants,
          splits: splits,
          createdBy: 'user1',
          createdAt: new Date(),
          updatedAt: new Date(),
        }));
      });
    }
  });

});
