# Bexly Development Guide

## Project Overview
**Bexly** is a personal finance and expense tracking app built with Flutter. It features offline support, multi-wallet support, and comprehensive expense management with Supabase backend for cloud sync.

- **App Name**: Bexly
- **Package ID**: `com.joy.bexly`
- **Firebase Project**: `dos-me` (shared DOS-Me ecosystem)
- **Supabase Project**: `dos` (Supabase URL: https://dos.supabase.co)
- **Flutter Path**: `D:\Dev\flutter`
- **Project Path**: `D:\Projects\Bexly`
- **Original Fork**: Pockaw (open-source)

---

## 🚀 Quick Start

### Run the App
```bash
# Quick run with helper script
D:\Projects\DOSafe\run_bexly.bat

# Or directly with Flutter
D:\Dev\flutter\bin\flutter run
```

### Essential Commands
```bash
# Install dependencies
D:\Dev\flutter\bin\flutter pub get

# Generate database code (required after DB changes)
D:\Dev\flutter\bin\dart run build_runner build

# Clean build
D:\Dev\flutter\bin\flutter clean
D:\Dev\flutter\bin\flutter pub get
```

---

## 🛠️ Environment Setup

### Prerequisites
- Flutter SDK: `D:\Dev\flutter`
- Dart SDK: Included with Flutter
- Android Studio / VS Code
- Firebase CLI: `firebase --version`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Initial Setup
```bash
# 1. Clone repository
cd D:\Projects\DOSafe

# 2. Install dependencies
D:\Dev\flutter\bin\flutter pub get

# 3. Generate code (Drift database)
D:\Dev\flutter\bin\dart run build_runner build

# 4. Run the app
D:\Projects\DOSafe\run_bexly.bat
```

---

## 📦 Project Structure

```
DOSafe/
├── lib/
│   ├── core/
│   │   ├── app.dart           # App configuration
│   │   ├── database/          # Drift SQLite database
│   │   ├── components/        # Shared UI components
│   │   └── router/            # Go Router navigation
│   ├── features/
│   │   ├── transaction/       # Transaction management
│   │   ├── wallet/           # Multi-wallet support
│   │   ├── budget/           # Budget tracking
│   │   ├── category/         # Categories
│   │   └── analytics/        # Reports & charts
│   └── main.dart             # Entry point
├── android/
│   └── app/
│       ├── build.gradle      # Android config (com.joy.bexly)
│       └── src/main/kotlin/com/joy/bexly/
├── ios/
│   └── Runner.xcodeproj/     # iOS config (com.joy.bexly)
├── docs/                     # Documentation
└── firebase_options.dart     # Firebase configuration
```

---

## 🔥 Firebase Setup (dos-me project)

### Project Details
- **Project Name**: DOS-Me (shared ecosystem project)
- **Project ID**: `dos-me`
- **Project Number**: 368090586626

**Services Used:**
- Firebase Cloud Messaging (FCM) - Push notifications
- Firebase Analytics - User behavior tracking
- Firebase Crashlytics - Crash reporting
- Firebase Storage - Avatar uploads (bucket: `bexly-app.firebasestorage.app`)

### Configuration Process
```bash
# Download google-services.json from Firebase Console
# Place in: android/app/google-services.json
# DO NOT commit to git (already in .gitignore)
```

**Important:** `google-services.json` is environment-specific. Each developer must:
1. Go to Firebase Console (dos-me project)
2. Add their debug keystore SHA-1 fingerprint
3. Download their own `google-services.json`

---

## 🗄️ Supabase Setup (Backend)

### Project Details
- **Project**: DOS
- **Organization**: DOS-Me
- **Supabase URL**: https://dos.supabase.co
- **Publishable Key**: Set in `.env` file

### Enabled Services
1. **Supabase Auth** - User authentication (Google, Email)
2. **Supabase Database** - PostgreSQL with Row Level Security (RLS)
3. **Realtime** - Real-time sync across devices

### Environment Configuration

Create `.env` file (NOT in git):
```env
SUPABASE_URL=https://dos.supabase.co
SUPABASE_PUBLISHABLE_KEY=your_publishable_key_here

# Google OAuth Client IDs
GOOGLE_WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID_DEBUG=your_debug_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID_RELEASE=your_release_client_id.apps.googleusercontent.com
```

See `.env.example` for complete template.

### Package ID Migration History
- Original: `com.layground.pockaw` (from forked source)
- Current: `com.joy.bexly` (JOY brand ecosystem)

---

## 🏗️ Development

### Technology Stack
- **State Management**: Riverpod with Hooks
- **Database**: Drift (SQLite) for offline storage
- **Navigation**: Go Router
- **Theming**: flex_color_scheme
- **Firebase**: Analytics, Crashlytics, Performance

### Making Changes

#### 1. Database Changes
```bash
# Update table definitions in lib/core/database/tables/
# Then regenerate code
D:\Dev\flutter\bin\dart run build_runner build --delete-conflicting-outputs
```

#### 2. Adding New Features
Create feature directory: `lib/features/your_feature/`
```
your_feature/
├── domain/          # Business logic & models
├── presentation/    # UI screens & widgets
├── riverpod/        # State providers
└── utils/           # Feature utilities
```

#### 3. Code Generation
```bash
# One-time generation
D:\Dev\flutter\bin\dart run build_runner build

# Watch mode for auto-generation
D:\Dev\flutter\bin\dart run build_runner watch
```

### Code Style
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

### Testing
```bash
# Run all tests
D:\Dev\flutter\bin\flutter test

# Run with coverage
D:\Dev\flutter\bin\flutter test --coverage

# Analyze code quality
D:\Dev\flutter\bin\flutter analyze
```

---

## 📱 Build & Deployment

### Android Build

#### Debug/Testing
```bash
# Run in debug mode (with hot reload)
D:\Dev\flutter\bin\flutter run

# Build APK for testing
D:\Dev\flutter\bin\flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk

# Install on device
adb install build\app\outputs\flutter-apk\app-release.apk
```

#### Production (Play Store)
```bash
# Build App Bundle
D:\Dev\flutter\bin\flutter build appbundle --release
# Output: build\app\outputs\bundle\release\app-release.aab

# Split APKs by architecture (smaller size)
D:\Dev\flutter\bin\flutter build apk --split-per-abi
```

### iOS Build (macOS Required)
```bash
# Build for iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
# Then Archive and upload to App Store Connect
```

### Web Build
```bash
# Build web version
D:\Dev\flutter\bin\flutter build web --release
# Output: build\web\

# Deploy to Firebase Hosting
firebase init hosting
firebase deploy --only hosting
```

### Version Management
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version+buildNumber
```
- Version: `major.minor.patch` (e.g., 1.0.0)
- Build number: Integer increment (e.g., 1, 2, 3...)

---

## 🐛 Troubleshooting

### Common Issues

1. **Build errors after database changes**
```bash
D:\Dev\flutter\bin\flutter clean
D:\Dev\flutter\bin\dart run build_runner build --delete-conflicting-outputs
```

2. **Dependencies not resolving**
```bash
D:\Dev\flutter\bin\flutter clean
D:\Dev\flutter\bin\flutter pub cache clean
D:\Dev\flutter\bin\flutter pub get
```

3. **Firebase connection issues**
```bash
# Re-configure Firebase
flutterfire configure --project=bexly-app
```

4. **Package ID mismatch after fork**
```bash
# Ensure all references updated to com.joy.bexly:
# - android/app/build.gradle
# - android/app/src/main/kotlin/com/joy/bexly/
# - ios/Runner.xcodeproj/project.pbxproj
```

### Cloud Sync Issues (October 2025)

#### Problem: App hangs 30s after Google/Facebook Sign In
**Symptoms:**
- Login successful but app shows loading spinner for 30 seconds
- Eventually enters app but poor UX

**Root Cause:**
- `fullSync()` called during initial sync was blocking without timeout
- Firestore `.set()` operations had no timeout protection
- Conflict detection ran unnecessary sync even when data already synced

**Solution (Build v0.0.7+90):**
1. Added auto-resolve logic in `conflict_resolution_service.dart`:
   - Skip conflict dialog when both sides have same wallet count + 0 transactions
   - Only show dialog for real conflicts requiring user decision

2. Skip `fullSync()` in `sync_trigger_service.dart`:
   - When conflict auto-resolved, no need to sync again
   - Real-time sync handles ongoing changes

3. Added timeout protection:
   - All Firestore queries now have 10s timeout
   - Wrapped sync call in login_screen.dart with 30s timeout + try-catch

**Prevention:**
- Always add `.timeout()` to Firestore operations
- Design sync logic to be non-blocking
- Use auto-resolve for trivial conflicts

#### Problem: Google Sign-In with Supabase Auth [28444] Error

**Background:**
Bexly migrated from Firebase Auth to Supabase Auth. Google Sign-In required significant changes due to:
1. API changes in `google_sign_in` v7.0
2. Different token requirements between Firebase and Supabase

**Symptoms:**
- Error `[28444] Developer console is not set up correctly`
- Account picker shows but fails after account selection

**Root Cause:**
1. **API Breaking Changes**: `google_sign_in` v7.0 removed `signIn()`, added `authenticate()`
2. **Missing accessToken**: Supabase requires BOTH `idToken` AND `accessToken` (Firebase only needed `idToken`)
3. **Client Type Confusion**: Native app must use Web Client ID for token generation

---

### Google Sign-In Architecture

**Key Concept:** Native mobile apps with backend authentication require **2 types of OAuth clients**:

| Client Type | Purpose | Used For |
|------------|---------|----------|
| **Android Clients** | SHA-1 validation | Local app signature verification |
| **Web Client** | Token generation | Server-side token verification (Supabase) |

**Why Web Client?**
- Android Client tokens can only be verified by Google services (Firebase)
- 3rd party backends (Supabase, custom servers) require Web Client tokens
- Web Client tokens are verifiable by any OAuth 2.0 compliant server

---

### OAuth Client Setup (Google Cloud Console - dos-me project)

**Required Clients:**

1. **Web Application** (auto-detected from google-services.json)
   - Client ID: `368090586626-ch5cd0afri6pilfipeersbtqkpf6huj6`
   - Purpose: Token generation for server verification
   - No restrictions needed

2. **Android (Debug)**
   - Client ID: `368090586626-2i3h1mmsrmjn30865q883lioaruhpbqu`
   - SHA-1: `79:CF:10:6C:1D:4C:E7:B1:7D:6C:CF:FC:25:E5:E1:DE:18:C1:59:C7`
   - Package: `com.joy.bexly`
   - Purpose: Validate debug builds

3. **Android (Release)**
   - Client ID: `368090586626-lu2v4fapus52k6sjcs0edneglm3spuu4`
   - SHA-1: `B8:B5:58:78:A4:1E:59:70:69:C6:0E:97:0F:B6:33:E2:A6:4A:6A:39`
   - Package: `com.joy.bexly`
   - Purpose: Validate release builds (DOS-key.jks)

**Get SHA-1 from keystore:**
```bash
# Debug keystore
cd android && gradlew signingReport | grep SHA1

# Or with keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

---

### Supabase Google Provider Configuration

**Dashboard:** Supabase Console → Authentication → Providers → Google

**Authorized Client IDs:** (comma-separated, no spaces)
```
368090586626-ch5cd0afri6pilfipeersbtqkpf6huj6.apps.googleusercontent.com,368090586626-2i3h1mmsrmjn30865q883lioaruhpbqu.apps.googleusercontent.com,368090586626-lu2v4fapus52k6sjcs0edneglm3spuu4.apps.googleusercontent.com
```

All 3 client IDs must be added to allow authentication from Web, Debug, and Release builds.

---

### Code Implementation

**Google Sign-In Flow:**
```dart
// 1. Initialize (auto-detects Web Client from google-services.json)
await GoogleSignIn.instance.initialize();

// 2. Authenticate user
final googleUser = await GoogleSignIn.instance.authenticate();

// 3. Get ID token
final googleAuth = googleUser.authentication;
final idToken = googleAuth.idToken;

// 4. Get access token (requires scope)
const scopes = ['email'];
final clientAuth = await googleUser.authorizationClient.authorizationForScopes(scopes);
final accessToken = clientAuth.accessToken;

// 5. Sign in with Supabase (BOTH tokens required!)
await supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: idToken,
  accessToken: accessToken,
);
```

**Key Points:**
- Use `authenticate()` not `signIn()` (v7.0 change)
- Supabase requires both `idToken` AND `accessToken`
- Empty scopes `[]` not allowed - must specify at least `['email']`
- Auto-detection works better than manual `serverClientId` configuration

---

### Token Requirements: Firebase vs Supabase

| Backend | idToken | accessToken | Why? |
|---------|---------|-------------|------|
| **Firebase** | ✅ Required | ❌ Not used | Google ecosystem - trusts idToken |
| **Supabase** | ✅ Required | ✅ Required | 3rd party - needs full OAuth verification |

---

### Common Issues

**Issue 1: [28444] Developer console not set up correctly**
- **Cause**: Missing accessToken or wrong client type
- **Fix**: Ensure both tokens provided, use Web Client for serverClientId

**Issue 2: "requestedScopes cannot be null or empty"**
- **Cause**: Passing empty `[]` to `authorizationForScopes()`
- **Fix**: Specify at least `['email']` scope

**Issue 3: "signIn method not found"**
- **Cause**: Using v6.x API with v7.x package
- **Fix**: Use `authenticate()` instead of `signIn()`

---

### References

- [google_sign_in v7.0 Migration Guide](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/MIGRATION.md)
- [Supabase signInWithIdToken API](https://supabase.com/docs/reference/dart/auth-signinwithidtoken)
- [DEV_LOG.md - Google Sign-In Session](./DEV_LOG.md#session-google-sign-in-with-supabase-auth-v475)

---

## 📋 Pre-deployment Checklist

### Before Building
- [ ] Update version in `pubspec.yaml`
- [ ] Run tests: `flutter test`
- [ ] Check code quality: `flutter analyze`
- [ ] Test on multiple devices
- [ ] Verify package ID: `com.joy.bexly`

### Android Specific
- [ ] Check minimum SDK version (currently: 26)
- [ ] Verify signing configuration
- [ ] Test ProGuard rules if using

### iOS Specific
- [ ] Verify bundle ID: `com.joy.bexly`
- [ ] Update provisioning profiles
- [ ] Check minimum iOS version

---

## 📊 Post-deployment Monitoring

### Firebase Console
- Check Crashlytics for crash reports
- Monitor Analytics for user engagement
- Review Performance metrics
- URL: https://console.firebase.google.com/project/bexly-app

### Store Consoles
- Monitor user reviews
- Check crash statistics
- Review ANRs (Android)

---

## 🔧 Helper Scripts

### run_bexly.bat
Quick run script with mode selection (debug/profile/release)

### run_flutterfire.bat
Re-configure Firebase connection

### Clean Build Script
Create `clean_build.bat`:
```batch
@echo off
echo Cleaning and rebuilding Bexly...
D:\Dev\flutter\bin\flutter clean
D:\Dev\flutter\bin\flutter pub get
D:\Dev\flutter\bin\dart run build_runner build --delete-conflicting-outputs
D:\Dev\flutter\bin\flutter build apk --release
echo Build complete! Check build\app\outputs\flutter-apk\
```

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Drift Documentation](https://drift.simonbinder.eu)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Material Design](https://material.io/design)

---

*Last updated: January 2026*