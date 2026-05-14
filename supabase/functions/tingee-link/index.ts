// Tingee link/unlink proxy.
//
// Bexly client never holds the Tingee secret, so all Tingee API calls go
// through this Edge Function. Authenticated with the user's Supabase JWT.
// Body shape: { action: '<verb>', ...params }.
//
// Tingee outbound timestamp format: 'yyyyMMddHHmmssSSS' (UTC+7, with ms).
// HMAC-SHA512(`${timestamp}:${requestBody}`, secret), hex-encoded.
//
// Multi-step flows (Tingee returns confirmId, we call confirm-* next):
//   create-va  → confirm-va  → register-notify → confirm-register-notify
//   delete-va  → confirm-delete-va
//
// Webhook URL is configured ONCE in Tingee dashboard. register-notify only
// turns ON notifications for a specific VA - it does not accept a URL field.
//
// Deploy: supabase functions deploy tingee-link --no-verify-jwt --project-ref gulptwduchsjcsbndmua
// Secrets: TINGEE_CLIENT_ID, TINGEE_SECRET_TOKEN
// (Sandbox URL https://uat-open-api.tingee.vn - switch to prod when ready.)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const TINGEE_BASE_URL =
  Deno.env.get('TINGEE_BASE_URL') ?? 'https://open-api.tingee.vn';
const TINGEE_CLIENT_ID = Deno.env.get('TINGEE_CLIENT_ID')!;
const TINGEE_SECRET_TOKEN = Deno.env.get('TINGEE_SECRET_TOKEN')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

interface LinkRequest {
  action:
    | 'list_banks'
    | 'list_vas'
    | 'sync_vas'
    | 'tingee_raw'
    | 'create_va'
    | 'confirm_va'
    | 'register_notify'
    | 'confirm_register_notify'
    | 'delete_va'
    | 'confirm_delete_va';
  [key: string]: unknown;
}

function corsJson(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      'access-control-allow-origin': '*',
      'access-control-allow-headers': 'authorization, content-type',
      'access-control-allow-methods': 'POST, OPTIONS',
    },
  });
}

async function hmacSha512Hex(key: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const ck = await crypto.subtle.importKey(
    'raw',
    enc.encode(key),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', ck, enc.encode(message));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// Tingee outbound timestamp: yyyyMMddHHmmssSSS in UTC+7
function tingeeTimestamp(): string {
  const now = new Date(Date.now() + 7 * 60 * 60 * 1000); // shift to UTC+7
  const pad = (n: number, w = 2) => n.toString().padStart(w, '0');
  return (
    now.getUTCFullYear().toString() +
    pad(now.getUTCMonth() + 1) +
    pad(now.getUTCDate()) +
    pad(now.getUTCHours()) +
    pad(now.getUTCMinutes()) +
    pad(now.getUTCSeconds()) +
    pad(now.getUTCMilliseconds(), 3)
  );
}

interface TingeeResult {
  status: number;
  body: { code?: string; message?: string; data?: Record<string, unknown> } & Record<string, unknown>;
}

async function callTingee(
  path: string,
  method: 'GET' | 'POST' | 'DELETE',
  body?: unknown,
): Promise<TingeeResult> {
  const ts = tingeeTimestamp();
  // Tingee signs the body even when empty: `${ts}:${JSON.stringify(body ?? {})}`.
  // For GET requests the request body itself stays empty, but the signed
  // string uses '{}' to match the official NodeJS/PHP samples.
  const signedBody = JSON.stringify(body ?? {});
  const signature = await hmacSha512Hex(
    TINGEE_SECRET_TOKEN,
    `${ts}:${signedBody}`,
  );

  const res = await fetch(`${TINGEE_BASE_URL}${path}`, {
    method,
    headers: {
      'content-type': 'application/json',
      'x-client-id': TINGEE_CLIENT_ID,
      'x-request-timestamp': ts,
      'x-signature': signature,
    },
    body: body ? signedBody : undefined,
  });

  const text = await res.text();
  let parsed: Record<string, unknown> = { code: 'parse_error', raw: text };
  try {
    parsed = JSON.parse(text);
  } catch {
    /* leave parsed as parse_error */
  }
  return { status: res.status, body: parsed };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsJson(204, null);
  if (req.method !== 'POST') {
    return corsJson(405, { error: 'method_not_allowed' });
  }

  // Authenticate the calling user via their Supabase JWT.
  const auth = req.headers.get('authorization') ?? '';
  if (!auth.startsWith('Bearer ')) {
    return corsJson(401, { error: 'missing_bearer' });
  }
  const jwt = auth.slice(7);
  const { data: userData, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !userData?.user) {
    return corsJson(401, { error: 'invalid_jwt' });
  }
  const userId = userData.user.id;

  let payload: LinkRequest;
  try {
    payload = (await req.json()) as LinkRequest;
  } catch {
    return corsJson(400, { error: 'invalid_json' });
  }

  switch (payload.action) {
    case 'list_banks': {
      const r = await callTingee('/v1/get-banks', 'GET');
      return corsJson(r.status, r.body);
    }

    case 'list_vas': {
      // Raw passthrough of /v1/get-va-paging - returns all VAs Tingee has
      // for this client (the entire Bexly tenant, not just the calling user).
      // Note: Tingee uses POST (not GET) for this endpoint, with optional
      // {page, size} pagination body.
      const r = await callTingee('/v1/get-va-paging', 'POST', { page: 1, size: 100 });
      console.log('[tingee-link] list_vas response', JSON.stringify(r.body));
      return corsJson(r.status, r.body);
    }

    case 'tingee_raw': {
      // Debug-only: forward arbitrary path+method+body to Tingee. Useful
      // for discovering the correct endpoint shape during integration.
      const tPath = (payload.path as string | undefined) ?? '/v1/get-va-paging';
      const tMethod = ((payload.method as string | undefined) ?? 'GET').toUpperCase() as 'GET' | 'POST' | 'DELETE';
      const tBody = payload.body;
      const r = await callTingee(tPath, tMethod, tBody);
      console.log('[tingee-link] tingee_raw', tMethod, tPath, '->', JSON.stringify(r.body).slice(0, 500));
      return corsJson(r.status, r.body);
    }

    case 'sync_vas': {
      // Recover/reconcile: fetch VAs from Tingee, upsert any that match
      // identifying info passed in payload. Client must supply at least
      // accountNumber so we can match the right VA to the calling user
      // (Tingee returns the entire tenant's VAs, not user-scoped).
      const targetAccountNumber = (payload.accountNumber as string | undefined)?.trim();
      const targetIdentity = (payload.identity as string | undefined)?.trim();
      if (!targetAccountNumber && !targetIdentity) {
        return corsJson(400, {
          error: 'sync_vas needs accountNumber or identity to match the VA',
        });
      }
      const r = await callTingee('/v1/get-va-paging', 'POST', { page: 1, size: 100 });
      if (r.body.code !== '00') {
        return corsJson(r.status, r.body);
      }
      const data = r.body.data as Record<string, unknown> | undefined;
      const rawList = Array.isArray(data)
        ? data
        : Array.isArray(data?.items)
            ? (data!.items as unknown[])
            : Array.isArray(data?.records)
                ? (data!.records as unknown[])
                : [];
      const matched: Record<string, unknown>[] = [];
      for (const item of rawList) {
        const v = item as Record<string, unknown>;
        const acc = (v.accountNumber as string | undefined)?.trim();
        const ident = (v.identity as string | undefined)?.trim();
        if (
          (targetAccountNumber && acc === targetAccountNumber) ||
          (targetIdentity && ident === targetIdentity)
        ) {
          matched.push(v);
        }
      }
      console.log(
        '[tingee-link] sync_vas matched',
        matched.length,
        'of',
        rawList.length,
        'VAs',
      );
      let inserted = 0;
      for (const v of matched) {
        const vaNumber =
          (v.vaAccountNumber as string | undefined) ??
          (v.vAccountNumber as string | undefined);
        const bankBin = v.bankBin as string | undefined;
        if (!vaNumber || !bankBin) continue;
        const accountNumber = v.accountNumber as string | undefined;
        const { error } = await supabase
          .schema('bexly')
          .from('linked_bank_accounts')
          .upsert(
            {
              user_id: userId,
              tingee_account_id: vaNumber,
              bank_code: bankBin,
              account_number_masked: maskAccount(accountNumber ?? vaNumber),
              label: (payload.label as string | undefined) ?? (v.label as string | undefined) ?? null,
              status: 'active',
            },
            { onConflict: 'user_id,tingee_account_id' },
          );
        if (error) {
          console.error('[tingee-link] sync_vas upsert failed', error);
          return corsJson(500, { error: error.message });
        }
        inserted++;
      }
      return corsJson(200, {
        code: '00',
        message: 'sync_vas done',
        data: { matched: matched.length, upserted: inserted, total: rawList.length },
      });
    }

    case 'create_va': {
      const reqBody = {
        accountType: payload.accountType ?? 'personal-account',
        bankBin: payload.bankBin,
        accountNumber: payload.accountNumber,
        accountName: payload.accountName,
        identity: payload.identity,
        mobile: payload.mobile,
        isNotifyAccountNumber: payload.isNotifyAccountNumber ?? false,
      };
      if (!reqBody.bankBin || !reqBody.accountNumber || !reqBody.accountName ||
          !reqBody.identity || !reqBody.mobile) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/create-va', 'POST', reqBody);
      return corsJson(r.status, r.body);
    }

    case 'confirm_va': {
      const reqBody = {
        bankBin: payload.bankBin,
        confirmId: payload.confirmId,
        otpNumber: payload.otpNumber,
      };
      if (!reqBody.bankBin || !reqBody.confirmId) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/confirm-va', 'POST', reqBody);
      console.log('[tingee-link] confirm_va response', JSON.stringify(r.body));

      // On success, persist the link locally + auto-chain to register-notify.
      // Tingee's confirm-va response shape is undocumented in our copy of the
      // spec, so prefer fields from the response but fall back to payload
      // values the client passed in (these were the same fields used at
      // create-va time, so they identify the same VA).
      if (r.body.code === '00') {
        const data = (r.body.data ?? {}) as Record<string, unknown>;
        const vaNumber =
          (data.vaAccountNumber as string | undefined) ??
          (data.vAccountNumber as string | undefined) ??
          (payload.vaAccountNumber as string | undefined);
        const accountNumber =
          (data.accountNumber as string | undefined) ??
          (payload.accountNumber as string | undefined);
        const bankBin =
          (data.bankBin as string | undefined) ??
          (payload.bankBin as string | undefined);

        // If we still don't have a vaNumber from any source, fall back to
        // fetching it from /v1/get-va-paging and matching by accountNumber.
        let resolvedVaNumber = vaNumber;
        if (!resolvedVaNumber && accountNumber) {
          console.log('[tingee-link] confirm_va missing vaNumber, fetching from get-va-paging');
          const list = await callTingee('/v1/get-va-paging', 'POST', { page: 1, size: 100 });
          const listData = (list.body.data ?? {}) as Record<string, unknown>;
          const items: unknown[] = Array.isArray(listData)
            ? (listData as unknown[])
            : Array.isArray(listData.items)
                ? (listData.items as unknown[])
                : Array.isArray(listData.records)
                    ? (listData.records as unknown[])
                    : [];
          for (const it of items) {
            const v = it as Record<string, unknown>;
            if ((v.accountNumber as string | undefined) === accountNumber) {
              resolvedVaNumber =
                (v.vaAccountNumber as string | undefined) ??
                (v.vAccountNumber as string | undefined);
              if (resolvedVaNumber) break;
            }
          }
          console.log('[tingee-link] confirm_va resolved vaNumber via paging:', resolvedVaNumber);
        }

        if (resolvedVaNumber && bankBin) {
          const vaNumber = resolvedVaNumber;
          // Insert linked_bank_accounts row (idempotent on (user_id, tingee_account_id))
          const { error: insertErr } = await supabase
            .schema('bexly')
            .from('linked_bank_accounts')
            .upsert(
              {
                user_id: userId,
                tingee_account_id: vaNumber,
                bank_code: bankBin,
                account_number_masked: maskAccount(accountNumber ?? vaNumber),
                label: payload.label as string | null,
                status: 'active',
              },
              { onConflict: 'user_id,tingee_account_id' },
            );

          if (insertErr) {
            console.error('linked_bank_accounts upsert failed', insertErr);
            // Don't fail the API call - the user still has the VA on Tingee
            // side. Surface a warning so the client can retry register_notify.
            return corsJson(r.status, {
              ...r.body,
              warning: 'Created VA on Tingee but failed to persist locally.',
            });
          }

          // Fire-and-forget register-notify so notifications start flowing.
          // Client may also call action=register_notify manually if this fails.
          callTingee('/v1/register-notify', 'POST', {
            vaAccountNumber: vaNumber,
            bankBin,
          })
            .then((rn) => {
              if (rn.body.code === '00' && rn.body.data) {
                console.log(
                  '[tingee-link] register_notify started for VA',
                  vaNumber,
                  'confirmId=',
                  (rn.body.data as Record<string, unknown>).confirmId,
                );
              } else {
                console.warn('[tingee-link] register_notify failed', rn.body);
              }
            })
            .catch((e) => {
              console.error('[tingee-link] register_notify threw', e);
            });
        }
      }
      return corsJson(r.status, r.body);
    }

    case 'register_notify': {
      const reqBody = {
        vaAccountNumber: payload.vaAccountNumber,
        bankBin: payload.bankBin,
      };
      if (!reqBody.vaAccountNumber || !reqBody.bankBin) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/register-notify', 'POST', reqBody);
      return corsJson(r.status, r.body);
    }

    case 'confirm_register_notify': {
      const reqBody = {
        bankBin: payload.bankBin,
        confirmId: payload.confirmId,
        otpNumber: payload.otpNumber,
      };
      if (!reqBody.bankBin || !reqBody.confirmId) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/confirm-register-notify', 'POST', reqBody);
      return corsJson(r.status, r.body);
    }

    case 'delete_va': {
      const reqBody = {
        bankBin: payload.bankBin,
        vaAccountNumber: payload.vaAccountNumber,
      };
      if (!reqBody.bankBin || !reqBody.vaAccountNumber) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/delete-va', 'DELETE', reqBody);
      return corsJson(r.status, r.body);
    }

    case 'confirm_delete_va': {
      const reqBody = {
        bankBin: payload.bankBin,
        confirmId: payload.confirmId,
        otpNumber: payload.otpNumber,
      };
      if (!reqBody.bankBin || !reqBody.confirmId) {
        return corsJson(400, { error: 'missing_required_fields' });
      }
      const r = await callTingee('/v1/confirm-delete-va', 'POST', reqBody);

      // On success mark the local row as unlinked so the client list updates.
      if (r.body.code === '00') {
        const va = (payload as Record<string, unknown>).vaAccountNumber as string | undefined;
        if (va) {
          await supabase
            .schema('bexly')
            .from('linked_bank_accounts')
            .update({ status: 'unlinked', unlinked_at: new Date().toISOString() })
            .eq('user_id', userId)
            .eq('tingee_account_id', va);
        }
      }
      return corsJson(r.status, r.body);
    }

    default:
      return corsJson(400, { error: 'unknown_action', action: payload.action });
  }
});

/** Show only the last 4 digits of an account number; everything else becomes '*'. */
function maskAccount(num: string): string {
  if (num.length <= 4) return num;
  return '*'.repeat(num.length - 4) + num.slice(-4);
}
