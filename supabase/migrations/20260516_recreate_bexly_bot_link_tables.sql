-- Recreate Bexly-owned bot-link tables destroyed as collateral of the
-- 2026-04-30 `DROP SCHEMA bexly CASCADE` incident (DOS-AI team confirmed
-- 2026-05-16 this was accidental, not a consolidation). Idempotent.
-- Schema reconstructed from all 6 edge-function call-sites.

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

CREATE TABLE IF NOT EXISTS bexly.bot_link_codes (
  code       text        NOT NULL,
  user_id    uuid        NOT NULL,
  platform   text        NOT NULL CHECK (platform IN ('telegram','zalo')),
  expires_at timestamptz NOT NULL DEFAULT now() + interval '10 minutes',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (code)
);

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
