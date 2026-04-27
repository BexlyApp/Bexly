// Tingee Open Banking webhook receiver.
//
// Tingee POSTs to this URL whenever a linked virtual account sees a credit
// or debit. We:
//   1. Verify the HMAC-SHA512 signature (header x-signature) against the
//      raw body using TINGEE_SECRET_TOKEN (Supabase secret).
//   2. Insert one row into bexly.tingee_transactions, idempotent on
//      transactionCode (Tingee retries up to 5x on non-OK responses).
//   3. Return code "00" so Tingee marks the delivery as successful.
//
// Realtime push to the user's client happens automatically because
// bexly.tingee_transactions is part of the supabase_realtime publication.
//
// Tingee retry policy (per https://developers.tingee.vn/docs/luu-y-quan-trong):
//   - non-"00"/"02" response → retry max 5 times, 5 minutes apart
//   - >10s timeout            → retry max 5 times, 1 minute apart
// We must respond fast (validate → insert → return) and never block on
// downstream side-effects.
//
// Deploy: supabase functions deploy tingee-webhook --project-ref gulptwduchsjcsbndmua
// Secrets needed: TINGEE_CLIENT_ID, TINGEE_SECRET_TOKEN

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface TingeePayload {
  clientId: string;
  transactionCode: string;
  amount: number;
  content: string;
  bank: string;
  accountNumber: string;
  vaAccountNumber: string;
  transactionDate: string; // 'yyyyMMddHHmmss'
  additionalData?: unknown[];
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const TINGEE_CLIENT_ID = Deno.env.get('TINGEE_CLIENT_ID')!;
const TINGEE_SECRET_TOKEN = Deno.env.get('TINGEE_SECRET_TOKEN')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

// Tingee response codes
const RC_OK = '00';
const RC_DUPLICATE = '02'; // also treated as success / no retry
const RC_INVALID_SIGNATURE = '99';
const RC_INVALID_PAYLOAD = '98';
const RC_INTERNAL_ERROR = '97';

function rc(code: string, message?: string) {
  return new Response(
    JSON.stringify({ code, ...(message ? { message } : {}) }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  );
}

async function hmacSha512Hex(key: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    enc.encode(key),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(message));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

// Tingee transactionDate is 'yyyyMMddHHmmss' in UTC+7 → ISO8601
function parseTingeeDate(s: string): string | null {
  if (!/^\d{14}$/.test(s)) return null;
  const y = s.slice(0, 4);
  const mo = s.slice(4, 6);
  const d = s.slice(6, 8);
  const h = s.slice(8, 10);
  const mi = s.slice(10, 12);
  const se = s.slice(12, 14);
  return `${y}-${mo}-${d}T${h}:${mi}:${se}+07:00`;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const rawBody = await req.text();
  const signatureHeader = req.headers.get('x-signature') ?? '';
  const timestampHeader = req.headers.get('x-request-timestamp') ?? '';

  // 1. Reject stale or missing timestamps. Tingee allows ±10 minutes UTC+7.
  const ts = parseInt(timestampHeader, 10);
  if (!ts || Math.abs(Date.now() / 1000 - ts) > 600) {
    return rc(RC_INVALID_SIGNATURE, 'stale or missing timestamp');
  }

  // 2. Verify HMAC-SHA512(`${timestamp}:${rawBody}`, secret) === x-signature
  const expected = await hmacSha512Hex(
    TINGEE_SECRET_TOKEN,
    `${timestampHeader}:${rawBody}`,
  );
  if (!constantTimeEqual(expected, signatureHeader.toLowerCase())) {
    return rc(RC_INVALID_SIGNATURE, 'signature mismatch');
  }

  // 3. Parse payload
  let payload: TingeePayload;
  try {
    payload = JSON.parse(rawBody) as TingeePayload;
  } catch {
    return rc(RC_INVALID_PAYLOAD, 'invalid JSON');
  }

  if (
    !payload.transactionCode ||
    !payload.vaAccountNumber ||
    typeof payload.amount !== 'number'
  ) {
    return rc(RC_INVALID_PAYLOAD, 'missing required fields');
  }

  // Tingee may eventually multiplex partner accounts on one webhook; reject
  // anything that isn't ours.
  if (payload.clientId && payload.clientId !== TINGEE_CLIENT_ID) {
    return rc(RC_INVALID_PAYLOAD, 'wrong clientId');
  }

  // 4. Resolve which Bexly user owns this virtual account.
  const { data: linkedAccount, error: lookupErr } = await supabase
    .schema('bexly')
    .from('linked_bank_accounts')
    .select('id, user_id')
    .eq('tingee_account_id', payload.vaAccountNumber)
    .eq('status', 'active')
    .maybeSingle();

  if (lookupErr) {
    console.error('linked_bank_accounts lookup failed', lookupErr);
    return rc(RC_INTERNAL_ERROR, 'db lookup failed');
  }

  if (!linkedAccount) {
    // VA not linked to any Bexly user — silently accept so Tingee stops
    // retrying. This also covers the case where a user unlinked between
    // notification and delivery.
    return rc(RC_OK);
  }

  // 5. Insert the row. Idempotent on tingee_transaction_id.
  const direction = payload.amount >= 0 ? 'in' : 'out';
  const occurredAt = parseTingeeDate(payload.transactionDate);

  const { error: insertErr } = await supabase
    .schema('bexly')
    .from('tingee_transactions')
    .insert({
      user_id: linkedAccount.user_id,
      linked_account_id: linkedAccount.id,
      tingee_transaction_id: payload.transactionCode,
      raw_payload: payload,
      amount: Math.abs(payload.amount),
      direction,
      bank_code: payload.bank,
      account_number: payload.accountNumber,
      description: payload.content,
      occurred_at: occurredAt,
    });

  if (insertErr) {
    // Duplicate (UNIQUE on tingee_transaction_id) → success, no retry.
    if (insertErr.code === '23505') {
      return rc(RC_DUPLICATE, 'already received');
    }
    console.error('tingee_transactions insert failed', insertErr);
    return rc(RC_INTERNAL_ERROR, 'db insert failed');
  }

  return rc(RC_OK);
});
