// Unlink Telegram account from Bexly user
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createSupabaseClient } from "../_shared/supabase-client.ts";

serve(async (req) => {
  try {
    // Get auth header
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401 },
      );
    }

    // Create Supabase client
    const supabase = createSupabaseClient();

    // Get user from JWT
    const jwt = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      jwt,
    );

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401 },
      );
    }

    // Delete link
    const { error: deleteError } = await supabase
      .from("user_integrations")
      .delete()
      .eq("user_id", user.id)
      .eq("platform", "telegram");

    if (deleteError) {
      console.error("Error deleting link:", deleteError);
      return new Response(
        JSON.stringify({ error: "Failed to unlink account" }),
        { status: 500 },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Telegram account unlinked successfully",
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error in unlink-telegram:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500 },
    );
  }
});
