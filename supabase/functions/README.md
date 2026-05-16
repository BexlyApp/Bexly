# Bexly Supabase Edge Functions

Edge Functions migration từ Firebase Cloud Functions để giảm chi phí (~99% so với min-instances).

## 📁 Structure

```
supabase/functions/
├── _shared/                    # Shared utilities
│   ├── types.ts               # Shared types và localizations
│   ├── supabase-client.ts     # Supabase client helpers
│   └── ai-providers.ts        # AI parsing (Gemini/OpenAI/Claude)
├── telegram-webhook/          # Telegram bot webhook
├── link-telegram/             # Link Telegram account
└── unlink-telegram/           # Unlink Telegram account
```

## 🚀 Deploy

### 1. Apply Migration

Apply `user_integrations` table migration:

```bash
supabase db push
```

Hoặc apply specific migration:

```bash
supabase migration up --file 20260120_add_user_integrations_table.sql
```

### 2. Set Environment Variables

Tạo `.env` file trong `supabase/` folder:

```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# AI Providers
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
CLAUDE_API_KEY=your_claude_api_key  # Optional

# Supabase (tự động set khi deploy)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3. Deploy Edge Functions

Deploy tất cả functions:

```bash
cd supabase
supabase functions deploy telegram-webhook
supabase functions deploy link-telegram
supabase functions deploy unlink-telegram
```

### 4. Setup Telegram Webhook URL

Set webhook URL cho Telegram bot:

```bash
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/telegram-webhook"}'
```

Verify webhook:

```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getWebhookInfo"
```

## 📝 Testing

### Test Telegram Bot

1. Open Telegram: https://t.me/BexlyBot
2. Send `/start` command
3. Link account bằng cách send message → Click "🔗 Link Account" button
4. Send expense message: "50k cafe" hoặc "lunch $20"
5. Bot sẽ parse và hiện confirmation button

### Test Link/Unlink APIs

Link account:

```bash
curl -X POST "https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/link-telegram" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_USER_JWT>" \
  -d '{"telegram_id": "123456789"}'
```

Unlink account:

```bash
curl -X POST "https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/unlink-telegram" \
  -H "Authorization: Bearer <YOUR_USER_JWT>"
```

## 💰 Chi phí

**Trước (Firebase Cloud Functions)**:
- Min-instances: ~1.3M VND/tháng (14 functions × minInstances=1)
- Actual invocations: ~1,500 VND

**Sau (Supabase Edge Functions)**:
- 100K requests/tháng: ~$0.20 = ~5,000 VND
- Không có min-instances!
- **Tiết kiệm: ~99.6%**

## Zalo Channel (Phase 3.3)

Edge Functions for Zalo Official Account integration. Mirrors the Telegram channel pattern.

### Functions

| Function | Purpose |
|----------|---------|
| `zalo-webhook` | Receives Zalo OA events, verifies HMAC signature, routes to Bexly Agent |
| `link-zalo` | Called by mobile app to bind a Zalo user to a Bexly account |

### Environment Variables

Set via `supabase secrets set` before deploying:

```bash
# Required for zalo-webhook
supabase secrets set BEXLY_ZALO_ACCESS_TOKEN=<oa_access_token>
supabase secrets set BEXLY_ZALO_APP_SECRET=<oa_app_secret>
supabase secrets set BEXLY_ZALO_USE_AGENT=true          # default false (maintenance mode)
supabase secrets set BEXLY_AGENT_URL=https://ai.bexly.app
# Shared secret proving telegram/zalo webhooks are trusted backend callers
# into the agent (the agent uses its own service key + this userId; webhooks
# no longer forge a user JWT). Must match BEXLY_CHANNEL_SECRET set on Vercel.
supabase secrets set BEXLY_CHANNEL_SECRET=<32+_char_shared_secret>
# SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY are auto-injected
```

### OA Setup Flow

1. Register Zalo Official Account at https://oa.zalo.me
2. In OA Manager, go to Settings > API and generate Access Token + App Secret
3. Set the secrets above via Supabase CLI
4. Deploy the functions:
   ```bash
   supabase functions deploy zalo-webhook
   supabase functions deploy link-zalo
   ```
5. In OA Manager, set webhook URL to:
   `https://<project_id>.supabase.co/functions/v1/zalo-webhook`
6. Subscribe to event: `user_send_text` (minimum required)

### Signature Verification

Zalo signs each POST with header `mac` = HMAC-SHA256(rawBody + access_token, app_secret) as lowercase hex.
The `zalo-webhook` function verifies this on every incoming request.

### Link Code Flow

1. Zalo user sends any message to OA when not yet linked
2. `zalo-webhook` generates a 6-char code in `bot_link_codes` table (`platform='zalo'`)
3. User opens Bexly app and enters the code
4. Mobile app POSTs to `link-zalo` with `{ link_code: "XXXXXX" }` + user JWT
5. `link-zalo` validates the code, creates row in `user_integrations` (`platform='zalo'`)
6. Subsequent messages are forwarded to Bexly Agent

### Deploy

```bash
supabase functions deploy zalo-webhook
supabase functions deploy link-zalo
```

---

## Telegram Channel (Phase 3.2)

### Setup Telegram Webhook URL

Set webhook URL for Telegram bot:

```bash
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/telegram-webhook"}'
```

Verify webhook:

```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getWebhookInfo"
```

---

## 🔄 Migration Status

- ✅ Telegram webhook
- ✅ Link/Unlink Telegram
- ✅ AI parsing (Gemini/OpenAI/Claude)
- ✅ Zalo webhook (Phase 3.3 - scaffold, activate after OA provisioning)
- ✅ Link Zalo (Phase 3.3 - scaffold, activate after OA provisioning)
- ⏳ Messenger webhook (TODO)
- ⏳ Stripe Financial Connections (TODO)
- ⏳ Auth hooks (TODO)

## 📚 Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Deno Deploy Docs](https://docs.deno.com/deploy/manual)
- [Grammy Bot Framework](https://grammy.dev/)
- [Zalo OA API Docs](https://developers.zalo.me/docs/api/official-account-api)
- [Zalo Webhook Verification](https://developers.zalo.me/docs/official-account/webhook/verify-webhook-origin)
