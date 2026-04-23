# AI Proxy Edge Function Design

Date: 2026-03-03
Status: Approved

## Problem

OpenAI, Gemini, and Claude API keys are bundled in `.env` inside the app binary.
Anyone who decompiles the APK/AAB/web build can extract and abuse them.

## Solution

Single Supabase Edge Function `ai-proxy` that receives AI requests from the
Flutter app, authenticates the user via Supabase JWT, then forwards the request
to the correct provider using server-side API keys.

DOS AI (`api.dos.ai`) is already a server-side proxy — excluded from this change.

## Scope

Proxy 3 providers: OpenAI, Gemini, Claude.
Two actions: `chat` (text conversation) and `ocr` (receipt image scanning).

## Edge Function API

```
POST /functions/v1/ai-proxy
Authorization: Bearer <supabase_access_token>
Content-Type: application/json
```

### Request body

```json
{
  "provider": "openai" | "gemini" | "claude",
  "action": "chat" | "ocr",
  "model": "gpt-4o-mini",
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user", "content": "..." }
  ],
  "image": "base64...",
  "temperature": 0.3,
  "max_tokens": 2000
}
```

- `provider` — required
- `action` — required (`chat` or `ocr`)
- `model` — optional, falls back to provider default
- `messages` — required for `chat`
- `image` — required for `ocr` (base64 JPEG)
- `temperature`, `max_tokens` — optional

### Response

Forward provider response as-is for `chat`. For `ocr`, return parsed JSON.

### Defaults

| Provider | Default Chat Model         | Default OCR Model          |
|----------|---------------------------|---------------------------|
| OpenAI   | gpt-4o-mini               | —                         |
| Gemini   | gemini-2.5-flash-preview  | gemini-2.5-flash-preview  |
| Claude   | —                         | claude-sonnet-4-20250514  |

## Auth Flow

1. Edge Function extracts JWT from `Authorization: Bearer` header
2. Creates Supabase client with user JWT to verify auth
3. Extracts `user_id` for logging
4. Rejects unauthenticated requests with 401

## Server-Side Secrets

Set via `supabase secrets set`:
- `OPENAI_API_KEY`
- `GEMINI_API_KEY`
- `CLAUDE_API_KEY`

## Flutter App Changes

### OpenAIService
- Replace `api.openai.com/v1/chat/completions` URL with Edge Function URL
- Replace `Authorization: Bearer {openai_key}` with `Authorization: Bearer {supabase_jwt}`
- Add `provider: "openai"` and `action: "chat"` to request body

### GeminiService
- Replace `google_generative_ai` SDK calls with HTTP POST to Edge Function
- Add `provider: "gemini"` and `action: "chat"` to request body
- Auth header: Supabase JWT

### GeminiOCRProvider
- Replace direct Gemini API call with Edge Function
- Send `provider: "gemini"`, `action: "ocr"`, `image: base64`

### ClaudeOCRProvider
- Replace `api.anthropic.com/v1/messages` with Edge Function
- Send `provider: "claude"`, `action: "ocr"`, `image: base64`

### BackgroundAIService
- Same changes as above for whichever provider it uses

### .env cleanup
- Remove `OPENAI_API_KEY`, `GEMINI_API_KEY`, `CLAUDE_API_KEY`
- Keep `BEXLY_FREE_AI_KEY` (DOS AI, already server-side)
- Keep all other keys (Stripe publishable, Supabase anon, etc.)

## Error Handling

| Error | HTTP Status | Action |
|-------|-------------|--------|
| No JWT / invalid JWT | 401 | Return error |
| Missing provider/action | 400 | Return error |
| Provider API error (rate limit, quota) | 502 | Forward provider error |
| Provider timeout | 504 | Return timeout error |

## What's NOT in scope

- Streaming (not currently used, add later)
- Rate limiting per user (add later if needed)
- Usage tracking/billing (add later if needed)
- DOS AI proxy (already server-side)
