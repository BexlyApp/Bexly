// Script to clean up duplicate wallets from Firestore
// Run with: node cleanup_duplicate_wallets.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // You need to download this from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'bexly'
});

const db = admin.firestore();
db.settings({ databaseId: 'bexly' });

async function cleanupDuplicateWallets(userId) {
  console.log(`Cleaning up duplicate wallets for user: ${userId}`);

  const walletsRef = db.collection('users').doc(userId).collection('wallets');
  const snapshot = await walletsRef.get();

  console.log(`Total wallets found: ${snapshot.size}`);

  // Group wallets by name + currency
  const walletGroups = {};

  snapshot.forEach(doc => {
    const data = doc.data();
    const key = `${data.name}_${data.currency}`;

    if (!walletGroups[key]) {
      walletGroups[key] = [];
    }

    walletGroups[key].push({
      id: doc.id,
      data: data,
      createdAt: data.createdAt?.toDate() || new Date(0)
    });
  });

  // Find and delete duplicates (keep the oldest one)
  for (const [key, wallets] of Object.entries(walletGroups)) {
    if (wallets.length > 1) {
      console.log(`\nFound ${wallets.length} duplicates for: ${key}`);

      // Sort by createdAt (oldest first)
      wallets.sort((a, b) => a.createdAt - b.createdAt);

      // Keep the first one, delete the rest
      const toKeep = wallets[0];
      const toDelete = wallets.slice(1);

      console.log(`  Keeping: ${toKeep.id} (created: ${toKeep.createdAt})`);

      for (const wallet of toDelete) {
        console.log(`  Deleting: ${wallet.id} (created: ${wallet.createdAt})`);
        await walletsRef.doc(wallet.id).delete();
      }

      console.log(`  ✓ Deleted ${toDelete.length} duplicate(s)`);
    }
  }

  console.log('\n✅ Cleanup completed!');
}

// Replace with your user ID from logs
const userId = '8g91QXUpaYaU3VdNfJ5Ph0xGVy02';

cleanupDuplicateWallets(userId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
