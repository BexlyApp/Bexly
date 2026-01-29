// Create short link for Telegram bot
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createSupabaseClient } from "../_shared/supabase-client.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const { tg_token, redirect_url } = await req.json();

    if (!tg_token || !redirect_url) {
      return new Response(
        JSON.stringify({ error: "tg_token and redirect_url are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Generate random short code (8 characters)
    const code = generateCode(8);

    // Store in database (expires in 1 hour)
    const supabase = createSupabaseClient();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

    const { error: insertError } = await supabase
      .from("short_links")
      .insert({
        code,
        tg_token,
        redirect_url,
        expires_at: expiresAt,
      });

    if (insertError) {
      console.error("Error creating short link:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to create short link" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const shortUrl = `https://id.dos.me/l/${code}`;

    return new Response(
      JSON.stringify({
        success: true,
        code,
        short_url: shortUrl,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error in create-short-link:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

function generateCode(length: number): string {
  const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
  let code = "";
  for (let i = 0; i < length; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
