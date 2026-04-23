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

    // Get request body
    const body = await req.json();
    let telegram_id = body.telegram_id;

    // If link_code is provided, look up telegram_id from bot_link_codes table
    if (body.link_code) {
      console.log("[link-telegram] Verifying link_code:", body.link_code);
      const { data: linkCode, error: codeError } = await supabase
        .from("bot_link_codes")
        .select("*")
        .eq("code", body.link_code.toUpperCase())
        .eq("platform", "telegram")
        .gt("expires_at", new Date().toISOString())
        .single();

      if (codeError || !linkCode) {
        console.error("[link-telegram] Invalid or expired link code:", codeError);
        return new Response(
          JSON.stringify({ error: "Invalid or expired link code" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      telegram_id = linkCode.platform_user_id;
      console.log("[link-telegram] Link code verified, telegram_id:", telegram_id);

      // Delete the used code
      await supabase
        .from("bot_link_codes")
        .delete()
        .eq("code", body.link_code.toUpperCase());
    }

    if (!telegram_id) {
      return new Response(
        JSON.stringify({ error: "telegram_id or link_code is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Check if Telegram account is already linked
    const { data: existing, error: checkError } = await supabase
      .from("user_integrations")
      .select("*")
      .eq("platform", "telegram")
      .eq("platform_user_id", String(telegram_id))
      .single();

    if (existing) {
      return new Response(
        JSON.stringify({
          error: "This Telegram account is already linked to another user",
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Create link
    console.log("[link-telegram] Creating link for user:", user.id, "telegram_id:", telegram_id);
    const { data: insertData, error: insertError } = await supabase
      .from("user_integrations")
      .insert({
        user_id: user.id,
        platform: "telegram",
        platform_user_id: String(telegram_id),
        linked_at: new Date().toISOString(),
        last_activity: new Date().toISOString(),
      })
      .select();

    if (insertError) {
      console.error("[link-telegram] Error creating link:", JSON.stringify(insertError, null, 2));
      return new Response(
        JSON.stringify({
          error: "Failed to link account",
          details: insertError.message,
          code: insertError.code
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[link-telegram] Link created successfully:", insertData);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Telegram account linked successfully",
        telegram_id: telegram_id,
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
