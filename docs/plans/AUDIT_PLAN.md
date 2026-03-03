# Bexly Repository Audit Plan (Updated 2026-03-03)

## 1) Scope

- Flutter app (`lib/`, `assets/`, `web/`, `android/`, `ios/`)
- Backend/serverless (`functions/`, `supabase/functions/`)
- Build/release pipelines (`.github/workflows/*`)
- Existing docs/plans under `docs/`

## 2) Audit Snapshot (2026-03-03)

### Codebase shape

- Dart source files in `lib/`: ~517
- Asset files in `assets/`: ~229
- `functions/src/index.ts`: ~3,900 lines (LEGACY — no longer deployed)
- Generated DB file `lib/core/database/app_database.g.dart`: ~753 KB

### Backend reality (corrected)

**Flutter app Firebase usage (client-side):**
- Analytics — screen views, events, user properties
- Crashlytics — fatal error recording
- Cloud Messaging (FCM) — push notifications + token management
- Storage — receipt image uploads
- Firestore — ONLY `saveTokenToFirestore()` for FCM token; NO data storage

**Cloud Functions — NO LONGER IN USE:**
- `functions/src/index.ts` (3,900 LOC) is legacy code, not deployed
- Telegram/Messenger webhooks migrated to Supabase Edge Functions
- Firestore usage from Cloud Functions is also inactive

**Supabase is PRIMARY** for auth, local/cloud DB sync, edge functions, webhooks

### Size baseline

- Total `assets/`: ~7.7 MB
- Total `fonts/`: ~8.2 MB (only ~1.6 MB actually used — variable fonts)
- Total `web/`: ~3.4 MB
- `build/web` total: ~53 MB
- `app-release.apk`: ~63 MB

## 3) Priority Findings (Validated 2026-03-03)

### P0 - Critical

#### P0-1: Client-side AI API keys exposed in app binary
- **Status:** CONFIRMED CRITICAL
- **Path:** `.env` file bundled via `pubspec.yaml` assets
- **Keys at risk:**
  - `OPENAI_API_KEY` (sk-proj-...) — server-side secret, billable
  - `GEMINI_API_KEY` (AIzaSy...) — server-side secret, billable
  - `BEXLY_FREE_AI_KEY` (dos_sk_...) — DOS AI server key (lower risk, self-hosted)
- **Why GitHub Actions Secrets won't help:** App makes DIRECT runtime API calls
  to OpenAI/Gemini/Claude — keys must be in the app binary, not build-time secrets.
  Real fix requires a server-side AI proxy (Supabase Edge Function or Cloud Function)
- **Keys that are SAFE (designed for client-side):**
  - `STRIPE_PUBLISHABLE_KEY` (pk_live_...) — publishable by design
  - `SUPABASE_PUBLISHABLE_KEY` — anon role, RLS-protected
  - Firebase API keys — public, protected by Security Rules
  - Google OAuth Client IDs — public, PKCE flow
- **Impact:** Anyone who decompiles APK/AAB/web build can extract API keys and make billable API calls
- **Fix:** Move AI calls to server-side proxy (Cloud Function or Supabase Edge Function)
- **Scope:** Requires architectural change — NOT a quick fix

#### P0-2: Firestore rules ownership transfer risk
- **Status:** LOW PRIORITY — Flutter app barely uses Firestore
- **Path:** `firestore.rules`
- **Reality:** Flutter app only writes FCM tokens to Firestore. All financial data
  (wallets, transactions, budgets) lives in Supabase with RLS.
  Firestore is primarily used by Cloud Functions (server-side) for
  platform links, bot conversations, and AI usage tracking.
- **Risk:** Minimal for Flutter app; server-side Cloud Functions have admin access anyway
- **Fix:** Server-side change to `firestore.rules` — outside Flutter app scope
- **Recommendation:** DEFER — not a priority given minimal client-side Firestore usage

#### ~~P0-3: Public HTTP endpoints (Cloud Functions)~~
- **Status:** NO LONGER RELEVANT — Cloud Functions not deployed
- **Path:** `functions/src/index.ts` (3,900 LOC) — legacy code
- **Reality:** Webhooks migrated to Supabase Edge Functions
- **Recommendation:** Consider removing `functions/` directory to reduce confusion

### P1 - High

#### P1-1: Startup path heavily serialized ← FIXED
- **Status:** FIXED in commit `5f952bc6`
- **Path:** `lib/main.dart`
- **Fix applied:** 3-phase parallel init with `Future.wait()`

#### P1-2: Oversized static assets shipped ← FIXED
- **Status:** FIXED in commit `5f952bc6`
- **Fix applied:** Removed 36 static font files (~6.7 MB) + 2 duplicate icons (~2.2 MB)

#### P1-3: Web bootstrap includes redundant wasm
- **Status:** CONFIRMED — both sqlite3.wasm (714K) and sql-wasm.wasm (640K) present
- **Path:** `web/`
- **Additional:** drift_worker.js.map (349K) is debug artifact
- **Fix:** Investigate which wasm Drift actually needs, remove debug map

#### ~~P1-4: Monolithic Cloud Functions module~~
- **Status:** NO LONGER RELEVANT — Cloud Functions not deployed
- **Path:** `functions/src/index.ts` (3,900 LOC) — legacy code
- **Recommendation:** Remove `functions/` directory when ready

### P2 - Medium

1. **Router imports all features eagerly** — relevant for web, low priority for mobile
2. **No CI size budget gates** — no size reporting in any workflow
3. **Android APK ~63 MB** — large for emerging markets
4. **`.env` in pubspec.yaml assets** — should use build-time config instead

## 4) Execution Decision (2026-03-03)

### Execute NOW (this session):
- P1-1: Parallelize startup initialization
- P1-2: Remove unused fonts and duplicate icons
- P1-3: Clean web debug artifacts

### DEFER (requires architectural decisions):
- P0-1: AI API key proxy (needs Supabase Edge Function as proxy)
- P2: CI guardrails, code splitting (future sprint)

### NO LONGER RELEVANT:
- ~~P0-3: Cloud Functions hardening~~ — not deployed
- ~~P1-4: Cloud Functions refactor~~ — not deployed
- P0-2: Firestore rules — minimal client-side usage, low priority

## 5) Recommended Next Steps (Post-Optimization)

1. Create server-side AI proxy (Supabase Edge Function) to eliminate client-side API keys
2. Remove legacy `functions/` directory (Cloud Functions no longer deployed)
3. Implement CI size budget gates in GitHub Actions
