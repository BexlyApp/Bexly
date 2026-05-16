# Bexly Bot-Link Plan 4: dos.me ID Signup Callback — DEFERRED (cross-team blocked)

Date: 2026-05-17
Status: **Deferred / blocked on cross-team dependency** (autonomous decision, JOY asleep)

## Why deferred (not built)

Plan 4's substance is the no-Bexly-account path: bot emits a dos.me ID
sign-up link carrying a signed `state` (platform + chat id); after the
user creates a dos.me ID account, dos.me ID round-trips that `state` to
a Bexly `link-signup-callback` endpoint which creates `user_integrations`
and notifies the chat.

The pivotal piece — **dos.me ID accepting and round-tripping the
`state`** — is dos.me-ID-owned (DOS-Me repo / dos.me team), exactly the
lane boundary established earlier this session. It cannot be implemented
from the Bexly side, and cannot be coordinated while JOY and the dos.me
team are unavailable.

Building the Bexly-side `link-signup-callback` endpoint now would be
**speculative**: nothing can invoke it until dos.me ID supports the
state round-trip. That violates YAGNI and risks shipping an untested,
unreachable endpoint.

## Graceful degradation is already shipped

The spec (§"Cross-team dependency") explicitly defines a degraded path
for exactly this case: a plain sign-up link + "after creating your
account, generate a link code in the Bexly app and send it to the bot"
— i.e. the normal app→bot flow from Plans 2/3.

This is **already delivered**: the no-account branch in `telegram-webhook`
(Plan 2 T3) and `zalo-webhook` (Plan 3 T3) tells unlinked users without
an account to get the Bexly app (`https://bexly.app`), then generate a
6-char code in Settings and send it to the bot. That is the full,
working degraded flow. No further code is needed for users to onboard.

## When to resume Plan 4

Resume only after the dos.me team confirms dos.me ID can carry +
round-trip an opaque `state` param through signup to a redirect/callback.
Then implement: (a) `link-signup-callback` (HMAC-verify state, create
`user_integrations`, notify chat); (b) switch the no-account branch to
emit the state-bearing dos.me ID sign-up link. Spec section already
written: `docs/superpowers/specs/2026-05-16-bexly-bot-link-redesign-design.md`.

## Action taken

A coordination note was posted to DOS-Me #115 describing the required
dos.me-ID `state` round-trip contract so the team can scope it when
available. No Bexly code shipped for Plan 4 (correct: degraded path
already covers onboarding; the enhanced path is blocked + would be
speculative).
