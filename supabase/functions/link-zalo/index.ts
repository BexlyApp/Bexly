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

    // Get request body - expects { link_code: string }
    const body = await req.json();

    if (!body.link_code) {
      return new Response(
        JSON.stringify({ error: "link_code is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[link-zalo] Verifying link_code:", body.link_code);
    const { data: linkCode, error: codeError } = await supabase
      .from("bot_link_codes")
      .select("*")
      .eq("code", body.link_code.toUpperCase())
      .eq("platform", "zalo")
      .gt("expires_at", new Date().toISOString())
      .single();

    if (codeError || !linkCode) {
      console.error("[link-zalo] Invalid or expired link code:", codeError);
      return new Response(
        JSON.stringify({ error: "Invalid or expired link code" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const zaloUserId = linkCode.platform_user_id;
    console.log("[link-zalo] Link code verified, zalo_user_id:", zaloUserId);

    // Delete the used code
    await supabase
      .from("bot_link_codes")
      .delete()
      .eq("code", body.link_code.toUpperCase());

    // Check if this Zalo account is already linked to another Bexly user
    const { data: existing } = await supabase
      .from("user_integrations")
      .select("*")
      .eq("platform", "zalo")
      .eq("platform_user_id", String(zaloUserId))
      .single();

    if (existing) {
      return new Response(
        JSON.stringify({
          error: "This Zalo account is already linked to another user",
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Create the link in user_integrations
    console.log("[link-zalo] Creating link for user:", user.id, "zalo_user_id:", zaloUserId);
    const { data: insertData, error: insertError } = await supabase
      .from("user_integrations")
      .insert({
        user_id: user.id,
        platform: "zalo",
        platform_user_id: String(zaloUserId),
        linked_at: new Date().toISOString(),
        last_activity: new Date().toISOString(),
      })
      .select();

    if (insertError) {
      console.error("[link-zalo] Error creating link:", JSON.stringify(insertError, null, 2));
      return new Response(
        JSON.stringify({
          error: "Failed to link account",
          details: insertError.message,
          code: insertError.code
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[link-zalo] Link created successfully:", insertData);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Zalo account linked successfully",
        zalo_user_id: zaloUserId,
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
