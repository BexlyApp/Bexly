// Tingee link/unlink proxy.
//
// Bexly client never holds the Tingee secret, so all Tingee API calls go
// through this Edge Function. Authenticated with the user's Supabase JWT.
// Body shape: { action: '<verb>', ...params }.
//
// Phase B implements:
//   action=list_banks       → GET /v1/get-banks
// Phase B.1 will add:
//   action=create_va        → POST /v1/create-va
//   action=confirm_va       → POST /v1/confirm-va
//   action=register_notify  → POST /v1/register-notify
//   action=confirm_register_notify
//   action=delete_va        → DELETE /v1/delete-va
//   action=confirm_delete_va
//
// Deploy: supabase functions deploy tingee-link --project-ref gulptwduchsjcsbndmua
// Secrets: TINGEE_CLIENT_ID, TINGEE_SECRET_TOKEN

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const TINGEE_BASE_URL = 'https://api-sandbox.tingee.vn'; // TODO: switch to prod URL when sandbox testing complete
const TINGEE_CLIENT_ID = Deno.env.get('TINGEE_CLIENT_ID')!;
const TINGEE_SECRET_TOKEN = Deno.env.get('TINGEE_SECRET_TOKEN')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

interface LinkRequest {
  action: 'list_banks' | 'create_va' | 'confirm_va' | 'register_notify' |
          'confirm_register_notify' | 'delete_va' | 'confirm_delete_va';
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

async function callTingee(path: string, method: 'GET' | 'POST' | 'DELETE', body?: unknown) {
  const ts = Math.floor(Date.now() / 1000).toString();
  const bodyStr = body ? JSON.stringify(body) : '';
  const signature = await hmacSha512Hex(
    TINGEE_SECRET_TOKEN,
    `${ts}:${bodyStr}`,
  );

  const res = await fetch(`${TINGEE_BASE_URL}${path}`, {
    method,
    headers: {
      'content-type': 'application/json',
      'x-client-id': TINGEE_CLIENT_ID,
      'x-request-timestamp': ts,
      'x-signature': signature,
    },
    body: body ? bodyStr : undefined,
  });

  const text = await res.text();
  let parsed: unknown = text;
  try {
    parsed = JSON.parse(text);
  } catch {
    /* Non-JSON response; pass through as text */
  }
  return { status: res.status, body: parsed };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return corsJson(204, null);
  }
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
      const { status, body } = await callTingee('/v1/get-banks', 'GET');
      return corsJson(status, body);
    }

    case 'create_va':
    case 'confirm_va':
    case 'register_notify':
    case 'confirm_register_notify':
    case 'delete_va':
    case 'confirm_delete_va':
      // Stub — Phase B.1 will wire these. Returning 501 makes the client
      // show "coming soon" rather than fail silently.
      console.log(`[tingee-link] action=${payload.action} called by ${userId} but not implemented`);
      return corsJson(501, {
        error: 'not_implemented',
        action: payload.action,
        message: 'Phase B.1 — link/unlink flow lands soon.',
      });

    default:
      return corsJson(400, { error: 'unknown_action', action: payload.action });
  }
});
