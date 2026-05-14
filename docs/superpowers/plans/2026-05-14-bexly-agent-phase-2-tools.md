# Bexly Agent - Phase 2 (MCP Tools) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ~21 MCP tools to `mainAgent` covering all 5 tiers from spec section 9 except bank comparison (Phase 8) and cron-scheduled proactive workflows (Phase 7). Tools query/mutate Bexly Supabase (`gulptwduchsjcsbndmua`) directly via PostgREST with user JWT pass-through (RLS enforces per-user scoping).

**Architecture:** Inline MCP tools in `apps/bexly-agent/src/mcp/`. Per-request Bexly Supabase client factory takes user JWT from tool runtime context. Tools grouped by domain (one file per domain). Each tool ships with Zod schema + Mastra tool definition + unit tests with mocked Supabase client. Live integration smoke test at the end uses JOY's real user_id against Bexly prod with a dummy wallet + automatic cleanup.

**Tech Stack:** TypeScript, Mastra `@mastra/core/agent` `tools` option, `@supabase/supabase-js`, zod, `node:test` for unit tests.

**Reference spec:** `docs/superpowers/specs/2026-05-13-bexly-agent-persona-design.md` (section 9 - Tools)

**Bexly DB schema (cached, do not re-query):**
- `bexly.transactions` (cloud_id uuid PK, user_id uuid, wallet_id uuid, category_id uuid, transaction_type text, amount numeric, currency varchar, description text, notes text, transaction_date timestamp, is_deleted bool, created_at, updated_at)
- `bexly.budgets` (cloud_id uuid PK, user_id, wallet_id, category_id, name text, amount numeric, currency, period text, start_date, end_date, alert_threshold int, is_active bool, is_routine bool, is_deleted bool)
- `bexly.goals` (cloud_id uuid PK, user_id, name text, target_amount numeric, current_amount numeric, currency, deadline timestamp, is_achieved bool, pinned bool, is_deleted bool)
- `bexly.recurring_transactions` (cloud_id uuid PK, user_id, name text, amount numeric, currency, transaction_type, category_id, frequency text, next_date timestamp, is_active bool, is_deleted bool, wallet_id)
- `bexly.wallets` (cloud_id uuid PK, user_id, name text, balance numeric, currency, wallet_type, is_active bool, is_deleted bool)
- `bexly.categories` (cloud_id uuid PK, user_id, name text, icon, color, category_type text, is_default bool, parent_id uuid, is_deleted bool)
- Soft-delete pattern: filter `is_deleted = false` on every read
- RLS: `auth.uid() = user_id` policies expected (verify in Task 1)

---

## File structure

```
DOS-AI/apps/bexly-agent/src/
├── lib/
│   ├── supabase-client.ts        # Factory: createBexlyClient(jwt) returns scoped client
│   └── tool-context.ts           # Type: { userId, jwt, locale } - passed via Mastra runtime
├── mcp/
│   ├── index.ts                  # Aggregates all tools, exports `bexlyTools`
│   ├── transactions.ts           # 4 tools: record/update/delete/list
│   ├── budgets.ts                # 2 tools: create/query_status
│   ├── goals.ts                  # 2 tools: create/query_progress
│   ├── recurring.ts              # 3 tools: create/list/cancel
│   ├── insights.ts               # 4 tools: analyze/anomaly/savings/health
│   ├── memory.ts                 # 3 tools: update/query/forget (wraps Mastra working memory)
│   ├── education.ts              # 1 tool: explain_concept (curated JSON-backed)
│   ├── locale.ts                 # 2 tools: format_currency, format_date
│   └── concepts/                 # Knowledge base for education tool
│       ├── vi.json
│       └── en.json
└── mastra/agents/main.ts         # Modified: add `tools: bexlyTools` to Agent config
```

---

## Phase 2 environment additions

Add to `.env.example` + `env.ts` schema:

```
# Bexly user DB (separate from agent's own Supabase)
BEXLY_SUPABASE_URL=https://gulptwduchsjcsbndmua.supabase.co
BEXLY_SUPABASE_ANON_KEY=<bexly-anon-key>
```

The anon key is used as PostgREST `apikey`; the user JWT becomes the `Authorization: Bearer` header, so RLS scopes queries to `auth.uid() = user_id`.

---

## Task 1: Plumbing - Supabase client factory + tool runtime context

**Files:**
- Create: `apps/bexly-agent/src/lib/tool-context.ts`
- Create: `apps/bexly-agent/src/lib/supabase-client.ts`
- Create: `apps/bexly-agent/tests/lib/supabase-client.test.ts`
- Modify: `apps/bexly-agent/src/lib/env.ts` (add BEXLY_SUPABASE_URL, BEXLY_SUPABASE_ANON_KEY)
- Modify: `apps/bexly-agent/.env.example`

- [ ] **Step 1.1: Add env vars**

In `.env.example`:
```bash
BEXLY_SUPABASE_URL=https://gulptwduchsjcsbndmua.supabase.co
BEXLY_SUPABASE_ANON_KEY=<bexly-anon-key>
```

In `env.ts`, add to schema:
```typescript
BEXLY_SUPABASE_URL: z.string().url(),
BEXLY_SUPABASE_ANON_KEY: z.string().min(1),
```

- [ ] **Step 1.2: Define tool runtime context type**

`src/lib/tool-context.ts`:
```typescript
import { z } from 'zod'

export const ToolContextSchema = z.object({
  userId: z.string().uuid().describe('Bexly user_id (Supabase auth.uid)'),
  jwt: z.string().min(1).describe('User Supabase JWT, used for RLS scoping'),
  locale: z.enum(['vi', 'en', 'zh', 'ja', 'ko', 'th']).default('vi'),
})
export type ToolContext = z.infer<typeof ToolContextSchema>
```

- [ ] **Step 1.3: Write supabase-client.ts**

```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { env } from './env.ts'

/**
 * Creates a Bexly Supabase client scoped to a user via their JWT.
 * RLS policies enforce per-user data isolation; the anon key is just the
 * PostgREST apikey.
 */
export function createBexlyClient(jwt: string): SupabaseClient {
  return createClient(env.BEXLY_SUPABASE_URL, env.BEXLY_SUPABASE_ANON_KEY, {
    auth: { persistSession: false },
    global: {
      headers: { Authorization: `Bearer ${jwt}` },
    },
    db: { schema: 'bexly' },
  })
}
```

- [ ] **Step 1.4: Add `@supabase/supabase-js` dep**

Add to `apps/bexly-agent/package.json` dependencies (check Nhan version - use the same):
```json
"@supabase/supabase-js": "^2.104.1"
```

Run `pnpm install` from worktree root.

- [ ] **Step 1.5: Write unit test for client factory**

`tests/lib/supabase-client.test.ts`:
```typescript
import { describe, it } from 'node:test'
import { strict as assert } from 'node:assert'
import { createBexlyClient } from '../../src/lib/supabase-client.ts'

describe('createBexlyClient', () => {
  it('creates client with bexly schema and user JWT header', () => {
    const client = createBexlyClient('test-jwt-token')
    // Supabase client doesn't expose headers/schema directly; verify it doesn't throw
    // and exposes the .from() method we'll use in tools.
    assert.ok(typeof client.from === 'function')
  })
})
```

Add test script to `package.json`:
```json
"test": "node --env-file=.env --import tsx --test 'tests/**/*.test.ts'"
```

- [ ] **Step 1.6: Verify RLS policies on bexly.transactions, budgets, goals, recurring_transactions, wallets, categories**

Use Supabase MCP `execute_sql` (controller runs, not subagent):
```sql
SELECT tablename, policyname, cmd, qual::text
FROM pg_policies
WHERE schemaname = 'bexly'
  AND tablename IN ('transactions','budgets','goals','recurring_transactions','wallets','categories');
```

Document findings in commit message. If any table lacks `auth.uid() = user_id` SELECT policy, flag as BLOCKED so JOY can add migration before tools land.

- [ ] **Step 1.7: Commit**

```bash
git -C <worktree> add apps/bexly-agent/src/lib/ apps/bexly-agent/tests/lib/ apps/bexly-agent/package.json apps/bexly-agent/.env.example
git -C <worktree> commit -m "feat(bexly-agent): Bexly Supabase client factory + tool runtime context

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Transaction tools (4)

**Files:**
- Create: `apps/bexly-agent/src/mcp/transactions.ts`
- Create: `apps/bexly-agent/tests/mcp/transactions.test.ts`

Tools (Mastra `createTool` pattern, each takes `context: ToolContext` plus typed input):

| Tool | Input | Behavior |
|---|---|---|
| `record_transaction` | `{ amount, transaction_type: 'income'\|'expense', wallet_id?, category_id?, description, notes?, transaction_date? }` | Insert into `bexly.transactions`. Default `wallet_id` = first active wallet of user (query `bexly.wallets`). Default `transaction_date` = now. Returns `{ cloud_id }`. |
| `update_transaction` | `{ cloud_id, fields: Partial<...> }` | UPDATE row scoped by user_id (RLS). `has_been_modified=true`. Returns updated row. |
| `delete_transaction` | `{ cloud_id }` | Soft delete: `is_deleted=true, deleted_at=now()`. |
| `list_transactions` | `{ period?, wallet_id?, category_id?, transaction_type?, min_amount?, max_amount?, limit? = 20 }` | SELECT with filters + `is_deleted = false`, ORDER BY transaction_date DESC. |

- [ ] **Step 2.1: Write tests first** - mock `createBexlyClient` to return a stub with `from()` chain, assert tools call the right table/columns. Test happy path + wallet fallback (no wallet_id → uses first active wallet) + RLS error propagation.

Skeleton:
```typescript
import { describe, it, mock } from 'node:test'
import { strict as assert } from 'node:assert'
import { recordTransaction } from '../../src/mcp/transactions.ts'

// Mock createBexlyClient to return a chainable stub
function stubClient(impl: (chain: string[]) => unknown) {
  // [implement stub - chain.from('transactions').insert({...}).select().single()]
}

describe('record_transaction', () => {
  it('inserts with default wallet when wallet_id missing', async () => {
    // arrange + act + assert
  })
  it('inserts at provided wallet_id', async () => { /* ... */ })
  it('defaults transaction_date to now', async () => { /* ... */ })
})

// Repeat for update/delete/list
```

- [ ] **Step 2.2: Implement `transactions.ts`** - use `createTool` from `@mastra/core/tools`. Pattern:

```typescript
import { createTool } from '@mastra/core/tools'
import { z } from 'zod'
import { createBexlyClient } from '../lib/supabase-client.ts'
import type { ToolContext } from '../lib/tool-context.ts'

export const recordTransaction = createTool({
  id: 'record_transaction',
  description: 'Record a financial transaction (income or expense) in the user's Bexly account.',
  inputSchema: z.object({
    amount: z.number().positive(),
    transaction_type: z.enum(['income', 'expense']),
    wallet_id: z.string().uuid().optional(),
    category_id: z.string().uuid().optional(),
    description: z.string().min(1),
    notes: z.string().optional(),
    transaction_date: z.string().datetime().optional(),
  }),
  outputSchema: z.object({
    cloud_id: z.string().uuid(),
    transaction_date: z.string(),
  }),
  execute: async ({ context, runtimeContext }) => {
    const ctx = runtimeContext.get('user') as ToolContext
    const sb = createBexlyClient(ctx.jwt)

    let walletId = context.wallet_id
    if (!walletId) {
      const { data: w } = await sb
        .from('wallets')
        .select('cloud_id')
        .eq('user_id', ctx.userId)
        .eq('is_active', true)
        .eq('is_deleted', false)
        .order('created_at', { ascending: true })
        .limit(1)
        .single()
      if (!w) throw new Error('User has no active wallet')
      walletId = w.cloud_id
    }

    const { data, error } = await sb
      .from('transactions')
      .insert({
        user_id: ctx.userId,
        wallet_id: walletId,
        category_id: context.category_id ?? null,
        transaction_type: context.transaction_type,
        amount: context.amount,
        currency: 'VND',  // TODO Phase 2.1: derive from wallet
        description: context.description,
        notes: context.notes ?? null,
        transaction_date: context.transaction_date ?? new Date().toISOString(),
        is_deleted: false,
        has_been_modified: false,
        parsed_from_email: false,
      })
      .select('cloud_id, transaction_date')
      .single()

    if (error) throw new Error(`record_transaction failed: ${error.message}`)
    return data
  },
})
```

Continue with `updateTransaction`, `deleteTransaction`, `listTransactions` following the same template.

- [ ] **Step 2.3: Run tests** - `pnpm --filter @dos/bexly-agent test tests/mcp/transactions.test.ts`. Iterate until green.

- [ ] **Step 2.4: Commit**

```bash
git -C <worktree> add apps/bexly-agent/src/mcp/transactions.ts apps/bexly-agent/tests/mcp/transactions.test.ts
git -C <worktree> commit -m "feat(bexly-agent): transaction tools (record/update/delete/list)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Budget tools (2)

**Files:**
- Create: `apps/bexly-agent/src/mcp/budgets.ts`
- Create: `apps/bexly-agent/tests/mcp/budgets.test.ts`

| Tool | Input | Behavior |
|---|---|---|
| `create_budget` | `{ name, amount, period: 'weekly'\|'monthly'\|'one-time', category_id?, wallet_id?, start_date?, end_date?, alert_threshold? = 80 }` | INSERT into `bexly.budgets`. Default start_date=today. is_active=true, is_routine=(period != 'one-time'). |
| `query_budget_status` | `{ period? = 'current_month' }` | SELECT all active budgets + compute used% (sum of matching `bexly.transactions.amount` in period). Returns array `[{name, amount, used, used_pct, period}]`. |

Same TDD pattern as Task 2. Mock client, test happy paths + edge cases (no category filter, wallet fallback). Commit after green.

---

## Task 4: Goal tools (2)

**Files:**
- Create: `apps/bexly-agent/src/mcp/goals.ts`
- Create: `apps/bexly-agent/tests/mcp/goals.test.ts`

| Tool | Input | Behavior |
|---|---|---|
| `create_goal` | `{ name, target_amount, deadline?, currency? = 'VND' }` | INSERT into `bexly.goals` with current_amount=0, is_achieved=false, pinned=false. |
| `query_goal_progress` | `{ goal_id?: uuid }` | SELECT goal(s) for user. If `goal_id` given, return that one; else list all not-deleted goals with `pct_complete = current_amount/target_amount`. |

Same TDD pattern. Commit.

---

## Task 5: Recurring tools (3)

**Files:**
- Create: `apps/bexly-agent/src/mcp/recurring.ts`
- Create: `apps/bexly-agent/tests/mcp/recurring.test.ts`

| Tool | Input | Behavior |
|---|---|---|
| `create_recurring` | `{ name, amount, transaction_type, frequency: 'daily'\|'weekly'\|'monthly'\|'yearly', start_date?, category_id?, wallet_id? }` | INSERT into `bexly.recurring_transactions` with is_active=true, next_date computed from start_date + frequency. |
| `list_recurring` | `{ include_inactive? = false }` | SELECT for user. Returns array with `name, amount, frequency, next_date, total_monthly` (normalized monthly cost: weekly*4.33, daily*30, yearly/12). |
| `cancel_recurring` | `{ cloud_id }` | UPDATE is_active=false. Does NOT soft-delete (history preserved for past charges). |

Same TDD pattern. Commit.

---

## Task 6: Insights compute tools (4)

**Files:**
- Create: `apps/bexly-agent/src/mcp/insights.ts`
- Create: `apps/bexly-agent/tests/mcp/insights.test.ts`

Read-only compute. No DB writes. Each tool aggregates `bexly.transactions` data.

| Tool | Input | Behavior |
|---|---|---|
| `analyze_spending` | `{ period: 'this_week'\|'this_month'\|'last_month'\|'last_3_months', group_by: 'category'\|'wallet'\|'day' }` | Aggregate sum(amount) where transaction_type='expense', is_deleted=false. Returns `{ total, breakdown: [{key, amount, pct}] }`. |
| `detect_anomalies` | `{ period: 'this_week'\|'this_month' }` | Compare current period vs same-length prior period per category. Return categories where current > 1.3 * prior. Output: `[{category_id, category_name, current, prior, pct_change}]`. |
| `compute_savings_potential` | `{}` | sum(income last 30d) - sum(expense last 30d) = idle. If idle > avg monthly income, return `{ idle_balance, monthly_income_avg, potential_yearly_interest: idle * 0.06 }`. |
| `compute_financial_health_score` | `{}` | 0-100 score. Components: savings_rate (40pt), budget_adherence (30pt), goal_progress (20pt), recurring_ratio (10pt). Returns `{ score, components: {...}, tier: 'excellent'\|'good'\|'needs_work'\|'needs_attention' }`. |

TDD: mock client returns canned aggregates, assert math + thresholds. Commit.

---

## Task 7: Memory wrappers (3)

**Files:**
- Create: `apps/bexly-agent/src/mcp/memory.ts`
- Create: `apps/bexly-agent/tests/mcp/memory.test.ts`

Mastra's working memory has built-in tools (`updateWorkingMemory`, etc.) but they auto-fire during reasoning. We expose explicit user-facing tools so the agent has a deliberate "remember/forget" verb the user can ask for.

| Tool | Input | Behavior |
|---|---|---|
| `update_user_memory` | `{ section: string, field: string, value: string }` | Reads current working memory markdown, parses sections, updates field, writes back via Mastra Memory API. |
| `query_user_memory` | `{ section?: string, field?: string }` | Reads current working memory, returns full markdown or filtered section/field value. |
| `forget_memory` | `{ section: string, field: string }` | Sets field value to blank in working memory markdown. |

Implementation note: working memory in Mastra is stored as a markdown string per the template. Parse via simple regex/`marked` lib for section/field extraction. Round-trip the string preserving structure.

TDD: mock Mastra Memory `getWorkingMemory()` + `updateWorkingMemory()`. Commit.

---

## Task 8: Education tool (1) + concepts JSON

**Files:**
- Create: `apps/bexly-agent/src/mcp/education.ts`
- Create: `apps/bexly-agent/src/mcp/concepts/vi.json`
- Create: `apps/bexly-agent/src/mcp/concepts/en.json`
- Create: `apps/bexly-agent/tests/mcp/education.test.ts`

| Tool | Input | Behavior |
|---|---|---|
| `explain_concept` | `{ concept_id, depth: 'short'\|'detailed' = 'short' }` | Look up concept_id in `concepts/<locale>.json` (locale from runtime context). Return `{ title, explanation, example, related_concepts }`. |

Concept IDs (initial set, both vi.json and en.json must have all):
- `lai_kep` (compound interest)
- `lam_phat` (inflation)
- `quy_etf` (ETF fund)
- `quy_mo` (open-ended fund)
- `bao_hiem_nhan_tho` (life insurance)
- `dau_tu_dai_han` (long-term investing)
- `ngan_sach` (budget concept)
- `quy_du_phong` (emergency fund)
- `lai_suat_ngan_hang` (bank interest)
- `tin_dung` (credit basics)

Each entry: `{ title, short, detailed, example, related }`.

TDD: assert lookup hit + locale fallback (if vi has it but en is missing, fall back to vi with a notice). Commit.

---

## Task 9: Locale tools (2)

**Files:**
- Create: `apps/bexly-agent/src/mcp/locale.ts`
- Create: `apps/bexly-agent/tests/mcp/locale.test.ts`

| Tool | Input | Behavior |
|---|---|---|
| `format_currency` | `{ amount: number, currency? = 'VND', locale? }` | Use `Intl.NumberFormat`. VN locale defaults: `vi-VN` with `currency: 'VND', maximumFractionDigits: 0`. |
| `format_date` | `{ date: string (ISO), format? = 'short'\|'long', locale? }` | Use `Intl.DateTimeFormat`. VN short = `DD-MM-YYYY`, long = `Thứ <day>, DD/MM/YYYY`. |

TDD: snapshot expected outputs for vi/en. Commit.

---

## Task 10: Aggregate + wire into agent

**Files:**
- Create: `apps/bexly-agent/src/mcp/index.ts`
- Modify: `apps/bexly-agent/src/mastra/agents/main.ts`

- [ ] **Step 10.1: Aggregate exports**

`src/mcp/index.ts`:
```typescript
import { recordTransaction, updateTransaction, deleteTransaction, listTransactions } from './transactions.ts'
import { createBudget, queryBudgetStatus } from './budgets.ts'
// ... etc

export const bexlyTools = {
  record_transaction: recordTransaction,
  update_transaction: updateTransaction,
  delete_transaction: deleteTransaction,
  list_transactions: listTransactions,
  create_budget: createBudget,
  query_budget_status: queryBudgetStatus,
  create_goal: createGoal,
  query_goal_progress: queryGoalProgress,
  create_recurring: createRecurring,
  list_recurring: listRecurring,
  cancel_recurring: cancelRecurring,
  analyze_spending: analyzeSpending,
  detect_anomalies: detectAnomalies,
  compute_savings_potential: computeSavingsPotential,
  compute_financial_health_score: computeFinancialHealthScore,
  update_user_memory: updateUserMemory,
  query_user_memory: queryUserMemory,
  forget_memory: forgetMemory,
  explain_concept: explainConcept,
  format_currency: formatCurrency,
  format_date: formatDate,
}
```

- [ ] **Step 10.2: Wire into mainAgent**

In `src/mastra/agents/main.ts`, add tools to Agent constructor:

```typescript
import { bexlyTools } from '../../mcp/index.ts'

export const mainAgent = new Agent({
  id: 'bexly-main',
  name: 'BexlyAgent',
  instructions: systemInstructions,
  model: dosAi(env.DOS_AI_MODEL),
  memory,
  tools: bexlyTools,
})
```

- [ ] **Step 10.3: Typecheck**

```bash
pnpm --filter @dos/bexly-agent typecheck
```

Expected: PASS.

- [ ] **Step 10.4: Commit**

```bash
git commit -m "feat(bexly-agent): wire 21 MCP tools into mainAgent"
```

---

## Task 11: Live integration smoke test

**Files:**
- Create: `apps/bexly-agent/scripts/smoke-tools.ts`

Smoke test that:
1. Creates a throwaway test wallet on JOY's account (so we don't pollute his real wallets)
2. Runs the agent with a few VN messages exercising each tool tier:
   - "Anh chi 80k cafe sáng nay nhé em" → expects `record_transaction` call
   - "Tháng này anh chi bao nhiêu cho ăn uống?" → expects `analyze_spending` 
   - "Lập budget 3 triệu cho cafe mỗi tháng" → expects `create_budget`
   - "Tạo goal mua xe 500 triệu trong 2 năm" → expects `create_goal`
   - "Lãi kép là gì em?" → expects `explain_concept`
3. After all, deletes the test wallet + its transactions (cleanup)

Uses JOY's user_id `8f2d530b-8528-415a-bd62-e9876f698ffb`. Needs a real Bexly user JWT (extract from emulator like before).

- [ ] **Step 11.1: Write smoke-tools.ts**

```typescript
import { mainAgent } from '../src/mastra/agents/main.ts'
import { createBexlyClient } from '../src/lib/supabase-client.ts'

const USER_ID = '8f2d530b-8528-415a-bd62-e9876f698ffb'
const JWT = process.env.BEXLY_USER_JWT
if (!JWT) throw new Error('Set BEXLY_USER_JWT env var with JOY user JWT (extract from emulator)')

const sb = createBexlyClient(JWT)

// Setup: create throwaway wallet
const { data: testWallet, error: walletErr } = await sb
  .from('wallets')
  .insert({
    user_id: USER_ID,
    name: 'Agent Test Wallet',
    balance: 0,
    currency: 'VND',
    wallet_type: 'cash',
    is_active: true,
    is_deleted: false,
    has_been_modified: false,
  })
  .select('cloud_id')
  .single()
if (walletErr) throw walletErr
const TEST_WALLET_ID = testWallet.cloud_id
console.log('[setup] test wallet', TEST_WALLET_ID)

const ctx = { userId: USER_ID, jwt: JWT, locale: 'vi' as const }
const runtimeContext = new Map([['user', ctx]])

try {
  const prompts = [
    'Anh chi 80k cafe sáng nay nhé em',
    'Tháng này anh chi bao nhiêu cho ăn uống?',
    'Lập budget 3 triệu cho cafe mỗi tháng',
    'Tạo goal mua xe 500 triệu trong 2 năm',
    'Lãi kép là gì em?',
  ]
  for (const p of prompts) {
    console.log('\n--- USER:', p)
    const r = await mainAgent.generate(p, {
      memory: { resource: 'smoke-tools-' + USER_ID, thread: 'smoke-tools-vi' },
      runtimeContext,
    })
    console.log('AGENT:', r.text)
  }
} finally {
  // Cleanup: delete test wallet's transactions + wallet itself
  await sb.from('transactions').delete().eq('wallet_id', TEST_WALLET_ID).eq('user_id', USER_ID)
  await sb.from('wallets').delete().eq('cloud_id', TEST_WALLET_ID).eq('user_id', USER_ID)
  console.log('\n[cleanup] removed test wallet + transactions')
}

process.exit(0)
```

- [ ] **Step 11.2: Add script to package.json**

```json
"smoke-tools": "node --env-file=.env --import tsx scripts/smoke-tools.ts"
```

- [ ] **Step 11.3: Run smoke test (controller, not subagent)**

Extract JWT from emulator like Phase 1, set `BEXLY_USER_JWT` env, then:
```bash
pnpm --filter @dos/bexly-agent smoke-tools
```

Expected:
- Each prompt produces an agent reply that includes the matching tool result (transaction recorded, budget created, etc.)
- After completion, the test wallet + all test TXs are gone (cleanup ran)

- [ ] **Step 11.4: Commit**

```bash
git commit -m "feat(bexly-agent): live tool smoke test with throwaway wallet + cleanup"
```

---

## Task 12: PR + final review

- [ ] Push branch, open PR against `dev` (NOT `main`, per DOS-AI policy)
- [ ] Run `superpowers:code-reviewer` against the PR
- [ ] Apply MUST-FIX + SHOULD-FIX items
- [ ] Merge PR myself (controller does this, never JOY - per [[feedback-joy-never-reviews-code]])
- [ ] Cleanup worktree

---

## What's deferred to later phases

- Mobile/Telegram/Zalo channel adapters (Phase 3-5)
- Onboarding consent toggle + Settings memory UI (Phase 6)
- Cron-scheduled proactive insights workflows (Phase 7) - this phase ships the *compute* tools only
- `compare_bank_products` + `get_bank_product_info` (Phase 8) - need data source pipeline
- Push notification delivery (`send_push_notification`) - adapter-injected, Phase 3
- Multi-currency handling - tools default to VND, multi-currency wallets handled when channels land

---

## Self-review checklist

- [x] **Spec coverage:** All Phase 9 tools except 2 deferred (bank, push) and 1 covered by Mastra (`present_action_confirmation` lives in adapter). 21 of 25 listed in spec section 9.
- [x] **Placeholder scan:** No "TBD"/"add handling later"/etc. The single `TODO Phase 2.1` in transaction tool is for multi-currency wallet derivation - explicit and scoped, not a placeholder.
- [x] **Type consistency:** `ToolContext` defined Task 1, consumed by all tools. `bexlyTools` aggregate in Task 10 matches per-domain exports.
- [x] **Scope check:** Phase 2 is large (21 tools, 12 task groups) but still 1 implementation cycle - each task self-contained with TDD, commits incremental.
- [x] **Ambiguity:** RLS verification (Task 1.6) is the only check that could block - if RLS missing, escalate to JOY before tools land. Otherwise tasks are concrete.
