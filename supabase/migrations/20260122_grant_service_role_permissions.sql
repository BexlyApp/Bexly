-- Grant service_role permissions on bexly schema
-- Required for Edge Functions to access bexly schema

GRANT USAGE ON SCHEMA bexly TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA bexly TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA bexly TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA bexly TO service_role;

-- Auto-grant for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT ALL ON FUNCTIONS TO service_role;
