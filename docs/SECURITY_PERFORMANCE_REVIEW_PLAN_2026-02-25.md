# Bexly Security + Performance Review & Plan (2026-02-25)

> 📍 **Snapshot từ 2026-02-25.** Tài liệu này là điểm chụp tại thời
> điểm review, không cập nhật theo state hiện tại. Sau ngày review:
> Firebase Cloud Functions (`functions/`) đã bị xóa hoàn toàn vì không
> còn deploy. `.env` không còn bundle vào APK (sửa 2026-04-22 sau khi
> phát hiện key leak). Khi đọc tài liệu này hãy lưu ý các thay đổi đó.

## Scope

- Flutter app (`lib/`, `web/`)
- Firebase Cloud Functions (`functions/src/index.ts`) — *(đã xóa)*
- Supabase Edge Functions (`supabase/functions/*`)
- Firebase/Supabase config and rules visible in repo

## Baseline Measurements

- `flutter analyze`: ~133.5s
- Analyzer issues: `555`
- `flutter build web --release`: ~62.9s (build succeeds)
- Warning during web build: `Unexpected wasm dry run failure (252)` (non-blocking)
- `build/web` total size (uncompressed): ~`52.97 MB`

### Local Disk Usage (observed)

- `build/`: ~`2669 MB`
- `.dart_tool/`: ~`889 MB`
- `functions/`: ~`112 MB`
- `assets/`: ~`7.12 MB`
- `web/`: ~`3.30 MB`

## Key Security Findings

### S-01 (High) Client app can bundle/load AI secrets from `.env`

Evidence:

- `.env` is included as Flutter asset: `pubspec.yaml:136`
- App loads `.env` at startup: `lib/main.dart:93`
- Client reads AI keys directly:
  - `lib/core/config/llm_config.dart:42`
  - `lib/core/config/llm_config.dart:59`
  - `lib/features/receipt_scanner/presentation/riverpod/receipt_scanner_provider.dart:32`

Impact:

- If `.env` contains real provider secrets (`OPENAI/GEMINI/CLAUDE`), they can be extracted from app/web artifacts.

Notes:

- Firebase API keys in generated Firebase config are often public-by-design, but AI provider keys are not.

### S-02 (High) Messenger webhook signature verification is bypassed on mismatch

Evidence:

- Webhook signature check exists: `functions/src/index.ts:3138`
- Invalid signature is logged but request continues:
  - `functions/src/index.ts:3143`
  - `functions/src/index.ts:3146`

Impact:

- Forged webhook events may be processed.

### S-03 (High) Public short-link endpoint lacks auth/rate-limit and accepts arbitrary redirect input

Evidence:

- Wildcard CORS: `supabase/functions/create-short-link/index.ts:6`
- Public endpoint handler: `supabase/functions/create-short-link/index.ts:11`
- Accepts user JSON directly: `supabase/functions/create-short-link/index.ts:18`
- Stores `redirect_url` as-is: `supabase/functions/create-short-link/index.ts:39`

Impact:

- Abuse/spam of short-link service
- Potential open-redirect / phishing vector (depending on resolver behavior outside this repo)

### S-04 (High/Medium) `link-telegram-web` performs account-linking using GET + cookie session without visible CSRF/state protection

Evidence:

- Reads `telegram_id` from query: `supabase/functions/link-telegram-web/index.ts:7`
- Parses cookies manually: `supabase/functions/link-telegram-web/index.ts:22`
- Extracts access token from cookie: `supabase/functions/link-telegram-web/index.ts:29`
- Uses authenticated user to insert link immediately: `supabase/functions/link-telegram-web/index.ts:50`
- Shared helper uses service role key:
  - `supabase/functions/_shared/supabase-client.ts:6`

Impact:

- Risk of unintended account linking if a logged-in user is tricked into visiting a crafted URL.

### S-05 (Medium) Supabase Telegram webhook lacks visible request verification and leaks stack traces on error

Evidence:

- Parses request JSON directly without visible signature/secret validation: `supabase/functions/telegram-webhook/index.ts:89`
- Returns error message and stack trace: `supabase/functions/telegram-webhook/index.ts:163`

Impact:

- Information leakage
- Possible webhook spoofing if no external verification is configured

### S-06 (Medium) Plaintext password field persists in local model/DB and may be logged

Evidence:

- `UserModel` contains `password` field: `lib/features/authentication/data/models/user_model.dart:12`
- Drift users table stores `password`: `lib/core/database/tables/users.dart:8`
- DAO maps password in/out of DB: `lib/core/database/daos/user_dao.dart:32`
- Session state logging may include serialized user data: `lib/features/authentication/presentation/riverpod/auth_provider.dart:58`

Impact:

- Credential exposure risk in local database and logs.

## Key Performance / Cleanup Findings

### P-01 Web bundle is heavy for initial load

Observed top files in `build/web`:

- `build/web/main.dart.js` ~`10.4 MB`
- multiple `canvaskit/*.wasm` files (large)
- `build/web/sqlite3.wasm` ~`714 KB`
- `build/web/sql-wasm.wasm` ~`639 KB`
- `build/web/drift_worker.js(.map)` included

### P-02 Large and likely redundant image assets are shipped

Examples:

- `assets/icon/icon.png` ~`1.1 MB`
- `assets/icon/icon.jpg` ~`1.1 MB`
- `assets/icon/icon-transparent-full.png` ~`1.1 MB`
- large splash images (4x variants) are present in web build

### P-03 Font footprint is non-trivial

Evidence:

- Montserrat variable fonts are included via `pubspec.yaml:154`
- Web build contains large font assets (Montserrat variable files)

### P-04 Analyzer debt is high and slows maintenance/optimization

- `555 issues` across unused imports, debug prints, deprecated APIs, and framework misuse warnings
- This increases noise and makes performance/security-focused changes harder to validate

### P-05 Large local cache/build artifacts and ignored files can be cleaned safely

`git clean -ndX` preview shows substantial removable generated/cache/log files, including:

- `.dart_tool/`
- `build/`
- logs (`*.log`)
- generated folders (`functions/lib`, `functions/node_modules`, etc.)

## Repo / Project Cleanup Findings (Additional Review)

### R-01 `.gitignore` currently hides important infra/project files (process risk + cleanup risk)

Observed ignored patterns include files/directories that are often part of project source/config:

- `firebase.json`: `.gitignore:76`
- `firestore.rules`: `.gitignore:85`
- `firestore.indexes.json`: `.gitignore:86`
- `public/`: `.gitignore:87`
- `functions/package.json`: effectively ignored by `package.json` pattern at `.gitignore:75`
- `functions/package-lock.json`: effectively ignored by `package-lock.json` pattern at `.gitignore:74`

Impact:

- Team config drift (infra config changes may stay local only)
- `git clean -fdX` can remove files that look like project source/config
- Harder onboarding/reproducibility for Firebase/functions setup

### R-02 Duplicate Supabase project structures exist (`supabase/` and `supabase/supabase/`)

Evidence:

- Both contain `config.toml` and `migrations/`:
  - `supabase/config.toml`
  - `supabase/supabase/config.toml`
  - `supabase/migrations/*`
  - `supabase/supabase/migrations/*`

Migration filename comparison shows divergence (not identical sets), increasing confusion over source of truth.

Impact:

- Incorrect migration path used during deploy/reset
- Team confusion over active config
- Risk of applying wrong schema state

### R-03 Temporary Claude/Codex artifacts remain under `supabase/`

Evidence:

- Multiple temp marker files in `supabase/`: `supabase/tmpclaude-*`
- Additional temp dirs/files: `supabase/.temp`, `supabase/supabase/.temp`

Impact:

- Repo clutter and accidental misuse as “real” project files

### R-04 Untracked legacy/placeholder Supabase function folders exist (5 empty dirs)

Observed under `supabase/functions/`:

- `ai-chat/`
- `messenger-webhook/`
- `stripe-complete-connection/`
- `stripe-create-session/`
- `stripe-sync-transactions/`

Current scan shows these are empty and untracked.

Impact:

- Creates uncertainty about active vs deprecated implementation
- Slows code navigation and deployment review

### R-05 Root temp/log files accumulate (local clutter)

Examples observed in repo root:

- `.pipeflutter_r`
- `temp_db.db`
- `test_webhook.json`
- `custom_lint.log`
- `final_test.log`
- `flutter_output.log`
- `flutter_google_signin_debug.log`
- `flutter_supabase_debug.log`
- `nul` (Windows artifact; path is awkward to manage)

Impact:

- No direct runtime impact, but noisy workspace and accidental confusion in manual review

### R-06 Web source contains generator/dev artifacts

Evidence:

- `web/drift_worker.js.map`
- `web/drift_worker.js.deps`

Impact:

- Source clutter
- Possible accidental shipping of dev/debug artifacts if build/deploy pipeline copies raw `web/` unexpectedly

## Additional Observations

- `web/index.html` loads Facebook SDK globally: `web/index.html:148`
- No CSP visible in repo `web/index.html` (verify if headers are added at CDN/edge)
- `web/index.html` includes `sql-wasm.js`: `web/index.html:42` (expected for Drift web, but contributes to payload)
- `.gitignore` already ignores many sensitive/generated files, including `.env`, `*.key`, `build/`:
  - `/.gitignore:2`
  - `/.gitignore:35`
  - `/.gitignore:40`
  - `/.gitignore:90`

## Prioritized Plan

### Phase 1 - Security Hotfixes (Immediate)

1. Remove AI provider secrets from client/runtime bundle.
2. Stop shipping `.env` as Flutter asset for production builds.
3. Enforce Messenger webhook signature verification (reject on mismatch).
4. Harden `create-short-link`:
   - auth (or signed request)
   - rate limiting / abuse controls
   - strict allowlist validation for `redirect_url`
   - narrower CORS policy
5. Redesign `link-telegram-web` linking flow to include CSRF/state/nonce and explicit confirmation step (POST).
6. Remove stack traces from HTTP responses in Supabase functions.

### Phase 2 - Quick Performance Wins / Cleanup (1-2 days)

1. Create a safe cleanup script for local artifacts/logs.
2. Remove duplicate icon assets and compress oversized PNGs/WebP where possible.
3. Review whether web source maps/dev artifacts should ship in production (`drift_worker.js.map` etc.).
4. Load Facebook SDK conditionally/lazily instead of global page load.
5. Remove temp marker files (`tmpclaude-*`, local logs, test payloads) and empty legacy folders after confirmation.
6. Rationalize `.gitignore` so local junk is ignored but real infra/project files are versioned intentionally.

### Phase 2.5 - Repo Hygiene / Source of Truth Cleanup (1 day)

1. Decide canonical Supabase project root (`supabase/` vs `supabase/supabase/`).
2. Archive/remove duplicate migrations/config after verification.
3. Remove empty untracked Supabase function directories or add README indicating future placeholders.
4. Add `.gitkeep` only where empty folders are intentionally reserved.
5. Document cleanup conventions (what is safe to delete, what must remain tracked).

### Phase 3 - Web Bundle Optimization (2-4 days)

1. Run size analysis (`flutter build web --analyze-size`) and document top contributors.
2. Review renderer strategy for target deployment (avoid shipping unnecessary rendering artifacts where possible).
3. Optimize fonts:
   - subset
   - reduce variants/weights
4. Reassess heavy assets/data packages (e.g., flags/resources) and use subset alternatives if feasible.
5. Lazy-init heavy features/routes (AI, scanner, charts) where architecture permits.

### Phase 4 - Code Health / Analyzer Debt Reduction (Parallel)

1. Remove `unused import` / `unused variable` warnings in batches.
2. Replace `print` with structured logger + redaction rules.
3. Address deprecated APIs that affect compatibility/perf.
4. Triage framework misuse warnings (Riverpod protected member usage, etc.).

### Phase 5 - Guardrails / CI

1. Add CI checks:
   - `flutter analyze`
   - secret scan
   - optional web bundle size budget
2. Add webhook/public-endpoint security checklist (signature/auth/rate-limit/logging).
3. Document approved patterns for client vs server secrets.
4. Add repo hygiene checks/scripts (safe cleanup, ignore policy validation, optional temp-file scan).

## Suggested Execution Order (Pragmatic)

1. Fix `S-02` (webhook signature bypass)
2. Fix `S-01` (client AI secrets / `.env` asset)
3. Fix `S-03` (short-link endpoint)
4. Fix `S-04` (link flow CSRF/state)
5. Quick cleanup + asset dedupe (`P-02`, `P-05`)
6. Bundle analysis and deeper optimization (`P-01`, `P-03`)

## Open Questions / Verify at Runtime

1. Are CSP/security headers applied at CDN/hosting edge for web?
2. Does `id.dos.me` short-link resolver already enforce a redirect allowlist?
3. Are untracked `supabase/functions/*` folders legacy or active work-in-progress?
4. Which Supabase directory is the canonical source of truth for deploys (`supabase/` vs `supabase/supabase/`)?
