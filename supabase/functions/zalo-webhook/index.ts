// Zalo Webhook - Phase 3.3: routes to Bexly Agent when BEXLY_ZALO_USE_AGENT=true.
// Zalo OA Message API docs: https://developers.zalo.me/docs/api/official-account-api
//
// Required env (Supabase secrets):
//   BEXLY_ZALO_ACCESS_TOKEN  - OA access token from oa.zalo.me dashboard
//   BEXLY_ZALO_APP_SECRET    - OA app secret (used for HMAC signature verify)
//   BEXLY_ZALO_USE_AGENT     - "true" to route to agent; otherwise replies with maintenance notice
//   BEXLY_AGENT_URL          - Bexly Agent base URL (default https://ai.bexly.app)
//   BEXLY_CHANNEL_SECRET     - shared secret proving this is a trusted backend
//                              caller into the agent (no forged user JWT)
//   SUPABASE_URL             - auto-injected
//   SUPABASE_SERVICE_ROLE_KEY - auto-injected
//
// Signature scheme: Zalo signs POSTs with header `mac` =
//   HMAC-SHA256(rawBody + access_token, app_secret) as lowercase hex.
// See: https://developers.zalo.me/docs/official-account/webhook/verify-webhook-origin

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

const ZALO_ACCESS_TOKEN = Deno.env.get('BEXLY_ZALO_ACCESS_TOKEN')
const ZALO_APP_SECRET = Deno.env.get('BEXLY_ZALO_APP_SECRET')
const USE_AGENT = Deno.env.get('BEXLY_ZALO_USE_AGENT') === 'true'
const BEXLY_AGENT_URL = Deno.env.get('BEXLY_AGENT_URL') ?? 'https://ai.bexly.app'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
// Shared secret for trusted server-to-server calls into the Bexly Agent.
// Supabase signs user JWTs with asymmetric ES256 keys, so this webhook
// cannot mint a matching token; it authenticates as a trusted channel
// caller instead and names the target user via X-Bexly-User-Id.
const BEXLY_CHANNEL_SECRET = Deno.env.get('BEXLY_CHANNEL_SECRET')

function getSupabaseClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: 'bexly' },
  })
}

// Verify Zalo OA webhook signature.
// Zalo computes: HMAC-SHA256(rawBody + access_token, app_secret) as lowercase hex,
// then sends it in the `mac` request header.
async function verifyZaloSignature(rawBody: string, macHeader: string | null): Promise<boolean> {
  if (!macHeader || !ZALO_APP_SECRET || !ZALO_ACCESS_TOKEN) return false
  const message = rawBody + ZALO_ACCESS_TOKEN
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(ZALO_APP_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(message))
  const expected = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
  // Constant-time compare to prevent timing attacks
  if (expected.length !== macHeader.length) return false
  let diff = 0
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ macHeader.charCodeAt(i)
  }
  return diff === 0
}

// Send a text message to a Zalo user via the OA Customer Service Message API.
// Docs: https://developers.zalo.me/docs/api/official-account-api/message/send-message-to-user
async function sendZaloMessage(zaloUserId: string, text: string): Promise<void> {
  if (!ZALO_ACCESS_TOKEN) {
    console.error('[zalo-webhook] BEXLY_ZALO_ACCESS_TOKEN not set; cannot send message')
    return
  }
  const res = await fetch('https://openapi.zalo.me/v3.0/oa/message/cs', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      access_token: ZALO_ACCESS_TOKEN,
    },
    body: JSON.stringify({
      recipient: { user_id: zaloUserId },
      message: { text },
    }),
  })
  if (!res.ok) {
    const body = await res.text().catch(() => '')
    console.error(`[zalo-webhook] sendZaloMessage failed (${res.status}): ${body.slice(0, 200)}`)
  }
}

// Look up the Bexly user_id linked to this Zalo user, if any.
async function getBexlyUserId(zaloUserId: string): Promise<string | null> {
  const { data } = await getSupabaseClient()
    .from('user_integrations')
    .select('user_id')
    .eq('platform', 'zalo')
    .eq('platform_user_id', zaloUserId)
    .maybeSingle()
  return data?.user_id ?? null
}

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

// POST message to the Bexly Agent as a trusted channel caller, accumulate the
// streamed reply, return plain text. Authenticates with the shared channel
// secret + explicit user id instead of forging a user JWT (Supabase signs
// user tokens with asymmetric ES256 keys; no shared HS256 secret exists).
async function callBexlyAgent(bexlyUserId: string, message: string, threadId: string): Promise<string> {
  if (!BEXLY_CHANNEL_SECRET) throw new Error('BEXLY_CHANNEL_SECRET not configured')
  const res = await fetch(`${BEXLY_AGENT_URL}/api/agent/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Bexly-Channel-Secret': BEXLY_CHANNEL_SECRET,
      'X-Bexly-User-Id': bexlyUserId,
    },
    body: JSON.stringify({ message, threadId, locale: 'vi' }),
  })
  if (!res.ok) {
    const body = await res.text().catch(() => '')
    throw new Error(`agent ${res.status}: ${body.slice(0, 200)}`)
  }
  // Accumulate plain-text or SSE streaming response
  const decoder = new TextDecoder()
  const reader = res.body?.getReader()
  if (!reader) throw new Error('agent: no response body')
  let full = ''
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    full += decoder.decode(value, { stream: true })
  }
  return full.trim()
}

// ── Webhook entry point ──────────────────────────────────────────────────────

serve(async (req) => {
  // Zalo sends GET to verify webhook URL during OA setup - respond 200 immediately
  if (req.method === 'GET') {
    return new Response('ok', { status: 200 })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const rawBody = await req.text()

  // Verify Zalo HMAC signature from `mac` header
  const macHeader = req.headers.get('mac')
  const isAuthentic = await verifyZaloSignature(rawBody, macHeader)
  if (!isAuthentic) {
    console.error('[zalo-webhook] Signature verification failed')
    return new Response(JSON.stringify({ error: 'invalid_signature' }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    })
  }

  let body: {
    event_name?: string
    sender?: { id?: string }
    message?: { text?: string }
    follower?: { id?: string }
  }
  try {
    body = JSON.parse(rawBody)
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_json' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    })
  }

  console.log('[zalo-webhook] event_name:', body.event_name)

  // Only handle user_send_text; acknowledge everything else so Zalo stops retrying
  if (body.event_name !== 'user_send_text') {
    return new Response('ok', { status: 200 })
  }

  const zaloUserId = body.sender?.id
  const text = body.message?.text?.trim()
  if (!zaloUserId || !text) {
    return new Response('ok', { status: 200 })
  }

  console.log('[zalo-webhook] message from zaloUserId:', zaloUserId, '| text:', text.slice(0, 80))

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

  if (!USE_AGENT) {
    await sendZaloMessage(
      zaloUserId,
      'Bexly Agent dang trong giai doan beta. Vui long quay lai sau.',
    )
    return new Response('ok', { status: 200 })
  }

  // Forward to Bexly Agent
  try {
    const reply = await callBexlyAgent(bexlyUserId, text, `zalo-${zaloUserId}`)
    if (reply.length > 0) {
      await sendZaloMessage(zaloUserId, reply)
    } else {
      await sendZaloMessage(zaloUserId, 'Em chua hieu ro y anh/chi, anh/chi noi lai giup em nhe.')
    }
  } catch (err) {
    console.error('[zalo-webhook] agent call failed:', err)
    await sendZaloMessage(zaloUserId, 'Em gap loi tam thoi, anh/chi thu lai sau it phut nhe.')
  }

  return new Response('ok', { status: 200 })
})
