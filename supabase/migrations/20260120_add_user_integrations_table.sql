-- Create user_integrations table for linking Bexly accounts with external platforms
-- This table is used by Telegram/Messenger bot integrations

CREATE TABLE IF NOT EXISTS bexly.user_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('telegram', 'messenger')),
  platform_user_id TEXT NOT NULL,
  linked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_activity TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Ensure one platform account can only link to one Bexly user
  UNIQUE (platform, platform_user_id),

  -- Ensure one Bexly user can only have one account per platform
  UNIQUE (user_id, platform)
);

-- Create index for faster lookups by platform_user_id
CREATE INDEX IF NOT EXISTS idx_user_integrations_platform_user
ON bexly.user_integrations(platform, platform_user_id);

-- Create index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_user_integrations_user_id
ON bexly.user_integrations(user_id);

-- Enable RLS
ALTER TABLE bexly.user_integrations ENABLE ROW LEVEL SECURITY;

-- RLS policies: users can only see and modify their own integrations
CREATE POLICY "Users can view their own integrations"
ON bexly.user_integrations
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own integrations"
ON bexly.user_integrations
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own integrations"
ON bexly.user_integrations
FOR DELETE
USING (auth.uid() = user_id);

-- Service role can access all integrations (for Edge Functions)
CREATE POLICY "Service role has full access"
ON bexly.user_integrations
FOR ALL
USING (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON bexly.user_integrations TO authenticated;
GRANT ALL ON bexly.user_integrations TO service_role;
