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