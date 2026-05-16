# Bexly Bot-Link Redesign — Design Spec

Date: 2026-05-16
Status: Approved (direction B + corrected app→bot code direction)

## Problem & Context

Bexly's Telegram/Zalo channels are broken at the link-resolution layer. Six
Supabase edge functions (`telegram-webhook`, `zalo-webhook`, `link-telegram`,
`link-telegram-web`, `link-zalo`, `unlink-telegram`) read/write
`bexly.user_integrations` and `bexly.bot_link_codes`. Both tables were
destroyed as **collateral of the 2026-04-30 `DROP SCHEMA bexly CASCADE`
incident** and never recreated (schema recovered empty 2026-05-10). The
DOS-AI team confirmed (2026-05-16) this was accidental, NOT a consolidation
into `dosai.shared_bot_links` (that is a separate, pre-existing,
api-gateway-owned, currently-churning table; not a stable external contract;
the DOS agent platform does not support external non-container agents, so
Bexly cannot register into it today).

Consequence today: `getUserId()` always returns null → the hackathon
demo-account picker is shown → linking fails ("Failed to switch") → messages
never reach the (verified-working) Bexly Agent.

The Bexly Agent core itself is verified end-to-end on prod (channel-secret
auth + Mastra memory + DOS AI LLM + MCP tools + SSE). Only this
link-resolution layer is broken.

## Decision

**Option B**: Bexly owns its link tables. Recreate `bexly.user_integrations`
+ `bexly.bot_link_codes` as a **registered migration** (applied to prod via
the DOS-Me migration flow, same channel as `0001` — registered so future
cleanup migrations preserve them, per the 2026-04-30 lesson). Keep Bexly's
edge-function webhooks. Do NOT touch `dosai.shared_bot_links`. Re-evaluate
Option A only if/when the DOS platform officially offers external-agent
registration as a supported contract.

## Canonical Link Flow (corrected: code generated in APP, consumed by BOT)

1. **App** (authenticated Bexly user): Settings → Telegram → "Liên kết" →
   calls the link edge function in *generate* mode → inserts
   `bot_link_codes(code, user_id=<bexly user>, platform='telegram',
   expires_at)` → app displays the 6-char code **and** a deep-link
   `https://t.me/<bot_username>?start=<code>` with a copy button.
2. **User in Telegram**: taps the deep-link (bot receives `/start <code>`)
   **or** pastes the bare code as a message.
3. **telegram-webhook**: extracts the code (from `/start` start-param or
   message text) → looks up `bot_link_codes` by `code` where
   `expires_at > now()` → reads `user_id` → upserts
   `user_integrations(user_id, platform='telegram',
   platform_user_id=<telegram chat id>, linked_at, last_activity)` →
   deletes the consumed code → replies "✅ Đã liên kết tài khoản Bexly!".
4. **Linked user** messages → `getUserId()` returns `user_id` → routed to
   the Bexly Agent (existing, working path).
5. **Telegram user with NO Bexly account** (messages bot, not linked, no
   valid code) → bot replies with a **dos.me ID sign-up link** carrying a
   signed state that encodes `platform='telegram'` + the Telegram chat id
   (+ short TTL). The user creates a dos.me ID account (the centralized DOS
   identity that Bexly auth uses). On signup completion, a callback
   consumes the state → creates `user_integrations(user_id=<newly created
   Bexly user>, platform='telegram', platform_user_id=<chat id>)` → then
   notifies the Telegram chat ("✅ Tài khoản đã tạo & liên kết!"). No
   separate code step for the no-account case — signup + callback links
   directly. (Recover the pre-demo-picker sign-up copy/links from
   `git log -- supabase/functions/telegram-webhook` as a starting point.)

   Cross-team dependency: dos.me ID signup must accept and round-trip the
   `state` param to the callback. The dos.me-ID-side change is
   DOS-Me-owned (coordinate via the DOS-Me flow, like migrations); the
   Bexly side owns (a) the bot emitting the state-bearing link and (b) the
   callback endpoint that creates `user_integrations` + notifies the
   chat. State is HMAC-signed + short-TTL to prevent forgery/replay.

Zalo follows the identical pattern (`platform='zalo'`), reusing
`zalo-webhook` + `link-zalo`.

## Goals / Non-Goals

**Goals**: restore Telegram + Zalo linking; one canonical code+deeplink
flow; remove the hackathon demo-account picker; registered migration so it
survives cleanups; Telegram→Agent E2E works for a real linked user.

**Non-Goals**: Tingee/open-banking; migrating to `dosai.shared_bot_links`
or the DOS agent platform; changing the Agent core; multi-account linking
(one platform account ↔ one Bexly user stays the invariant).

**Cross-team dependency**: the no-account path needs dos.me ID signup to
accept + round-trip a signed `state` to the Bexly callback. The
dos.me-ID-side change is DOS-Me-owned (coordinate via the DOS-Me flow,
same as registered migrations). Bexly owns the state-bearing link and the
callback endpoint. If dos.me-ID state round-trip is not yet available,
the no-account branch degrades gracefully to a plain dos.me ID sign-up
link + "after creating your account, generate a link code in the Bexly
app" instruction (the normal app→bot flow).

## Data Model (exact, reconstructed from all call-sites)

```sql
-- bexly.user_integrations  (one platform account ↔ one Bexly user)
user_id           uuid        NOT NULL
platform          text        NOT NULL CHECK (platform IN ('telegram','zalo'))
platform_user_id  text        NOT NULL          -- stringified chat/user id
linked_at         timestamptz NOT NULL DEFAULT now()
last_activity     timestamptz NOT NULL DEFAULT now()
PRIMARY KEY (platform, platform_user_id)
INDEX user_integrations_user_id_idx (user_id)    -- unlink WHERE user_id+platform

-- bexly.bot_link_codes  (app-generated, short-lived; consumed by bot)
code         text        NOT NULL
user_id      uuid        NOT NULL                -- Bexly user who generated it
platform     text        NOT NULL CHECK (platform IN ('telegram','zalo'))
expires_at   timestamptz NOT NULL DEFAULT now() + interval '10 minutes'
created_at   timestamptz NOT NULL DEFAULT now()
PRIMARY KEY (code)                                -- globally unique; lookup is by code
```

`code` is a random 6-char base36 string, single-use (deleted on consume).
`PRIMARY KEY (code)` covers the bot's lookup; the `.eq('platform', ...)`
in the consume query is a cheap filter on the PK-fetched row, so no
separate composite index is needed. On the rare PK collision at
generation, regenerate the code (bounded retry).

Schema-direction change vs the old code: `bot_link_codes` is keyed by
`code` and carries `user_id` (the generating Bexly user), NOT
`platform_user_id` (the Telegram/Zalo id is unknown at generation time).
The old edge-function generate/consume logic must be rewritten accordingly.

## RLS

- `user_integrations`: RLS ON. Policy `auth.uid() = user_id` for
  select/insert/delete (app may read/manage its own links). Service-role
  (webhooks) bypasses RLS.
- `bot_link_codes`: RLS ON, **no public policy** (ephemeral internal;
  accessed only by service-role edge functions). App generates codes via
  the link edge function, not by direct table access.

## Migration & Registration

- File: `supabase/migrations/0003_recreate_bexly_bot_link_tables.sql` in the
  Bexly repo, idempotent (`CREATE TABLE IF NOT EXISTS`, guarded policy
  creation).
- Registered for prod via the DOS-Me migration flow (DOS-Me issue/PR, same
  channel as `0001`/`0002`). dos.me applies to prod
  `gulptwduchsjcsbndmua`. The beta branch is provisioned the same way.
- Idempotent so re-application is safe.

## Edge-Function Changes

- **link-telegram / link-zalo**: become the *generate-code* endpoint —
  authenticated app user → insert `bot_link_codes(code, user_id,
  platform, expires_at)` → return `{ code, deep_link }`. Drop the old
  inbound telegram_id/token paths that assumed bot-generated codes.
- **telegram-webhook**: handle `/start <code>` (deep-link start-param) and
  a bare code message → consume `bot_link_codes` → upsert
  `user_integrations` → confirm. Remove `DEMO_ACCOUNTS` + `showDemoSelector`
  + demo callback handlers. Add the "no Bexly account → dos.me ID sign-up
  link" branch: emit a link with an HMAC-signed, short-TTL `state`
  (platform + chat id). Linked path unchanged (routes to Agent).
- **new: signup-callback endpoint** (Bexly-owned, e.g.
  `link-signup-callback`): invoked after dos.me ID signup completes with
  the round-tripped `state`; verifies the HMAC + TTL, resolves the newly
  created Bexly user, inserts `user_integrations`, then notifies the
  Telegram/Zalo chat. Idempotent on replay.
- **zalo-webhook**: same code-consume + no-account changes for parity.
- **link-telegram-web**: default = retire it (legacy web link path). During
  planning, grep callers; keep only if an active caller exists, in which
  case align it to the generate-code model.
- **unlink-telegram**: unchanged logic (`delete user_integrations WHERE
  user_id AND platform`) — works once the table exists.
- `_shared/supabase-client.ts` + `telegram-webhook/supabase-client.ts`:
  verify schema/`bexly` targeting; no change expected beyond table
  existence.

## Flutter App Changes

`lib/features/settings/presentation/screens/bot_integration_screen.dart`
(+ `telegram_bot_service.dart`, `telegram_deep_link_handler.dart`): switch
the link UI to *show the generated code + tappable `t.me` deep-link + copy
button*, polling/refreshing link status via `isLinked()`. Remove the old
"enter code from bot into app" direction. Keep unlink.

## Error Handling

- Expired/invalid code → bot replies "Mã không hợp lệ hoặc đã hết hạn, vui
  lòng tạo mã mới trong app." (do not leak whether the code ever existed).
- Code already consumed (race) → treated as invalid (single-use; deleted on
  consume).
- Platform account already linked to a different Bexly user → reject with a
  clear message; do not silently relink.
- Edge function errors logged with a per-platform label; user sees a
  generic retry message.

## Testing

- Migration applies cleanly on beta branch; tables + RLS present.
- Unit/manual: generate code (app) → `/start <code>` deep-link →
  `user_integrations` row created → message → Agent responds.
- Bare-code message path verified (no deep-link).
- Expired-code and already-linked rejection paths verified.
- Unlinked-no-account path returns the sign-up link.
- Zalo parity smoke.
- Regression: linked user's normal messages still route to the Agent
  (channel-secret E2E already verified).

## Rollout

1. Migration `0003` → register via DOS-Me → applied to beta, verified.
2. Edge-function rewrite → review → deploy to beta → E2E test.
3. Flutter app screen update.
4. Promote migration + functions to prod via the registered flow.
5. Real Telegram E2E confirmation by JOY.
