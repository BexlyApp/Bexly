/**
 * Script to delete corrupted categories from Firestore
 *
 * This will delete ALL categories from the user's Firestore collection
 * so they can be re-populated with correct default categories.
 */

const admin = require('firebase-admin');

// Initialize with application default credentials
// Make sure you've run: firebase login or set GOOGLE_APPLICATION_CREDENTIALS
admin.initializeApp({
  projectId: 'bexly-app'
});

const db = admin.firestore();
// Use the 'bexly' database
db.settings({ databaseId: 'bexly' });

async function deleteAllCategories() {
  try {
    console.log('🔍 Finding all user documents...');

    // Get all users
    const usersSnapshot = await db.collection('users').get();

    if (usersSnapshot.empty) {
      console.log('❌ No users found');
      return;
    }

    console.log(`📊 Found ${usersSnapshot.size} users`);

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`\n👤 Processing user: ${userId}`);

      // Get all categories for this user
      const categoriesRef = db.collection('users').doc(userId).collection('categories');
      const categoriesSnapshot = await categoriesRef.get();

      if (categoriesSnapshot.empty) {
        console.log('  ℹ️  No categories found for this user');
        continue;
      }

      console.log(`  📁 Found ${categoriesSnapshot.size} categories to delete`);

      // Delete all categories in batches (Firestore limit is 500 per batch)
      const batch = db.batch();
      let count = 0;

      for (const doc of categoriesSnapshot.docs) {
        batch.delete(doc.ref);
        count++;
        console.log(`  🗑️  Deleting category: ${doc.data().title || 'Unknown'}`);
      }

      await batch.commit();
      console.log(`  ✅ Deleted ${count} categories for user ${userId}`);
    }

    console.log('\n✅ All categories deleted successfully!');
    console.log('ℹ️  You can now re-populate default categories from the app');

  } catch (error) {
    console.error('❌ Error deleting categories:', error);
    throw error;
  } finally {
    // Close the connection
    await admin.app().delete();
  }
}

// Run the script
deleteAllCategories()
  .then(() => {
    console.log('\n🎉 Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Script failed:', error);
    process.exit(1);
  });
