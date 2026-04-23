# Bexly MCP Server Plan

## Overview
Build an MCP (Model Context Protocol) server that exposes Bexly financial data
to AI agents (Claude Desktop, ChatGPT Desktop, Cursor, etc.), enabling users
to query and manage their finances via any AI client.

## Goals
- Read + Write access to Bexly data via MCP
- Priority clients: Claude Desktop, ChatGPT Desktop
- Auth: per-user API key generated in Bexly app
- Host: Google Cloud Run (dos.me infra)

---

## Architecture

```
Claude.ai Web ──────────────────────────────────┐
Claude Desktop (config Remote URL) ─────────────┤  HTTPS + SSE
ChatGPT (custom connector) ─────────────────────┤
                                                 ▼
                                ┌─────────────────────────────┐
                                │   Bexly MCP Server          │
                                │   Node.js + TypeScript      │
                                │   Cloud Run — dos.me        │
                                │   mcp.bexly.app             │
                                └─────────────┬───────────────┘
                                              │ Supabase JS SDK
                                              ▼
                                ┌─────────────────────────────┐
                                │   Supabase PostgreSQL       │
                                │   schema: bexly             │
                                └─────────────────────────────┘
```

### Why hosted server (Cloud Run) instead of local npx?
- Claude.ai **web** connector yêu cầu **Remote MCP server URL** (SSE)
- Cho phép **publish lên connector marketplace** của Claude → user search "Bexly" và connect, không cần paste URL
- Claude Desktop cũng support remote URL → 1 server phục vụ tất cả clients
- Cloud Run dos.me: scale to zero → cost thấp khi idle

### Transport
- **SSE (Server-Sent Events)** — required cho web connectors
- Endpoint: `https://mcp.bexly.app/sse`

### Why Node.js/TypeScript?
- Official MCP SDK (@modelcontextprotocol/sdk) — best JS/TS support
- Supabase JS SDK first-class
- SSE built-in với `@modelcontextprotocol/sdk/server/sse`

---

## Auth

### Flow
1. User opens Bexly app → Settings → "MCP / AI Integrations"
2. App generates a **per-user API key** (stored in Supabase, hashed)
3. User pastes key into Claude Desktop / ChatGPT config
4. MCP server validates key → maps to user_id → scopes all queries to that user

### Security
- Keys are prefixed: `bex_live_xxxxxxxxxx`
- Keys stored hashed (SHA-256) in Supabase table `bexly.mcp_api_keys`
- Rate limiting: 100 req/min per key (Cloud Run + middleware)
- Write operations return confirmation summary before committing
- HTTPS only (Cloud Run default)

---

## MCP Tools

### Read Tools
| Tool | Description | Params |
|------|-------------|--------|
| `list_wallets` | Get all wallets | — |
| `list_transactions` | Query transactions | wallet_id?, start_date?, end_date?, category?, limit=50 |
| `get_spending_summary` | Spending breakdown by category | period (this_month/last_month/this_year), wallet_id? |
| `list_budgets` | Get budgets + progress | month? (YYYY-MM) |
| `list_goals` | Get savings goals + progress | — |
| `list_categories` | Get all categories | type? (income/expense) |
| `get_balance` | Total balance across wallets | currency? |
| `get_streak` | Current transaction streak | — |
| `get_gamification` | Level, XP, BEX balance | — |

### Write Tools
| Tool | Description | Params |
|------|-------------|--------|
| `add_transaction` | Add new transaction | wallet_id, amount, type, category_id, note?, date? |
| `update_transaction` | Edit transaction | id, amount?, category_id?, note?, date? |
| `delete_transaction` | Delete transaction | id |
| `add_goal` | Create savings goal | name, target_amount, wallet_id, deadline? |
| `update_goal` | Update goal progress | id, current_amount |

### MCP Resources (read-only context)
- `bexly://wallets` — list of wallets as context
- `bexly://categories` — category list
- `bexly://summary/current-month` — current month snapshot

---

## Client Config

### Claude.ai Web
Settings → Connectors → Add custom connector:
- Name: `Bexly`
- Remote MCP server URL: `https://mcp.bexly.app/sse?key=bex_live_xxx`

Hoặc nếu published lên marketplace → user search "Bexly", click Connect, OAuth flow tự động.

### Claude Desktop
```json
{
  "mcpServers": {
    "bexly": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.bexly.app/sse"],
      "env": {
        "BEXLY_API_KEY": "bex_live_xxxxxxxxxx"
      }
    }
  }
}
```

### ChatGPT Desktop / Web
Thêm custom connector với URL `https://mcp.bexly.app/sse`.
Fallback: `/openapi.json` cho ChatGPT Actions nếu cần.

## Publishing to Claude Connector Marketplace
- Submit qua Anthropic developer portal
- Cần: OAuth 2.0 flow, logo, description, tool list
- User chỉ cần search "Bexly" → Connect → Done (không cần paste URL)

---

## Implementation Phases

### Phase 1 — Read-only MVP
- [ ] Setup TypeScript project + @modelcontextprotocol/sdk
- [ ] Auth middleware (API key validation)
- [ ] Implement read tools: list_transactions, get_spending_summary, list_wallets, list_budgets
- [ ] Deploy to Cloud Run (dos.me) tại `mcp.bexly.app` hoặc `api.dos.me/bexly-mcp`
- [ ] Bexly app: UI generate API key trong Settings

### Phase 2 — Write access
- [ ] add_transaction, update_transaction, delete_transaction
- [ ] Confirmation prompt trong tool response trước khi commit
- [ ] Audit log table trong Supabase

### Phase 3 — Advanced
- [ ] MCP Resources (wallets, categories as context)
- [ ] Prompt templates ("Analyze my spending", "Am I on track for budget?")
- [ ] npm package publish (@bexly/mcp-server)
- [ ] OpenAPI spec cho ChatGPT Actions fallback
- [ ] Webhook: notify app khi agent adds transaction

---

## Supabase Table: mcp_api_keys
```sql
CREATE TABLE bexly.mcp_api_keys (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  key_hash    TEXT NOT NULL UNIQUE,  -- SHA-256 of the actual key
  key_prefix  TEXT NOT NULL,         -- first 12 chars for display e.g. "bex_live_abc"
  name        TEXT,                  -- e.g. "Claude Desktop"
  last_used   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  is_active   BOOLEAN DEFAULT TRUE
);
```

---

## Cost Estimate
- Cloud Run dos.me: scale to zero → ~$1-3/month cho 1000 users active
- Supabase: within existing plan limits
- npm publish `mcp-remote` wrapper: free
