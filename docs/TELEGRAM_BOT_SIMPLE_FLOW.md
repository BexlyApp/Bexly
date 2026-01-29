# Telegram Bot Integration - Simplified Flow

## Overview

**Simple approach:** Use existing `/login` page instead of creating new routes!

## Flow

```
Bot → https://id.dos.me/login?redirect=bexly://telegram/linked&tg_token=JWT
    → User logs in
    → id.dos.me calls Bexly Edge Function
    → Redirect to bexly://telegram/linked
```

## Implementation

### 1. Bexly Bot (✅ DONE)

Bot generates JWT and creates login URL:

```typescript
const redirectUrl = encodeURIComponent("bexly://telegram/linked");
const loginUrl = `https://id.dos.me/login?redirect=${redirectUrl}&tg_token=${jwtToken}`;
```

**Status:** ✅ Deployed to `https://dos.supabase.co/functions/v1/telegram-webhook`

### 2. id.dos.me Login Page (⏳ IN PROGRESS)

After successful login, check for `tg_token`:

```typescript
// In login success handler
const tgToken = searchParams.get('tg_token');
const redirect = searchParams.get('redirect');

if (tgToken && redirect) {
  // Decode JWT
  const payload = jwt.verify(tgToken, process.env.TELEGRAM_JWT_SECRET);

  // Call Bexly API
  await fetch('https://dos.supabase.co/functions/v1/link-telegram', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ telegram_id: payload.telegram_id }),
  });

  // Redirect to app
  window.location.href = redirect;
}
```

**Status:** ⏳ DOS.me team implementing

### 3. Bexly App Deep Link (TODO)

Handle `bexly://telegram/linked` deep link:

```dart
// In deep link handler
if (uri.scheme == 'bexly' && uri.host == 'telegram' && uri.pathSegments.contains('linked')) {
  // Show success message
  showSuccessToast('Telegram account linked successfully!');

  // Navigate to bot integration screen
  context.go('/settings/bot-integration');
}
```

**Status:** TODO

## Advantages

✅ No new routes needed
✅ Simpler architecture
✅ No 404 errors
✅ Less code to maintain
✅ Reuses existing login flow

## Test

1. Open Telegram: https://t.me/BexlyBot
2. Send any message
3. Click "🔗 Link Account" button
4. Login on id.dos.me
5. Get redirected to Bexly app

## Environment Variables

### Bexly (Supabase)
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_JWT_SECRET`

### id.dos.me
- `TELEGRAM_JWT_SECRET` (same as Bexly)
