# Development Log

## 2026-01-02: Google Sign-In Debug Build Fix

### Problem
Google Sign-In failed with error `[28444] Developer console is not set up correctly` on debug builds.

### Root Cause
- Debug build was using `DOS-key.jks` (release keystore) with SHA-1 `B8:B5:58:78:A4:1E:59:70:69:C6:0E:97:0F:B6:33:E2:A6:4A:6A:39`
- This SHA-1 was registered in `bexly-app` Firebase project, but app uses `dos-me` for authentication
- Google Cloud Console only allows one OAuth client per SHA-1 + package name combination across all projects
- Could not create new OAuth client in `dos-me` because SHA-1 already in use by `bexly-app`

### Solution
Modified `android/app/build.gradle` to use default debug keystore for debug builds:
- **Debug build**: Uses default debug keystore at `~/.android/debug.keystore`
  - SHA-1: `79:CF:10:6C:1D:4C:E7:B1:7D:6C:CF:FC:25:E5:E1:DE:18:C1:59:C7`
  - Already registered in `dos-me` Firebase project
- **Release build**: Uses `DOS-key.jks` from `keystore.properties`
  - SHA-1: `B8:B5:58:78:A4:1E:59:70:69:C6:0E:97:0F:B6:33:E2:A6:4A:6A:39`

### Key Learnings
1. Each SHA-1 + package name can only have ONE Android OAuth client across ALL Google Cloud projects
2. Debug and release builds should use different keystores when possible
3. `google-services.json` must contain the OAuth client ID for the SHA-1 being used
4. `google_sign_in 7.x` requires `serverClientId` parameter for proper initialization

### Related Files
- `android/app/build.gradle` - Signing config
- `android/app/google-services.json` - Firebase/OAuth config (from dos-me project)
- `lib/main.dart` - Google Sign-In initialization with serverClientId
