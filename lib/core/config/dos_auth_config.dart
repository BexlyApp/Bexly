import 'package:firebase_core/firebase_core.dart';

class DOSAuthConfig {
  static const String projectName = 'DOS ID';

  // Firebase configuration for DOS ID project
  // Project ID: dos-me
  static const FirebaseOptions dosIdOptions = FirebaseOptions(
    apiKey: 'AIzaSyDxxxxxx',  // TODO: Replace with actual API key from Firebase Console
    authDomain: 'dos-me.firebaseapp.com',
    projectId: 'dos-me',
    storageBucket: 'dos-me.appspot.com',
    messagingSenderId: 'xxxxxxxxxx',  // TODO: Replace with actual sender ID
    appId: '1:xxxxxxxxxx:android:xxxxxxxxxx',  // TODO: Replace with actual app ID
  );

}