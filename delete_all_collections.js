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

    console.log(`Deleting ${snapshot.size} documents from ${query._queryOptions.parentPath}...`);

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

// Delete all collections
const collections = ['wallets', 'categories', 'transactions', 'budgets', 'goals', 'checklistItems'];

async function deleteAllCollections() {
  console.log('🗑️  Starting to delete all collections from Firestore...\n');

  for (const collection of collections) {
    console.log(`📦 Deleting collection: ${collection}`);
    try {
      await deleteCollection(collection);
      console.log(`✅ Successfully deleted ${collection}\n`);
    } catch (error) {
      console.error(`❌ Error deleting ${collection}:`, error.message, '\n');
    }
  }

  console.log('🎉 All collections deleted!');
  process.exit(0);
}

deleteAllCollections().catch((error) => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
