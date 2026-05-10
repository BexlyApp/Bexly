-- Force-update gate: minimum supported build per platform.
-- Bexly client checks this on app start and blocks below the threshold.
-- Used to lock out APKs from before the 2026-04-22 .env-key-leak fix.

CREATE TABLE IF NOT EXISTS bexly.app_min_versions (
  platform          TEXT PRIMARY KEY,
                    -- 'android' | 'ios' | 'web' | 'macos' | 'linux' | 'windows'
  min_build_number  INT  NOT NULL,
  min_version_name  TEXT NOT NULL,         -- semver display, e.g. '0.0.11'
  message           TEXT,                  -- shown in update dialog (i18n key or fallback EN)
  store_url         TEXT,                  -- direct link to update on this platform
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE bexly.app_min_versions ENABLE ROW LEVEL SECURITY;

-- Public read (anonymous client must check before sign-in)
CREATE POLICY app_min_versions_public_read
  ON bexly.app_min_versions
  FOR SELECT USING (true);

-- Only service role writes
CREATE POLICY app_min_versions_service_write
  ON bexly.app_min_versions
  FOR ALL USING (auth.role() = 'service_role');

-- Initial values: anything below build 586 (the security fix) must update.
-- Adjust min_build_number after each security-critical release.
INSERT INTO bexly.app_min_versions (platform, min_build_number, min_version_name, message, store_url) VALUES
  ('android', 586, '0.0.11',
   'Bexly cần cập nhật để bảo vệ tài khoản của bạn. Vui lòng cập nhật để tiếp tục.',
   'https://play.google.com/store/apps/details?id=com.joy.bexly'),
  ('ios', 586, '0.0.11',
   'Bexly cần cập nhật để bảo vệ tài khoản của bạn. Vui lòng cập nhật để tiếp tục.',
   'https://apps.apple.com/app/bexly/id6739280617'),
  ('web', 586, '0.0.11',
   'Bexly cần cập nhật. Hãy reload trang.',
   'https://bexly.app'),
  ('macos', 586, '0.0.11',
   'Bexly cần cập nhật để bảo vệ tài khoản của bạn.',
   'https://apps.apple.com/app/bexly/id6739280617'),
  ('linux', 586, '0.0.11', 'Bexly cần cập nhật.', 'https://bexly.app'),
  ('windows', 586, '0.0.11', 'Bexly cần cập nhật.', 'https://bexly.app')
ON CONFLICT (platform) DO NOTHING;
