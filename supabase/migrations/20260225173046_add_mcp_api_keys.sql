-- MCP API keys table for authenticating external AI agents (Claude, ChatGPT, etc.)
create table if not exists bexly.mcp_api_keys (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  key_hash      text not null unique,        -- SHA-256 hash of the raw API key
  name          text not null default 'My API Key',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  last_used_at  timestamptz
);

create index if not exists mcp_api_keys_key_hash_idx on bexly.mcp_api_keys(key_hash);
create index if not exists mcp_api_keys_user_id_idx  on bexly.mcp_api_keys(user_id);

-- RLS enabled; Worker uses secret key which bypasses RLS
alter table bexly.mcp_api_keys enable row level security;
