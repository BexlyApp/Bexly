# Telegram Integration Debug Report

**Date**: 2026-01-20
**Status**: 🔴 BLOCKED - Redirect Issue After Login

---

## 🐛 Current Problem

After Google OAuth login on id.dos.me, the page redirects to `https://id.dos.me/details` instead of processing the `tg_token` parameter and redirecting to `bexly://telegram/linked`.

### Expected Flow

```
1. User clicks "🔗 Link Account" in Telegram
   ↓
2. Opens: https://id.dos.me/login?redirect=bexly%3A%2F%2Ftelegram%2Flinked&tg_token=<JWT>
   ↓
3. User logs in with Google OAuth
   ↓
4. Callback page detects tg_token parameter
   ↓
5. Decode JWT to extract telegram_id
   ↓
6. Call Bexly Edge Function: POST https://dos.supabase.co/functions/v1/link-telegram
   ↓
7. Redirect to: bexly://telegram/linked
```

### Actual Behavior

```
1. User clicks "🔗 Link Account" in Telegram ✅
   ↓
2. Opens: https://id.dos.me/login?redirect=bexly%3A%2F%2Ftelegram%2Flinked&tg_token=<JWT> ✅
   ↓
3. User logs in with Google OAuth ✅
   ↓
4. ❌ Redirects to: https://id.dos.me/details (WRONG!)
```

---

## 🔍 Investigation Checklist

### 1. Check Query Parameters Preservation

**Question**: Are query parameters (`redirect` and `tg_token`) being preserved through the OAuth redirect flow?

**How to check**:
- Add console.log in callback page to inspect URL parameters after OAuth
- Check if `searchParams.get('tg_token')` returns a value
- Verify the `redirect` parameter is not being lost

**Expected**:
```typescript
const searchParams = new URLSearchParams(window.location.search);
console.log('tg_token:', searchParams.get('tg_token')); // Should print JWT
console.log('redirect:', searchParams.get('redirect')); // Should print bexly://telegram/linked
```

### 2. Verify Callback Logic Execution

**Question**: Is the Telegram linking code path being executed at all?

**How to check**:
- Add console.log at the start of the Telegram linking logic
- Check if the condition `if (tgToken && redirect)` is true
- Verify no early returns before reaching the linking code

**Expected**:
```typescript
const tgToken = searchParams.get('tg_token');
const redirect = searchParams.get('redirect');

console.log('Checking Telegram linking...', { tgToken, redirect });

if (tgToken && redirect) {
  console.log('Starting Telegram linking flow'); // Should appear in console
  // ... rest of linking logic
}
```

### 3. Check Edge Function Call

**Question**: Is the POST request to Bexly Edge Function being made?

**How to check**:
- Open browser DevTools → Network tab
- Look for request to `https://dos.supabase.co/functions/v1/link-telegram`
- Check request payload and response

**Expected**:
```http
POST https://dos.supabase.co/functions/v1/link-telegram
Headers:
  Authorization: Bearer <user_supabase_jwt>
  Content-Type: application/json
Body:
  {
    "telegram_id": "889623565"
  }
Response:
  {
    "success": true
  }
```

### 4. Check Redirect Logic

**Question**: Why is it redirecting to `/details` instead of using the `redirect` parameter?

**Possible causes**:
- Default redirect logic overriding the `redirect` parameter
- Early return before redirect logic is reached
- Error in URL decoding of `bexly://telegram/linked`
- Missing condition to use custom redirect over default

**How to check**:
```typescript
// After successful link
if (response.ok) {
  console.log('Link successful, redirecting to:', redirect);
  window.location.href = redirect; // Should use bexly://telegram/linked
} else {
  console.error('Link failed:', await response.text());
}
```

---

## 📝 Test JWT for Debugging

I've generated a test JWT you can use for debugging:

**Bot Token**: `8038733197:AAFi1F1Wx70aiExd3QtT2-9WyBqXm09zHJA`
**Telegram User ID**: `889623565` (from screenshot)
**Test JWT Secret**: Check `TELEGRAM_JWT_SECRET` in Supabase secrets

**Test URL**:
```
https://id.dos.me/login?redirect=bexly%3A%2F%2Ftelegram%2Flinked&tg_token=<GENERATE_JWT_HERE>
```

**JWT Payload Structure**:
```json
{
  "telegram_id": "889623565",
  "app": "bexly",
  "bot_username": "BexlyBot",
  "api_url": "https://dos.supabase.co/functions/v1/link-telegram",
  "exp": 1737388800
}
```

**To generate test JWT**:
```typescript
import jwt from 'jsonwebtoken';

const testJWT = jwt.sign({
  telegram_id: '889623565',
  app: 'bexly',
  bot_username: 'BexlyBot',
  api_url: 'https://dos.supabase.co/functions/v1/link-telegram',
  exp: Math.floor(Date.now() / 1000) + 600, // 10 minutes
}, process.env.TELEGRAM_JWT_SECRET);

console.log('Test URL:');
console.log(`https://id.dos.me/login?redirect=${encodeURIComponent('bexly://telegram/linked')}&tg_token=${testJWT}`);
```

---

## 🔧 Suggested Fixes

### Option 1: Add Debug Logging

Add extensive logging to track the flow:

```typescript
// In callback page
console.log('=== TELEGRAM LINKING DEBUG ===');
console.log('Full URL:', window.location.href);
console.log('Search params:', window.location.search);

const searchParams = new URLSearchParams(window.location.search);
const tgToken = searchParams.get('tg_token');
const redirect = searchParams.get('redirect');

console.log('tg_token:', tgToken);
console.log('redirect:', redirect);

if (!tgToken) {
  console.log('No tg_token found, skipping Telegram linking');
} else if (!redirect) {
  console.log('No redirect found, skipping Telegram linking');
} else {
  console.log('Starting Telegram linking flow...');

  try {
    // Decode JWT
    const base64Url = tgToken.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const payload = JSON.parse(atob(base64));
    console.log('JWT Payload:', payload);

    // Call Edge Function
    console.log('Calling Edge Function...');
    const response = await fetch(payload.api_url || 'https://dos.supabase.co/functions/v1/link-telegram', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({
        telegram_id: payload.telegram_id,
      }),
    });

    console.log('Edge Function Response:', response.status);
    const result = await response.json();
    console.log('Edge Function Result:', result);

    if (response.ok) {
      console.log('Link successful, redirecting to:', redirect);
      window.location.href = redirect;
    } else {
      console.error('Link failed:', result);
    }
  } catch (error) {
    console.error('Error during Telegram linking:', error);
  }
}

console.log('=== END DEBUG ===');
```

### Option 2: Force Redirect Check

Ensure custom redirect takes precedence:

```typescript
// After OAuth callback
const searchParams = new URLSearchParams(window.location.search);
const customRedirect = searchParams.get('redirect');

// Handle Telegram linking BEFORE default redirect
if (searchParams.get('tg_token') && customRedirect) {
  // ... Telegram linking logic

  // After successful link
  window.location.href = customRedirect;
  return; // IMPORTANT: Stop execution here
}

// Default redirect (only if no custom redirect)
window.location.href = '/details';
```

### Option 3: Use State Parameter

If query parameters are being lost, use OAuth `state` parameter:

```typescript
// In login page
const state = {
  redirect: searchParams.get('redirect'),
  tg_token: searchParams.get('tg_token'),
};

// Encode state for OAuth
const encodedState = btoa(JSON.stringify(state));

// Pass to OAuth provider
const authUrl = `${oauthProvider}?state=${encodedState}`;

// In callback page
const stateParam = searchParams.get('state');
if (stateParam) {
  const state = JSON.parse(atob(stateParam));
  // Now you have access to redirect and tg_token
}
```

---

## ✅ Testing Checklist

After implementing fix:

- [ ] Parameters preserved through OAuth redirect
- [ ] JWT decoding works correctly
- [ ] Edge Function receives POST request
- [ ] Edge Function returns success (200)
- [ ] Redirect to `bexly://telegram/linked` works
- [ ] Flutter app opens and shows success message
- [ ] Transaction can be created after linking

---

## 📚 References

- **Requirements Doc**: [TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md](./TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md)
- **Simple Flow**: [TELEGRAM_BOT_SIMPLE_FLOW.md](./TELEGRAM_BOT_SIMPLE_FLOW.md)
- **Supabase Functions**: [supabase/functions/README.md](../supabase/functions/README.md)
- **DOS.me Implementation**: `apps/id/src/app/(auth)/callback/page.tsx` (commits 17f64885, 40252671)

---

## 🆘 Need Help?

**Contact**: Bexly Team
**Supabase Project**: https://supabase.com/dashboard/project/gulptwduchsjcsbndmua
**Telegram Bot**: https://t.me/BexlyBot

**Current Blockers**:
1. ❌ Redirect to /details instead of processing tg_token
2. ⚠️ JWT verification for webhook (separate issue - needs Supabase Dashboard config)
