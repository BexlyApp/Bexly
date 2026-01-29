# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quy tắc giao tiếp
- **LUÔN trả lời bằng tiếng Việt** khi làm việc với repository này
- **LUÔN viết code comments bằng tiếng Anh**
- Chỉ dùng tiếng Việt khi chat/giải thích với user
- Documentation và code comments phải bằng tiếng Anh

## CRITICAL: Command Usage Rules
- **ALWAYS use `flutter` command directly** (NOT `/d/Dev/flutter/bin/flutter` or `D:/Dev/flutter/bin/flutter.bat`)
- **ALWAYS use `dart` command directly** (NOT full paths)
- Flutter and Dart are already in PATH - use them directly
- Examples:
  - ✅ CORRECT: `flutter build apk --release`
  - ❌ WRONG: `D:/Dev/flutter/bin/flutter.bat build apk --release`
  - ✅ CORRECT: `dart run build_runner build`
  - ❌ WRONG: `/d/Dev/flutter/bin/dart run build_runner build`

## Project Overview

Bexly is a Flutter-based personal finance and budget tracking application with a focus on cross-platform sync and AI agent capabilities. The project uses a feature-based clean architecture with Riverpod for state management, Drift for local database storage, and Firebase for cloud sync and authentication.

## IMPORTANT: Firebase Configuration
**Firebase Project ID: `bexly-app`** - App sử dụng Firebase project `bexly-app` cho toàn bộ authentication, Firestore và các services. Firestore database ID là `bexly`.

## Essential Commands

### Development
```bash
# Install/update dependencies
flutter pub get

# Run the app
flutter run                    # Debug mode (default)
flutter run --profile          # Profile mode for performance analysis
flutter run --release          # Release mode

# Code generation (required after modifying Drift database schemas)
dart run build_runner build    # One-time generation
dart run build_runner watch    # Watch mode for continuous generation
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Run tests (minimal coverage currently)
flutter test
```

### Building
```bash
# Android (build locally on Windows)
flutter build apk              # APK for direct installation
flutter build appbundle        # For Play Store submission

# iOS - MUST use GitHub Actions (cannot build on Windows!)
# Merge dev to main and push → GitHub Actions auto-builds iOS
git checkout main && git merge dev && git push bexly main

# Other platforms (planned)
flutter build web              # Web version
flutter build windows          # Windows desktop
```

**IMPORTANT: Android Bundle Build Warning**
- Lệnh `flutter build appbundle` có thể hiện lỗi "failed to strip debug symbols from native libraries"
- **ĐÂY CHỈ LÀ WARNING, KHÔNG PHẢI LỖI** - Bundle vẫn được tạo thành công
- File output: `build/app/outputs/bundle/release/app-release.aab`
- KHÔNG cần build lại nhiều lần khi thấy warning này
- Kiểm tra file đã tồn tại bằng: `dir build\app\outputs\bundle\release`

**IMPORTANT: iOS Build Process**
- **KHÔNG THỂ build iOS trên Windows** - yêu cầu macOS
- Project dùng **GitHub Actions** để build iOS tự động
- Push code lên GitHub → Actions tự động build
- Check build status: https://github.com/BexlyApp/Bexly/actions

### App Icons
```bash
# Regenerate app icons after changes to flutter_launcher_icons.yaml
flutter pub run flutter_launcher_icons:main
```

## Architecture Overview

### State Management Pattern
The app uses Riverpod with Hooks for state management. Each feature typically has:
- A provider file defining the state providers
- Domain models with Freezed for immutability
- Repository pattern for data access
- UI components using HookConsumerWidget

### Database Architecture
Uses Drift (formerly Moor) for SQLite database management:
- Tables defined in `lib/core/database/tables/`
- DAOs (Data Access Objects) in `lib/core/database/daos/`
- Database instance managed through Riverpod providers
- Schema migrations tracked in `drift_schemas/`

### Navigation Structure
Uses Go Router for declarative routing:
- Routes defined in `lib/core/router/`
- Deep linking support
- Named routes for type-safe navigation

### Feature Module Pattern
Each feature in `lib/features/` is self-contained with:
```
feature_name/
├── domain/          # Business logic and models
├── presentation/    # UI screens and widgets
├── riverpod/        # State management providers
└── utils/           # Feature-specific utilities
```

## Key Technical Decisions

### Multi-Wallet Architecture
- Each wallet can have a different currency
- Transactions are scoped to individual wallets
- Wallet switching handled via dedicated UI component

### Local Storage & Offline Support
- All data stored locally using Drift/SQLite
- Works without internet connection
- Optional cloud sync via Supabase when authenticated
- Backup/restore functionality for data portability

### Theme System
- Uses flex_color_scheme for advanced theming
- Dark/light mode toggle
- Custom color schemes per wallet

### Form Handling
- Custom keyboard implementation for amount entry
- Date pickers with calendar integration
- Category picker with icon support

## Development Guidelines

### Security Best Practices (CRITICAL)

**NEVER commit sensitive files to git:**
- ❌ `google-services.json` - Contains OAuth client IDs and is environment-specific (each developer needs their own)
- ❌ `keystore.properties` - Contains keystore passwords
- ❌ `*.jks` files - Release signing keys
- ❌ `.env` files - Contains API keys for Gemini, OpenAI, Claude, etc.
- ❌ Any file with credentials, tokens, or secrets

**Why `google-services.json` should NOT be committed:**
- Contains OAuth 2.0 client IDs tied to specific SHA-1 fingerprints
- Each developer has different keystores with different SHA-1s
- Each environment (dev/staging/prod) may need different configs
- Already in `.gitignore` - keep it there
- Each developer must download their own from Firebase Console after adding their keystore's SHA-1 fingerprint

**Before EVERY commit:**
1. Run `git status` and carefully review ALL files
2. Check for `.backup`, `.json`, `.env` files
3. NEVER use `git add .` blindly - add files explicitly
4. Use `.gitignore` to prevent accidental commits

**If API key is exposed:**
1. Remove file immediately: `git rm <file>`
2. Commit removal
3. **REVOKE API key in Google Cloud Console**
4. **Generate new API key**
5. Update config with new key
6. Rewrite git history: `git filter-repo --path <file> --invert-paths`

**Incident Log:**
- 2025-11-09: Exposed Google API key `AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM` in commit `4e15da4` via file `android/app/google-services.json.dos-me.backup`. Key must be revoked.

### When Adding New Features
1. Create a new directory under `lib/features/`
2. Follow the existing feature structure pattern
3. Use Riverpod providers for state management
4. Add database tables/DAOs if persistent storage needed
5. Update router configuration for new screens

### When Modifying Database
1. Update table definitions in `lib/core/database/tables/`
2. Run `dart run build_runner build` to regenerate code
3. Handle migrations if schema changes affect existing data

### When Working with Transactions
- Transactions belong to wallets
- Categories are shared across wallets
- Date/time handling uses local timezone
- Amount stored as double with currency-specific decimal places

### Common UI Patterns
- Use components from `lib/core/components/` for consistency
- Follow Material Design guidelines with custom enhancements
- Responsive design using responsive_framework
- Custom bottom sheets for forms and pickers

## Current Development Focus

The app is in active development with focus on:
- Android platform stability (currently in Play Store beta)
- Core expense/income tracking features
- Budget and goal management
- Basic analytics and reporting

Upcoming priorities include:
- Enhanced analytics and charts
- Web and desktop platform support
- Improved test coverage
- Multi-language support via localization