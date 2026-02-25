import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL ?? 'https://gulptwduchsjcsbndmua.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? '';

// Minimal Database type so Supabase SDK accepts custom schema 'bexly'
type BexlyDatabase = {
  bexly: {
    Tables: { [key: string]: { Row: any; Insert: any; Update: any } };
    Views: { [key: string]: { Row: any } };
    Functions: { [key: string]: any };
    Enums: { [key: string]: any };
  };
};

// Service role client — bypasses RLS, scoped per-query using user_id filter
const _client = createClient<BexlyDatabase, 'bexly'>(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  { db: { schema: 'bexly' } },
);

// Cast to any to avoid per-query TypeScript gymnastics (no generated DB types)
export const supabase = _client as any;

export interface ApiKey {
  user_id: string;
  key_prefix: string;
  name: string | null;
  last_used: string | null;
}

/**
 * Validate an API key and return the associated user_id.
 * The key is stored hashed (SHA-256) in mcp_api_keys.
 */
export async function validateApiKey(rawKey: string): Promise<string | null> {
  if (!rawKey.startsWith('bex_live_')) return null;

  const hash = await sha256(rawKey);

  const { data, error } = await supabase
    .from('mcp_api_keys')
    .select('user_id')
    .eq('key_hash', hash)
    .eq('is_active', true)
    .single();

  if (error || !data) return null;

  // Update last_used timestamp (fire-and-forget)
  supabase
    .from('mcp_api_keys')
    .update({ last_used: new Date().toISOString() })
    .eq('key_hash', hash)
    .then(() => {});

  return data.user_id as string;
}

async function sha256(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
