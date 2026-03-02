# Bexly Optimization Plan (Performance + Filesize)

Updated: 2026-03-03
Owner: Core app team
Status: Phase 1 in execution

## 1) Goals

1. Reduce shipped asset size by removing unused fonts (~6.7 MB savings)
2. Improve cold start by parallelizing non-critical init (target: 35% faster)
3. Clean web debug artifacts from production path
4. Establish baseline for future CI size budgets

## 2) Baseline Metrics (2026-03-03)

- `assets/` total: ~7.7 MB (222 category icons, 5 app icons, 1 lottie, 1 JSON)
- `fonts/` total: ~8.2 MB (only ~1.6 MB actually declared in pubspec.yaml)
- `web/` total: ~3.4 MB
- `app-release.apk`: ~63 MB
- Startup blocking time: ~600-1500ms (17 sequential awaits)

### Font breakdown
- Montserrat Variable (USED): 685K + 673K = 1.4 MB
- Montserrat Static (UNUSED): 18 files = ~5.9 MB
- Urbanist Variable (USED): 84K + 81K = 165K
- Urbanist Static (UNUSED): 18 files = ~792K
- **Total unused fonts: ~6.7 MB**

### Icon breakdown
- `icon.png`: 1.2 MB — NOT referenced in code
- `icon.jpg`: 1.2 MB — NOT referenced in code
- `icon-transparent-full.png`: 1.2 MB — USED in splash_screen.dart
- `Bexly-Logo-no-text-1024.png`: 811K — USED in onboarding
- `Bexly-logo-no-bg.png`: 202K — check usage

### Startup sequence (pre-runApp)
1. WidgetsBinding + Splash [sync, <1ms]
2. dotenv.load() [await, 10-50ms] — NON-CRITICAL
3. NumberFormatNotifier.initFromPrefs() [await, 10-50ms] — CRITICAL
4. SystemChrome.setPreferredOrientations() [await, 5-20ms] — NON-CRITICAL
5. SupabaseInitService.initialize() [await, 50-200ms] — CRITICAL
6. FirebaseInitService.initialize() [await, 100-500ms] — CRITICAL (slowest!)
7. GoogleSignIn.initialize() [await, 50-100ms] — NON-CRITICAL
8. PackageInfoService.init() [await, 10-30ms] — CRITICAL
9. NotificationService.initialize() [await, 5-50ms] — NON-CRITICAL
10. FirebaseMessagingService.initialize() [await, 100-300ms] — NON-CRITICAL
11. BackgroundService.initialize() [await, 20-50ms] — NON-CRITICAL
12. Workmanager().initialize() [await, 20-50ms] — NON-CRITICAL
13. SharedPreferences.getInstance() [await, 20-100ms] — CRITICAL
14. AdService().initialize() [await, 20-50ms] — NON-CRITICAL

**CRITICAL services (must be sequential): 5 services, ~290-880ms**
**NON-CRITICAL services (can parallelize): 8 services, ~280-670ms**

## 3) Workstreams

### WS-A: Remove Unused Fonts and Duplicate Icons [EXECUTE NOW]

Tasks:
- Delete `fonts/Montserrat/static/` folder (18 files, ~5.9 MB)
- Delete `fonts/Urbanist/static/` folder (18 files, ~792K)
- Remove `assets/icon/icon.png` and `assets/icon/icon.jpg` (unused duplicates)
- Verify no code references to removed files

Risk: LOW — pubspec.yaml only declares variable fonts
Expected savings: ~8.1 MB from source, proportional reduction in APK/web

### WS-B: Web Debug Artifact Cleanup [EXECUTE NOW]

Tasks:
- Remove `web/drift_worker.js.map` (349K debug source map)
- Investigate sql-wasm.wasm vs sqlite3.wasm overlap (defer removal until tested)

Risk: LOW for source map removal
Expected savings: ~349K immediately

### WS-C: Startup Parallelization [EXECUTE NOW]

Tasks:
- Keep critical services sequential: NumberFormat → Supabase → Firebase → PackageInfo → SharedPreferences
- Batch non-critical services with `Future.wait()`:
  - GoogleSignIn, NotificationService, FCM, BackgroundService, Workmanager, AdService
- Move dotenv.load() and SystemChrome before critical path (they're fast, keep sequential)

Expected improvement: ~35% reduction in pre-runApp blocking time

### ~~WS-D: Code Splitting~~ [SKIP]

Rationale: Deferred imports primarily benefit web. App is mobile-first (Android Play Store beta). Revisit when web becomes a priority target.

### ~~WS-E: CI Guardrails~~ [DEFER]

Rationale: Useful but requires careful CI workflow changes. Not blocking for current optimization work. Add in a dedicated CI sprint.

## 4) Execution Order

### Phase 1: Quick wins (this session)
1. WS-A: Delete unused font files and duplicate icons
2. WS-B: Remove web debug artifacts
3. Verify build still works after cleanup

### Phase 2: Performance (this session)
4. WS-C: Refactor main.dart startup to parallelize non-critical services
5. Verify app launches correctly on emulator

### Deferred
- WS-D, WS-E: Future sprints
- AI API key proxy: Separate security sprint (requires backend changes)

## 5) Risk Register

1. Removing font files could break text rendering if any code references static font files directly
   - Mitigation: grep codebase for font file references before deletion
2. Parallelizing startup could cause race conditions if services have hidden dependencies
   - Mitigation: test on emulator, check for crashes in logcat
3. Removing sql-wasm could break Drift web DB
   - Mitigation: defer until web testing is possible; only remove source map for now

## 6) Measurement

After execution, capture:
1. `fonts/` directory size (before vs after)
2. `flutter analyze` passes
3. App launches successfully on emulator
4. No new crash logs in logcat
