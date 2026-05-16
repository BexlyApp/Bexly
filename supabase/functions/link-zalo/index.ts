// Link Zalo account to Bexly user - mirror of link-telegram/index.ts
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
    console.log("[link-zalo] JWT received (first 30 chars):", jwt.substring(0, 30));

    // Verify JWT with DOS ID project using REST API
    const dosIdUrl = "https://gulptwduchsjcsbndmua.supabase.co";
    const dosIdPublishableKey = "sb_publishable_0rxEMRqaM-J_neOtMUTuXQ_4-dP6Dj5";

    console.log("[link-zalo] Verifying JWT with DOS ID project via REST API...");
    const verifyResponse = await fetch(`${dosIdUrl}/auth/v1/user`, {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'apikey': dosIdPublishableKey,
      },
    });

    if (!verifyResponse.ok) {
      console.error("[link-zalo] Auth verification failed:", verifyResponse.status);
      const errorText = await verifyResponse.text().catch(() => '');
      console.error("[link-zalo] Error response:", errorText);
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
          details: `Auth verification failed: ${verifyResponse.status}`
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const user = await verifyResponse.json();
    console.log("[link-zalo] JWT verified successfully. User ID:", user.id);

    // Now use Bexly Supabase client for database operations
    const supabase = createSupabaseClient();

    // Generate a 6-char A-Z0-9 code keyed by the authenticated Bexly user.
    // Zalo OA has no deep-link start param; the user pastes the code into
    // the OA chat, and zalo-webhook consumes it.
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    function genCode(): string {
      let c = "";
      for (let i = 0; i < 6; i++) {
        c += alphabet[Math.floor(Math.random() * alphabet.length)];
      }
      return c;
    }

    await supabase
      .from("bot_link_codes")
      .delete()
      .eq("user_id", user.id)
      .eq("platform", "zalo");

    let code = "";
    let insertErr: unknown = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      code = genCode();
      const { error } = await supabase
        .from("bot_link_codes")
        .insert({ code, user_id: user.id, platform: "zalo" });
      if (!error) {
        insertErr = null;
        break;
      }
      insertErr = error;
    }
    if (insertErr) {
      console.error("[link-zalo] code insert failed:", JSON.stringify(insertErr));
      return new Response(
        JSON.stringify({ error: "Failed to generate link code" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[link-zalo] code generated for user", user.id);
    return new Response(
      JSON.stringify({
        success: true,
        code,
        platform: "zalo",
        expires_in_minutes: 10,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error in link-zalo:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
