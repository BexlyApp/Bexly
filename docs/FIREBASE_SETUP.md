# Firebase Setup Guide for Bexly

## Overview
This guide documents the Firebase integration for Bexly app, including the migration from the original package ID to the JOY brand ecosystem.

## Firebase Project Details
- **Project Name**: Bexly
- **Project ID**: `bexly-app`
- **Project Number**: 657555385291
- **Package ID**: `com.joy.bexly`

## Initial Setup Process

### 1. Prerequisites
- Firebase CLI installed: `firebase --version`
- FlutterFire CLI installed
- Google account with Firebase access

### 2. Firebase Project Creation
```bash
# Login to Firebase
firebase login

# List available projects
firebase projects:list

# Create project (if using Google Cloud)
# Project was created in Google Cloud Console first
# Then enabled Firebase through Firebase Console
```

### 3. FlutterFire Configuration

#### Install FlutterFire CLI
```bash
D:\Dev\flutter\bin\dart pub global activate flutterfire_cli
```

#### Configure Firebase
```bash
# Run configuration
flutterfire configure --project=bexly-app --platforms=android,ios,web
```

This command:
- Registers Android app (`com.joy.bexly`)
- Registers iOS app (`com.joy.bexly`)
- Registers Web app
- Generates `lib/firebase_options.dart`
- Downloads platform-specific config files

## Package ID Migration

### Original Setup
- Package ID: `com.layground.pockaw` (from forked source)

### Migration to JOY Brand
Changed to: `com.joy.bexly`

#### Android Changes
1. **build.gradle** (`android/app/build.gradle`):
```gradle
android {
    namespace = "com.joy.bexly"
    defaultConfig {
        applicationId = "com.joy.bexly"
    }
}
```

2. **Kotlin Package Structure**:
```
android/app/src/main/kotlin/com/joy/bexly/MainActivity.kt
```

#### iOS Changes
1. **project.pbxproj** (`ios/Runner.xcodeproj/project.pbxproj`):
   - Updated all `PRODUCT_BUNDLE_IDENTIFIER` to `com.joy.bexly`

### Re-configuration After Package Change
```bash
# Remove old config
rm lib/firebase_options.dart
rm android/app/google-services.json

# Re-run FlutterFire
flutterfire configure --project=bexly-app
```

## Firebase Services Enabled

### 1. Firebase Analytics
Track user behavior and app usage:
```dart
// lib/core/app.dart
static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
  analytics: analytics,
);
```

### 2. Firebase Crashlytics
Automatic crash reporting:
```dart
// lib/main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

### 3. Firebase Performance
Monitor app performance metrics (configured in pubspec.yaml)

## Configuration Files

### Generated Files
- `lib/firebase_options.dart` - Firebase configuration
- `android/app/google-services.json` - Android config
- `ios/Runner/GoogleService-Info.plist` - iOS config (when building)
- `web/index.html` - Web config (when building)

### Helper Scripts
- `run_flutterfire.bat` - Quick Firebase reconfiguration

## Verification

### Check Firebase Connection
```bash
# Run the app
D:\Dev\flutter\bin\flutter run

# Check Firebase Console
# https://console.firebase.google.com/project/bexly-app
# Should see active users in Analytics after app launch
```

### Test Crashlytics
```dart
// Add test crash button (development only)
FirebaseCrashlytics.instance.crash();
```

## Troubleshooting

### Issue: Firebase project not found
**Solution**: Ensure Firebase is enabled in Google Cloud project
1. Go to Firebase Console
2. Click "Add project"
3. Select "Add Firebase to Google Cloud project"
4. Choose your GCP project

### Issue: Package ID mismatch
**Solution**: Re-run FlutterFire after changing package ID
```bash
flutterfire configure --project=bexly-app
```

### Issue: Build errors after setup
**Solution**: Clean and rebuild
```bash
D:\Dev\flutter\bin\flutter clean
D:\Dev\flutter\bin\flutter pub get
D:\Dev\flutter\bin\dart run build_runner build
```

## Security Notes

### Never Commit
- `google-services.json` (already in .gitignore)
- `GoogleService-Info.plist`
- API keys or sensitive configuration

### Firebase Security Rules
Configure in Firebase Console:
- Firestore rules (if using)
- Storage rules (if using)
- Realtime Database rules (if using)

## Future Considerations

### Multi-environment Setup
For production/staging/dev:
```bash
# Dev environment
flutterfire configure --project=bexly-dev

# Production
flutterfire configure --project=bexly-app
```

### Additional Services
Ready to enable:
- Cloud Firestore (online sync)
- Firebase Auth (user accounts)
- Cloud Storage (file uploads)
- Cloud Functions (backend logic)
- Remote Config (feature flags)

## DOS ID Authentication Integration

### Overview
Bexly uses DOS ID (dos-me Firebase project) as a centralized authentication provider while maintaining its own Firebase project for other services.

### Architecture - Dual App Initialization

#### Important: App Registration Still Required
- **DOS-Me**: Must register Bexly app to get Firebase Auth config (API key, App ID)
- **Bexly Project**: Keeps its own google-services.json for Analytics, Crashlytics, Firestore, etc.
- **Solution**: Initialize TWO Firebase apps on client - one for auth (DOS-Me), one for services (Bexly)

#### Correct Architecture
```
DOS-Me (Firebase Identity Platform)
├── Auth service only (no Firestore/Storage needed)
├── Register Bexly app here (to get auth config)
├── Issues ID tokens with custom claims (joy_uid, etc.)
└── Handles all authentication

Bexly (Firebase Project)
├── Own google-services.json (default app)
├── Analytics, Crashlytics, Firestore, Storage
├── Backend verifies tokens with DOS-Me Admin SDK
└── All non-auth Firebase services
```

### Implementation - Dual App Init

#### 1. Flutter/Dart Implementation
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Initialize default app (Bexly) - from google-services.json
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Initialize DOS-Me app for auth (secondary app)
const dosConfig = FirebaseOptions(
  apiKey: "AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM",
  authDomain: "dos-me.firebaseapp.com",
  projectId: "dos-me",
  storageBucket: "dos-me.firebasestorage.app",
  messagingSenderId: "368090586626",
  appId: "1:368090586626:android:cb9d0236b3d7ef9277511b", // Android app ID from DOS-Me
);

final dosApp = await Firebase.initializeApp(
  name: 'dos-id',
  options: dosConfig,
);

// Use DOS-Me for auth
final dosAuth = FirebaseAuth.instanceFor(app: dosApp);
// dosAuth.tenantId = 'public'; // or 'org-<account_id>' for staff

// Use default app for other services
final db = FirebaseFirestore.instance; // Uses Bexly project
final analytics = FirebaseAnalytics.instance; // Uses Bexly project
```

#### 2. Web Implementation
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// DOS-Me config (for auth)
const dosConfig = {
  apiKey: "AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM",
  authDomain: "dos-me.firebaseapp.com",
  projectId: "dos-me",
  storageBucket: "dos-me.firebasestorage.app",
  messagingSenderId: "368090586626",
  appId: "1:368090586626:web:xxxxx" // Web app ID from DOS-Me
};

// Bexly config (for services)
const bexlyConfig = {
  apiKey: "AIzaSyDeCdbi63ZcD-JEG5JzeIWZ4q_tSxta7x0",
  authDomain: "bexly-app.firebaseapp.com",
  projectId: "bexly-app",
  // ... rest of Bexly config
};

// Initialize both apps
const dosApp = initializeApp(dosConfig, 'dos-id');
const bexlyApp = initializeApp(bexlyConfig, 'bexly');

// Auth from DOS-Me
const auth = getAuth(dosApp);
auth.tenantId = 'public'; // or 'org-<account_id>'

// Services from Bexly
const db = getFirestore(bexlyApp);
```

#### 3. Android Native (Kotlin)
```kotlin
// Default app from google-services.json (Bexly)
FirebaseApp.initializeApp(this)

// Secondary app for DOS-Me auth
val dosOptions = FirebaseOptions.Builder()
  .setApplicationId("1:368090586626:android:cb9d0236b3d7ef9277511b")
  .setApiKey("AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM")
  .setProjectId("dos-me")
  .build()

val dosApp = FirebaseApp.initializeApp(this, dosOptions, "dos-id")
val auth = FirebaseAuth.getInstance(dosApp)
auth.tenantId = "public" // or "org-<account_id>"
```

#### 4. iOS Native (Swift)
```swift
// Default app from GoogleService-Info.plist (Bexly)
FirebaseApp.configure()

// Secondary app for DOS-Me auth
let options = FirebaseOptions(
  googleAppID: "1:368090586626:ios:xxxxx",
  gcmSenderID: "368090586626"
)
options.apiKey = "AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM"
options.projectID = "dos-me"

FirebaseApp.configure(name: "dos-id", options: options)

let dosApp = FirebaseApp.app(name: "dos-id")!
let auth = Auth.auth(app: dosApp)
auth.tenantID = "public" // or "org-<account_id>"
```

### Backend Token Verification
```javascript
// Backend uses DOS-Me Admin SDK to verify tokens
const admin = require('firebase-admin');
const dosAdmin = admin.initializeApp({
  projectId: 'dos-me',
  // Service account credentials for DOS-Me
}, 'dos-admin');

// Verify ID token from client
async function verifyToken(idToken) {
  const decoded = await dosAdmin.auth().verifyIdToken(idToken, true);

  // Extract custom claims
  const joyUid = decoded.joy_uid || decoded.uid;
  const accountId = decoded.account_id;
  const role = decoded.role;
  const tenant = decoded.firebase?.tenant;

  // Validate tenant if needed
  if (tenant && !['public', `org-${accountId}`].includes(tenant)) {
    throw new Error('Invalid tenant');
  }

  return { joyUid, accountId, role, tenant };
}
```

### Custom Claims Structure
```json
{
  "sub": "firebase_uid",
  "joy_uid": "internal_user_id",
  "account_id": "org_account_id",
  "role": "admin|agent|member",
  "firebase": {
    "tenant": "public|org-xxx"
  },
  "email": "user@example.com",
  "email_verified": true,
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Setup Checklist

#### DOS-Me Project Setup
- [ ] Create Android app entry for Bexly (com.joy.bexly)
- [ ] Create iOS app entry for Bexly (com.joy.bexly)
- [ ] Create Web app entry for Bexly
- [ ] Add `bexly.com` to Authorized domains in Authentication settings
- [ ] Configure Identity Platform if using multi-tenant

#### Bexly Project Setup
- [ ] Keep existing google-services.json (for default app)
- [ ] Keep existing GoogleService-Info.plist (for default app)
- [ ] Add DOS-Me config as secondary app in code
- [ ] Update auth service to use DOS-Me app instance
- [ ] Keep all other services using default app

### Benefits of Dual App Approach
1. **Clean Separation**: Auth from DOS-Me, services from Bexly
2. **No Migration Required**: Keep existing Firebase services intact
3. **Centralized Auth**: All apps authenticate through DOS-Me
4. **Service Isolation**: Each app manages its own data/services
5. **Easy Token Verification**: Backend only needs DOS-Me Admin SDK

### Common Pitfalls to Avoid
- ❌ Don't try to use DOS-Me project for non-auth services
- ❌ Don't replace Bexly's google-services.json with DOS-Me's
- ❌ Don't forget to register app in DOS-Me (still needed for config)
- ✅ Do use dual app initialization
- ✅ Do keep services in their respective projects
- ✅ Do verify all tokens with DOS-Me Admin SDK
- ✅ Do use joy_uid as primary key, not Firebase uid