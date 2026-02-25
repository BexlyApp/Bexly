import { createClient } from '@supabase/supabase-js';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Supabase = any;

/** Create a per-request Supabase client using secret key for schema bexly. */
export function createSupabase(url: string, secretKey: string): Supabase {
  // Cast to any to avoid TypeScript schema type mismatch (no generated DB types)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return createClient(url, secretKey, {
    db: { schema: 'bexly' as any },
  }) as any;
}

/**
 * Validate a Bexly API key and return the associated user_id.
 * Keys are stored hashed (SHA-256) in bexly.mcp_api_keys.
 */
export async function validateApiKey(
  supabase: Supabase,
  rawKey: string,
): Promise<string | null> {
  if (!rawKey.startsWith('bex_live_')) return null;

  const hash = await sha256(rawKey);

  const { data, error } = await supabase
    .from('mcp_api_keys')
    .select('user_id')
    .eq('key_hash', hash)
    .eq('is_active', true)
    .single();

  if (error || !data) return null;

  // Fire-and-forget: update last_used
  supabase
    .from('mcp_api_keys')
    .update({ last_used: new Date().toISOString() })
    .eq('key_hash', hash)
    .then(() => {});

  return data.user_id as string;
}

async function sha256(text: string): Promise<string> {
  const data = new TextEncoder().encode(text);
  const buf = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
