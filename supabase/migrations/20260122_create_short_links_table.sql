-- Create table to store short link codes for Telegram bot links
CREATE TABLE IF NOT EXISTS bexly.short_links (
  code TEXT PRIMARY KEY,
  tg_token TEXT NOT NULL,
  redirect_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ
);

-- Index for cleanup of expired links
CREATE INDEX IF NOT EXISTS idx_short_links_expires_at ON bexly.short_links(expires_at);

-- Grant permissions to service_role (for Edge Functions)
GRANT ALL ON bexly.short_links TO service_role;
