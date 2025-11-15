const admin = require('firebase-admin');

// Initialize with application default credentials
// Make sure you've run: firebase login or set GOOGLE_APPLICATION_CREDENTIALS
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
    deleteQueryBatch(db, query, resolve, reject);
  });
}

async function deleteQueryBatch(db, query, resolve, reject) {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      resolve();
      return;
    }

    console.log(`Deleting ${snapshot.size} documents...`);

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // Recurse on the next batch
    process.nextTick(() => {
      deleteQueryBatch(db, query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

// Delete wallets collection
console.log('Starting to delete wallets collection...');
deleteCollection('wallets')
  .then(() => {
    console.log('✅ Successfully deleted all wallets from Firestore');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error deleting wallets:', error);
    process.exit(1);
  });
