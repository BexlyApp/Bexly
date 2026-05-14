# Bexly Agent - Phase 3.1 (Mobile Channel + Multi-System Coalescer) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Unblock live `agent.generate()` with tools + memory by adding a multi-system-message coalescer (currently DOS AI vLLM rejects multi-system requests). Stand up a Next.js HTTP server in `apps/bexly-agent/` exposing a `POST /api/agent/chat` endpoint. Replace Bexly Flutter mobile chat's `ai-proxy` call with the new endpoint. Render tool calls in the Flutter chat UI as action confirmation cards.

**Architecture:**
- Convert `apps/bexly-agent/` from pure Mastra Node app to Next.js 16 app (matches Nhan pattern; Vercel Fluid Compute deploy target).
- Add Mastra input processor `coalesce-system-messages` that merges all `system` role messages into the first one. Mirrors Nhan's `noopChannelContextProcessor` pattern but solves a different symptom (multi-system content vs duplicate channel context).
- `POST /api/agent/chat` accepts `{ message, threadId? }` with Supabase JWT in Authorization header. Verifies JWT, extracts user_id, calls `mainAgent.generate(message, { memory: { resource: user_id, thread: threadId }, requestContext: { user: { userId, jwt, locale } } })`. Streams response back (SSE).
- Bexly Flutter chat replaces `ai-proxy` call with the new endpoint. Tool calls appear in stream as JSON events; Flutter renders them as action confirmation cards (e.g., "Bexly muốn ghi 50k cà phê - xác nhận?").

**Tech Stack:** Next.js 16 App Router, Mastra v1.33, AI SDK v6 streaming, Vercel AI SDK `useChat` on Flutter side (or custom SSE parser), Supabase JWT auth.

**Reference docs:**
- Spec: `docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md` (section 8 - Channels)
- Nhan Next.js pattern: `C:/tmp/dos-nhan-standalone/apps/nhan/`
- Bexly mobile chat current: `lib/features/ai_chat/data/services/`

---

## File structure (after Phase 3.1)

```
DOS-AI/apps/bexly-agent/
├── package.json                  # + next, react, react-dom deps
├── next.config.mjs               # NEW: Next.js config
├── tsconfig.json                 # + Next.js paths
├── src/
│   ├── app/
│   │   ├── layout.tsx            # NEW: root layout (empty - we're API-only)
│   │   └── api/
│   │       └── agent/
│   │           └── chat/
│   │               └── route.ts  # NEW: POST handler
│   ├── lib/
│   │   ├── env.ts                # unchanged
│   │   ├── supabase-client.ts    # unchanged
│   │   └── verify-jwt.ts         # NEW: server-side JWT verification helper
│   └── mastra/
│       ├── processors/
│       │   └── coalesce-system.ts  # NEW: input processor
│       └── agents/main.ts        # MODIFIED: register processor
├── scripts/ (unchanged)
└── tests/
    └── mastra/
        └── coalesce-system.test.ts  # NEW: unit tests for processor

Bexly/lib/features/ai_chat/data/services/
├── ai_proxy_service.dart         # MODIFIED or DEPRECATED
└── bexly_agent_service.dart      # NEW: calls /api/agent/chat

Bexly/lib/features/ai_chat/presentation/components/
└── action_confirmation_card.dart # NEW: render tool calls
```

---

## Phase 3.1 environment additions

`apps/bexly-agent/.env.example` appends:

```bash
# Public base URL for the agent server (where mobile + future channels will call)
BEXLY_AGENT_PUBLIC_URL=https://bexly-agent.dos.ai
# Used by API routes for verifying JWTs (different from Mastra's pooler URL)
BEXLY_SUPABASE_JWT_ISSUER=https://gulptwduchsjcsbndmua.supabase.co/auth/v1
```

Bexly Flutter `.env` adds:

```
BEXLY_AGENT_URL=https://bexly-agent.dos.ai
```

---

## Task 1: Multi-system message coalescer

**Files:**
- Create: `apps/bexly-agent/src/mastra/processors/coalesce-system.ts`
- Create: `apps/bexly-agent/tests/mastra/coalesce-system.test.ts`
- Modify: `apps/bexly-agent/src/mastra/agents/main.ts` (register processor)

- [ ] **Step 1.1: Write the processor**

```typescript
// src/mastra/processors/coalesce-system.ts
//
// Mastra input processor that merges all system-role messages into a single
// system message at index 0. DOS AI vLLM (Qwen) rejects multi-system or
// out-of-order system messages with "System message must be at the beginning".
// Same class of issue Nhan handled with noopChannelContextProcessor, but
// the upstream cause is different (tool schemas + memory recall both inject
// extra system blocks).

import type { ChatMessage } from '@mastra/core/llm'

interface ProcessorInput {
  messages: ChatMessage[]
}

export const coalesceSystemMessages = {
  id: 'coalesce-system-messages' as const,
  processInputStep: ({ messages }: ProcessorInput): ProcessorInput => {
    const systemBlocks: string[] = []
    const rest: ChatMessage[] = []
    for (const msg of messages) {
      if (msg.role === 'system') {
        // Mastra/AI SDK may put string content or {type:'text', text}[] arrays.
        if (typeof msg.content === 'string') {
          systemBlocks.push(msg.content)
        } else if (Array.isArray(msg.content)) {
          for (const part of msg.content) {
            if (typeof part === 'object' && part !== null && 'text' in part) {
              systemBlocks.push((part as { text: string }).text)
            }
          }
        }
      } else {
        rest.push(msg)
      }
    }
    if (systemBlocks.length === 0) return { messages: rest }
    const merged: ChatMessage = {
      role: 'system',
      content: systemBlocks.join('\n\n---\n\n'),
    }
    return { messages: [merged, ...rest] }
  },
}
```

- [ ] **Step 1.2: Tests**

```typescript
// tests/mastra/coalesce-system.test.ts
import { describe, it } from 'node:test'
import { strict as assert } from 'node:assert'
import { coalesceSystemMessages } from '../../src/mastra/processors/coalesce-system.ts'

describe('coalesceSystemMessages', () => {
  it('passes through when only one system message', () => {
    const result = coalesceSystemMessages.processInputStep({
      messages: [
        { role: 'system', content: 'You are Bexly.' },
        { role: 'user', content: 'Hi' },
      ],
    })
    assert.equal(result.messages.length, 2)
    assert.equal(result.messages[0].role, 'system')
    assert.equal(result.messages[0].content, 'You are Bexly.')
  })

  it('merges multiple system messages with separator', () => {
    const result = coalesceSystemMessages.processInputStep({
      messages: [
        { role: 'system', content: 'Persona' },
        { role: 'system', content: 'Tools' },
        { role: 'user', content: 'Hi' },
      ],
    })
    assert.equal(result.messages.length, 2)
    assert.equal(result.messages[0].role, 'system')
    assert.match(result.messages[0].content as string, /Persona\n\n---\n\nTools/)
    assert.equal(result.messages[1].role, 'user')
  })

  it('moves system message to index 0 even if it appears mid-conversation', () => {
    const result = coalesceSystemMessages.processInputStep({
      messages: [
        { role: 'system', content: 'Persona' },
        { role: 'user', content: 'Hi' },
        { role: 'assistant', content: 'Hello' },
        { role: 'system', content: 'Tool result context injected mid-stream' },
        { role: 'user', content: 'Add 50k cafe' },
      ],
    })
    assert.equal(result.messages[0].role, 'system')
    assert.match(result.messages[0].content as string, /Persona/)
    assert.match(result.messages[0].content as string, /Tool result context/)
    // Original conversation order preserved for non-system messages
    assert.deepEqual(result.messages.slice(1).map((m) => m.role), ['user', 'assistant', 'user'])
  })

  it('handles array-typed system content', () => {
    const result = coalesceSystemMessages.processInputStep({
      messages: [
        { role: 'system', content: [{ type: 'text', text: 'Block A' }, { type: 'text', text: 'Block B' }] as any },
        { role: 'user', content: 'Hi' },
      ],
    })
    assert.match(result.messages[0].content as string, /Block A/)
    assert.match(result.messages[0].content as string, /Block B/)
  })

  it('returns empty system absent if no system messages', () => {
    const result = coalesceSystemMessages.processInputStep({
      messages: [{ role: 'user', content: 'Hi' }],
    })
    assert.equal(result.messages.length, 1)
    assert.equal(result.messages[0].role, 'user')
  })
})
```

- [ ] **Step 1.3: Register on mainAgent**

In `src/mastra/agents/main.ts`, after the existing imports add:

```typescript
import { coalesceSystemMessages } from '../processors/coalesce-system.ts'
```

In the Agent constructor block, add `inputProcessors`:

```typescript
export const mainAgent = new Agent({
  id: 'bexly-main',
  name: 'BexlyAgent',
  instructions: systemInstructions,
  model: dosAi(env.DOS_AI_MODEL),
  memory,
  tools: bexlyTools,
  inputProcessors: [coalesceSystemMessages],
})
```

- [ ] **Step 1.4: Run smoke against DOS AI to confirm fix**

Bring back the live `agent.generate()` calls in `scripts/smoke-tools.ts` (the ones removed in Phase 2 with the documented known issue). Run:

```bash
pnpm --filter @dos/bexly-agent smoke-tools
```

Expected: 3 prompts succeed, agent reply text shows VN/EN persona, no "System message must be at the beginning" error. Update the smoke script to remove the KNOWN ISSUE block.

- [ ] **Step 1.5: Commit**

```bash
git commit -m "feat(bexly-agent): coalesce-system-messages input processor (unblocks tool calls with memory)"
```

---

## Task 2: Add Next.js framework

**Files:**
- Modify: `apps/bexly-agent/package.json` (add next, react, react-dom)
- Create: `apps/bexly-agent/next.config.mjs`
- Create: `apps/bexly-agent/src/app/layout.tsx` (minimal - we're API-only)
- Modify: `apps/bexly-agent/tsconfig.json` (Next.js paths)
- Modify: `apps/bexly-agent/.env.example`

- [ ] **Step 2.1: Add Next.js deps (match Nhan versions)**

Update `package.json` dependencies:

```json
"next": "^16.2.4",
"react": "^19.2.5",
"react-dom": "^19.2.5"
```

devDependencies:

```json
"@types/react": "^19",
"@types/react-dom": "^19"
```

Add `scripts.dev` and `scripts.build`:

```json
"dev": "next dev --turbopack --port 3003",
"build": "next build",
"start": "next start --port 3003"
```

(Port 3003 - Nhan uses 3002, leave space.)

Run `pnpm install`.

- [ ] **Step 2.2: Create next.config.mjs**

```javascript
// next.config.mjs
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Mastra uses dynamic imports that benefit from server components
    serverComponentsExternalPackages: ['@mastra/core', '@mastra/memory', '@mastra/pg'],
  },
}

export default nextConfig
```

- [ ] **Step 2.3: Update tsconfig.json**

Extend Next.js base. Final tsconfig.json:

```json
{
  "extends": "@dos/typescript-config/base.json",
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "target": "ES2022",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "types": ["node"],
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*", "scripts/**/*", "tests/**/*", ".next/types/**/*.ts"],
  "exclude": ["node_modules", "dist", ".next"]
}
```

- [ ] **Step 2.4: Minimal root layout**

`src/app/layout.tsx`:

```tsx
export const metadata = {
  title: 'Bexly Agent',
  description: 'Bexly personal finance AI agent',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="vi">
      <body>{children}</body>
    </html>
  )
}
```

- [ ] **Step 2.5: Add env var**

`.env.example` appends:

```bash
BEXLY_AGENT_PUBLIC_URL=https://bexly-agent.dos.ai
BEXLY_SUPABASE_JWT_ISSUER=https://gulptwduchsjcsbndmua.supabase.co/auth/v1
```

Update `env.ts`:

```typescript
BEXLY_AGENT_PUBLIC_URL: z.string().url().default('http://localhost:3003'),
BEXLY_SUPABASE_JWT_ISSUER: z.string().url(),
```

- [ ] **Step 2.6: Verify**

```bash
pnpm --filter @dos/bexly-agent typecheck
pnpm --filter @dos/bexly-agent build
```

Build should produce a `.next` directory. App will be empty (no pages) but builds.

- [ ] **Step 2.7: Commit**

```bash
git commit -m "feat(bexly-agent): add Next.js 16 framework for HTTP channel layer"
```

---

## Task 3: JWT verification helper

**Files:**
- Create: `apps/bexly-agent/src/lib/verify-jwt.ts`
- Create: `apps/bexly-agent/tests/lib/verify-jwt.test.ts`

- [ ] **Step 3.1: Write the helper**

```typescript
// src/lib/verify-jwt.ts
//
// Server-side JWT verification using Supabase's getUser endpoint. Validates
// that an `Authorization: Bearer <jwt>` header belongs to a real Bexly user
// and returns { userId, jwt } for downstream tool calls. Uses the same
// /auth/v1/user endpoint Bexly mobile uses, so behavior is consistent.

import { env } from './env.ts'

export interface VerifiedUser {
  userId: string
  jwt: string
  email?: string
}

export async function verifyBexlyJwt(authHeader: string | null): Promise<VerifiedUser> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('missing_bearer')
  }
  const jwt = authHeader.slice('Bearer '.length).trim()
  if (!jwt) throw new Error('empty_bearer')

  // Hit /auth/v1/user with the JWT - returns 401 if invalid, user object if valid.
  const res = await fetch(`${env.BEXLY_SUPABASE_JWT_ISSUER}/user`, {
    headers: {
      Authorization: `Bearer ${jwt}`,
      apikey: env.BEXLY_SUPABASE_PUBLISHABLE_KEY,
    },
  })
  if (res.status === 401) throw new Error('invalid_jwt')
  if (!res.ok) throw new Error(`auth_check_failed_${res.status}`)
  const user = (await res.json()) as { id: string; email?: string }
  if (!user.id) throw new Error('jwt_missing_sub')
  return { userId: user.id, jwt, email: user.email }
}
```

- [ ] **Step 3.2: Tests (with fetch mock)**

```typescript
// tests/lib/verify-jwt.test.ts
import { describe, it, mock, before, after } from 'node:test'
import { strict as assert } from 'node:assert'

// Mock global fetch
const realFetch = global.fetch

describe('verifyBexlyJwt', () => {
  before(() => {
    // intentionally left to per-test mocks
  })
  after(() => { global.fetch = realFetch })

  it('throws missing_bearer on null header', async () => {
    const { verifyBexlyJwt } = await import('../../src/lib/verify-jwt.ts')
    await assert.rejects(() => verifyBexlyJwt(null), /missing_bearer/)
  })

  it('throws missing_bearer when header lacks Bearer prefix', async () => {
    const { verifyBexlyJwt } = await import('../../src/lib/verify-jwt.ts')
    await assert.rejects(() => verifyBexlyJwt('Token abc'), /missing_bearer/)
  })

  it('throws invalid_jwt on 401 response', async () => {
    global.fetch = (async () => new Response('{}', { status: 401 })) as typeof fetch
    const { verifyBexlyJwt } = await import('../../src/lib/verify-jwt.ts')
    await assert.rejects(() => verifyBexlyJwt('Bearer expired-token'), /invalid_jwt/)
  })

  it('returns userId + jwt on success', async () => {
    global.fetch = (async () =>
      new Response(JSON.stringify({ id: 'user-uuid-123', email: 'joy@joy.vn' }), { status: 200 })
    ) as typeof fetch
    const { verifyBexlyJwt } = await import('../../src/lib/verify-jwt.ts')
    const result = await verifyBexlyJwt('Bearer valid-jwt')
    assert.equal(result.userId, 'user-uuid-123')
    assert.equal(result.jwt, 'valid-jwt')
    assert.equal(result.email, 'joy@joy.vn')
  })
})
```

- [ ] **Step 3.3: Commit**

```bash
git commit -m "feat(bexly-agent): server-side JWT verification helper"
```

---

## Task 4: `POST /api/agent/chat` route

**Files:**
- Create: `apps/bexly-agent/src/app/api/agent/chat/route.ts`

- [ ] **Step 4.1: Write the route**

```typescript
// src/app/api/agent/chat/route.ts
//
// POST /api/agent/chat - mobile chat endpoint.
// Body: { message: string, threadId?: string }
// Headers: Authorization: Bearer <bexly-user-jwt>
// Response: text stream (SSE) of the agent's reply plus tool-call events.

import { NextRequest } from 'next/server'
import { RequestContext } from '@mastra/core/request-context'
import { mainAgent } from '../../../../mastra/agents/main'
import { verifyBexlyJwt } from '../../../../lib/verify-jwt'

export const runtime = 'nodejs'  // Mastra needs Node, not Edge
export const dynamic = 'force-dynamic'
export const maxDuration = 300  // tool calls + LLM streaming can run long

export async function POST(req: NextRequest) {
  let user
  try {
    user = await verifyBexlyJwt(req.headers.get('authorization'))
  } catch (err) {
    return new Response(JSON.stringify({ error: String((err as Error).message) }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    })
  }

  let body: { message?: string; threadId?: string; locale?: string }
  try {
    body = (await req.json()) as typeof body
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_json' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    })
  }
  if (!body.message || typeof body.message !== 'string') {
    return new Response(JSON.stringify({ error: 'missing_message' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    })
  }

  const threadId = body.threadId ?? `mobile-${user.userId}-${Date.now()}`
  const locale = (body.locale ?? 'vi') as 'vi' | 'en' | 'zh' | 'ja' | 'ko' | 'th'
  const requestContext = new RequestContext()
  requestContext.set('user', { userId: user.userId, jwt: user.jwt, locale })

  const stream = await mainAgent.stream(body.message, {
    memory: { resource: user.userId, thread: threadId },
    requestContext,
  })

  return stream.toTextStreamResponse()
}
```

(Mastra's `agent.stream()` returns a streamable result; `toTextStreamResponse()` produces a streaming Response. Verify the exact method name in `@mastra/core/agent` - if it differs, use the equivalent.)

- [ ] **Step 4.2: Manual curl smoke**

After `pnpm --filter @dos/bexly-agent dev` starts the server on port 3003, run from another shell (controller, not subagent):

```bash
# Extract JWT from emulator (or use a service-issued JWT)
JWT=$(cat C:/tmp/joy-jwt.txt)
curl -N -X POST http://localhost:3003/api/agent/chat \
  -H "Authorization: Bearer $JWT" \
  -H 'Content-Type: application/json' \
  -d '{"message": "Chào em, hôm nay anh chi 80k cafe nhé"}'
```

Expected: streaming text response that ends with the agent's VN reply (Phúc tone), and includes a `record_transaction` tool call event in the stream that succeeds (or fails with explicit RLS error if user has no wallets).

- [ ] **Step 4.3: Commit**

```bash
git commit -m "feat(bexly-agent): POST /api/agent/chat with JWT auth + streaming"
```

---

## Task 5: Bexly Flutter mobile chat service

**Files:**
- Create: `Bexly/lib/features/ai_chat/data/services/bexly_agent_service.dart`
- Modify: `Bexly/lib/features/ai_chat/data/services/` to switch from `ai-proxy` to the new service
- Modify: `Bexly/.env` + `Bexly/lib/core/config/agent_config.dart` (or wherever public URLs live)

This step lives in the Bexly Flutter repo, not DOS-AI. Subagent runs against Bexly worktree, not DOS-AI.

- [ ] **Step 5.1: Set up Bexly worktree**

(Controller does this before dispatching subagent.) From `d:/Projects/Bexly`:

```bash
git worktree add C:/tmp/bexly-agent-channel-mobile -b feat/agent-channel-mobile dev
```

- [ ] **Step 5.2: Write the Dart service**

```dart
// Bexly/lib/features/ai_chat/data/services/bexly_agent_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/utils/logger.dart';

/// Streams agent replies + tool-call events from the Bexly Agent.
///
/// Replaces `ai_proxy_service.dart` for chat conversations. The agent
/// endpoint returns SSE-style chunks: plain text deltas + JSON events
/// for tool calls.
class BexlyAgentService {
  static const _label = 'BexlyAgent';
  final String _baseUrl;

  BexlyAgentService({String? baseUrl})
      : _baseUrl = baseUrl ?? const String.fromEnvironment(
          'BEXLY_AGENT_URL',
          defaultValue: 'https://bexly-agent.dos.ai',
        );

  /// Sends a message to the agent. Yields each text/tool-call chunk
  /// as it arrives. Throws if not signed in or the server returns
  /// non-2xx.
  Stream<AgentChunk> chat({
    required String message,
    String? threadId,
    String locale = 'vi',
  }) async* {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw StateError('Bạn cần đăng nhập để dùng chat AI.');
    }

    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse('$_baseUrl/api/agent/chat'))
        ..headers['Authorization'] = 'Bearer ${session.accessToken}'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'message': message,
          if (threadId != null) 'threadId': threadId,
          'locale': locale,
        });

      final streamed = await client.send(req).timeout(const Duration(seconds: 120));
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        Log.e('agent ${streamed.statusCode}: $body', label: _label);
        throw Exception('Agent error ${streamed.statusCode}');
      }

      await for (final raw in streamed.stream.transform(utf8.decoder)) {
        // Mastra/AI SDK protocol: lines prefixed with "0:" = text delta,
        // "9:" = tool call, "a:" = tool result, etc. (Vercel AI SDK
        // protocol). We parse minimally and surface text + tool calls.
        for (final line in raw.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final chunk = _parseChunk(trimmed);
          if (chunk != null) yield chunk;
        }
      }
    } finally {
      client.close();
    }
  }

  static AgentChunk? _parseChunk(String line) {
    // Vercel AI SDK protocol: <prefix>:<json>
    final colon = line.indexOf(':');
    if (colon < 0) return null;
    final prefix = line.substring(0, colon);
    final payload = line.substring(colon + 1);
    try {
      final decoded = jsonDecode(payload);
      switch (prefix) {
        case '0':
          // Text delta - decoded is a string
          return AgentChunk.text(decoded as String);
        case '9':
          // Tool call - decoded is { toolCallId, toolName, args }
          final m = decoded as Map<String, dynamic>;
          return AgentChunk.toolCall(
            id: m['toolCallId'] as String,
            name: m['toolName'] as String,
            args: (m['args'] as Map?)?.cast<String, dynamic>() ?? {},
          );
        case 'a':
          // Tool result - decoded is { toolCallId, result }
          final m = decoded as Map<String, dynamic>;
          return AgentChunk.toolResult(
            id: m['toolCallId'] as String,
            result: m['result'],
          );
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

class AgentChunk {
  final String type;
  final String? text;
  final String? toolCallId;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final Object? toolResult;

  AgentChunk._({
    required this.type,
    this.text,
    this.toolCallId,
    this.toolName,
    this.toolArgs,
    this.toolResult,
  });

  factory AgentChunk.text(String t) => AgentChunk._(type: 'text', text: t);
  factory AgentChunk.toolCall({required String id, required String name, required Map<String, dynamic> args}) =>
      AgentChunk._(type: 'tool_call', toolCallId: id, toolName: name, toolArgs: args);
  factory AgentChunk.toolResult({required String id, required Object? result}) =>
      AgentChunk._(type: 'tool_result', toolCallId: id, toolResult: result);
}
```

- [ ] **Step 5.3: Add `BEXLY_AGENT_URL` to .env-injected config**

In `lib/core/config/`, find where existing services pick up their base URL (e.g., `ai_proxy_config.dart`) and add an `agentUrl` getter that reads `String.fromEnvironment('BEXLY_AGENT_URL', defaultValue: 'https://bexly-agent.dos.ai')`. Update CI `.env` template + GitHub Actions secrets section in workflows.

- [ ] **Step 5.4: Wire chat provider to use new service**

Find `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` (or equivalent) - the chat state manager. Replace the call into `ai_proxy_service` for conversation turns with `bexlyAgentServiceProvider`. Keep the action-handler code for tool results (it already parses `ACTION_JSON` - now we receive structured tool calls instead, so map them through the same handlers).

This is the trickiest step - read existing code first, plan minimal change. Don't rewrite the whole chat module.

- [ ] **Step 5.5: Action confirmation card widget**

`lib/features/ai_chat/presentation/components/action_confirmation_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

/// Render an agent tool call as a card the user can confirm or cancel.
///
/// Used in the chat stream when the agent emits a `tool_call` event for
/// a mutating action (record_transaction, create_budget, etc.). Read-only
/// queries (analyze_spending, list_transactions) execute silently.
class ActionConfirmationCard extends StatelessWidget {
  const ActionConfirmationCard({
    super.key,
    required this.title,
    required this.body,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String body;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.body2),
          const Gap(AppSpacing.spacing4),
          Text(body, style: AppTextStyles.body4.copyWith(color: AppColors.neutral700)),
          const Gap(AppSpacing.spacing12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Hủy'),
                ),
              ),
              const Gap(AppSpacing.spacing8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Map tool names → confirmation title/body (Vietnamese phrasing matches Phúc persona):

```dart
String _confirmationTitle(String toolName) {
  switch (toolName) {
    case 'record_transaction': return 'Ghi giao dịch?';
    case 'create_budget': return 'Tạo budget?';
    case 'create_goal': return 'Tạo goal?';
    case 'create_recurring': return 'Tạo recurring?';
    case 'delete_transaction': return 'Xóa giao dịch?';
    case 'cancel_recurring': return 'Hủy recurring?';
    default: return 'Xác nhận hành động?';
  }
}
```

- [ ] **Step 5.6: Smoke (manual in emulator)**

Controller runs from `flutter run -d emulator-5554` against the worktree. Open AI chat, type "Anh chi 50k cafe", expect:
- Streaming reply appears
- After or during the text, an action confirmation card appears: "Ghi giao dịch? - 50,000đ - cafe - Ví Chính"
- Tap Xác nhận → transaction lands in Bexly DB (verify via Drift inspector or Supabase sync)
- Tap Hủy → card collapses with "Đã hủy" inline

- [ ] **Step 5.7: Commit + push (Bexly worktree)**

```bash
git -C C:/tmp/bexly-agent-channel-mobile commit -m "feat(ai-chat): mobile uses BexlyAgentService instead of ai-proxy"
git -C C:/tmp/bexly-agent-channel-mobile push origin feat/agent-channel-mobile
```

---

## Task 6: Two PRs + reviewer + merge

**Two PRs because Phase 3.1 spans two repos:**

PR A (DOS-AI): `feat/bexly-agent-phase3-1-mobile` → `dev`
- Coalescer + Next.js scaffold + JWT helper + /api/agent/chat route + smoke
- File diff scope: `apps/bexly-agent/*`

PR B (Bexly): `feat/agent-channel-mobile` → `dev`
- New `BexlyAgentService` + chat provider swap + action confirmation card widget + env var
- File diff scope: `lib/features/ai_chat/*`, `lib/core/config/*`, CI env templates

- [ ] **Step 6.1: Push DOS-AI branch + open PR**

After Tasks 1-4 commits, push and open PR against `dev` (DOS-AI policy: PRs into `main` must come from `dev`).

- [ ] **Step 6.2: Run reviewer subagent on PR A (DOS-AI)**

Dispatch `superpowers:code-reviewer` against the DOS-AI PR. Apply MUST-FIX inline, defer SHOULD-FIX to Phase 3.2/3.3 if not blocking.

- [ ] **Step 6.3: Merge PR A**

```bash
gh pr merge <num> --repo DOS/DOS.AI --squash --delete-branch
```

- [ ] **Step 6.4: Push Bexly branch + open PR**

PR B against `dev`. Body should link to PR A as the upstream dependency.

- [ ] **Step 6.5: Run reviewer subagent on PR B (Bexly)**

Dispatch `superpowers:code-reviewer` against the Bexly PR. Apply MUST-FIX.

- [ ] **Step 6.6: Merge PR B**

```bash
gh pr merge <num> --repo BexlyApp/Bexly --squash --delete-branch
```

- [ ] **Step 6.7: Cleanup worktrees**

```bash
rm -rf C:/tmp/dos-ai-bexly-agent-phase3-1
rm -rf C:/tmp/bexly-agent-channel-mobile
git -C d:/Projects/DOS-AI worktree prune
git -C d:/Projects/Bexly worktree prune
```

---

## Out of scope for Phase 3.1 (Phase 3.2 + 3.3 + later)

- Telegram channel adapter (Phase 3.2)
- Zalo channel adapter (Phase 3.3)
- Deployment to Vercel Fluid Compute (handle as part of PR A merge or follow-up infra ticket)
- Onboarding consent toggle for memory opt-in (Phase 6)
- Proactive insights cron workflows (Phase 7)
- Bank product comparison tool (Phase 8)

---

## Self-review checklist

- [x] **Spec coverage:** Mobile channel adapter (spec section 8) + multi-system coalescer (carries Phase 2 known issue) + JWT auth (consistent with `ai-proxy`).
- [x] **Placeholder scan:** Two deliberate references to "find existing code" in Task 5.3 + 5.4 - those steps require reading Bexly's current chat module first, can't be specified upfront without reading.
- [x] **Type consistency:** `RequestContext` from `@mastra/core/request-context`, `AgentChunk` Dart class matches `tool_call`/`tool_result` event types from Vercel AI SDK protocol.
- [x] **Scope check:** 2 PRs across 2 repos but tightly coupled (mobile won't work without DOS-AI side). Phase 3.2 (Telegram) and 3.3 (Zalo) each get own plan.
- [x] **Ambiguity:** Mastra `agent.stream()` exact method name + return type may differ in v1.33 - subagent should verify against installed types at Task 4 implementation. Same for `inputProcessors` field name on Agent constructor (Task 1.3).
