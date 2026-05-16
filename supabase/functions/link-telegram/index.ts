// Link Telegram account to Bexly user
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createSupabaseClient } from "../_shared/supabase-client.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*", // Allow Bexly app
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Get auth header
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Get user from JWT using DOS ID Supabase project
    // The JWT is issued by id.dos.me, not by Bexly
    const jwt = authHeader.replace("Bearer ", "");
    console.log("[link-telegram] JWT received (first 30 chars):", jwt.substring(0, 30));

    // Verify JWT with DOS ID project using REST API
    const dosIdUrl = "https://gulptwduchsjcsbndmua.supabase.co";
    const dosIdPublishableKey = "sb_publishable_0rxEMRqaM-J_neOtMUTuXQ_4-dP6Dj5";

    console.log("[link-telegram] Verifying JWT with DOS ID project via REST API...");
    const verifyResponse = await fetch(`${dosIdUrl}/auth/v1/user`, {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'apikey': dosIdPublishableKey,
      },
    });

    if (!verifyResponse.ok) {
      console.error("[link-telegram] Auth verification failed:", verifyResponse.status);
      const errorText = await verifyResponse.text().catch(() => '');
      console.error("[link-telegram] Error response:", errorText);
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
          details: `Auth verification failed: ${verifyResponse.status}`
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const user = await verifyResponse.json();
    console.log("[link-telegram] JWT verified successfully. User ID:", user.id);

    // Now use Bexly Supabase client for database operations
    const supabase = createSupabaseClient();

    const body = await req.json().catch(() => ({}));
    const platform: string = body.platform === "zalo" ? "zalo" : "telegram";

    // Resolve the Telegram bot username for the deep-link (cached per cold
    // start). Uses the bot token available as a Supabase secret to all
    // functions; avoids a separate username secret that could drift.
    const botToken = Deno.env.get("BEXLY_TELEGRAM_BOT_TOKEN");
    let botUsername = "";
    if (platform === "telegram" && botToken) {
      try {
        const me = await fetch(`https://api.telegram.org/bot${botToken}/getMe`);
        const meJson = await me.json();
        botUsername = meJson?.result?.username ?? "";
      } catch (_) {
        botUsername = "";
      }
    }

    // Generate a 6-char A-Z0-9 code; retry on the rare PK collision.
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    function genCode(): string {
      let c = "";
      for (let i = 0; i < 6; i++) {
        c += alphabet[Math.floor(Math.random() * alphabet.length)];
      }
      return c;
    }

    // Clear this user's prior unused codes for the platform, then insert.
    await supabase
      .from("bot_link_codes")
      .delete()
      .eq("user_id", user.id)
      .eq("platform", platform);

    let code = "";
    let insertErr: unknown = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      code = genCode();
      const { error } = await supabase
        .from("bot_link_codes")
        .insert({ code, user_id: user.id, platform });
      if (!error) {
        insertErr = null;
        break;
      }
      insertErr = error;
    }
    if (insertErr) {
      console.error("[link-telegram] code insert failed:", JSON.stringify(insertErr));
      return new Response(
        JSON.stringify({ error: "Failed to generate link code" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const deepLink = botUsername
      ? `https://t.me/${botUsername}?start=${code}`
      : null;

    console.log("[link-telegram] code generated for user", user.id, "platform", platform);
    return new Response(
      JSON.stringify({
        success: true,
        code,
        platform,
        deep_link: deepLink,
        expires_in_minutes: 10,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error in link-telegram:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
