# Bexly Integration với DOS-Me Supabase

Document này mô tả cách Bexly integrate với DOS-Me Supabase như một **first-party product**.

## TL;DR

Bexly sử dụng **Direct Supabase Access** - đúng approach cho first-party mobile app.

## Authentication Flow

### Current Implementation ✅

```dart
// lib/core/services/auth/supabase_auth_service.dart

// 1. Initialize Supabase client
final supabase = SupabaseClient(
  'https://dos.supabase.co',
  publishableKey, // Safe to expose in mobile apps
);

// 2. Sign in with Google OAuth
await supabase.auth.signInWithOAuth(provider: 'google');

// 3. Access token for API calls (if needed)
final session = await supabase.auth.getSession();
final token = session.access_token; // Supabase JWT
```

### Data Sync ✅

```dart
// lib/core/services/sync/supabase_sync_service.dart

// Direct database access với RLS policies
await _supabase
  .schema('bexly')
  .from('wallets')
  .select()
  .eq('user_id', userId);

await _supabase
  .schema('bexly')
  .from('transactions')
  .insert(data);
```

## Architecture

### ✅ What We Use (Correct)

| Component | Implementation | Status |
|-----------|----------------|--------|
| **Auth** | Supabase Auth | ✅ Correct |
| **Database** | Direct Supabase access | ✅ Correct |
| **Sync** | RLS-based queries | ✅ Correct |
| **Token** | Supabase JWT | ✅ Correct |

### ❌ What We Don't Need

- ~~OAuth 2.1 PKCE~~ - Only for third-party apps
- ~~DOS-Me API~~ - Direct Supabase access is sufficient
- ~~Origin validation~~ - Web-only (mobile apps don't send Origin header)
- ~~Custom tokens~~ - Supabase JWT works directly

## Configuration

### Environment Variables

```env
# .env
SUPABASE_URL=https://dos.supabase.co
SUPABASE_PUBLISHABLE_KEY=eyJhbG...  # Public key (safe to expose)
```

### Database Schema

All tables in `bexly` schema with RLS policies:
- `bexly.users` - User profiles
- `bexly.wallets` - User wallets
- `bexly.transactions` - Financial transactions
- `bexly.categories` - Category templates + custom
- `bexly.budgets` - Budget tracking
- `bexly.goals` - Financial goals

RLS ensures users can only access their own data:
```sql
CREATE POLICY "Users can view own data"
  ON bexly.wallets FOR SELECT
  USING (user_id = auth.uid());
```

## Modified Hybrid Sync

Category sync optimization (90-97% storage reduction):

```dart
// Only sync modified/custom categories
final categoriesToSync = categories.where((cat) {
  return cat.source == 'custom' ||
         (cat.source == 'built-in' && cat.hasBeenModified);
}).toList();

// Built-in categories stay local unless modified
await syncService.syncCategoriesToCloud(categoriesToSync);
```

**Result:**
- Before: 76 categories/user × 1M users = 76M records
- After: 2-8 categories/user × 1M users = 2-8M records
- **Savings: 90-97%**

## Security

### ✅ What's Secure

1. **Publishable Key** - Public by design, safe in mobile apps
2. **RLS Policies** - Server-side authorization
3. **Supabase JWT** - Verified by Supabase, cannot be forged
4. **Google OAuth** - Managed by Google, secure flow

### ⚠️ What to Avoid

- ❌ Never expose `SUPABASE_SERVICE_KEY` in client apps
- ❌ Never bypass RLS policies
- ❌ Never trust client-side validation only

## Future: DOS-Me API (If Needed)

If we need DOS-Me API endpoints in future (wallet transfers, gaming integration, etc.):

1. **Option A: Keep First-Party** (Recommended)
   - Contact DOS-Me team to whitelist Bexly
   - Use Supabase JWT for API calls
   - No OAuth needed

2. **Option B: Migrate to Third-Party**
   - Register OAuth client
   - Implement PKCE flow
   - Request scopes from users
   - See: `D:\Projects\DOS-Me\docs\developer\INTEGRATION-GUIDE.md`

## References

- [DOS-Me Integration Guide](../../../DOS-Me/docs/developer/INTEGRATION-GUIDE.md)
- [Supabase Docs](https://supabase.com/docs)
- [OAuth 2.1 PKCE](https://oauth.net/2.1/)

## Changelog

### 2026-01-15
- ✅ Removed legacy `dos_me_api_service.dart`
- ✅ Confirmed direct Supabase approach is correct
- ✅ Implemented Modified Hybrid Sync for categories
- ✅ Documented first-party integration pattern

---

**Status:** Production Ready ✅
**Last Updated:** 2026-01-15
**Maintained By:** Bexly Team
