import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Quick script to check categories in Firestore
// Run with: dart run tool_check_categories.dart

void main() async {
  // Initialize Firebase
  final bexlyApp = await Firebase.initializeApp(
    name: 'bexly',
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCmtd7aUU5qWHlnTlkLRQwqUGDNW8zU9rU',
      appId: '1:649097217855:android:8b2e29c5a7e6b8e9f5f5f5',
      messagingSenderId: '649097217855',
      projectId: 'bexly-9f0c3',
      storageBucket: 'bexly-9f0c3.firebasestorage.app',
    ),
  );

  final firestore = FirebaseFirestore.instanceFor(
    app: bexlyApp,
    databaseId: "bexly",
  );

  const userId = '8g91QXUpaYaU3VdNfJ5Ph0xGVy02';

  print('🔍 Checking categories for user: $userId\n');

  final categoriesSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('data')
      .doc('categories')
      .collection('items')
      .get();

  print('✅ Total categories found: ${categoriesSnapshot.docs.length}\n');

  if (categoriesSnapshot.docs.isNotEmpty) {
    print('Category list:');
    int count = 0;
    for (final doc in categoriesSnapshot.docs) {
      count++;
      final data = doc.data();
      print('  $count. ${data['title']} (cloudId: ${doc.id}, isSystemDefault: ${data['isSystemDefault'] ?? false})');
    }
  }

  print('\n✅ Done!');
}
