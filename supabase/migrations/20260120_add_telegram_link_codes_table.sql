-- Telegram Link Codes Table
-- Used for Flow 1 (Web → Telegram): User generates code in app, enters in Telegram bot

CREATE TABLE IF NOT EXISTS bexly.telegram_link_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_telegram_link_codes_code
ON bexly.telegram_link_codes(code) WHERE NOT used;

CREATE INDEX IF NOT EXISTS idx_telegram_link_codes_expires
ON bexly.telegram_link_codes(expires_at) WHERE NOT used;

CREATE INDEX IF NOT EXISTS idx_telegram_link_codes_user_id
ON bexly.telegram_link_codes(user_id);

-- Enable RLS
ALTER TABLE bexly.telegram_link_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can create their own link codes
CREATE POLICY "Users can create their own link codes"
ON bexly.telegram_link_codes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can read their own codes
CREATE POLICY "Users can read their own codes"
ON bexly.telegram_link_codes FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Service role can read all codes (for bot verification)
CREATE POLICY "Service role can read all codes"
ON bexly.telegram_link_codes FOR SELECT
TO service_role
USING (true);

-- Service role can update codes (mark as used)
CREATE POLICY "Service role can update codes"
ON bexly.telegram_link_codes FOR UPDATE
TO service_role
USING (true);

-- Service role can delete expired codes
CREATE POLICY "Service role can delete codes"
ON bexly.telegram_link_codes FOR DELETE
TO service_role
USING (true);

-- Cleanup function for expired codes (optional, run via cron)
CREATE OR REPLACE FUNCTION bexly.cleanup_expired_link_codes()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM bexly.telegram_link_codes
  WHERE expires_at < NOW() - INTERVAL '1 hour';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service role
GRANT EXECUTE ON FUNCTION bexly.cleanup_expired_link_codes() TO service_role;

COMMENT ON TABLE bexly.telegram_link_codes IS 'Temporary codes for linking Telegram accounts (Flow 1: Web → Telegram)';
COMMENT ON COLUMN bexly.telegram_link_codes.code IS 'Random 8-character code shown in app';
COMMENT ON COLUMN bexly.telegram_link_codes.expires_at IS 'Code valid for 5 minutes';
COMMENT ON COLUMN bexly.telegram_link_codes.used IS 'Mark true after bot successfully links';
