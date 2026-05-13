# Bexly Agent - Phase 1 (Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold `DOS-AI/apps/bexly-agent/` with Mastra agent that calls DOS AI LLM, persists working memory in Supabase Postgres, and responds to a smoke-test "ping" with locale-aware Phúc/Bexly persona.

**Architecture:** Mastra agent app under DOS-AI pnpm workspace. Single agent (`mainAgent`) with locale-switching system prompt. Storage = Supabase Postgres `bexly_agent` schema via `@mastra/pg` (`PostgresStore` + `PgVector`). LLM = DOS AI alias `dos-ai` via `@ai-sdk/openai-compatible`. No channels in Phase 1 - smoke-test via CLI script that calls `agent.generate()` directly.

**Tech Stack:** TypeScript, Node 24, pnpm workspace, Mastra (`@mastra/core` + `@mastra/memory` + `@mastra/pg`), `@ai-sdk/openai-compatible`, zod, Supabase Postgres.

**Reference spec:** `docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md`

---

## File structure

```
DOS-AI/apps/bexly-agent/
├── package.json                  # Workspace package, deps
├── tsconfig.json                 # TS config (extends @dos/typescript-config)
├── .env.example                  # Documented env vars
├── README.md                     # Run instructions
├── src/
│   ├── lib/
│   │   └── env.ts                # Zod-validated env loader
│   ├── mastra/
│   │   ├── index.ts              # Mastra instance, storage, vector exports
│   │   ├── agents/
│   │   │   └── main.ts           # mainAgent definition + persona + memory
│   │   ├── prompts/
│   │   │   ├── persona-vi.md     # Phúc system prompt (VN)
│   │   │   └── persona-en.md     # Bexly system prompt (EN)
│   │   └── memory/
│   │       └── working-template.md  # Working memory template (markdown)
└── scripts/
    └── smoke-test.ts             # CLI: call agent with "ping", print response
```

**Decisions:**
- Schema name in Postgres: `bexly_agent` (isolated from `bexly` app schema)
- DATABASE_URL: Supabase transaction pooler URL (port 6543, `?pgbouncer=true`) - mirror Nhan pattern, required for serverless concurrency
- LLM provider: `@ai-sdk/openai-compatible` (NOT `@ai-sdk/openai`) - DOS AI is OpenAI-compatible vLLM, strict openai package silently drops tools (per Nhan main.ts comment)
- Persona prompts as separate `.md` files imported as strings - easier to edit/version than inline template literals

---

## Task 1: Workspace scaffold

**Files:**
- Create: `DOS-AI/apps/bexly-agent/package.json`
- Create: `DOS-AI/apps/bexly-agent/tsconfig.json`
- Create: `DOS-AI/apps/bexly-agent/.env.example`
- Create: `DOS-AI/apps/bexly-agent/README.md`

- [ ] **Step 1.1: Create package.json**

```json
{
  "name": "@dos/bexly-agent",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "smoke": "tsx scripts/smoke-test.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@ai-sdk/openai-compatible": "^2.0.45",
    "@mastra/core": "^1.31.0",
    "@mastra/memory": "^1.17.4",
    "@mastra/pg": "^1.9.4",
    "pg": "^8.20.0",
    "zod": "^4.3.6"
  },
  "devDependencies": {
    "@dos/typescript-config": "workspace:*",
    "@types/node": "^24.0.0",
    "tsx": "^4.20.0",
    "typescript": "^6.0.3"
  }
}
```

- [ ] **Step 1.2: Create tsconfig.json**

```json
{
  "extends": "@dos/typescript-config/base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "target": "ES2022",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*", "scripts/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 1.3: Create .env.example**

```bash
# Supabase Postgres for Mastra storage + pgvector
# Use transaction pooler (port 6543) with pgbouncer for serverless concurrency
DATABASE_URL=postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres?pgbouncer=true

# DOS AI LLM endpoint (OpenAI-compatible)
DOS_AI_BASE_URL=https://api.dos.ai/v1
DOS_AI_API_KEY=<bearer-token-or-supabase-jwt>
DOS_AI_MODEL=dos-ai

# Schema isolation in Postgres
BEXLY_AGENT_SCHEMA=bexly_agent

# Disable Mastra auto-create-table fan-out at cold-start (provisioned via migration)
BEXLY_AGENT_MASTRA_DISABLE_INIT=1
```

- [ ] **Step 1.4: Create README.md**

```markdown
# Bexly Agent

Mastra agent for Bexly personal finance app. Phase 1 = foundation only (no channels yet).

## Setup

\`\`\`bash
pnpm install
cp .env.example .env
# fill DATABASE_URL + DOS AI creds
pnpm smoke
\`\`\`

Expected smoke output: agent responds to "ping" with VN greeting (Phúc) or EN greeting (Bexly) depending on input locale.

## References
- Persona spec: Bexly repo `docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md`
- Implementation plan: Bexly repo `docs/superpowers/plans/2026-05-13-bexly-agent-phase-1-foundation.md`
```

- [ ] **Step 1.5: Verify workspace recognizes new package**

Run from `DOS-AI/` root:
```bash
pnpm install
pnpm --filter @dos/bexly-agent typecheck
```

Expected: no errors (TS will complain about missing source files - acceptable until Task 2).

- [ ] **Step 1.6: Commit**

```bash
cd DOS-AI
git add apps/bexly-agent/
git commit -m "feat(bexly-agent): scaffold package + tsconfig + env example"
```

---

## Task 2: Env loader with zod validation

**Files:**
- Create: `DOS-AI/apps/bexly-agent/src/lib/env.ts`

- [ ] **Step 2.1: Write env.ts**

```typescript
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url().describe('Supabase Postgres pooler URL'),
  DOS_AI_BASE_URL: z.string().url().default('https://api.dos.ai/v1'),
  DOS_AI_API_KEY: z.string().min(1),
  DOS_AI_MODEL: z.string().default('dos-ai'),
  BEXLY_AGENT_SCHEMA: z.string().default('bexly_agent'),
  BEXLY_AGENT_MASTRA_DISABLE_INIT: z
    .enum(['0', '1'])
    .default('1')
    .transform((v) => v === '1'),
})

const parsed = envSchema.safeParse(process.env)
if (!parsed.success) {
  console.error('[bexly-agent] Invalid env:', parsed.error.flatten().fieldErrors)
  throw new Error('Invalid environment configuration. See .env.example.')
}

export const env = parsed.data
```

- [ ] **Step 2.2: Typecheck**

```bash
pnpm --filter @dos/bexly-agent typecheck
```

Expected: PASS (just env.ts, no other source files yet).

- [ ] **Step 2.3: Commit**

```bash
git add apps/bexly-agent/src/lib/env.ts
git commit -m "feat(bexly-agent): zod-validated env loader"
```

---

## Task 3: Persona prompts as markdown files

**Files:**
- Create: `DOS-AI/apps/bexly-agent/src/mastra/prompts/persona-vi.md`
- Create: `DOS-AI/apps/bexly-agent/src/mastra/prompts/persona-en.md`
- Create: `DOS-AI/apps/bexly-agent/src/mastra/memory/working-template.md`

- [ ] **Step 3.1: Write persona-vi.md (Phúc)**

```markdown
Bạn là Phúc - trợ lý tài chính cá nhân trong app Bexly.

# Identity
- Tên: Phúc (con trai, trẻ, thân thiện, hiểu tài chính)
- Xưng "em", gọi user "anh" (default) hoặc "chị" (nếu user là nữ)
- Vibe: bạn-thân assistant, lịch sự, lễ phép

# Tone
- Ngắn gọn 1-3 câu, không dài dòng
- Tiếng Việt thuần ("lãi kép" không phải "compound interest")
- Mirror tone user: user casual → em casual, user formal → em formal
- User frustrated → drop humor, direct + xin lỗi
- User tò mò ("là gì vậy?") → educational mode, giải thích đơn giản

# Capabilities (Full Coach)
- Ghi/sửa/xoá giao dịch, tạo budget/goal/recurring, query stats - dùng MCP tools
- Proactive insights: cảnh báo budget, gợi ý tiết kiệm, phát hiện chi tiêu bất thường
- Multi-step planning: phân tích chi tiêu → đề xuất → confirm → execute
- Giải thích khái niệm tài chính cơ bản (lãi kép, lạm phát, quỹ ETF)
- Small talk nhẹ rồi redirect về tài chính

# Boundaries
- KHÔNG tư vấn mua mã chứng khoán/crypto/forex cụ thể
- KHÔNG claim "làm giàu nhanh" hay guaranteed returns
- KHÔNG chính trị, tôn giáo, y tế, pháp luật
- Bank info OK với neutral framing: so sánh 3 bank rates khi user hỏi, không favor bank cụ thể
- Không phán xét đạo đức ("phí tiền", "lãng phí") - dùng từ trung tính ("vượt ngân sách")

# Memory
- Khi user share fact cá nhân (tên, gia đình, sở thích), update working memory template
- Khi cần context, query working memory trước khi hỏi user
- Cap 1 fact extract per message, max 5/day
- User có thể "nhớ giúp em..." để explicit save, "quên..." để delete

# Output
- Plain text reply, no markdown headers in chat
- Numbers: "50.000đ" hoặc "50k" (locale-friendly)
- Action confirmation < 2 câu
```

- [ ] **Step 3.2: Write persona-en.md (Bexly)**

```markdown
You are Bexly - a personal finance assistant in the Bexly app.

# Identity
- Name: Bexly (gender-neutral, young, friendly, financially knowledgeable)
- Use "you" / neutral address
- Vibe: friendly assistant, polite, respectful

# Tone
- 1-3 sentences, concise, no lectures
- Mirror user tone: casual → casual, formal → formal
- User frustrated → drop humor, direct + apologetic
- User curious ("what is...") → educational, explain simply

# Capabilities (Full Coach)
- Record/edit/delete transactions, create budgets/goals/recurring, query stats - use MCP tools
- Proactive insights: budget warnings, saving suggestions, anomaly detection
- Multi-step planning: analyze → propose → confirm → execute
- Explain finance concepts (compound interest, inflation, ETFs)
- Light small talk, redirect to finance

# Boundaries
- NO specific investment picks (which stock/crypto/forex to buy)
- NO get-rich-quick claims or guaranteed returns
- NO politics, religion, medical, legal opinions
- Bank info OK with neutral framing: compare top 3 bank rates when asked, no favoritism
- No moral judgment ("waste", "stupid spending") - use neutral language ("over budget")

# Memory
- When user shares personal facts (name, family, preferences), update working memory
- Query working memory before asking for info user already gave
- Cap 1 fact extract per message, max 5/day
- User can "remember that..." to save explicitly, "forget..." to delete

# Output
- Plain text reply, no markdown headers in chat
- Numbers: locale-friendly format with currency symbol
- Action confirmation under 2 sentences
```

- [ ] **Step 3.3: Write working memory template**

```markdown
# User Profile

## Personal Info
- Name:
- Pronoun: (anh / chị / em / bạn / you)
- Language: (vi / en / ...)
- Family:
- Location:

## Financial Goals
- Short-term (3-12 months):
- Long-term (1-5 years):

## Preferences
- Spending priorities:
- Communication style: (casual / formal)
- Topics to avoid:

## Recent Life Context
- (events affecting finances - new job, big purchase, etc.)

## Session State
- Current focus:
- Open suggestions agent made:
```

- [ ] **Step 3.4: Commit**

```bash
git add apps/bexly-agent/src/mastra/prompts/ apps/bexly-agent/src/mastra/memory/
git commit -m "feat(bexly-agent): persona prompts (vi/en) + working memory template"
```

---

## Task 4: Mastra storage + vector setup

**Files:**
- Create: `DOS-AI/apps/bexly-agent/src/mastra/index.ts`

- [ ] **Step 4.1: Write Mastra entry point**

```typescript
import { Mastra } from '@mastra/core'
import { ConsoleLogger, LogLevel } from '@mastra/core/logger'
import { PostgresStore, PgVector } from '@mastra/pg'

import { env } from '../lib/env.ts'
import { mainAgent } from './agents/main.ts'

// Mastra auto-create-table at cold-start fires 8+ CREATE TABLE statements
// in parallel which exhausts Postgres connections under serverless fan-out.
// We provision schema once via migration (Task 9) and require it to exist.
export const storage = new PostgresStore({
  id: 'bexly-agent-storage',
  connectionString: env.DATABASE_URL,
  schemaName: env.BEXLY_AGENT_SCHEMA,
  disableInit: env.BEXLY_AGENT_MASTRA_DISABLE_INIT,
})

export const vector = new PgVector({
  id: 'bexly-agent-vector',
  connectionString: env.DATABASE_URL,
  schemaName: env.BEXLY_AGENT_SCHEMA,
  disableInit: env.BEXLY_AGENT_MASTRA_DISABLE_INIT,
})

export const mastra = new Mastra({
  storage,
  agents: { main: mainAgent },
  logger: new ConsoleLogger({ name: 'bexly-agent', level: LogLevel.INFO }),
})
```

- [ ] **Step 4.2: Typecheck (will fail - agents/main not yet defined)**

```bash
pnpm --filter @dos/bexly-agent typecheck
```

Expected: FAIL on `Cannot find module './agents/main.ts'`. Proceed to Task 5.

---

## Task 5: Main agent with DOS AI provider + working memory

**Files:**
- Create: `DOS-AI/apps/bexly-agent/src/mastra/agents/main.ts`

- [ ] **Step 5.1: Write main agent**

```typescript
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

import { Agent } from '@mastra/core/agent'
import { Memory } from '@mastra/memory'
import { createOpenAICompatible } from '@ai-sdk/openai-compatible'

import { env } from '../../lib/env.ts'
import { storage, vector } from '../index.ts'

const here = dirname(fileURLToPath(import.meta.url))
const personaVi = readFileSync(join(here, '../prompts/persona-vi.md'), 'utf8')
const personaEn = readFileSync(join(here, '../prompts/persona-en.md'), 'utf8')
const workingMemoryTemplate = readFileSync(
  join(here, '../memory/working-template.md'),
  'utf8',
)

// Locale-aware system prompt: detect user input language, switch persona.
// Both prompts share the same identity rules; only the surface name + pronouns differ.
const systemInstructions = `You are an AI agent that serves users in their language.

## Language detection rule (FIRST priority)
1. Detect the user's input language before doing anything else.
2. If input contains Vietnamese characters (ă, ơ, ư, đ, ê, ô, ...) OR clearly Vietnamese words → respond as Phúc following the VN persona below.
3. Otherwise → respond as Bexly following the EN persona below.
4. NEVER mix languages in a single reply.

---

## VN persona (Phúc)

${personaVi}

---

## EN persona (Bexly)

${personaEn}
`

// DOS AI is OpenAI-protocol compatible (vLLM). Strict @ai-sdk/openai silently
// drops tools when the model alias is not a known OpenAI model. Use the
// -compatible provider instead.
const dosAi = createOpenAICompatible({
  name: 'dos-ai',
  baseURL: env.DOS_AI_BASE_URL,
  apiKey: env.DOS_AI_API_KEY,
})

const memory = new Memory({
  storage,
  vector,
  options: {
    lastMessages: 20,
    semanticRecall: {
      topK: 3,
      messageRange: { before: 2, after: 1 },
    },
    workingMemory: {
      enabled: true,
      scope: 'resource',
      template: workingMemoryTemplate,
    },
  },
})

export const mainAgent = new Agent({
  name: 'BexlyAgent',
  instructions: systemInstructions,
  model: dosAi(env.DOS_AI_MODEL),
  memory,
})
```

- [ ] **Step 5.2: Typecheck**

```bash
pnpm --filter @dos/bexly-agent typecheck
```

Expected: PASS.

- [ ] **Step 5.3: Commit**

```bash
git add apps/bexly-agent/src/mastra/
git commit -m "feat(bexly-agent): main agent with DOS AI provider + locale-switch persona + Mastra memory"
```

---

## Task 6: Postgres schema migration

**Files:**
- Create: `DOS-AI/apps/bexly-agent/scripts/init-schema.sql`
- Create: `DOS-AI/apps/bexly-agent/scripts/init-schema.ts`

- [ ] **Step 6.1: Write init-schema.sql**

Mastra `PostgresStore` and `PgVector` create their tables on first connection unless `disableInit=true`. We want explicit migration to avoid cold-start fan-out. Generate the SQL by running Mastra ONCE in init-enabled mode (locally), then capture DDL. For Phase 1, the simplest path: let Mastra create tables on first run, then commit to never letting it init again.

Pragmatic approach for Phase 1 - use a one-shot init script that:
1. Creates the schema if missing
2. Lets Mastra create its tables (disableInit=false for this single run)
3. Exits

```typescript
// scripts/init-schema.ts
import { PostgresStore, PgVector } from '@mastra/pg'
import { env } from '../src/lib/env.ts'

console.log('[init-schema] creating schema + tables...')

const storage = new PostgresStore({
  id: 'bexly-agent-storage',
  connectionString: env.DATABASE_URL,
  schemaName: env.BEXLY_AGENT_SCHEMA,
  disableInit: false, // allow init for this one-shot
})

const vector = new PgVector({
  id: 'bexly-agent-vector',
  connectionString: env.DATABASE_URL,
  schemaName: env.BEXLY_AGENT_SCHEMA,
  disableInit: false,
})

// Both classes init lazily on first use - force init by calling a no-op
await storage.init()
await vector.init()

console.log('[init-schema] done. Schema:', env.BEXLY_AGENT_SCHEMA)
process.exit(0)
```

- [ ] **Step 6.2: Add npm script**

Modify `apps/bexly-agent/package.json` scripts section:

```json
"scripts": {
  "smoke": "tsx scripts/smoke-test.ts",
  "init-schema": "tsx scripts/init-schema.ts",
  "typecheck": "tsc --noEmit"
}
```

- [ ] **Step 6.3: Run init-schema (manual, after `.env` is set)**

```bash
cd DOS-AI/apps/bexly-agent
pnpm init-schema
```

Expected output: `[init-schema] done. Schema: bexly_agent`. Verify in Supabase SQL editor:
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'bexly_agent';
```
Should list tables: `mastra_messages`, `mastra_threads`, `mastra_resources`, `mastra_evals`, `mastra_traces`, `mastra_workflow_snapshot`, `mastra_vector_*` (exact names per Mastra version).

- [ ] **Step 6.4: Commit**

```bash
git add apps/bexly-agent/scripts/init-schema.ts apps/bexly-agent/package.json
git commit -m "feat(bexly-agent): init-schema script for one-shot Postgres provisioning"
```

---

## Task 7: Smoke test

**Files:**
- Create: `DOS-AI/apps/bexly-agent/scripts/smoke-test.ts`

- [ ] **Step 7.1: Write smoke-test.ts**

```typescript
// scripts/smoke-test.ts
//
// Call the agent with a VN message and an EN message, print responses.
// Validates: env loads, DOS AI reachable, locale-switch works, memory storage writes.

import { mainAgent } from '../src/mastra/agents/main.ts'

const TEST_USER_ID = 'smoke-test-user-001'
const TEST_THREAD_ID_VI = 'smoke-test-thread-vi'
const TEST_THREAD_ID_EN = 'smoke-test-thread-en'

async function run() {
  console.log('--- VN test: expect Phúc reply ---')
  const viResult = await mainAgent.generate(
    'Chào em, anh là Anh. Em có thể giúp anh quản lý tài chính không?',
    {
      memory: { resource: TEST_USER_ID, thread: TEST_THREAD_ID_VI },
    },
  )
  console.log('VN reply:', viResult.text)
  console.log()

  console.log('--- EN test: expect Bexly reply ---')
  const enResult = await mainAgent.generate(
    'Hello, my name is Alex. Can you help me manage my finances?',
    {
      memory: { resource: TEST_USER_ID, thread: TEST_THREAD_ID_EN },
    },
  )
  console.log('EN reply:', enResult.text)
  console.log()

  console.log('--- Memory test: VN follow-up, expect agent to remember "Anh" ---')
  const followup = await mainAgent.generate(
    'Anh vừa chi 50 nghìn cho cafe. Em ghi nhận giúp anh.',
    {
      memory: { resource: TEST_USER_ID, thread: TEST_THREAD_ID_VI },
    },
  )
  console.log('Followup reply:', followup.text)

  process.exit(0)
}

run().catch((err) => {
  console.error('[smoke-test] FAILED:', err)
  process.exit(1)
})
```

- [ ] **Step 7.2: Run smoke test (manual, requires .env + schema initialized)**

```bash
cd DOS-AI/apps/bexly-agent
pnpm smoke
```

Expected:
- VN reply contains Vietnamese characters and ideally uses "em" / "anh"
- EN reply in English, addresses user as "Alex" or "you"
- Followup reply acknowledges the cafe transaction (no tool execution yet since Phase 1 has no tools - acceptable response: "Em ghi nhận anh chi 50.000đ cafe nhé. Hiện em chưa kết nối được công cụ ghi giao dịch, anh nhớ nhập tay vào Bexly cho em.")
- Memory storage row appears in `bexly_agent.mastra_messages`

- [ ] **Step 7.3: Verify memory rows in Supabase**

Run SQL in Supabase:
```sql
SELECT thread_id, role, content_text FROM bexly_agent.mastra_messages
WHERE thread_id IN ('smoke-test-thread-vi', 'smoke-test-thread-en')
ORDER BY created_at;
```
Expected: 6 rows (3 user + 3 assistant).

- [ ] **Step 7.4: Commit**

```bash
git add apps/bexly-agent/scripts/smoke-test.ts
git commit -m "feat(bexly-agent): CLI smoke test (vi + en + memory followup)"
```

---

## Task 8: Documentation polish

**Files:**
- Modify: `DOS-AI/apps/bexly-agent/README.md`

- [ ] **Step 8.1: Update README with actual run instructions**

```markdown
# Bexly Agent

Mastra agent for Bexly personal finance app. Phase 1 = foundation only (no channels yet).

## Persona
- VN locale → "Phúc" (male, xưng em-anh/chị)
- EN + others → "Bexly" (gender-neutral)

Source: see `src/mastra/prompts/persona-vi.md`, `persona-en.md`.

## Setup

1. From DOS-AI root: `pnpm install`
2. Copy `.env.example` to `.env`, fill values:
   - `DATABASE_URL` - Supabase Postgres pooler URL (port 6543, `?pgbouncer=true`)
   - `DOS_AI_API_KEY` - DOS AI bearer token or Supabase JWT
3. Provision schema: `pnpm --filter @dos/bexly-agent init-schema`
4. Smoke test: `pnpm --filter @dos/bexly-agent smoke`

## Architecture

- LLM: DOS AI via `@ai-sdk/openai-compatible` (alias `dos-ai`)
- Storage: Supabase Postgres schema `bexly_agent`
- Memory: `@mastra/memory` working memory (`scope: resource`) + semantic recall (top 3)
- Channels: NONE in Phase 1 (Phase 2+ adds mobile / Telegram / Zalo)

## References
- Persona spec: `Bexly/docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md`
- Implementation plan: `Bexly/docs/superpowers/plans/2026-05-13-bexly-agent-phase-1-foundation.md`
```

- [ ] **Step 8.2: Commit**

```bash
git add apps/bexly-agent/README.md
git commit -m "docs(bexly-agent): README with setup + smoke test instructions"
```

---

## Task 9: Push + verify in DOS-AI

- [ ] **Step 9.1: Push branch**

From `DOS-AI/`:
```bash
git push origin <branch-name>
```

- [ ] **Step 9.2: Final manual verification checklist**

Run from `DOS-AI/`:
```bash
pnpm --filter @dos/bexly-agent typecheck     # Expect: no errors
pnpm --filter @dos/bexly-agent init-schema   # Expect: schema created
pnpm --filter @dos/bexly-agent smoke         # Expect: 3 replies (VN, EN, VN followup)
```

Verify in Supabase SQL:
```sql
SELECT COUNT(*) FROM bexly_agent.mastra_messages;
-- Expect: 6 (3 user + 3 assistant)

SELECT data FROM bexly_agent.mastra_resources
WHERE resource_id = 'smoke-test-user-001';
-- Expect: working memory row with the template (possibly with Name=Anh filled in)
```

- [ ] **Step 9.3: Open PR**

PR title: `feat(bexly-agent): Phase 1 foundation (Mastra scaffold + DOS AI agent + memory)`

PR body should reference:
- Spec: Bexly `docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md`
- Plan: Bexly `docs/superpowers/plans/2026-05-13-bexly-agent-phase-1-foundation.md`

---

## Phase 1 done. What's NOT in Phase 1 (deferred)

- MCP tools (transaction/budget/goal/recurring/insights) → Phase 2
- Mobile channel adapter (replace `ai-proxy` in Bexly Flutter) → Phase 3
- Telegram channel adapter (upgrade `telegram-webhook` EF) → Phase 4
- Zalo channel adapter (new `zalo-webhook` EF) → Phase 5
- Onboarding consent toggle in Bexly mobile → Phase 6
- Tier 2 proactive insights (cron + push) → Phase 7
- Bank product comparison tool + data source → Phase 8

Each gets its own spec/plan/PR cycle.

---

## Self-review checklist

- [x] **Spec coverage:** Phase 1 covers spec sections 1 (Identity), 2 (Tone), 5 (Memory - working + semantic), 6 (Architecture), 7 (Token budget naturally satisfied by template + lastMessages=20). Sections 3-4 (Capabilities, Boundaries) covered partially via persona prompts. Sections 8 (Channels), 9 (Tools), 10 (Insights), 11 (Consent) explicitly deferred.
- [x] **Placeholder scan:** No "TBD" left in tasks. Two intentional deferrals are listed in "What's NOT in Phase 1" with link to future phases.
- [x] **Type consistency:** `mainAgent` defined Task 5, imported in Task 4 and Task 7. `storage` and `vector` exported from `mastra/index.ts` Task 4, imported by `agents/main.ts` Task 5. `env` from `lib/env.ts` Task 2, used by Tasks 4, 5, 6, 7.
- [x] **Ambiguity:** Init-schema strategy (one-shot via script vs proper migration) chosen with rationale - acceptable for Phase 1, can be migrated to proper Mastra migration tool in later phase.
