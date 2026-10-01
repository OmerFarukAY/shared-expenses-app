const { serverTimestamp, deleteField } = require('firebase/firestore');
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

  describe('Extended Expense Tests', () => {
    it('1) Geçerli expense UPDATE ve DELETE (grup üyesi) 2, 10, 20 katılımcıyla', async () => {
      const sizes = [2, 10, 20];
      for (const size of sizes) {
        const uids = Array.from({length: size}, (_, i) => `member${i}`);
        await setupGroup(`grp_ext_${size}`, 'user1');
        await addMembers(`grp_ext_${size}`, uids);

        const testParticipants = uids.slice(0, size);
        const splits = {};
        for (const u of testParticipants) splits[u] = 100;

        // Setup real expense
        await testEnv.withSecurityRulesDisabled(async (context) => {
          const adminDb = context.firestore();
          await adminDb.collection('groups').doc(`grp_ext_${size}`).collection('expenses').doc('exp1').set({
            id: 'exp1',
            groupId: `grp_ext_${size}`,
            title: 'Lunch',
            category: 'Food',
            currency: 'TRY',
            totalMinor: 100 * size,
            date: new Date(),
            splitMethod: 'equal',
            payers: { 'member0': 100 * size },
            participants: testParticipants,
            splits: splits,
            createdBy: 'user1',
            createdAt: new Date(),
            updatedAt: new Date(),
          });
        });

        // Member 0 updates and deletes
        const db = testEnv.authenticatedContext('member0').firestore();
        const docRef = db.collection('groups').doc(`grp_ext_${size}`).collection('expenses').doc('exp1');
        
        const snap = await docRef.get();
        const currentData = snap.data();

        // Update
        await assertSucceeds(
          docRef.update({
            ...currentData,
            title: 'Dinner',
            updatedAt: new Date()
          })
        );

        // Hacker cannot update/delete
        const hackerDb = testEnv.authenticatedContext('hacker99').firestore();
        const hackerDocRef = hackerDb.collection('groups').doc(`grp_ext_${size}`).collection('expenses').doc('exp1');
        
        await assertFails(hackerDocRef.update({ title: 'Hacked' }));
        await assertFails(hackerDocRef.delete());

        // Delete (by member0)
        await assertSucceeds(docRef.delete());
      }
    });

    it('2) 21 katılımcılı splits map reddedilmeli', async () => {
      const size = 21;
      const uids = Array.from({length: size}, (_, i) => `m${i}`);
      await setupGroup('grp_21', 'user1');
      await addMembers('grp_21', uids);

      const db = testEnv.authenticatedContext('user1').firestore();
      const docRef = db.collection('groups').doc('grp_21').collection('expenses').doc('exp1');

      const splits = {};
      for (const u of uids) splits[u] = 100;

      await assertFails(docRef.set({
        id: 'exp1',
        groupId: 'grp_21',
        title: 'Large Group',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 100 * size,
        date: new Date(),
        splitMethod: 'equal',
        payers: { 'user1': 100 * size },
        participants: uids,
        splits: splits,
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
    });

    it('3) Negatif split değeri reddedilmeli', async () => {
      await setupGroup('grp_neg', 'user1');
      await addMembers('grp_neg', ['user2']);

      const db = testEnv.authenticatedContext('user1').firestore();
      const docRef = db.collection('groups').doc('grp_neg').collection('expenses').doc('exp1');

      await assertFails(docRef.set({
        id: 'exp1',
        groupId: 'grp_neg',
        title: 'Negative',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'custom',
        payers: { 'user1': 1000 },
        participants: ['user1', 'user2'],
        splits: { 'user1': 1500, 'user2': -500 },
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
    });

    it('4) splits veya payers içinde participants listesinde olmayan uid reddedilmeli', async () => {
      await setupGroup('grp_uid', 'user1');
      await addMembers('grp_uid', ['user2', 'user3']);

      const db = testEnv.authenticatedContext('user1').firestore();
      
      const baseData = {
        groupId: 'grp_uid',
        title: 'Wrong UID',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'custom',
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      
      // Splits uid not in participants
      await assertFails(db.collection('groups').doc('grp_uid').collection('expenses').doc('exp1').set({
        ...baseData,
        id: 'exp1',
        payers: { 'user1': 1000 },
        participants: ['user1', 'user2'],
        splits: { 'user1': 500, 'user2': 250, 'user3': 250 },
      }));

      // Payers uid not in groupMembers
      await assertFails(db.collection('groups').doc('grp_uid').collection('expenses').doc('exp2').set({
        ...baseData,
        id: 'exp2',
        payers: { 'stranger': 1000 },
        participants: ['user1', 'user2'],
        splits: { 'user1': 500, 'user2': 500 },
      }));
    });

    it('5) payers toplamı totalMinor`a eşit değilse reddedilmeli', async () => {
      await setupGroup('grp_payer', 'user1');
      await addMembers('grp_payer', ['user2']);

      const db = testEnv.authenticatedContext('user1').firestore();
      const docRef = db.collection('groups').doc('grp_payer').collection('expenses').doc('exp1');

      await assertFails(docRef.set({
        id: 'exp1',
        groupId: 'grp_payer',
        title: 'Wrong Payers',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'equal',
        payers: { 'user1': 600, 'user2': 500 },
        participants: ['user1', 'user2'],
        splits: { 'user1': 500, 'user2': 500 },
        createdBy: 'user1',
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
    });

    it('6) Başkası adına createdBy ile harcama oluşturma reddedilmeli', async () => {
      await setupGroup('grp_spoof', 'user1');
      await addMembers('grp_spoof', ['user2']);

      const db = testEnv.authenticatedContext('user1').firestore();
      const docRef = db.collection('groups').doc('grp_spoof').collection('expenses').doc('exp1');

      await assertFails(docRef.set({
        id: 'exp1',
        groupId: 'grp_spoof',
        title: 'Spoofed',
        category: 'Food',
        currency: 'TRY',
        totalMinor: 1000,
        date: new Date(),
        splitMethod: 'equal',
        payers: { 'user1': 1000 },
        participants: ['user1', 'user2'],
        splits: { 'user1': 500, 'user2': 500 },
        createdBy: 'user2', // spoofing
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
    });

    it('7) Negatif değerler (başta, ortada, sonda) reddedilmeli (splits ve payers)', async () => {
      // Test for 3, 5, 10, 20 participants
      const sizes = [3, 5, 10, 20];
      for (const size of sizes) {
        const uids = Array.from({length: size}, (_, i) => `member${i}`); // sorted: member0, member1, member10, member11, ... member2. We need to be careful with sorting if we strictly want 'start', 'middle', 'end' but Firestore sorts by key.
        // Let's use clean alphabetical keys so we can control position.
        const letters = 'abcdefghijklmnopqrstuvwxyz';
        const sortedUids = Array.from({length: size}, (_, i) => `${letters[i]}_user`);
        
        await setupGroup(`grp_neg_${size}`, 'user1');
        await addMembers(`grp_neg_${size}`, sortedUids);
        const db = testEnv.authenticatedContext('user1').firestore();
        
        const baseData = {
          groupId: `grp_neg_${size}`,
          title: 'Negative Test',
          category: 'Food',
          currency: 'TRY',
          totalMinor: 1000,
          date: new Date(),
          splitMethod: 'custom',
          payers: { [sortedUids[0]]: 1000 },
          participants: sortedUids,
          createdBy: 'user1',
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        // Positions: start (0), middle (Math.floor(size/2)), end (size-1)
        const positions = [0, Math.floor(size / 2), size - 1];
        
        for (const pos of positions) {
          // SPLITS TEST
          const splits = {};
          for (let i = 0; i < size; i++) {
            splits[sortedUids[i]] = 100;
          }
          // Make pos negative, compensate elsewhere to keep sum = 1000
          splits[sortedUids[pos]] = -500;
          const otherPos = pos === 0 ? 1 : 0;
          splits[sortedUids[otherPos]] += (1000 - (100 * size - 100 - 500)); // ensure sum is 1000
          
          await assertFails(db.collection('groups').doc(`grp_neg_${size}`).collection('expenses').doc(`exp_s_${pos}`).set({
            ...baseData, id: `exp_s_${pos}`, splits
          }));

          // PAYERS TEST (only for sizes <= 5, as payer limit is 5)
          if (size <= 5) {
            const payers = {};
            for (let i = 0; i < size; i++) {
              payers[sortedUids[i]] = 100;
            }
            payers[sortedUids[pos]] = -500;
            payers[sortedUids[otherPos]] += (1000 - (100 * size - 100 - 500)); // sum = 1000
            
            // Valid splits for payer test
            const validSplits = {};
            for (const uid of sortedUids) validSplits[uid] = 100;
            validSplits[sortedUids[otherPos]] += (1000 - (100 * size));

            await assertFails(db.collection('groups').doc(`grp_neg_${size}`).collection('expenses').doc(`exp_p_${pos}`).set({
              ...baseData, id: `exp_p_${pos}`, payers, splits: validSplits
            }));
          }
        }
      }
    });

    it('8) Sıfır (0) değeri mevcut semantiğe göre reddedilmeli', async () => {
      await setupGroup('grp_zero', 'user1');
      await addMembers('grp_zero', ['a_user', 'b_user', 'c_user']);
      const db = testEnv.authenticatedContext('user1').firestore();
      const baseData = {
        id: 'exp1', groupId: 'grp_zero', title: 'Zero Test', category: 'Food', currency: 'TRY', totalMinor: 1000,
        date: new Date(), splitMethod: 'custom', createdBy: 'user1', createdAt: new Date(), updatedAt: new Date(),
        participants: ['a_user', 'b_user', 'c_user'], payers: { 'a_user': 1000 }
      };

      // Split has 0
      await assertFails(db.collection('groups').doc('grp_zero').collection('expenses').doc('exp_s_0').set({
        ...baseData, splits: { 'a_user': 1000, 'b_user': 0, 'c_user': 0 }
      }));
      
      // Payer has 0
      await assertFails(db.collection('groups').doc('grp_zero').collection('expenses').doc('exp_p_0').set({
        ...baseData, splits: { 'a_user': 500, 'b_user': 250, 'c_user': 250 }, payers: { 'a_user': 1000, 'b_user': 0 }
      }));
    });

    it('9) Float veya string değerler reddedilmeli', async () => {
      await setupGroup('grp_type', 'user1');
      await addMembers('grp_type', ['a_user', 'b_user']);
      const db = testEnv.authenticatedContext('user1').firestore();
      const baseData = {
        id: 'exp1', groupId: 'grp_type', title: 'Type Test', category: 'Food', currency: 'TRY', totalMinor: 1000,
        date: new Date(), splitMethod: 'custom', createdBy: 'user1', createdAt: new Date(), updatedAt: new Date(),
        participants: ['a_user', 'b_user'], payers: { 'a_user': 1000 }
      };

      // Float split
      await assertFails(db.collection('groups').doc('grp_type').collection('expenses').doc('exp_float').set({
        ...baseData, splits: { 'a_user': 500.5, 'b_user': 499.5 }
      }));

      // String split
      await assertFails(db.collection('groups').doc('grp_type').collection('expenses').doc('exp_str').set({
        ...baseData, splits: { 'a_user': '500', 'b_user': '500' }
      }));
    });
  });

  describe('Aşama 3: Group Members Departure, Kicking, and Deletion', () => {
    
    it('1) Üye ayrılma (self-leave): lastRemovedUid ve leftAt olmadan kabul EDİLMEZ', async () => {
      await setupGroup('grp_leave1', 'user1');
      await addMembers('grp_leave1', ['user2']);

      const db = testEnv.authenticatedContext('user2').firestore();
      const groupRef = db.collection('groups').doc('grp_leave1');
      const memberRef = groupRef.collection('members').doc('user2');

      let groupSnap; await testEnv.withSecurityRulesDisabled(async context => { groupSnap = await context.firestore().collection('groups').doc('grp_leave1').get(); });
      let memberSnap; await testEnv.withSecurityRulesDisabled(async context => { memberSnap = await context.firestore().collection('groups').doc('grp_leave1').collection('members').doc('user2').get(); });

      // Attempt leaving WITHOUT lastRemovedUid
      const batch1 = db.batch();
      batch1.update(groupRef, {
        memberUids: ['user1'],
        memberCount: 1,
        updatedAt: groupSnap.data().updatedAt,
      });
      batch1.update(memberRef, {
        leftAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await assertFails(batch1.commit());

      // Attempt leaving WITHOUT leftAt in members doc
      const batch2 = db.batch();
      batch2.update(groupRef, {
        memberUids: ['user1'],
        memberCount: 1,
        lastRemovedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      await assertFails(batch2.commit());

      // VALID LEAVE
      const batch3 = db.batch();
      batch3.update(groupRef, {
        memberUids: ['user1'],
        memberCount: 1,
        lastRemovedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch3.update(memberRef, {
        leftAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await assertSucceeds(batch3.commit());
    });

    it('2) Kurucu üye atma (kick): lastRemovedUid ve leftAt eşleşmeli', async () => {
      await setupGroup('grp_kick', 'user1');
      await addMembers('grp_kick', ['user2', 'user3']);

      const db = testEnv.authenticatedContext('user1').firestore();
      const groupRef = db.collection('groups').doc('grp_kick');
      const memberRef = groupRef.collection('members').doc('user2');

      let groupSnap; await testEnv.withSecurityRulesDisabled(async context => { groupSnap = await context.firestore().collection('groups').doc('grp_kick').get(); });
      let memberSnap; await testEnv.withSecurityRulesDisabled(async context => { memberSnap = await context.firestore().collection('groups').doc('grp_kick').collection('members').doc('user2').get(); });

      // Hacker tries to kick (fails)
      const hackerDb = testEnv.authenticatedContext('user3').firestore();
      const hackerBatch = hackerDb.batch();
      hackerBatch.update(hackerDb.collection('groups').doc('grp_kick'), {
        memberUids: ['user1', 'user3'],
        memberCount: 2,
        lastRemovedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      hackerBatch.update(hackerDb.collection('groups').doc('grp_kick').collection('members').doc('user2'), {
        leftAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await assertFails(hackerBatch.commit());

      // Owner kicks successfully
      const batch = db.batch();
      batch.update(groupRef, {
        memberUids: ['user1', 'user3'],
        memberCount: 2,
        lastRemovedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch.update(memberRef, {
        leftAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await assertSucceeds(batch.commit());
    });

    it('3) Kurucu kendi kendini atamaz / ayrılamaz', async () => {
      await setupGroup('grp_owner_leave', 'user1');
      
      const db = testEnv.authenticatedContext('user1').firestore();
      const groupRef = db.collection('groups').doc('grp_owner_leave');
      const memberRef = groupRef.collection('members').doc('user1');

      let groupSnap; await testEnv.withSecurityRulesDisabled(async context => { groupSnap = await context.firestore().collection('groups').doc('grp_owner_leave').get(); });
      let memberSnap; await testEnv.withSecurityRulesDisabled(async context => { memberSnap = await context.firestore().collection('groups').doc('grp_owner_leave').collection('members').doc('user1').get(); });

      const batch = db.batch();
      batch.update(groupRef, {
        memberUids: [],
        memberCount: 0,
        lastRemovedUid: 'user1',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch.update(memberRef, {
        leftAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await assertFails(batch.commit());
    });

    it('4) Rejoin (Tekrar katılma): kurucu keyfi uid ekleyemez', async () => {
      await setupGroup('grp_rejoin', 'user1');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('groups').doc('grp_rejoin').collection('members').doc('user2').set({
          uid: 'user2',
          displayName: 'Member user2',
          role: 'member',
          joinedAt: new Date(),
          leftAt: new Date(),
          updatedAt: new Date(),
        });
      });

      const db = testEnv.authenticatedContext('user1').firestore();
      const groupRef = db.collection('groups').doc('grp_rejoin');
      const memberRef = groupRef.collection('members').doc('user2');

      let groupSnap; await testEnv.withSecurityRulesDisabled(async context => { groupSnap = await context.firestore().collection('groups').doc('grp_rejoin').get(); });

      // Attempt to rejoin WITHOUT a joinRequest
      const batch1 = db.batch();
      batch1.update(groupRef, {
        memberUids: ['user1', 'user2'],
        memberCount: 2,
        lastAddedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch1.update(memberRef, {
        leftAt: deleteField(),
        updatedAt: serverTimestamp(),
      });
      await assertFails(batch1.commit());

      // Create a join request
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('groups').doc('grp_rejoin').collection('joinRequests').doc('user2').set({
          uid: 'user2'
        });
      });

      // Attempt to rejoin with other fields changed
      const batch2 = db.batch();
      batch2.update(groupRef, {
        memberUids: ['user1', 'user2'],
        memberCount: 2,
        lastAddedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch2.update(memberRef, {
        leftAt: deleteField(),
        role: 'owner', // Changed role
        updatedAt: serverTimestamp(),
      });
      await assertFails(batch2.commit());

      // Successful rejoin
      const batch3 = db.batch();
      batch3.update(groupRef, {
        memberUids: ['user1', 'user2'],
        memberCount: 2,
        lastAddedUid: 'user2',
        updatedAt: groupSnap.data().updatedAt,
      });
      batch3.update(memberRef, {
        leftAt: deleteField(),
        updatedAt: serverTimestamp(),
      });
      await assertSucceeds(batch3.commit());
    });

    it('5) Toplu grup silme limit', async () => {
      const sizes = [50, 200];
      for (const size of sizes) {
        await setupGroup(`grp_del_${size}`, 'user1');
        const uids = Array.from({length: size}, (_, i) => `user_${i}`);
        await addMembers(`grp_del_${size}`, uids);

        const db = testEnv.authenticatedContext('user1').firestore();
        const batch = db.batch();
        for (const uid of uids) {
          batch.delete(db.collection('groups').doc(`grp_del_${size}`).collection('members').doc(uid));
        }
        await assertSucceeds(batch.commit());
        
        await assertSucceeds(db.collection('groups').doc(`grp_del_${size}`).delete());
      }
    });

  });
});
