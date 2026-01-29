# Bexly Codebase Audit Plan

Scope
- Flutter app, Firebase/Firestore rules, Cloud Functions, and core configs.
- Review focused on security, reliability, performance, architecture, and best practices.
- Assumptions: current working tree reflects intended behavior; secrets were not inspected.

Priority Legend
- P0: Critical risk or exploit potential.
- P1: High impact risk or major reliability defect.
- P2: Medium impact issue or maintainability/perf concern.
- P3: Low impact or cleanup.

Findings (ranked)

P0-1 Firestore rules allow ownership change on update
- Location: firestore.rules
- Issue: `allow read, write: if request.auth.uid == resource.data.userId` allows an owner to update `userId` and transfer ownership because `request.resource.data.userId` is not checked.
- Impact: privilege escalation and data exfiltration if a user transfers docs to another user ID.
- Recommendation: split read/update/delete rules, enforce immutability, and validate request resource:
  - `allow read: if request.auth.uid == resource.data.userId`
  - `allow update: if request.auth.uid == resource.data.userId
     && request.resource.data.userId == resource.data.userId`
  - `allow create: if request.auth.uid == request.resource.data.userId`
  - Apply to `wallets`, `transactions`, and `user_platform_links`.

P0-2 Public HTTP functions can be abused
- Location: functions/src/index.ts
- Issue: `aiHealthCheck` and `updateTelegramCommands` are unauthenticated `onRequest` endpoints that can burn AI quota and modify bot commands.
- Impact: cost exposure, operational disruption, and potential abuse.
- Recommendation: enforce auth (IAM, App Check, or shared secret header), rate limit, and/or convert to `onCall` with auth checks.

P1-1 FCM token and message data are logged in production
- Location: lib/core/services/firebase_messaging_service.dart
- Issue: logs include FCM token and message payloads.
- Impact: sensitive token leakage in logs and device diagnostics.
- Recommendation: guard logs behind `kDebugMode`, redact tokens, or remove in release builds.

P1-2 Plaintext password stored locally
- Location: lib/core/database/tables/users.dart, lib/features/authentication/data/models/user_model.dart
- Issue: `password` is persisted in local DB and model.
- Impact: local compromise exposes user credentials.
- Recommendation: remove password persistence if not required, or store only hashes with salt using secure storage.

P1-3 Firestore rules do not cover `/users` while app writes to it
- Location: firestore.rules, lib/core/services/firebase_messaging_service.dart
- Issue: app writes FCM token to `users/{userId}`, but rules do not include this path.
- Impact: FCM token sync likely fails in production.
- Recommendation: add rules for `/users/{userId}` allowing owner to read/write specific fields (e.g., `fcmToken`, timestamps).

P1-4 Public webhook endpoints do not verify caller authenticity
- Location: functions/src/index.ts
- Issue: `telegramWebhook` and `messengerWebhook` accept requests without verifying a shared secret or signature.
- Impact: possible spoofed webhook events.
- Recommendation: verify `X-Telegram-Bot-Api-Secret-Token` or request signature and reject mismatches.

P2-1 Monolithic Cloud Functions file
- Location: functions/src/index.ts
- Issue: 3k+ lines mixing AI, bot handlers, payments, and utilities.
- Impact: higher defect rate and harder testing.
- Recommendation: split by domain (ai/, telegram/, messenger/, payments/, utils/) and add unit tests for parsing and currency conversion.

P2-2 Unbounded in-memory caches in Functions
- Location: functions/src/index.ts (processedMessageIds, pendingTransactions)
- Issue: Sets/Maps grow without TTL or size limits.
- Impact: memory bloat and cold start churn under load.
- Recommendation: use LRU with max size or external store (Firestore/Redis) with TTL.

P2-3 Startup does heavy serial initialization
- Location: lib/main.dart
- Issue: multiple network initializations run sequentially before `runApp`.
- Impact: slower cold start and perceived app latency.
- Recommendation: parallelize non-critical init via `Future.wait` and defer optional services until after first frame.

P2-4 Firestore rules lack schema validation
- Location: firestore.rules
- Issue: rules allow any fields and values.
- Impact: data integrity issues and unexpected app behavior.
- Recommendation: validate required fields and types via `request.resource.data.keys()` and explicit checks.

P2-5 Excessive debug logging in production paths
- Location: lib/core/services/firebase_messaging_service.dart, functions/src/index.ts
- Issue: verbose logs with user content and IDs.
- Impact: log noise, privacy exposure, and higher costs.
- Recommendation: add log levels and redaction; disable verbose logs in release.

P3-1 TODO stubs left in feature screens
- Location: lib/features/family/presentation/screens/*.dart and others listed by rg
- Issue: placeholder actions exist in production paths.
- Impact: user flows appear complete but do nothing.
- Recommendation: track as issues and add guard UI (disabled buttons with tooltip).

Recommended Next Steps (short-term)
- Fix Firestore rules (P0-1, P1-3) and protect public HTTP functions (P0-2).
- Remove or mask sensitive logging (P1-1, P2-5).
- Decide on password storage strategy and migrate accordingly (P1-2).

Recommended Next Steps (mid-term)
- Refactor Cloud Functions into modules (P2-1) and add unit tests for parsing/conversion.
- Add TTL/LRU to in-memory caches (P2-2).
- Rework startup init to improve time-to-first-frame (P2-3).
