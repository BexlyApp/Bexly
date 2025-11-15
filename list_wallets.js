const admin = require('firebase-admin');

// Initialize with application default credentials
admin.initializeApp({
  projectId: 'bexly-app'
});

const db = admin.firestore();
// Use the 'bexly' database
db.settings({ databaseId: 'bexly' });

async function listWallets() {
  try {
    const userId = '8g91QXUpaYaU3VdNfJ5Ph0xGVy02';
    const snapshot = await db
      .collection('users')
      .doc(userId)
      .collection('data')
      .doc('wallets')
      .collection('items')
      .get();

    console.log(`Total wallets in Firestore for user ${userId}: ${snapshot.size}`);

    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`\nWallet cloudId: ${doc.id}`);
      console.log(`  Name: ${data.name}`);
      console.log(`  Balance: ${data.balance} ${data.currency}`);
      console.log(`  Created: ${data.createdAt?.toDate?.() || data.createdAt}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Error listing wallets:', error);
    process.exit(1);
  }
}

listWallets();
