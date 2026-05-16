# Bexly Bot-Link Plan 2: Telegram Core Flow

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Rewrite the Telegram link flow to: app generates a code (via `link-telegram`), user links by deep-link `/start <code>` or pasting the code into the bot (`telegram-webhook`); remove the hackathon demo-account picker.

**Architecture:** `link-telegram` becomes a *generate-code* endpoint (authenticated Bexly user → row in `bexly.bot_link_codes` keyed by `user_id` → returns `{code, deep_link}`). `telegram-webhook` consumes the code (from `/start <code>` start-param or a bare 6-char message) → upserts `bexly.user_integrations` → routes linked users to the Bexly Agent (unchanged). Demo-account code removed. No-account → simple "link via app" prompt (the dos.me-ID signup callback is Plan 4).

**Tech Stack:** Deno (Supabase Edge Functions), Telegram Bot API, Postgres. No unit-test harness exists for these functions; verification is `deno check` + curl smoke against the BETA branch function URL (beta already has the tables from Plan 1).

**Spec:** `docs/superpowers/specs/2026-05-16-bexly-bot-link-redesign-design.md`

**Beta function base URL:** `https://oyajkbadsykigtfrpdpg.supabase.co/functions/v1`
**Prod (do NOT deploy here in Plan 2):** `gulptwduchsjcsbndmua` — prod cutover waits on dos.me applying the Plan-1 migration.

---

### Task 1: Rewrite `link-telegram` as the generate-code endpoint

**Files:**
- Modify: `supabase/functions/link-telegram/index.ts` (full replace of body logic, lines 60-154)

- [ ] **Step 1: Replace the post-auth body (the `const supabase = createSupabaseClient();` block through the success response)**

Find this exact block (lines 60-154, from `// Now use Bexly Supabase client` through the closing of the success `return`) and replace the **entire** block from line 60 `// Now use Bexly Supabase client for database operations` up to and including line 154 (the `);` closing the success Response) with:

```typescript
    // Now use Bexly Supabase client for database operations
    const supabase = createSupabaseClient();

    const body = await req.json().catch(() => ({}));
    const platform: string = body.platform === "zalo" ? "zalo" : "telegram";

    // Resolve the Telegram bot username for the deep-link (cached per cold
    // start). Uses the bot token available as a Supabase secret to all
    // functions; avoids a separate username secret that could drift.
    const botToken = Deno.env.get("BEXLY_TELEGRAM_BOT_TOKEN");
    let botUsername = "";
    if (platform === "telegram" && botToken) {
      try {
        const me = await fetch(`https://api.telegram.org/bot${botToken}/getMe`);
        const meJson = await me.json();
        botUsername = meJson?.result?.username ?? "";
      } catch (_) {
        botUsername = "";
      }
    }

    // Generate a 6-char A-Z0-9 code; retry on the rare PK collision.
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    function genCode(): string {
      let c = "";
      for (let i = 0; i < 6; i++) {
        c += alphabet[Math.floor(Math.random() * alphabet.length)];
      }
      return c;
    }

    // Clear this user's prior unused codes for the platform, then insert.
    await supabase
      .from("bot_link_codes")
      .delete()
      .eq("user_id", user.id)
      .eq("platform", platform);

    let code = "";
    let insertErr: unknown = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      code = genCode();
      const { error } = await supabase
        .from("bot_link_codes")
        .insert({ code, user_id: user.id, platform });
      if (!error) {
        insertErr = null;
        break;
      }
      insertErr = error;
    }
    if (insertErr) {
      console.error("[link-telegram] code insert failed:", JSON.stringify(insertErr));
      return new Response(
        JSON.stringify({ error: "Failed to generate link code" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const deepLink = botUsername
      ? `https://t.me/${botUsername}?start=${code}`
      : null;

    console.log("[link-telegram] code generated for user", user.id, "platform", platform);
    return new Response(
      JSON.stringify({
        success: true,
        code,
        platform,
        deep_link: deepLink,
        expires_in_minutes: 10,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
```

(Leave lines 1-59 — imports, CORS, JWT verify — unchanged. Leave the
`catch (error)` block lines 155-162 unchanged.)

- [ ] **Step 2: Type-check the function**

Run: `cd d:/Projects/Bexly && deno check supabase/functions/link-telegram/index.ts 2>&1 | tail -3`
Expected: no errors (exit 0). If `deno` is unavailable, run
`npx --yes deno@1.45 check supabase/functions/link-telegram/index.ts`.

- [ ] **Step 3: Commit**

```bash
cd d:/Projects/Bexly && git add supabase/functions/link-telegram/index.ts && git commit -m "feat(link-telegram): generate-code endpoint (app-side), returns code + t.me deep-link" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `telegram-webhook` — add code-consume helper, remove demo code

**Files:**
- Modify: `supabase/functions/telegram-webhook/index.ts`

- [ ] **Step 1: Replace the auth/link helpers block (lines 166-253)**

Find the exact block from line 166 (`// Generate a random 6-char alphanumeric link code and store in DB`)
through line 253 (the closing `}` of `unlinkUser`) and replace the
**entire** block with:

```typescript
// Look up the Bexly user linked to this Telegram chat (null if unlinked).
async function getUserId(telegramId: string): Promise<string | null> {
  const { data } = await getSupabaseClient()
    .from("user_integrations")
    .select("user_id")
    .eq("platform", "telegram")
    .eq("platform_user_id", telegramId)
    .maybeSingle();
  return data?.user_id ?? null;
}

// Consume an app-generated link code: validate (unexpired, telegram),
// link this Telegram chat to the code's Bexly user, delete the code.
// Returns the linked user_id, or null if the code is invalid/expired,
// or the string "ALREADY" if this chat is already linked to a user.
async function consumeLinkCode(
  rawCode: string,
  telegramId: string,
): Promise<string | "ALREADY" | null> {
  const code = rawCode.trim().toUpperCase();
  const sb = getSupabaseClient();

  const { data: row } = await sb
    .from("bot_link_codes")
    .select("user_id")
    .eq("code", code)
    .eq("platform", "telegram")
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();
  if (!row?.user_id) return null;

  // If this Telegram chat is already linked, do not silently relink.
  const existing = await getUserId(telegramId);
  if (existing) {
    await sb.from("bot_link_codes").delete().eq("code", code);
    return "ALREADY";
  }

  const { error: insErr } = await sb.from("user_integrations").insert({
    user_id: row.user_id,
    platform: "telegram",
    platform_user_id: telegramId,
    linked_at: new Date().toISOString(),
    last_activity: new Date().toISOString(),
  });
  if (insErr) {
    console.error("[telegram-webhook] link insert failed:", JSON.stringify(insErr));
    return null;
  }
  await sb.from("bot_link_codes").delete().eq("code", code);
  return row.user_id;
}

async function unlinkUser(telegramId: string): Promise<boolean> {
  const { error } = await getSupabaseClient()
    .from("user_integrations")
    .delete()
    .eq("platform", "telegram")
    .eq("platform_user_id", telegramId);
  return !error;
}
```

This removes `generateLinkCode`, `linkToDemoAccount`, and
`showDemoSelector`, and makes `getUserId` use `.maybeSingle()` (the old
`.single()` throws on 0 rows).

- [ ] **Step 2: Remove the `DEMO_ACCOUNTS` constant block**

Find the `DEMO_ACCOUNTS` array declaration (search the file for
`const DEMO_ACCOUNTS`) and delete the entire `const DEMO_ACCOUNTS = [ ... ];`
declaration including all its element lines and the closing `];`. Also
delete the section comment line immediately above it if it is
`// ── Demo accounts for hackathon ...`.

- [ ] **Step 3: Type-check to surface every remaining demo reference**

Run: `cd d:/Projects/Bexly && deno check supabase/functions/telegram-webhook/index.ts 2>&1 | tail -20`
Expected: errors ONLY of the form "Cannot find name 'DEMO_ACCOUNTS'" /
"Cannot find name 'showDemoSelector'" / "Cannot find name
'linkToDemoAccount'" / "Cannot find name 'generateLinkCode'" at the
dispatch call-sites. Record the reported line numbers — Task 3 replaces
exactly those call-sites. (If no such errors, the call-sites were already
covered; proceed.)

- [ ] **Step 4: Commit**

```bash
cd d:/Projects/Bexly && git add supabase/functions/telegram-webhook/index.ts && git commit -m "refactor(telegram-webhook): code-consume helpers, drop demo-account code" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `telegram-webhook` — rewrite the command/message dispatch

**Files:**
- Modify: `supabase/functions/telegram-webhook/index.ts` (the message
  dispatch, currently lines ~786-909: the `/start`, `/demo`, `/help`,
  `/insights`, `/link`, `/unlink`, demo-keyboard-match, and
  unlinked-fallthrough blocks)

- [ ] **Step 1: Replace the dispatch from the `/start` handler through the unlinked-fallthrough**

Find the block that begins at `if (text === "/start") {` and ends just
before `// Phase 3.2: route to Bexly Agent when feature flag is on`
(currently lines ~790-909, covering `/start`, `/demo`, `/help`,
`/insights`, `/link`, `/unlink`, the `demoMatch` block, and the
`const userId = await getUserId(...); if (!userId) { showDemoSelector }`
fallthrough). Replace that entire span with:

```typescript
    // Extract a link code from "/start <code>" or a bare 6-char message.
    const startMatch = text.match(/^\/start(?:\s+([A-Za-z0-9]{6}))?$/);
    const bareCodeMatch = text.match(/^([A-Za-z0-9]{6})$/);
    const linkCode = startMatch?.[1] ?? (bareCodeMatch ? bareCodeMatch[1] : null);

    if (linkCode) {
      const result = await consumeLinkCode(linkCode, telegramUserId);
      if (result === "ALREADY") {
        await sendMessage(chatId,
          "✅ Tài khoản Telegram này đã được liên kết. Cứ nhắn tin để dùng trợ lý Bexly.");
      } else if (result) {
        await sendMessage(chatId,
          "✅ *Đã liên kết tài khoản Bexly!*\n\nNhắn tin cho tôi để ghi chép & hỏi về tài chính của bạn.");
      } else {
        await sendMessage(chatId,
          "❌ Mã không hợp lệ hoặc đã hết hạn.\n\nMở app Bexly → Cài đặt → Liên kết Telegram để lấy mã mới.");
      }
      return new Response("OK");
    }

    if (text === "/start") {
      await sendMessage(chatId,
        "👋 *Chào mừng đến Bexly!*\n\n" +
        "Tôi là trợ lý tài chính của bạn. Để bắt đầu:\n\n" +
        "1. Mở app Bexly → *Cài đặt* → *Liên kết Telegram*\n" +
        "2. Bấm nút mở Telegram (hoặc dán mã 6 ký tự vào đây)\n\n" +
        "Sau khi liên kết, cứ nhắn tin để ghi chép & hỏi về tài chính.");
      return new Response("OK");
    }

    if (text === "/help") {
      await sendMessage(chatId,
        "📖 *Bexly*\n\n" +
        "/start - Bắt đầu / hướng dẫn liên kết\n" +
        "/unlink - Huỷ liên kết tài khoản\n" +
        "/help - Trợ giúp\n\n" +
        "Đã liên kết? Cứ nhắn tự nhiên:\n" +
        "`ăn sáng 25k` · `lương 15 triệu` · `Tháng này tôi tiêu bao nhiêu?`");
      return new Response("OK");
    }

    if (text === "/unlink") {
      const existing = await getUserId(telegramUserId);
      if (!existing) {
        await sendMessage(chatId, "❌ Chưa liên kết. Mở app Bexly để liên kết trước.");
        return new Response("OK");
      }
      await sendMessage(chatId, "⚠️ Huỷ liên kết tài khoản Bexly?", {
        reply_markup: {
          inline_keyboard: [[
            { text: "✅ Huỷ liên kết", callback_data: `unlink_confirm_${telegramUserId}` },
            { text: "❌ Thôi", callback_data: `unlink_cancel_${telegramUserId}` },
          ]],
        },
      });
      return new Response("OK");
    }

    // Any other message requires a linked account.
    const userId = await getUserId(telegramUserId);
    if (!userId) {
      await sendMessage(chatId,
        "🔗 Bạn chưa liên kết tài khoản Bexly.\n\n" +
        "Mở app Bexly → *Cài đặt* → *Liên kết Telegram*, rồi bấm nút mở " +
        "Telegram hoặc dán mã 6 ký tự vào đây.\n\n" +
        "_Chưa có tài khoản Bexly? Tải app tại https://bexly.app_");
      return new Response("OK");
    }
```

Notes for the implementer:
- This removes `/demo`, `/insights`-via-demo, the old `/link`
  (code-from-bot) handler, and the `demoMatch` reply-keyboard branch.
- `/insights` previously depended on demo accounts; it is dropped here.
  If `handleInsightsCommand` becomes unused after this, that is fine
  (dead code is removed in Step 2 of this task only if `deno check`
  flags it as unused — otherwise leave it; do not chase unrelated
  cleanup).
- The line immediately after this block must remain
  `// Phase 3.2: route to Bexly Agent when feature flag is on` and the
  agent-routing + `handleTransactionMessage` logic stays unchanged.
- The "no Bexly account → dos.me ID signup" branch is intentionally NOT
  here — that is Plan 4. Plan 2's unlinked message is the plain
  app-link prompt above.

- [ ] **Step 2: Type-check; remove now-unused symbols only if flagged**

Run: `cd d:/Projects/Bexly && deno check supabase/functions/telegram-webhook/index.ts 2>&1 | tail -20`
Expected: exit 0, no errors. If `deno check` reports an unused
`handleInsightsCommand` (or similar) as an *error* (not warning), delete
that now-unreachable function and re-run until clean. Do NOT remove
anything `deno check` does not flag.

- [ ] **Step 3: Commit**

```bash
cd d:/Projects/Bexly && git add supabase/functions/telegram-webhook/index.ts && git commit -m "feat(telegram-webhook): app-generated code consume via /start or bare code; drop demo-picker" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Deploy to BETA and smoke-test the flow end-to-end

**Files:** none (deploy + curl against beta `oyajkbadsykigtfrpdpg`)

- [ ] **Step 1: Deploy both functions to the BETA project only**

```bash
cd d:/Projects/Bexly && supabase functions deploy link-telegram --project-ref oyajkbadsykigtfrpdpg --no-verify-jwt 2>&1 | tail -2 && supabase functions deploy telegram-webhook --project-ref oyajkbadsykigtfrpdpg --no-verify-jwt 2>&1 | tail -2
```
Expected: both print "Deployed Functions on project oyajkbadsykigtfrpdpg".
NEVER pass `--project-ref gulptwduchsjcsbndmua` here (prod is gated on
dos.me).

- [ ] **Step 2: Generate a code directly in beta DB (simulates the app call)**

Use Supabase MCP `execute_sql` on `project_id` `oyajkbadsykigtfrpdpg`:
```sql
DELETE FROM bexly.bot_link_codes WHERE code='TST123';
INSERT INTO bexly.bot_link_codes (code, user_id, platform)
VALUES ('TST123', '8f2d530b-8528-415a-bd62-e9876f698ffb', 'telegram');
SELECT code, user_id, expires_at > now() AS valid FROM bexly.bot_link_codes WHERE code='TST123';
```
Expected: one row, `valid` = true.

- [ ] **Step 3: Simulate a Telegram "/start TST123" webhook to beta**

```bash
curl -sS -m 30 -X POST "https://oyajkbadsykigtfrpdpg.supabase.co/functions/v1/telegram-webhook" -H "Content-Type: application/json" -d '{"update_id":1,"message":{"message_id":1,"from":{"id":999000111,"language_code":"vi"},"chat":{"id":999000111},"text":"/start TST123"}}' 2>&1 | tail -3
```
Expected: HTTP body `OK` (200). The bot send may 401 to Telegram (fake
chat) — that is fine; we assert the DB side next.

- [ ] **Step 4: Assert the link row was created and the code consumed**

Use Supabase MCP `execute_sql` on `oyajkbadsykigtfrpdpg`:
```sql
SELECT
  (SELECT user_id::text FROM bexly.user_integrations
     WHERE platform='telegram' AND platform_user_id='999000111') AS linked_user,
  (SELECT count(*) FROM bexly.bot_link_codes WHERE code='TST123') AS code_remaining;
```
Expected: `linked_user` = `8f2d530b-8528-415a-bd62-e9876f698ffb`,
`code_remaining` = 0 (single-use, deleted on consume).

- [ ] **Step 5: Assert invalid-code path**

```bash
curl -sS -m 30 -X POST "https://oyajkbadsykigtfrpdpg.supabase.co/functions/v1/telegram-webhook" -H "Content-Type: application/json" -d '{"update_id":2,"message":{"message_id":2,"from":{"id":999000222},"chat":{"id":999000222},"text":"ZZZZZZ"}}' 2>&1 | tail -2
```
Expected: body `OK` (200). MCP `execute_sql` assert no link created:
```sql
SELECT count(*) AS n FROM bexly.user_integrations WHERE platform_user_id='999000222';
```
Expected: `n` = 0.

- [ ] **Step 6: Clean up beta test rows**

Use Supabase MCP `execute_sql` on `oyajkbadsykigtfrpdpg`:
```sql
DELETE FROM bexly.user_integrations WHERE platform_user_id IN ('999000111','999000222');
DELETE FROM bexly.bot_link_codes WHERE code IN ('TST123','ZZZZZZ');
```
Expected: success.

- [ ] **Step 7: Commit a checkpoint marker + push dev**

```bash
cd d:/Projects/Bexly && git commit --allow-empty -m "test(bot-link): Plan 2 Telegram flow verified on beta (link + invalid-code paths)" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>" && git push bexly dev 2>&1 | tail -2
```

---

## Self-Review

**Spec coverage (spec §"Canonical Link Flow" 1-4, §"Edge-Function Changes"):**
- App generates code (link-telegram) keyed by user_id, returns code+deep_link → Task 1 ✓
- Bot consumes `/start <code>` AND bare code → Task 3 Step 1 ✓
- Upsert user_integrations, delete code, single-use → Task 2 Step 1 (`consumeLinkCode`) ✓
- Demo-picker removed (DEMO_ACCOUNTS, showDemoSelector, linkToDemoAccount, /demo, demoMatch) → Task 2 Step 2 + Task 3 Step 1 ✓
- `getUserId` `.single()`→`.maybeSingle()` (was crashing on 0 rows) → Task 2 Step 1 ✓
- Linked path unchanged (agent routing) → explicitly preserved, Task 3 Step 1 notes ✓
- Already-linked rejection (no silent relink) → `consumeLinkCode` returns "ALREADY" ✓
- Expired/invalid → generic message, no leak → Task 3 Step 1 ✓
- No-account dos.me signup deferred to Plan 4 (Plan 2 = plain app-link prompt) → Task 3 Step 1 notes ✓
- Beta-only deploy, prod gated on dos.me → Task 4 Step 1 ✓

**Placeholder scan:** all code shown in full; no TBD/TODO; bot username
resolved via getMe (no unknown secret). ✓

**Type consistency:** `consumeLinkCode` returns `string | "ALREADY" |
null`, handled exactly in Task 3 Step 1 (`=== "ALREADY"`, truthy, else).
`getUserId` returns `string | null` used consistently. `bot_link_codes`
columns (`code`,`user_id`,`platform`,`expires_at`) match Plan 1 schema. ✓

**Out of scope (correct):** Zalo (Plan 3), dos.me signup callback (Plan
4), Flutter screen (Plan 5). Plan 2 is independently testable on beta.
