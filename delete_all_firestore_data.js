/**
 * Script to delete ALL user data from Firestore
 *
 * This will delete:
 * - All wallets
 * - All categories
 * - All transactions
 * - All recurring payments
 * - All budgets
 *
 * Use this to start completely fresh.
 */

const admin = require('firebase-admin');

// Initialize with application default credentials
admin.initializeApp({
  projectId: 'bexly-app'
});

const db = admin.firestore();
// Use the 'bexly' database
db.settings({ databaseId: 'bexly' });

async function deleteCollection(collectionPath, batchSize = 100) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.size} documents`);

    // Recurse on the next batch
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

async function deleteAllUserData(userId) {
  try {
    console.log(`\n🔍 Deleting all data for user: ${userId}`);

    // Delete all subcollections
    const collections = ['wallets', 'categories', 'transactions', 'recurring', 'budgets'];

    for (const collection of collections) {
      const collectionPath = `users/${userId}/${collection}`;
      console.log(`\n🗑️  Deleting ${collection}...`);
      await deleteCollection(collectionPath);
      console.log(`✅ Deleted all ${collection}`);
    }

    console.log(`\n✅ Successfully deleted all data for user ${userId}`);
  } catch (error) {
    console.error('❌ Error deleting user data:', error);
    throw error;
  }
}

async function main() {
  try {
    // Replace with your actual user ID
    // You can find it by checking Firebase Auth or running list_wallets.js
    const userId = 'REPLACE_WITH_YOUR_USER_ID';

    if (userId === 'REPLACE_WITH_YOUR_USER_ID') {
      console.error('❌ Please replace REPLACE_WITH_YOUR_USER_ID with your actual Firebase user ID');
      console.log('\nYou can find your user ID by:');
      console.log('1. Running: node list_wallets.js');
      console.log('2. Or check Firebase Console > Authentication');
      process.exit(1);
    }

    console.log('⚠️  WARNING: This will DELETE ALL your data from Firestore!');
    console.log('⚠️  This action CANNOT be undone!');
    console.log('\nStarting in 3 seconds... Press Ctrl+C to cancel');

    await new Promise(resolve => setTimeout(resolve, 3000));

    await deleteAllUserData(userId);

    console.log('\n✅ All done! Your Firestore data has been deleted.');
    console.log('You can now start fresh with the app.');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();
