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
- `functions/src/index.ts`: ~3,900 lines (Telegram/Messenger bots, Stripe, AI)
- Generated DB file `lib/core/database/app_database.g.dart`: ~753 KB

### Backend reality (corrected)

**Previous assumption was wrong:** Memory said "NO Firebase" but investigation shows:

- **Firebase IS still actively used** for:
  - Cloud Messaging (FCM) — push notifications
  - Firestore — FCM tokens, platform links (Telegram/Messenger), bot analytics
  - Crashlytics — crash reporting
  - Cloud Functions — 3,900 LOC handling Telegram/Messenger webhooks, Stripe Financial Connections
- **Supabase is PRIMARY** for auth, local/cloud DB sync, edge functions
- Both coexist — Firebase handles messaging/bots, Supabase handles core data

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
  - `BEXLY_FREE_AI_KEY` (dos_sk_...) — server-side secret
- **Keys that are SAFE (designed for client-side):**
  - `STRIPE_PUBLISHABLE_KEY` (pk_live_...) — publishable by design
  - `SUPABASE_PUBLISHABLE_KEY` — anon role, RLS-protected
  - Firebase API keys — public, protected by Security Rules
  - Google OAuth Client IDs — public, PKCE flow
- **Impact:** Anyone who decompiles APK/AAB/web build can extract API keys and make billable API calls
- **Fix:** Move AI calls to server-side proxy (Cloud Function or Supabase Edge Function)
- **Scope:** Requires architectural change — NOT a quick fix

#### P0-2: Firestore rules ownership transfer risk
- **Status:** STILL RELEVANT but low-priority
- **Path:** `firestore.rules`
- **Reality:** Firestore is used for FCM tokens and platform links, not core financial data
- **Risk:** Lower than initially assessed since financial data lives in Supabase with RLS
- **Fix:** Server-side change to `firestore.rules` — outside Flutter app scope
- **Recommendation:** DEFER to dedicated security sprint

#### P0-3: Public HTTP endpoints (Cloud Functions)
- **Status:** STILL RELEVANT but complex
- **Path:** `functions/src/index.ts` (3,900 LOC)
- **Reality:** Handles Telegram/Messenger webhooks, Stripe connections — actively used
- **Fix:** Server-side auth hardening — outside Flutter app scope
- **Recommendation:** DEFER to dedicated security sprint

### P1 - High

#### P1-1: Startup path heavily serialized ← ACTIONABLE NOW
- **Status:** CONFIRMED — 17 sequential awaits, 600-1500ms blocking
- **Path:** `lib/main.dart`
- **Finding:** Firebase init is slowest single operation (100-500ms)
- **8 services can be parallelized:** GoogleSignIn, NotificationService, FCM, BackgroundService, WorkManager, AdService
- **Estimated improvement:** 35-40% reduction in time-to-first-frame
- **Fix:** Group non-critical services with `Future.wait()`

#### P1-2: Oversized static assets shipped ← ACTIONABLE NOW
- **Status:** CONFIRMED — 6.7 MB unused static font files
- **Path:** `fonts/Montserrat/static/` and `fonts/Urbanist/static/`
- **Finding:** pubspec.yaml only declares variable fonts; 36 static font files are never used
- **Additional:** Duplicate icon files (icon.png + icon.jpg = same content)
- **Fix:** Delete static font folders, remove duplicate icons

#### P1-3: Web bootstrap includes redundant wasm
- **Status:** CONFIRMED — both sqlite3.wasm (714K) and sql-wasm.wasm (640K) present
- **Path:** `web/`
- **Additional:** drift_worker.js.map (349K) is debug artifact
- **Fix:** Investigate which wasm Drift actually needs, remove debug map

#### P1-4: Monolithic Cloud Functions module
- **Status:** STILL RELEVANT but DEFER
- **Path:** `functions/src/index.ts` (3,900 LOC)
- **Recommendation:** Out of scope for this sprint

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
- P0-1: AI API key proxy (needs backend work, user input on approach)
- P0-2: Firestore rules (server-side, different repo)
- P0-3: Cloud Functions hardening (server-side)
- P1-4: Cloud Functions refactor (server-side)
- P2: CI guardrails, code splitting (future sprint)

## 5) Recommended Next Steps (Post-Optimization)

1. Create server-side AI proxy to eliminate client-side API keys
2. Audit and tighten `firestore.rules` for FCM/platform-link collections
3. Add rate limiting to Cloud Functions HTTP endpoints
4. Implement CI size budget gates in GitHub Actions
