/**
 * Denk — Option B: memberUids Backfill / Migration Script
 *
 * Scans all documents in the `groups` collection.
 * For each group, inspects `groups/{groupId}/members` subcollection,
 * collects all member UIDs, and updates `groups/{groupId}`:
 *   - memberUids: [uid1, uid2, ...] (unique, sorted)
 *   - memberCount: memberUids.length
 *
 * Features:
 * - Idempotent: Does not rewrite if memberUids is already synchronized.
 * - Non-destructive: Does NOT touch member documents, roles, expenses, or invites.
 * - Dry-run mode by default: Pass --execute to commit writes to Firestore.
 */

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';

const isExecute = process.argv.includes('--execute');

async function runMigration() {
  console.log('====================================================');
  console.log('Denk: Option B memberUids Migration / Backfill');
  console.log(`Mode: ${isExecute ? 'LIVE EXECUTION' : 'DRY RUN (pass --execute to commit)'}`);
  console.log('====================================================\n');

  // Initialize Firebase Admin with ADC or project ID
  const app = getApps().length === 0
    ? initializeApp({ projectId: 'denk-262c0' })
    : getApps()[0];

  const db = getFirestore(app);

  const groupsSnap = await db.collection('groups').get();
  console.log(`Found ${groupsSnap.size} group(s) in collection 'groups'.\n`);

  let updatedCount = 0;
  let skippedCount = 0;

  for (const groupDoc of groupsSnap.docs) {
    const groupId = groupDoc.id;
    const groupData = groupDoc.data();
    const existingMemberUids = groupData.memberUids || [];

    // Query members subcollection
    const membersSnap = await db.collection('groups').doc(groupId).collection('members').get();
    const actualMemberUids = membersSnap.docs.map(d => d.id).sort();

    // If no members subcollection documents exist, fall back to createdBy
    if (actualMemberUids.length === 0 && groupData.createdBy) {
      actualMemberUids.push(groupData.createdBy);
    }

    const isAlreadySynced =
      Array.isArray(existingMemberUids) &&
      existingMemberUids.length === actualMemberUids.length &&
      existingMemberUids.slice().sort().every((uid, idx) => uid === actualMemberUids[idx]);

    if (isAlreadySynced) {
      console.log(`[SKIP] Group '${groupId}' (${groupData.name || 'unnamed'}): already synchronized with ${actualMemberUids.length} member(s).`);
      skippedCount++;
      continue;
    }

    console.log(`[SYNC NEEDED] Group '${groupId}' (${groupData.name || 'unnamed'}):`);
    console.log(`  Current memberUids: ${JSON.stringify(existingMemberUids)}`);
    console.log(`  Target memberUids:  ${JSON.stringify(actualMemberUids)} (${actualMemberUids.length} members)`);

    if (isExecute) {
      await db.collection('groups').doc(groupId).update({
        memberUids: actualMemberUids,
        memberCount: actualMemberUids.length,
        updatedAt: FieldValue.serverTimestamp(),
      });
      console.log(`  ✔ Successfully updated group '${groupId}'.`);
    } else {
      console.log(`  [DRY-RUN] Would update group '${groupId}'.`);
    }
    updatedCount++;
  }

  console.log('\n====================================================');
  console.log(`Migration Complete Summary:`);
  console.log(`- Total Groups Inspected: ${groupsSnap.size}`);
  console.log(`- Updated: ${updatedCount}`);
  console.log(`- Already in sync (Skipped): ${skippedCount}`);
  console.log('====================================================');
}

runMigration().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
