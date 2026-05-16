# Bexly Bot-Link Plan 3: Zalo Parity

> Execute via superpowers:subagent-driven-development. Mirrors the verified Plan 2 (Telegram) for Zalo.

**Goal:** App generates a code (via `link-zalo`); user pastes the code into the Zalo OA chat; `zalo-webhook` consumes it → links → routes linked users to the Bexly Agent (already wired). Drop the old bot-generates-code direction.

**Architecture:** Identical pattern to Plan 2. Zalo OA has no `t.me`-style deep-link, so `link-zalo` returns just the code (no deep_link). `zalo-webhook` consumes a bare 6-char code message. Tables/RLS/GRANTs/schema-exposure + sb_secret edge client already verified on beta (Plan 1 + Plan 2 T5).

**Verification reality:** `zalo-webhook` HMAC-verifies the `mac` header (needs `BEXLY_ZALO_ACCESS_TOKEN`/`BEXLY_ZALO_APP_SECRET`, which require Zalo OA registration — JOY-pending, external). So full real-message E2E is gated on Zalo OA. Plan 3 verifies via: `deno check`; data-layer PostgREST probe (select bot_link_codes platform=zalo + insert user_integrations platform=zalo with the beta sb_secret) — structurally identical to the already-passing Telegram path; and `link-zalo` generate endpoint smoke (JWT auth, no Zalo sig).

---

### Task 1: Rewrite `link-zalo` as generate-code endpoint

**Files:** Modify `supabase/functions/link-zalo/index.ts` (replace lines 60-150: from `// Now use Bexly Supabase client` through the success `);`).

- [ ] Step 1: Replace that exact block with:

```typescript
    // Now use Bexly Supabase client for database operations
    const supabase = createSupabaseClient();

    // Generate a 6-char A-Z0-9 code keyed by the authenticated Bexly user.
    // Zalo OA has no deep-link start param; the user pastes the code into
    // the OA chat, and zalo-webhook consumes it.
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    function genCode(): string {
      let c = "";
      for (let i = 0; i < 6; i++) {
        c += alphabet[Math.floor(Math.random() * alphabet.length)];
      }
      return c;
    }

    await supabase
      .from("bot_link_codes")
      .delete()
      .eq("user_id", user.id)
      .eq("platform", "zalo");

    let code = "";
    let insertErr: unknown = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      code = genCode();
      const { error } = await supabase
        .from("bot_link_codes")
        .insert({ code, user_id: user.id, platform: "zalo" });
      if (!error) {
        insertErr = null;
        break;
      }
      insertErr = error;
    }
    if (insertErr) {
      console.error("[link-zalo] code insert failed:", JSON.stringify(insertErr));
      return new Response(
        JSON.stringify({ error: "Failed to generate link code" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[link-zalo] code generated for user", user.id);
    return new Response(
      JSON.stringify({
        success: true,
        code,
        platform: "zalo",
        expires_in_minutes: 10,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
```

(Lines 1-59 JWT-verify + the `catch` block stay unchanged. No more `link_code`/`platform_user_id` logic in this file.)

- [ ] Step 2: `cd d:/Projects/Bexly && deno check supabase/functions/link-zalo/index.ts 2>&1 | tail -3` → expect exit 0.
- [ ] Step 3: `git add supabase/functions/link-zalo/index.ts && git commit -m "feat(link-zalo): generate-code endpoint (app-side), mirrors link-telegram" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"`

---

### Task 2: `zalo-webhook` — replace generateZaloLinkCode with consumeZaloLinkCode

**Files:** Modify `supabase/functions/zalo-webhook/index.ts`.

- [ ] Step 1: Replace exactly this block (the `generateZaloLinkCode` function, ~lines 100-124):

```
// Generate a 6-char alphanumeric link code and store in bot_link_codes table.
// Reuses the same table pattern as the Telegram channel (platform='zalo').
async function generateZaloLinkCode(zaloUserId: string): Promise<string> {
  const code = Math.random().toString(36).substring(2, 8).toUpperCase()

  const supabase = getSupabaseClient()

  // Delete any existing pending codes for this Zalo user
  await supabase
    .from('bot_link_codes')
    .delete()
    .eq('platform', 'zalo')
    .eq('platform_user_id', zaloUserId)

  // Insert new code
  await supabase
    .from('bot_link_codes')
    .insert({
      code,
      platform: 'zalo',
      platform_user_id: zaloUserId,
    })

  return code
}
```

with:

```
// Consume an app-generated link code: validate (unexpired, zalo), link
// this Zalo user to the code's Bexly user, delete the code. Returns the
// linked user_id, "ALREADY" if this Zalo user is already linked, or null
// if the code is invalid/expired.
async function consumeZaloLinkCode(
  rawCode: string,
  zaloUserId: string,
): Promise<string | 'ALREADY' | null> {
  const code = rawCode.trim().toUpperCase()
  const sb = getSupabaseClient()

  const { data: row } = await sb
    .from('bot_link_codes')
    .select('user_id')
    .eq('code', code)
    .eq('platform', 'zalo')
    .gt('expires_at', new Date().toISOString())
    .maybeSingle()
  if (!row?.user_id) return null

  const existing = await getBexlyUserId(zaloUserId)
  if (existing) {
    await sb.from('bot_link_codes').delete().eq('code', code)
    return 'ALREADY'
  }

  const { error: insErr } = await sb.from('user_integrations').insert({
    user_id: row.user_id,
    platform: 'zalo',
    platform_user_id: zaloUserId,
    linked_at: new Date().toISOString(),
    last_activity: new Date().toISOString(),
  })
  if (insErr) {
    console.error('[zalo-webhook] link insert failed:', JSON.stringify(insErr))
    return null
  }
  await sb.from('bot_link_codes').delete().eq('code', code)
  return row.user_id
}
```

- [ ] Step 2: `cd d:/Projects/Bexly && deno check supabase/functions/zalo-webhook/index.ts 2>&1 | tail -10` → expect ONLY "Cannot find name 'generateZaloLinkCode'" at the dispatch call-site (fixed in Task 3). Record line.
- [ ] Step 3: `git add supabase/functions/zalo-webhook/index.ts && git commit -m "refactor(zalo-webhook): consumeZaloLinkCode helper (replaces generate direction)" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"`

---

### Task 3: `zalo-webhook` — rewrite dispatch to consume code

**Files:** Modify `supabase/functions/zalo-webhook/index.ts`.

- [ ] Step 1: Replace exactly this block (the not-linked branch, ~lines 213-224):

```
  const bexlyUserId = await getBexlyUserId(zaloUserId)

  if (!bexlyUserId) {
    // Account not linked yet - generate a link code and prompt the user
    const code = await generateZaloLinkCode(zaloUserId)
    await sendZaloMessage(
      zaloUserId,
      `Chao ban! De lien ket voi tai khoan Bexly, vui long mo app Bexly va nhap ma: ${code}\n` +
        `(Ma co hieu luc trong 10 phut.)`,
    )
    return new Response('ok', { status: 200 })
  }
```

with:

```
  // A bare 6-char message is treated as an app-generated link code.
  const bareCode = text.match(/^([A-Za-z0-9]{6})$/)
  if (bareCode) {
    const result = await consumeZaloLinkCode(bareCode[1], zaloUserId)
    if (result === 'ALREADY') {
      await sendZaloMessage(zaloUserId, 'Tai khoan Zalo nay da duoc lien ket. Cu nhan tin de dung tro ly Bexly.')
      return new Response('ok', { status: 200 })
    }
    if (result) {
      await sendZaloMessage(zaloUserId, 'Da lien ket tai khoan Bexly! Nhan tin cho toi de ghi chep & hoi ve tai chinh.')
      return new Response('ok', { status: 200 })
    }
    await sendZaloMessage(zaloUserId, 'Ma khong hop le hoac da het han. Mo app Bexly de lay ma moi.')
    return new Response('ok', { status: 200 })
  }

  const bexlyUserId = await getBexlyUserId(zaloUserId)

  if (!bexlyUserId) {
    await sendZaloMessage(
      zaloUserId,
      'Ban chua lien ket tai khoan Bexly. Mo app Bexly, vao Cai dat de lay ma 6 ky tu roi dan vao day.',
    )
    return new Response('ok', { status: 200 })
  }
```

- [ ] Step 2: `cd d:/Projects/Bexly && deno check supabase/functions/zalo-webhook/index.ts 2>&1 | tail -10` → expect exit 0, no errors. Fix any introduced error, re-run.
- [ ] Step 3: `grep -n "generateZaloLinkCode" supabase/functions/zalo-webhook/index.ts` → expect zero hits.
- [ ] Step 4: `git add supabase/functions/zalo-webhook/index.ts && git commit -m "feat(zalo-webhook): consume app-generated code from bare message; link via app" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"`

---

### Task 4: Deploy beta + verifiable smoke

**Files:** none (controller deploy + MCP/curl on beta `oyajkbadsykigtfrpdpg`).

- [ ] Step 1: Deploy BETA only: `cd d:/Projects/Bexly && supabase functions deploy link-zalo --project-ref oyajkbadsykigtfrpdpg --no-verify-jwt && supabase functions deploy zalo-webhook --project-ref oyajkbadsykigtfrpdpg --no-verify-jwt`. NEVER prod.
- [ ] Step 2: Data-layer probe (proves consumeZaloLinkCode's exact ops; structurally identical to verified Telegram path). MCP `execute_sql` on `oyajkbadsykigtfrpdpg`:
```sql
DELETE FROM bexly.bot_link_codes WHERE code='ZAL123';
DELETE FROM bexly.user_integrations WHERE platform='zalo' AND platform_user_id='zalo_smoke_1';
INSERT INTO bexly.bot_link_codes (code, user_id, platform) VALUES ('ZAL123','8f2d530b-8528-415a-bd62-e9876f698ffb','zalo');
-- replicate consumeZaloLinkCode select then insert then delete
SELECT user_id FROM bexly.bot_link_codes WHERE code='ZAL123' AND platform='zalo' AND expires_at>now();
INSERT INTO bexly.user_integrations (user_id, platform, platform_user_id, linked_at, last_activity)
  VALUES ('8f2d530b-8528-415a-bd62-e9876f698ffb','zalo','zalo_smoke_1', now(), now());
DELETE FROM bexly.bot_link_codes WHERE code='ZAL123';
SELECT
 (SELECT user_id::text FROM bexly.user_integrations WHERE platform='zalo' AND platform_user_id='zalo_smoke_1') AS linked,
 (SELECT count(*) FROM bexly.bot_link_codes WHERE code='ZAL123') AS code_left;
```
Expected: `linked` = the uuid, `code_left` = 0.
- [ ] Step 3: Cleanup: MCP `execute_sql` `DELETE FROM bexly.user_integrations WHERE platform='zalo' AND platform_user_id='zalo_smoke_1';`
- [ ] Step 4: `link-zalo` generate smoke is JWT-gated (needs a real user JWT) — skip live call; deno check + data-layer probe + structural equivalence to verified Telegram path is the proof. Document that full real-Zalo-message E2E is gated on Zalo OA registration (BEXLY_ZALO_ACCESS_TOKEN/APP_SECRET, JOY-pending external).
- [ ] Step 5: `git commit --allow-empty -m "test(bot-link): Plan 3 Zalo parity - deno clean + data-layer verified on beta; real-msg E2E gated on Zalo OA creds" -m "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>" && git push bexly dev`

---

## Self-Review
- link-zalo → generate-code keyed by user_id (mirror link-telegram) → T1 ✓
- consumeZaloLinkCode (select/already/insert/delete, platform=zalo) → T2 ✓
- dispatch: bare code → consume; not-linked → app-link prompt; drop generate direction → T3 ✓
- getBexlyUserId already `.maybeSingle()` (no change needed) ✓
- agent routing for linked users unchanged (existing callBexlyAgent) ✓
- Beta-only deploy; prod gated on dos.me #115 ✓
- Verification honest about Zalo-OA-creds gate (no fake "E2E passed") ✓
- No placeholders; exact old/new strings; types consistent with Plan 2 (`string|'ALREADY'|null`) ✓
