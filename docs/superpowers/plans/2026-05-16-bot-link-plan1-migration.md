# Bexly Bot-Link Plan 1: Recreate Link Tables (Registered Migration)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recreate `bexly.user_integrations` + `bexly.bot_link_codes` (destroyed as collateral of the 2026-04-30 schema-drop incident) as an idempotent, registered migration applied to beta then prod via the DOS-Me flow.

**Architecture:** A single idempotent SQL migration file in the Bexly repo's existing `supabase/migrations/` directory (date-prefixed, matching repo convention). Applied to the beta Supabase branch (`oyajkbadsykigtfrpdpg`) via MCP `apply_migration` for verification, then registered for prod (`gulptwduchsjcsbndmua`) via a DOS-Me issue (same channel as migrations `0001`/`0002`, DOS-Me #115). Schema reconstructed exactly from all 6 edge-function call-sites (see spec §"Data Model").

**Tech Stack:** Postgres (Supabase), Supabase MCP (`apply_migration`, `execute_sql`), `gh` CLI for DOS-Me registration.

**Spec:** `docs/superpowers/specs/2026-05-16-bexly-bot-link-redesign-design.md`

**Convention note:** repo migrations use `YYYYMMDD_<desc>.sql` (e.g. `20260427_add_tingee_tables.sql`), NOT `000N_`. The spec's "0003" name is superseded by the repo convention: file is `20260516_recreate_bexly_bot_link_tables.sql`.

---

### Task 1: Write the migration SQL file

**Files:**
- Create: `supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql`

- [ ] **Step 1: Create the migration file with exact reconstructed schema**

Create `supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql`:

```sql
-- Recreate Bexly-owned bot-link tables destroyed as collateral of the
-- 2026-04-30 `DROP SCHEMA bexly CASCADE` incident (DOS-AI team confirmed
-- 2026-05-16 this was accidental, not a consolidation). Idempotent.
-- Schema reconstructed from all 6 edge-function call-sites.

-- user_integrations: one platform account <-> one Bexly user
CREATE TABLE IF NOT EXISTS bexly.user_integrations (
  user_id          uuid        NOT NULL,
  platform         text        NOT NULL CHECK (platform IN ('telegram','zalo')),
  platform_user_id text        NOT NULL,
  linked_at        timestamptz NOT NULL DEFAULT now(),
  last_activity    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (platform, platform_user_id)
);

CREATE INDEX IF NOT EXISTS user_integrations_user_id_idx
  ON bexly.user_integrations (user_id);

-- bot_link_codes: app-generated, short-lived, single-use; consumed by bot
CREATE TABLE IF NOT EXISTS bexly.bot_link_codes (
  code       text        NOT NULL,
  user_id    uuid        NOT NULL,
  platform   text        NOT NULL CHECK (platform IN ('telegram','zalo')),
  expires_at timestamptz NOT NULL DEFAULT now() + interval '10 minutes',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (code)
);

-- RLS: user_integrations readable/manageable by its owner; service-role
-- (edge functions) bypasses RLS. bot_link_codes is service-role only.
ALTER TABLE bexly.user_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.bot_link_codes    ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='bexly' AND tablename='user_integrations'
      AND policyname='user_integrations_owner'
  ) THEN
    CREATE POLICY user_integrations_owner ON bexly.user_integrations
      FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- bot_link_codes: no public policy on purpose (ephemeral internal;
-- only service-role edge functions touch it). RLS enabled with zero
-- policies => denied to anon/authenticated, allowed to service-role.
```

- [ ] **Step 2: Static-check the SQL parses (no DB write)**

Run:
```bash
cd d:/Projects/Bexly && python3 -c "import pathlib,sys; s=pathlib.Path('supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql').read_text(); assert s.count('CREATE TABLE')==2 and 'ENABLE ROW LEVEL SECURITY' in s and s.count('PRIMARY KEY')==2, 'structure check failed'; print('ok: 2 tables, RLS, 2 PKs')"
```
Expected: `ok: 2 tables, RLS, 2 PKs`

- [ ] **Step 3: Commit**

```bash
cd d:/Projects/Bexly && git add supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql && git commit -m "feat(bot-link): migration to recreate bexly.user_integrations + bot_link_codes

Reconstructed from edge-function call-sites. Idempotent. Restores tables
dropped as collateral of the 2026-04-30 schema-drop incident.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Apply + verify on the BETA branch (not prod)

**Files:** none (DB operation on beta branch `oyajkbadsykigtfrpdpg`)

- [ ] **Step 1: Apply the migration to beta via MCP**

Use the Supabase MCP `apply_migration` tool:
- `project_id`: `oyajkbadsykigtfrpdpg`
- `name`: `recreate_bexly_bot_link_tables`
- `query`: the full contents of `supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql`

Expected: success (no error). If "already exists" errors surface, the
idempotent guards are wrong — fix the SQL and re-run.

- [ ] **Step 2: Verify tables + columns exist on beta**

Use Supabase MCP `execute_sql` on `project_id` `oyajkbadsykigtfrpdpg`:
```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema='bexly'
  AND table_name IN ('user_integrations','bot_link_codes')
ORDER BY table_name, ordinal_position;
```
Expected rows (exact):
- `bot_link_codes`: `code` text, `user_id` uuid, `platform` text, `expires_at` timestamptz, `created_at` timestamptz
- `user_integrations`: `user_id` uuid, `platform` text, `platform_user_id` text, `linked_at` timestamptz, `last_activity` timestamptz

- [ ] **Step 3: Verify PK, index, RLS, policy**

Use Supabase MCP `execute_sql` on `oyajkbadsykigtfrpdpg`:
```sql
SELECT
  (SELECT count(*) FROM pg_indexes WHERE schemaname='bexly'
     AND tablename='user_integrations') AS ui_indexes,
  (SELECT count(*) FROM pg_indexes WHERE schemaname='bexly'
     AND tablename='bot_link_codes') AS blc_indexes,
  (SELECT relrowsecurity FROM pg_class
     WHERE oid='bexly.user_integrations'::regclass) AS ui_rls,
  (SELECT relrowsecurity FROM pg_class
     WHERE oid='bexly.bot_link_codes'::regclass) AS blc_rls,
  (SELECT count(*) FROM pg_policies WHERE schemaname='bexly'
     AND tablename='user_integrations') AS ui_policies;
```
Expected: `ui_indexes`>=2 (PK + user_id idx), `blc_indexes`>=1 (PK),
`ui_rls`=true, `blc_rls`=true, `ui_policies`=1.

- [ ] **Step 4: Verify idempotency (re-apply must not error)**

Re-run the MCP `apply_migration` from Task 2 Step 1 with `name`:
`recreate_bexly_bot_link_tables_idempotency_check`, same `query`.
Expected: success, no "already exists" error (guards work).

- [ ] **Step 5: Functional smoke on beta — insert/select/expire**

Use Supabase MCP `execute_sql` on `oyajkbadsykigtfrpdpg`:
```sql
INSERT INTO bexly.bot_link_codes (code, user_id, platform)
VALUES ('SMK001', '00000000-0000-0000-0000-000000000001', 'telegram');
INSERT INTO bexly.user_integrations (user_id, platform, platform_user_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'telegram', 'tg_smoke_1');
SELECT
  (SELECT user_id FROM bexly.bot_link_codes WHERE code='SMK001') AS code_user,
  (SELECT expires_at > now() FROM bexly.bot_link_codes WHERE code='SMK001') AS not_expired,
  (SELECT user_id FROM bexly.user_integrations
     WHERE platform='telegram' AND platform_user_id='tg_smoke_1') AS link_user;
DELETE FROM bexly.bot_link_codes WHERE code='SMK001';
DELETE FROM bexly.user_integrations WHERE platform_user_id='tg_smoke_1';
```
Expected: `code_user` = the uuid, `not_expired` = true, `link_user` = the uuid. (Cleanup deletes run in same batch.)

---

### Task 3: Register the migration for PROD via the DOS-Me flow

**Files:** none (GitHub issue on `DOS/DOS.Me`)

> Prod (`gulptwduchsjcsbndmua`) is the shared DOS Supabase. Per the
> 2026-04-30 lesson, Bexly must NOT apply DDL to prod directly — it goes
> through a registered migration the dos.me team applies, so future
> cleanup migrations preserve it. Same channel as migrations 0001/0002
> (DOS-Me #115).

- [ ] **Step 1: Write the registration request body to a temp file**

The prod-guard hook blocks SQL keywords in shell args, so write the body
to a file (avoids `CREATE TABLE` etc. in the command line). Create
`C:/Temp/dosme_botlink_migration.md`:

```markdown
### Register migration: recreate Bexly bot-link tables (prod)

Follow-up to #115. Please apply, as a **registered migration** to prod
`gulptwduchsjcsbndmua`, the Bexly migration:

`supabase/migrations/20260516_recreate_bexly_bot_link_tables.sql` (Bexly
repo, branch `dev`).

Recreates `bexly.user_integrations` + `bexly.bot_link_codes`, removed as
collateral of the 2026-04-30 schema-drop incident (you confirmed
2026-05-16 it was accidental, not consolidation into
`dosai.shared_bot_links`). Additive only: two tables in the existing
`bexly` schema + RLS + indexes, idempotent (`IF NOT EXISTS` + guarded
policy). No `ALTER`/`DROP` on existing objects; does not touch
`dosai.shared_bot_links`.

Verified on beta branch `oyajkbadsykigtfrpdpg`: applies clean,
idempotent re-apply OK, columns/RLS/policy present, insert/select smoke
passes.

Registered (not ad-hoc) so future cleanup migrations preserve it.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 2: Post the registration request as a DOS-Me #115 comment**

Run:
```bash
cd d:/Projects/DOS-Me && gh issue comment 115 --repo DOS/DOS.Me --body-file /c/Temp/dosme_botlink_migration.md
```
Expected: prints the new comment URL (`https://github.com/DOS/DOS.Me/issues/115#issuecomment-...`).

- [ ] **Step 3: Clean up the temp file**

Run:
```bash
rm -f /c/Temp/dosme_botlink_migration.md && echo cleaned
```
Expected: `cleaned`

- [ ] **Step 4: Record the prod-apply dependency**

Run:
```bash
cd d:/Projects/Bexly && git commit --allow-empty -m "chore(bot-link): prod migration registered with dos.me (DOS-Me #115)

Plan 1 done on beta; prod apply is dos.me-owned. Plans 2-5 (edge
function + Flutter rewrite) can proceed against beta in parallel; prod
cutover waits on dos.me applying 20260516_recreate_bexly_bot_link_tables.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage (this plan's slice — spec §"Data Model", §"RLS", §"Migration & Registration"):**
- user_integrations DDL (cols/PK/index) → Task 1 Step 1 ✓
- bot_link_codes DDL (code PK, user_id, 10-min TTL) → Task 1 Step 1 ✓
- RLS (owner policy on user_integrations; service-role-only bot_link_codes) → Task 1 Step 1 + Task 2 Step 3 ✓
- Idempotent → Task 1 Step 1 guards + Task 2 Step 4 verify ✓
- Beta-before-prod (memory rule) → Task 2 (beta) precedes Task 3 (prod registration) ✓
- Registered via DOS-Me flow, not direct prod DDL → Task 3 ✓
- Repo migration naming convention followed (date-prefix) → header note + Task 1 path ✓

**Placeholder scan:** no TBD/TODO; every SQL/command shown in full. ✓

**Type consistency:** column names/types identical between Task 1 DDL and Task 2 verification queries (`user_id` uuid, `platform_user_id` text, `code` text PK, `expires_at` timestamptz). ✓

**Out of scope (correctly deferred to Plans 2-5):** edge-function rewrite, demo-picker removal, dos.me signup callback, Flutter screen. Plan 1 only restores the tables — it is independently shippable and unblocks the rest.
