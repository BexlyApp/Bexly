# Telegram OAuth Parameter Loss Bug

**Date**: 2026-01-21
**Status**: 🔴 CRITICAL BUG
**Component**: id.dos.me OAuth flow

---

## 🐛 Bug Description

When user clicks "🔗 Link Account" in Telegram bot and opens the login URL with `tg_token` and `redirect` parameters, these parameters are **LOST** during Google OAuth flow.

## 📍 Reproduction Steps

1. Open URL with parameters:
```
https://id.dos.me/login?redirect=bexly%3A%2F%2Ftelegram%2Flinked&tg_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

2. Click "Google" button

3. OAuth redirects to Google:
```
https://accounts.google.com/v3/signin/identifier?
  redirect_uri=https://dos.supabase.co/auth/v1/callback
  state=eyJ... (JWT contains only: referrer, provider, site_url)
```

4. After OAuth completes, callback URL is:
```
https://id.dos.me/auth/callback
```

**Expected**: `https://id.dos.me/auth/callback?tg_token=...&redirect=...`

**Actual**: Parameters are LOST ❌

## 🔍 Root Cause

The `/login` page does NOT preserve `tg_token` and `redirect` query parameters when initiating OAuth flow.

**Current flow**:
```
/login?tg_token=X&redirect=Y
→ Click Google
→ OAuth (state only has referrer)
→ /auth/callback (NO tg_token, NO redirect)
→ STUCK: Cannot process Telegram linking!
```

## ✅ Expected Flow

```
/login?tg_token=X&redirect=Y
→ Click Google
→ OAuth (state preserves tg_token + redirect)
→ /auth/callback?tg_token=X&redirect=Y
→ Process Telegram linking
→ Redirect to bexly://telegram/linked
```

## 🔧 Suggested Fixes

### Option 1: Pass via OAuth `redirectTo` (Recommended)

```typescript
// In /login page
const searchParams = new URLSearchParams(window.location.search);
const tgToken = searchParams.get('tg_token');
const redirect = searchParams.get('redirect');

if (tgToken && redirect) {
  // Preserve parameters in redirectTo
  const callbackUrl = new URL('/auth/callback', window.location.origin);
  callbackUrl.searchParams.set('tg_token', tgToken);
  callbackUrl.searchParams.set('redirect', redirect);

  supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: callbackUrl.toString()
    }
  });
} else {
  // Normal OAuth without Telegram linking
  supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/auth/callback`
    }
  });
}
```

### Option 2: Use Session Storage

```typescript
// In /login page - Before OAuth
const tgToken = searchParams.get('tg_token');
const redirect = searchParams.get('redirect');

if (tgToken && redirect) {
  sessionStorage.setItem('telegram_link_data', JSON.stringify({
    tgToken,
    redirect,
    timestamp: Date.now()
  }));
}

// In /auth/callback page - After OAuth
const linkDataStr = sessionStorage.getItem('telegram_link_data');
if (linkDataStr) {
  const linkData = JSON.parse(linkDataStr);

  // Check not expired (10 minutes)
  if (Date.now() - linkData.timestamp < 600000) {
    const { tgToken, redirect } = linkData;

    // Process Telegram linking...
    // (existing code from commit e691511a)

    sessionStorage.removeItem('telegram_link_data');
  }
}
```

### Option 3: Encode in OAuth State (Complex)

If Supabase allows custom state, encode parameters there:

```typescript
// Not recommended - Supabase manages state internally
// But if possible, add to state JWT
```

## 📊 Impact

- **Severity**: CRITICAL
- **Affected Feature**: Telegram bot account linking
- **User Experience**: Users click link → Stuck on loading page
- **Workaround**: None

## 🧪 Test Cases

After fix, verify:

1. ✅ Parameters preserved through OAuth
2. ✅ Callback receives both `tg_token` and `redirect`
3. ✅ Telegram linking completes successfully
4. ✅ User redirected to `bexly://telegram/linked`
5. ✅ Normal login (without tg_token) still works

## 🔗 Related

- **Original Implementation**: Commit e691511a
- **Test URL**: https://id.dos.me/login?redirect=bexly%3A%2F%2Ftelegram%2Flinked&tg_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZWxlZ3JhbV9pZCI6Ijg4OTYyMzU2NSIsImFwcCI6ImJleGx5IiwiYm90X3VzZXJuYW1lIjoiQmV4bHlCb3QiLCJhcGlfdXJsIjoiaHR0cHM6Ly9kb3Muc3VwYWJhc2UuY28vZnVuY3Rpb25zL3YxL2xpbmstdGVsZWdyYW0iLCJleHAiOjE3Njg5OTA3Njl9.TuYBRiMGI2su50yHnbr95mG-iQ8M_5cKk2ryyE8iKrs
- **Bexly Requirements**: [TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md](./TELEGRAM_BOT_ID_DOS_ME_REQUIREMENTS.md)
- **Debug Report**: [TELEGRAM_INTEGRATION_DEBUG_REPORT.md](./TELEGRAM_INTEGRATION_DEBUG_REPORT.md)

## 📸 Evidence

**Playwright Test Results**:
- ✅ Login page loads correctly
- ✅ Google OAuth triggered
- ❌ Parameters lost in OAuth state
- ❌ Callback URL missing tg_token

**Console Logs**: No errors
**Network Requests**: OAuth flow working, but parameters not preserved

---

**Assignee**: DOS.me Team
**Priority**: P0 (Blocker)
**Labels**: bug, oauth, telegram-integration
