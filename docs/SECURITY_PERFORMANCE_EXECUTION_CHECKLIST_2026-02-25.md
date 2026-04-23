# Bexly Security + Performance Execution Checklist (2026-02-25)

Reference: `docs/SECURITY_PERFORMANCE_REVIEW_PLAN_2026-02-25.md`

## Phase 1 - Security Hotfixes (Immediate)

### S-02 Messenger webhook signature bypass

- [ ] Remove debug bypass that continues processing on invalid signature (`functions/src/index.ts`)
- [ ] Return `401/403` immediately when signature verification fails
- [ ] Reduce sensitive request logging (no raw body dumps in production)
- [ ] Add test case / manual verification for valid and invalid webhook signatures

### S-01 Client AI secrets / `.env` bundling

- [ ] Remove `.env` from Flutter assets in production (`pubspec.yaml`)
- [ ] Audit all client reads of `OPENAI_API_KEY`, `GEMINI_API_KEY`, `CLAUDE_API_KEY`
- [ ] Move AI provider calls behind backend/edge proxy where secrets stay server-side
- [ ] Keep only non-secret client config in app-delivered env/config
- [ ] Add guard to prevent app startup from requiring secret env vars on client

### S-03 `create-short-link` endpoint hardening

- [ ] Add request auth (JWT/session/signed request) to `supabase/functions/create-short-link`
- [ ] Add input validation schema for `tg_token` and `redirect_url`
- [ ] Add redirect allowlist (host/path policy)
- [ ] Replace `Access-Control-Allow-Origin: *` with approved origins
- [ ] Add rate limiting / abuse throttling (edge/CDN/app-layer)
- [ ] Add expiration + one-time-use policy validation (if resolver supports)
- [ ] Add audit logging without leaking sensitive tokens

### S-04 `link-telegram-web` CSRF/state protection

- [ ] Introduce state/nonce flow for linking requests
- [ ] Change state-changing action to explicit POST confirmation (not implicit GET link)
- [ ] Bind state to user session and expire state token
- [ ] Validate `telegram_id` format strictly
- [ ] Review use of service-role client and minimize privilege where possible
- [ ] Add conflict and replay test cases

### S-05 Supabase Telegram webhook hardening

- [ ] Add webhook request verification (shared secret / signature / Telegram secret token header)
- [ ] Stop returning stack traces in HTTP responses
- [ ] Return generic error body for production
- [ ] Redact sensitive values in logs

### S-06 Plaintext password local storage/logging

- [ ] Remove `password` from local `UserModel` if no longer needed
- [ ] Remove `password` column from local Drift `users` table (migration required)
- [ ] Stop serializing/logging full user object with sensitive fields
- [ ] Verify login/session flow still works with Supabase-only auth
- [ ] Add migration/backward compatibility path for existing local DBs

## Phase 2 - Quick Performance Wins / Cleanup (1-2 days)

### Local cleanup / tooling

- [ ] Create `scripts/cleanup-safe.ps1` for cache/log/generated artifacts
- [ ] Include dry-run mode
- [ ] Exclude important local config files from accidental deletion
- [ ] Document cleanup usage in `docs/` or `README`
- [ ] Add targeted cleanup for root temp/log files (`*.log`, `temp_db.db`, `test_webhook.json`, `.pipeflutter_r`)
- [ ] Add targeted cleanup for `supabase/tmpclaude-*` and `.temp` directories
- [ ] Add targeted cleanup for `build/`, `.dart_tool/`, and generated `functions/lib`

### Asset cleanup (high ROI)

- [ ] Identify duplicate icon assets (`assets/icon/*`)
- [ ] Remove unused image variants from `assets/`
- [ ] Compress oversized PNG/JPG assets (lossless or visually acceptable lossy)
- [ ] Rebuild web and compare `build/web` size before/after

### Web page bootstrap hygiene

- [ ] Make Facebook SDK load conditional/lazy (`web/index.html`)
- [ ] Verify `sql-wasm.js` is required for all web flows; document if yes
- [ ] Review whether source maps/dev artifacts should ship in production
- [ ] Review/remove `web/drift_worker.js.map` and `web/drift_worker.js.deps` from source if not required

### Repo structure / source-of-truth cleanup (new)

- [ ] Decide canonical Supabase root: `supabase/` vs `supabase/supabase/`
- [ ] Compare and reconcile migration sets between both directories
- [ ] Archive/remove duplicate Supabase config/migrations after verification
- [ ] Remove empty legacy Supabase function folders (`ai-chat`, `messenger-webhook`, `stripe-*`) if deprecated
- [ ] Add placeholders (`.gitkeep`/README) only for intentionally empty directories
- [ ] Document active deployment paths for Supabase and Firebase

### `.gitignore` hygiene (new)

- [ ] Review overbroad ignores that hide project configs (`firebase.json`, `firestore.rules`, `firestore.indexes.json`, `public/`)
- [ ] Review generic `package.json` / `package-lock.json` ignore rules (avoid hiding `functions/` and `mcp-server/` manifests unintentionally)
- [ ] Split “local machine junk” vs “project source generated” sections in `.gitignore`
- [ ] Add comments for intentionally ignored infra files (if any are truly local-only)
- [ ] Validate with `git status --ignored` after changes

## Phase 3 - Web Bundle Optimization (2-4 days)

### Measurement

- [ ] Run `flutter build web --release --analyze-size`
- [ ] Save size reports in `docs/` (or attach summary)
- [ ] Identify top package/module contributors in `main.dart.js`

### Rendering/runtime strategy

- [ ] Confirm target renderer strategy for deployment (CanvasKit/SKWasm tradeoffs)
- [ ] Test load/perf on representative low-end mobile browser
- [ ] Decide if current WASM assets are all required for production

### Fonts and package assets

- [ ] Audit actually-used font families/weights
- [ ] Subset or reduce font variants
- [ ] Review `country_flags` asset impact and alternatives/subsets
- [ ] Rebuild and compare size/perf metrics

### Feature loading strategy

- [ ] Identify heavy features for lazy init (AI/scanner/charts)
- [ ] Delay non-critical service initialization on app startup
- [ ] Measure startup time before/after changes

## Phase 4 - Code Health / Analyzer Debt (Parallel)

### Batch 1 (safe auto-fixes / low risk)

- [ ] Remove unused imports
- [ ] Remove unused local variables
- [ ] Replace debug `print` with logger (with levels)
- [ ] Re-run `flutter analyze` and capture issue count

### Batch 2 (compatibility/deprecation)

- [ ] Replace deprecated `withOpacity` usages
- [ ] Replace deprecated Material surface color APIs
- [ ] Update deprecated Workmanager debug configuration
- [ ] Re-test affected screens

### Batch 3 (framework correctness)

- [ ] Triage Riverpod protected member misuse warnings
- [ ] Fix `use_build_context_synchronously` warnings in async flows
- [ ] Review unreachable/default switch cases and dead null-aware expressions

## Phase 5 - Guardrails / CI

### Security guardrails

- [ ] Add secret scan to CI (or pre-commit)
- [ ] Add webhook endpoint checklist (signature/auth/rate-limit/log redaction)
- [ ] Document server-only secrets policy (AI keys, service-role keys)

### Performance guardrails

- [ ] Add optional web bundle size budget check (threshold-based)
- [ ] Track `flutter analyze` issue count trend
- [ ] Add periodic dependency review cadence (`flutter pub outdated`, npm audit)
- [ ] Add optional repo hygiene check (temp-file scan / duplicate-folder warning)

## Suggested Assignment / Priority Labels

- `P0`: S-02, S-01, S-03
- `P1`: S-04, S-05, S-06
- `P2`: P-02, P-05, web bootstrap hygiene
- `P3`: deep bundle optimization + analyzer debt cleanup

## Progress Log

- [ ] Phase 1 started
- [ ] Phase 1 completed
- [ ] Phase 2 completed
- [ ] Phase 3 completed
- [ ] Phase 4 completed
- [ ] Phase 5 completed
