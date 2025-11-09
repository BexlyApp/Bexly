// Script to delete all categories from Firestore
// Run with: node delete_categories.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'bexly'
});

const db = admin.firestore();
db.settings({ databaseId: 'bexly' });

async function deleteAllCategories(userId) {
  console.log(`Deleting all categories for user: ${userId}`);

  const categoriesRef = db.collection('users').doc(userId).collection('data').doc('categories').collection('items');
  const snapshot = await categoriesRef.get();

  console.log(`Total categories found: ${snapshot.size}`);

  let deleted = 0;
  for (const doc of snapshot.docs) {
    console.log(`  Deleting category: ${doc.id} (${doc.data().title})`);
    await doc.ref.delete();
    deleted++;
  }

  console.log(`\n✅ Deleted ${deleted} categories`);
}

// Replace with your user ID
const userId = '8g91QXUpaYaU3VdNfJ5Ph0xGVy02';

deleteAllCategories(userId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
