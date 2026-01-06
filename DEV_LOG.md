# Development Log

## 2026-01-05: Bank Connections & Email Sync Improvements

### Changes Made

#### Bank Connections
1. **Local Cache for Linked Accounts**
   - Added SharedPreferences cache for linked accounts
   - Shows cached data immediately on screen load
   - Fetches fresh data from API in background
   - Better UX - no loading delay when entering screen

2. **Institution Icon Support**
   - Added `institutionIcon` field to `LinkedAccount` model
   - UI displays bank logo from Stripe when available
   - Falls back to default bank icon if no logo

3. **Disconnect Dialog → Bottom Sheet**
   - Changed from AlertDialog to bottom sheet (consistent with app design)
   - Added warning icon and better styling

4. **Stripe Badge**
   - Shows "Stripe" badge next to bank name to indicate provider

5. **Account Actions → Bottom Sheet**
   - Changed PopupMenuButton (context menu) to bottom sheet
   - Shows account info header with icon
   - Options: Sync Transactions, Disconnect
   - Sync also reloads account data to refresh icon

6. **Currency Conversion Fix**
   - Fixed daily totals mixing currencies (VND + USD)
   - Now converts all transactions to base currency before summing
   - Uses `ExchangeRateCacheNotifier` for conversion

#### Email Sync
1. **Fixed Gmail Re-authentication Issue**
   - Problem: "Sync Now" required login twice
   - Root cause: `attemptLightweightAuthentication()` returned null, but code didn't call `authenticate()`
   - Solution: Call `authenticate(scopeHint: _gmailScopes)` when lightweight auth fails
   - Then call `authorizeScopes()` if silent authorization fails

### Pending Issues
1. **Bank Logo Not Showing**
   - Backend needs to populate `institutionIcon` for existing accounts
   - New accounts should get icon from Stripe's `institution.icon.default` field
   - May need backend migration to update existing records

### Related Files
- `lib/features/bank_connections/riverpod/bank_connection_provider.dart` - Cache logic
- `lib/features/bank_connections/data/models/linked_account_model.dart` - institutionIcon field
- `lib/features/bank_connections/presentation/screens/bank_connections_screen.dart` - UI changes, bottom sheets
- `lib/features/email_sync/domain/services/gmail_api_service.dart` - Token flow fix
- `lib/features/transaction/presentation/components/transaction_grouped_card.dart` - Currency conversion
- `lib/features/transaction/presentation/components/transaction_summary_card.dart` - Currency conversion

---

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
