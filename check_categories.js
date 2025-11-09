// Script to check categories in Firestore
// Run with: node check_categories.js

const admin = require('firebase-admin');

// Use Application Default Credentials (gcloud auth application-default login)
admin.initializeApp({
  projectId: 'bexly-9f0c3',
});

const db = admin.firestore();
db.settings({ databaseId: 'bexly' });

async function checkCategories(userId) {
  console.log(`Checking categories for user: ${userId}`);

  const categoriesRef = db.collection('users').doc(userId).collection('data').doc('categories').collection('items');
  const snapshot = await categoriesRef.get();

  console.log(`\n✅ Total categories found: ${snapshot.size}`);

  if (snapshot.size > 0) {
    console.log('\nCategory list:');
    let count = 0;
    for (const doc of snapshot.docs) {
      count++;
      const data = doc.data();
      console.log(`  ${count}. ${data.title} (cloudId: ${doc.id}, isSystemDefault: ${data.isSystemDefault || false})`);
    }
  }
}

// Replace with your user ID
const userId = '8g91QXUpaYaU3VdNfJ5Ph0xGVy02';

checkCategories(userId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
