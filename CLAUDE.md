# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Rules
- **ALWAYS respond in Vietnamese** when working with this repository
- **ALWAYS write code comments in English**
- Documentation and code comments must be in English

## CRITICAL: Command Usage Rules
- **ALWAYS use `flutter` and `dart` commands directly** — they are in PATH
- ❌ NEVER use full paths like `D:/Dev/flutter/bin/flutter.bat` or `/d/Dev/flutter/bin/dart`

## CRITICAL: Production Safety — NEVER Run Without Explicit Approval
The following are **PERMANENTLY BANNED** unless the user explicitly says "run it":

- ❌ `supabase config push` / `supabase db push` / `supabase db reset`
- ❌ Any `supabase` CLI command that modifies production state
- ❌ `ALTER ROLE`, `ALTER TABLE`, `CREATE TABLE`, `DROP TABLE` on production
- ✅ READ-ONLY SQL (`SELECT`) is allowed without asking

**Incident (2026-03-07):** `supabase config push` ran without approval → removed `web3` and `stripe` from production API config.

## Essential Commands

```bash
# Dependencies
flutter pub get

# Run app (always target Android emulator)
flutter run -d emulator-5554

# Code generation (after modifying Drift schemas or Freezed models)
dart run build_runner build
dart run build_runner watch          # Watch mode

# Localization (after modifying .arb files)
flutter gen-l10n

# Code quality
flutter analyze
flutter test

# Build Android
flutter build apk                   # APK for direct install
flutter build appbundle              # AAB for Play Store

# iOS — MUST use GitHub Actions (cannot build on Windows)
# Push to main → GitHub Actions auto-builds
```

**Android `appbundle` warning:** "failed to strip debug symbols" is just a warning — the bundle builds successfully. Don't rebuild.

## Project Overview

Bexly is a Flutter personal finance app with offline-first architecture, cloud sync, AI chat, and multi-platform support (Android, iOS, web, desktop).

## Backend Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Auth** | Supabase (dos.me ID) | `https://dos.supabase.co` — JWT auth, social login (Google/Apple/Facebook) |
| **Local DB** | Drift/SQLite | Source of truth for offline — schema v27, 16 tables |
| **Cloud Sync** | Supabase PostgreSQL | Schema `bexly` — bidirectional sync when authenticated |
| **OAuth Tokens** | dos.me ID API | `https://api.dos.me` — centralized OAuth token management |
| **Firebase** | GCP project `dos-me` | Analytics, Crashlytics, FCM, Storage **only** — NOT for auth or data |
| **AI** | DOS AI + Gemini fallback | DOS AI direct (`api.dos.ai`), Gemini/OpenAI via Supabase Edge Function proxy (`ai-proxy`) |
| **Edge Functions** | Supabase/Deno | `ai-proxy`, `telegram-webhook`, `link-telegram`, `create-short-link` |

## Architecture Overview

### App Initialization (main.dart)
Phase-based startup: critical services first (Flutter, env, Firebase, Supabase), then auth, then remaining (WorkManager, notifications, ads). Background tasks via WorkManager isolate (`callbackDispatcher`).

### State Management
Riverpod + Hooks. Each feature uses:
- `riverpod/` — providers (state notifiers, async notifiers)
- `domain/` — models (Freezed for immutability)
- `data/repositories/` — data access layer
- `presentation/` — screens and widgets (HookConsumerWidget)

### Database (lib/core/database/)
Drift/SQLite with 16 tables, 12 DAOs, schema version 27.

**ID architecture (critical for sync):**
- Local DB uses **auto-increment integer IDs** for foreign keys
- Cloud (Supabase) uses **UUID v7 `cloud_id`** columns
- When entities re-sync, they get NEW integer IDs → dependent tables need FK repair
- Soft delete pattern: `is_deleted` boolean instead of hard DELETE

**Tables:** Users, Categories, Transactions, Wallets, Budgets, Goals, ChecklistItems, Recurrings, ChatMessages, Notifications, FamilyGroups, FamilyMembers, FamilyInvitations, SharedWallets, ParsedEmailTransactions, PendingTransactions

**After schema changes:**
1. Update table definition in `lib/core/database/tables/`
2. Add migration logic in `app_database.dart` `onUpgrade` (increment `schemaVersion`)
3. Run `dart run build_runner build`

### Sync Engine (lib/core/services/sync/)
- `supabase_sync_service.dart` — main sync (push BEFORE pull, order matters)
- `supabase_conflict_resolution_service.dart` — handles concurrent edits
- `realtime_sync_provider.dart` — live updates via Supabase realtime
- Push runs first to upload local changes, then pull fetches remote changes
- Pull logic: (1) get all including deleted, (2) delete local for soft-deleted, (3) upsert active
- Must check cloud `is_deleted` before uploading to prevent ghost resurrection

### AI Integration (lib/features/ai_chat/, lib/core/services/ai/)
- **DOS AI**: Direct to `api.dos.ai/v1` — needs `User-Agent` header (Cloudflare WAF blocks default)
- **Gemini/OpenAI/Claude**: Via Supabase Edge Function proxy (`ai-proxy`) with user JWT
- **Receipt OCR**: DOS AI vision → Gemini fallback via `FallbackOcrProvider`
- **Chat actions**: AI can create transactions, budgets, goals — uses active wallet with fallback chain

### Navigation
Go Router with 40+ named routes defined in `lib/core/router/routes.dart`. Feature routers composed in `app_router.dart`.

### Localization
14 languages via ARB files in `lib/l10n/`. Config in `l10n.yaml`. Generated output: `lib/core/localization/generated/`. Custom translations for categories (`category_name_l10n.dart`) and relative time (`time_ago_l10n.dart`).

### Feature Module Pattern
```
lib/features/<name>/
├── data/              # Models and repositories
├── domain/            # Business logic, services
├── presentation/      # Screens and components
├── riverpod/          # State providers
└── utils/             # Feature-specific utilities
```

34 feature modules including: ai_chat, auth, budget, category, dashboard, email_sync, family, gamification, goal, notification, onboarding, receipt_scanner, recurring, reports, settings, subscription, transaction, wallet.

## UI Rules (User Enforced)
- **NEVER use AlertDialog/floating popups** — ALWAYS use bottom sheet (`showModalBottomSheet`)
- Use `context.openBottomSheet()` from `popup_extension.dart` or `showModalBottomSheet`
- Confirmation sheets: `showDragHandle: true`, title + description + Cancel/Confirm buttons row
- Reusable components in `lib/core/components/`

## Key Technical Decisions

- **Multi-wallet**: Each wallet has independent currency, transactions scoped to wallets, categories shared
- **Amounts**: Stored as double with currency-specific decimal places
- **Theming**: flex_color_scheme with dark/light toggle, custom per-wallet color schemes
- **Amount entry**: Custom keyboard implementation (`lib/core/services/keyboard_service/`)
- **Background tasks**: WorkManager for email sync and recurring charges
- **Monetization**: Stripe payments, Google Mobile Ads, in-app purchases

## CI/CD (GitHub Actions)

All workflows trigger on push to `main`. Each injects `.env`, `google-services.json`, and keystore from GitHub Secrets.

| Workflow | Platform | Runner |
|----------|----------|--------|
| `android-build.yml` | APK + AAB | Ubuntu (Java 17) |
| `ios-build.yml` | iOS | macOS |
| `web-build.yml` | Web | Ubuntu |
| `linux-build.yml` | Linux | Ubuntu |
| `macos-build.yml` | macOS | macOS |
| `version-bump.yml` | Auto build number increment | Ubuntu |

**iOS cannot be built on Windows** — always use GitHub Actions.

## Security Reminders

- NEVER commit: `google-services.json`, `keystore.properties`, `*.jks`, `.env`
- NEVER use `git add .` — add files explicitly
- All sensitive files are in `.gitignore` — keep them there
