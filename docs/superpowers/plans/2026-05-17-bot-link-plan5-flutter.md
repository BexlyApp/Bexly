# Bexly Bot-Link Plan 5: Flutter bot_integration_screen (app-generates-code UX)

> Execute via superpowers:subagent-driven-development. One cohesive UI+service change.

**Goal:** App-side UX for the verified app→bot flow: user taps "Tạo mã liên kết" → app calls `link-telegram` (generate-code mode) → shows the 6-char code + a "Mở Telegram" deep-link button + copy button → user sends it to the bot → screen polls `isLinked()` and flips to Linked.

**Architecture:** `TelegramBotService.linkTelegramAccount(telegramId)` (obsolete inbound direction) → `generateLinkCode()` (calls `link-telegram`, returns `{code, deep_link}`). `bot_integration_screen.dart` not-linked branch rewritten. `isLinked`/`getLinkedTelegramId`/`unlinkTelegramAccount` unchanged.

**Verification:** `flutter analyze` (no device E2E — JOY's emulator, JOY asleep; on-device confirmation is JOY-pending and noted). Backend already verified on beta (Plans 1-3).

---

### Task 1: Service + screen (single implementer — tightly coupled)

**Files:** Modify `lib/core/services/telegram_bot_service.dart`, `lib/features/settings/presentation/screens/bot_integration_screen.dart`.

Steps (full code in the executor dispatch): replace `linkTelegramAccount` with `generateLinkCode()`; grep callers of `linkTelegramAccount` and ensure none break (telegram_deep_link_handler uses its own invoke, not this method — leave it); rewrite the not-linked UI to generate/show code + deep-link + copy + a "Tôi đã liên kết xong - Kiểm tra" refresh button; `flutter analyze lib/core/services/telegram_bot_service.dart lib/features/settings/presentation/screens/bot_integration_screen.dart` must be clean; commit.

## Self-Review
- Service generate-code method calls `link-telegram` (now generate endpoint) → ✓
- Screen shows code + t.me deep-link + copy + status refresh; removes obsolete "open ?text=/link" instruction → ✓
- linked/unlink/isLinked unchanged → ✓
- flutter analyze clean; device E2E explicitly JOY-pending → ✓
- No backend change (Plans 1-3 cover it) → ✓
