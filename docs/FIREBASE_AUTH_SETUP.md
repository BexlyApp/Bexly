# Bexly Firebase Auth Setup với DOS.AI (dos-me)

## Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│                    Firebase Projects                     │
├─────────────────────────────────────────────────────────┤
│  dos-me                    │  bexly-app                  │
│  ├── Auth (shared)         │  ├── Firestore             │
│  │   ├── Google Sign-In    │  ├── Storage               │
│  │   ├── Email/Password    │  ├── Analytics             │
│  │   └── Apple Sign-In     │  ├── Crashlytics           │
│  └── (dos.ai services)     │  └── Functions             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Bexly Flutter App                     │
├─────────────────────────────────────────────────────────┤
│  Firebase Auth  ──────►  dos-me (login/register)        │
│  Firebase Firestore ──►  bexly-app (app data)           │
│  Firebase Storage ────►  bexly-app (files)              │
│  Firebase Analytics ──►  bexly-app (tracking)           │
└─────────────────────────────────────────────────────────┘
```

## 1. Prerequisites - Firebase Console Setup

### 1.1 dos-me project - Add Bexly domains

1. Vào [Firebase Console](https://console.firebase.google.com) → Project `dos-me`
2. **Authentication** → **Settings** → **Authorized domains**
3. Add domains:
   - `bexly.app`
   - `www.bexly.app`
   - `localhost` (nếu chưa có)

### 1.2 dos-me project - Tạo App cho Bexly (Optional)

Nếu muốn tracking riêng Firebase Auth usage:

1. Project `dos-me` → **Project Settings** → **General** → **Your apps**
2. Click **Add app** → chọn platform (Android/iOS/Web)
3. App nickname: `Bexly Android`, `Bexly iOS`, etc.

### 1.3 Google Cloud Console - OAuth Credentials

1. Vào [Google Cloud Console](https://console.cloud.google.com) → Project `dos-me`
2. **APIs & Services** → **Credentials**
3. Tìm OAuth 2.0 Client ID đang dùng cho Google Sign-In
4. **Authorized redirect URIs**: Verify có callback cho mobile apps
5. **Authorized JavaScript origins**: Add `https://bexly.app` (cho web nếu có)

## 2. Flutter Implementation

### 2.1 Cấu trúc file

```
D:\Projects\Bexly\
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── firebase_config.dart      # Firebase initialization
│   │   └── services/
│   │       ├── auth_service.dart          # Auth với dos-me
│   │       └── firebase_service.dart      # Other services với bexly-app
│   └── ...
├── android/
│   └── app/
│       ├── google-services.json           # Từ bexly-app
│       └── src/main/AndroidManifest.xml   # Google Sign-In config
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist       # Từ bexly-app
│       └── Info.plist                     # URL schemes
└── pubspec.yaml
```

### 2.2 pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase Core
  firebase_core: ^3.8.1

  # Auth (sẽ dùng với dos-me)
  firebase_auth: ^5.3.4
  google_sign_in: ^6.2.2

  # Data services (sẽ dùng với bexly-app)
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.4.0
  firebase_analytics: ^11.4.0
  firebase_crashlytics: ^4.2.0
```

### 2.3 Firebase Config

**File: `lib/core/config/firebase_config.dart`**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseConfig {
  // ============================================
  // dos-me project config (for Auth only)
  // Get these values from Firebase Console → dos-me → Project Settings
  // ============================================
  static const FirebaseOptions dosMeOptions = FirebaseOptions(
    apiKey: 'AIzaSyD522D78jW8ye-WbfZgUmIaSt89Vbo0cvo',
    appId: '1:368090586626:web:6b4c61ee5d219f0777511b', // Web app ID
    messagingSenderId: '368090586626',
    projectId: 'dos-me',
    authDomain: 'dos-me.firebaseapp.com',
  );

  // ============================================
  // bexly-app project config (for Firestore, Storage, Analytics)
  // Get these values from Firebase Console → bexly-app → Project Settings
  // ============================================
  static const FirebaseOptions bexlyOptions = FirebaseOptions(
    apiKey: 'YOUR_BEXLY_API_KEY',           // Replace with actual value
    appId: 'YOUR_BEXLY_APP_ID',             // Replace with actual value
    messagingSenderId: 'YOUR_SENDER_ID',     // Replace with actual value
    projectId: 'bexly-app',                  // Your GCloud project ID
    storageBucket: 'bexly-app.appspot.com',
  );

  // ============================================
  // Firebase App instances
  // ============================================
  static FirebaseApp? _authApp;
  static FirebaseApp? _dataApp;

  // ============================================
  // Service getters
  // ============================================

  /// FirebaseAuth instance connected to dos-me
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: _authApp!);

  /// Firestore instance connected to bexly-app
  static FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: _dataApp!);

  /// Storage instance connected to bexly-app
  static FirebaseStorage get storage => FirebaseStorage.instanceFor(app: _dataApp!);

  /// Analytics instance connected to bexly-app
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instanceFor(app: _dataApp!);

  // ============================================
  // Initialization
  // ============================================
  static Future<void> initialize() async {
    // Initialize dos-me for Auth
    _authApp = await Firebase.initializeApp(
      name: 'dosme-auth',
      options: dosMeOptions,
    );
    debugPrint('✅ Firebase Auth (dos-me) initialized');

    // Initialize bexly-app for data services (as default app)
    _dataApp = await Firebase.initializeApp(
      options: bexlyOptions,
    );
    debugPrint('✅ Firebase Data (bexly-app) initialized');
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;

  /// Current user UID
  static String? get currentUserId => auth.currentUser?.uid;
}
```

### 2.4 Auth Service

**File: `lib/core/services/auth_service.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseConfig.auth;

  // ============================================
  // Streams & Getters
  // ============================================

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Current user UID
  String? get uid => currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // ============================================
  // Google Sign In
  // ============================================

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Configure Google Sign In
      // Note: clientId is required for web, optional for mobile
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // For web platform, use the web client ID from dos-me GCloud Console
        clientId: kIsWeb
          ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'  // Replace
          : null,
        scopes: ['email', 'profile'],
      );

      // Trigger sign in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return null;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase (dos-me)
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Signed in as: ${userCredential.user?.email}');

      return userCredential;
    } catch (e, stack) {
      debugPrint('❌ Google Sign In error: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ============================================
  // Email/Password Auth
  // ============================================

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ Signed in with email: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ Account created: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ============================================
  // Password Reset
  // ============================================

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    debugPrint('✅ Password reset email sent to: $email');
  }

  // ============================================
  // Sign Out
  // ============================================

  Future<void> signOut() async {
    try {
      // Sign out from Google
      await GoogleSignIn().signOut();

      // Sign out from Firebase
      await _auth.signOut();

      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // ============================================
  // Token Management
  // ============================================

  /// Get ID token for backend API calls
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await currentUser?.getIdToken(forceRefresh);
  }

  /// Get ID token result with claims
  Future<IdTokenResult?> getIdTokenResult({bool forceRefresh = false}) async {
    return await currentUser?.getIdTokenResult(forceRefresh);
  }
}
```

### 2.5 Firebase Data Service

**File: `lib/core/services/firebase_service.dart`**

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/firebase_config.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirebaseStorage _storage = FirebaseConfig.storage;

  // ============================================
  // Firestore Helpers
  // ============================================

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get document reference
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  // ============================================
  // User Profile Operations
  // ============================================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }

  /// Create or update user profile
  Future<void> setUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Create user profile on first login
  Future<void> createUserIfNotExists(String uid, {
    required String? email,
    required String? displayName,
    required String? photoUrl,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================
  // Storage Operations
  // ============================================

  /// Upload file to storage
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete file from storage
  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }

  /// Get download URL
  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }
}
```

### 2.6 Main.dart

**File: `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (both projects)
  await FirebaseConfig.initialize();

  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bexly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseConfig.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          return const HomeScreen();
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

// Placeholder screens - replace with your actual screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${FirebaseConfig.auth.currentUser?.email}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseConfig.auth.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Use AuthService for proper implementation
            final googleSignIn = GoogleSignIn();
            final account = await googleSignIn.signIn();
            if (account != null) {
              final auth = await account.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: auth.accessToken,
                idToken: auth.idToken,
              );
              await FirebaseConfig.auth.signInWithCredential(credential);
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
```

## 3. Platform-specific Setup

### 3.1 Android

**File: `android/app/build.gradle`**

```gradle
android {
    defaultConfig {
        // ... existing config

        // Required for Google Sign In
        manifestPlaceholders += [
            'appAuthRedirectScheme': 'com.bexly.app' // Your package name
        ]
    }
}
```

**File: `android/app/src/main/AndroidManifest.xml`**

```xml
<manifest>
    <application>
        <!-- ... existing config -->

        <!-- Google Sign In -->
        <activity
            android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
            android:exported="true" />
    </application>
</manifest>
```

### 3.2 iOS

**File: `ios/Runner/Info.plist`**

Add URL schemes for Google Sign In:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 4. Backend Token Verification (Optional)

If Bexly has a backend that needs to verify tokens:

```typescript
// Node.js example
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// Initialize with dos-me service account
const authApp = initializeApp({
  credential: cert(require('./dos-me-service-account.json')),
}, 'auth');

// Middleware to verify token
async function verifyToken(req, res, next) {
  const idToken = req.headers.authorization?.split('Bearer ')[1];

  if (!idToken) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decodedToken = await getAuth(authApp).verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

## 5. Firestore Security Rules (bexly-app)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false; // Don't allow deletion
    }

    // Example: User's private data
    match /users/{userId}/private/{document=**} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Example: Public data (anyone authenticated can read)
    match /public/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false;
    }
  }
}
```

## 6. Checklist

### Firebase Console
- [ ] Add `bexly.app` to dos-me authorized domains
- [ ] Add `www.bexly.app` to dos-me authorized domains
- [ ] Verify OAuth credentials in Google Cloud Console (dos-me project)
- [ ] Download `google-services.json` from bexly-app (Android)
- [ ] Download `GoogleService-Info.plist` from bexly-app (iOS)

### Flutter App
- [ ] Add Firebase dependencies to `pubspec.yaml`
- [ ] Create `firebase_config.dart` with both project configs
- [ ] Create `auth_service.dart`
- [ ] Create `firebase_service.dart`
- [ ] Update `main.dart` to initialize Firebase
- [ ] Configure Android (`build.gradle`, `AndroidManifest.xml`)
- [ ] Configure iOS (`Info.plist`)

### Testing
- [ ] Test Google Sign In
- [ ] Test Email/Password Sign In
- [ ] Verify Firestore read/write works
- [ ] Verify Storage upload works
- [ ] Check Analytics events in Firebase Console

## 7. Flow Summary

```
User opens Bexly app
    │
    ▼
Firebase.initializeApp() x 2
    │
    ├── dos-me (auth) ─────────────► For login/register
    └── bexly-app (data) ──────────► For Firestore/Storage/Analytics
    │
    ▼
User clicks "Sign in with Google"
    │
    ▼
GoogleSignIn → dos-me Auth
    │
    ▼
User authenticated (UID from dos-me)
    │
    ▼
App creates user profile in bexly-app Firestore
    │
    ▼
Firestore rules verify request.auth.uid (from dos-me token)
```

## 8. Analytics & Crashlytics User Tracking

Vì Auth ở `dos-me` nhưng Analytics/Crashlytics ở `bexly-app`, cần manually set user ID sau khi login:

```dart
// Trong AuthService hoặc sau khi login thành công
Future<void> _setupAnalyticsUser(User user) async {
  // Set user ID cho Analytics
  await FirebaseConfig.analytics.setUserId(id: user.uid);

  // Set user properties
  await FirebaseConfig.analytics.setUserProperty(
    name: 'email_domain',
    value: user.email?.split('@').last,
  );

  // Set user ID cho Crashlytics
  await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
}

// Clear khi logout
Future<void> _clearAnalyticsUser() async {
  await FirebaseConfig.analytics.setUserId(id: null);
  await FirebaseCrashlytics.instance.setUserIdentifier('');
}
```

**Lưu ý:** UID từ dos-me sẽ được dùng consistent across Analytics, Crashlytics, và Firestore.

## 9. Important Notes

1. **UID Consistency**: User UID từ dos-me sẽ được dùng cho tất cả operations trong bexly-app Firestore. Đây là key để link data giữa 2 projects.

2. **Token Verification**: Firestore Security Rules tự động verify token. Khi client gửi request, Firebase SDK include ID token, và Firestore verify với project đã issue token đó (dos-me).

3. **No SSO**: User vẫn phải login riêng trên Bexly app (không auto-login nếu đã login DOS.AI). Nhưng account/password giống nhau.

4. **Separate Analytics**: Analytics, Crashlytics sẽ track riêng cho Bexly trong bexly-app project.
