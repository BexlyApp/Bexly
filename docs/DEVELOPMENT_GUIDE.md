# Bexly Development Guide

## Project Overview
**Bexly** is a personal finance and expense tracking app built with Flutter. It features offline-first functionality, multi-wallet support, and comprehensive expense management.

- **App Name**: Bexly
- **Package ID**: `com.joy.bexly`
- **Firebase Project**: `bexly-app`
- **Flutter Path**: `D:\Dev\flutter`
- **Project Path**: `D:\Projects\DOSafe`
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

## 🔥 Firebase Setup

### Project Details
- **Project Name**: Bexly
- **Project ID**: `bexly-app`
- **Project Number**: 657555385291

### Configuration Process
```bash
# 1. Login to Firebase
firebase login

# 2. Configure FlutterFire
flutterfire configure --project=bexly-app --platforms=android,ios,web

# This generates:
# - lib/firebase_options.dart
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist (when building)
```

### Enabled Services
1. **Firebase Analytics** - User behavior tracking
2. **Firebase Crashlytics** - Crash reporting
3. **Firebase Performance** - Performance monitoring

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

*Last updated: September 2025*