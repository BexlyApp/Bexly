# Telegram Integration Status

**Last Updated**: 2026-01-21
**Status**: ⏳ WAITING FOR JWT VERIFICATION FIX

---

## ✅ Completed Tasks

### 1. Supabase Edge Functions Migration

✅ **Migrated from Firebase to Supabase**
- Created `telegram-webhook` function with JWT authentication
- Created `link-telegram` function for account linking
- Created `unlink-telegram` function for account unlinking
- Deployed AI parsing with Gemini/OpenAI/Claude support
- **Cost savings**: ~1.3M VND → ~5K VND/month (99.6% reduction)

**Files Created**:
- [supabase/functions/_shared/types.ts](../supabase/functions/_shared/types.ts)
- [supabase/functions/_shared/supabase-client.ts](../supabase/functions/_shared/supabase-client.ts)
- [supabase/functions/_shared/ai-providers.ts](../supabase/functions/_shared/ai-providers.ts)
- [supabase/functions/telegram-webhook/index.ts](../supabase/functions/telegram-webhook/index.ts)
- [supabase/functions/link-telegram/index.ts](../supabase/functions/link-telegram/index.ts)
- [supabase/functions/unlink-telegram/index.ts](../supabase/functions/unlink-telegram/index.ts)
- [supabase/migrations/20260120_add_user_integrations_table.sql](../supabase/migrations/20260120_add_user_integrations_table.sql)

### 2. Database Schema

✅ **Created `user_integrations` table**
- Schema: `bexly.user_integrations`
- Fields: `id`, `user_id`, `platform`, `platform_user_id`, `linked_at`, `last_activity`
- Constraints: Unique per platform, unique per user
- RLS policies: Users can only access their own integrations
- **Status**: Successfully applied via Supabase MCP

### 3. JWT-Based Authentication Flow

✅ **Implemented JWT linking via id.dos.me**
- Bot generates JWT with telegram_id and app info
- Uses existing `/login` page (no new routes needed!)
- JWT expires in 10 minutes for security
- Simplified flow: `login → link → redirect`

**Flow**:
```
Bot → https://id.dos.me/login?redirect=bexly://telegram/linked&tg_token=JWT
    → User logs in
    → id.dos.me calls Bexly Edge Function
    → Redirect to bexly://telegram/linked
```

### 4. Flutter App Integration

✅ **Added Bot Integration screen**
- Screen: [lib/features/settings/presentation/screens/bot_integration_screen.dart](../lib/features/settings/presentation/screens/bot_integration_screen.dart)
- Features:
  - Check link status on mount
  - Show linked/unlinked state with visual indicators
  - Unlink button for linked accounts
  - Instructions for linking
  - "Open in Telegram" button

✅ **Added deep link handler**
- Route: `/telegram/linked` → redirects to `/bot-integration`
- Automatically shows link status after successful linking

✅ **Added menu item in Settings**
- Location: Settings → Preferences → Bot Integration
- Icon: Telegram icon
- Navigation: Opens Bot Integration screen

**Files Modified**:
- [lib/core/router/routes.dart](../lib/core/router/routes.dart) - Added routes
- [lib/core/router/settings_router.dart](../lib/core/router/settings_router.dart) - Added deep link handler
- [lib/features/settings/presentation/screens/settings_screen.dart](../lib/features/settings/presentation/screens/settings_screen.dart) - Added import
- [lib/features/settings/presentation/components/settings_preferences_group.dart](../lib/features/settings/presentation/components/settings_preferences_group.dart) - Added menu item

### 5. Documentation

✅ **Created comprehensive documentation**
- [TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md](./TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md) - Full requirements for DOS.me team
- [TELEGRAM_BOT_SIMPLE_FLOW.md](./TELEGRAM_BOT_SIMPLE_FLOW.md) - Simplified flow overview
- [TELEGRAM_INTEGRATION_DEBUG_REPORT.md](./TELEGRAM_INTEGRATION_DEBUG_REPORT.md) - Debug guide for current issue
- [supabase/functions/README.md](../supabase/functions/README.md) - Edge Functions deployment guide

### 6. Webhook Configuration

✅ **Updated Telegram webhook URL**
- Old: `https://asia-southeast1-bexly-app.cloudfunctions.net/telegramWebhook`
- New: `https://dos.supabase.co/functions/v1/telegram-webhook`
- **Verified**: Webhook receiving messages correctly

---

## ❌ Current Blockers

### 1. ✅ ~~Redirect Issue (DOS.me Side)~~ - FIXED!

**Problem**: After Google OAuth login, redirects to `/details` instead of processing `tg_token`

**Solution**: Pass `tg_token` via OAuth redirectTo URL instead of cookies

**DOS.me Commits**:
- 17f64885 - Initial implementation
- 40252671 - Fix already-logged-in flow
- 58960a71 - Preserve tg_token through OAuth (cookie approach)
- **e691511a - FIXED: Pass tg_token via OAuth redirectTo URL** ✅

**Status**: ✅ RESOLVED - Ready for testing!

### 2. 🔴 CRITICAL - JWT Verification (Supabase Side)

**Problem**: Telegram webhook returns 401 because JWT verification is enabled

**Root Cause**: Supabase Edge Functions require JWT by default, but Telegram webhooks don't send auth headers

**Attempted Fixes**:
- ❌ Created `supabase/config.toml` with `verify_jwt = false` - didn't work
- ❌ Tried CLI flag `--no-verify-jwt` - not supported

**Required Action**: Disable JWT verification via Supabase Dashboard
1. Go to Supabase Dashboard
2. Navigate to Functions → telegram-webhook
3. Settings → Disable "Verify JWT"

**Status**: Waiting for manual configuration

---

## 📋 Testing Checklist

### After DOS.me Fix:

- [ ] Login with Google OAuth works
- [ ] `tg_token` parameter preserved through OAuth
- [ ] Edge Function receives POST request
- [ ] Edge Function returns success (200)
- [ ] Redirect to `bexly://telegram/linked` works
- [ ] Flutter app opens to Bot Integration screen
- [ ] Link status shows as "✅ Linked"
- [ ] Transaction creation works after linking

### After JWT Verification Fix:

- [ ] Bot responds to messages without 401 error
- [ ] Unlinked users see "🔗 Link Account" button
- [ ] Linked users can create transactions
- [ ] AI parsing works correctly

---

## 🚀 Next Steps

### Immediate (Only 1 Blocker Left!)

1. ~~**DOS.me team**: Debug redirect issue~~ ✅ FIXED!

2. **Bexly team**: Disable JWT verification for telegram-webhook 🔴
   - Access Supabase Dashboard: https://supabase.com/dashboard/project/gulptwduchsjcsbndmua
   - Navigate to Edge Functions → `telegram-webhook`
   - Settings → Disable "Verify JWT"
   - **This is the ONLY remaining blocker!**

### After Blockers Resolved

1. Test end-to-end flow
2. Verify transaction creation
3. Test error cases (already linked, expired JWT, etc.)
4. Monitor costs and performance
5. Consider adding:
   - Messenger bot integration (similar flow)
   - Bot commands (/help, /status, etc.)
   - Transaction history via bot
   - Budget alerts via bot

---

## 📚 Technical Details

### Bot Information
- **Bot Username**: @BexlyBot
- **Bot Token**: `[STORED IN SUPABASE SECRETS - DO NOT COMMIT]`
- **Webhook URL**: `https://dos.supabase.co/functions/v1/telegram-webhook`

### Test Data
- **Telegram User ID**: `889623565` (from screenshot)
- **JWT Secret**: `TELEGRAM_JWT_SECRET` (shared between bot and id.dos.me)

### Edge Function URLs
- **Link**: `https://dos.supabase.co/functions/v1/link-telegram` (requires user JWT)
- **Unlink**: `https://dos.supabase.co/functions/v1/unlink-telegram` (requires user JWT)
- **Webhook**: `https://dos.supabase.co/functions/v1/telegram-webhook` (public, needs JWT verification disabled)

### Database
- **Schema**: `bexly`
- **Table**: `user_integrations`
- **Supabase Project**: https://supabase.com/dashboard/project/gulptwduchsjcsbndmua

---

## 📊 Migration Comparison

### Before (Firebase Cloud Functions)

```
Cost: ~1.3M VND/month
- 14 functions × minInstances=1 × 24/7
- Actual invocations: ~1,500 VND
- Min-instances: ~1,298,500 VND

Total: ~1.3M VND/month
```

### After (Supabase Edge Functions)

```
Cost: ~5,000 VND/month
- 100K requests/month: ~$0.20
- No min-instances!
- Pay-per-use only

Total: ~5,000 VND/month
Savings: 99.6% 🎉
```

---

## 🔗 References

- **Supabase Docs**: https://supabase.com/docs/guides/functions
- **Grammy Docs**: https://grammy.dev/
- **Telegram Bot API**: https://core.telegram.org/bots/api
- **id.dos.me**: https://id.dos.me/
- **Bexly Bot**: https://t.me/BexlyBot
