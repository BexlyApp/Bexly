// Telegram Webhook - Full Version (Inline Supabase)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { create } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Create Supabase client
function getSupabaseClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: "bexly" },
  });
}

// Telegram API helpers
async function sendMessage(chatId: number, text: string, extra?: any) {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text, ...extra }),
  });
}

// Generate JWT for linking
async function generateLinkToken(telegramId: string): Promise<string> {
  const jwtSecret = Deno.env.get("TELEGRAM_JWT_SECRET")!;
  const payload = {
    telegram_id: telegramId,
    app: "bexly",
    bot_username: "BexlyBot",
    api_url: "https://dos.supabase.co/functions/v1/link-telegram",
    exp: Math.floor(Date.now() / 1000) + 600,
  };
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(jwtSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return await create({ alg: "HS256", typ: "JWT" }, payload, key);
}

// Get user ID from platform
async function getUserIdFromPlatform(platform: string, platformUserId: string) {
  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from("user_integrations")
      .select("user_id")
      .eq("platform", platform)
      .eq("platform_user_id", platformUserId)
      .single();

    if (error && error.code !== "PGRST116") {
      console.error("Query error:", error);
    }
    return data?.user_id || null;
  } catch (e) {
    console.error("getUserIdFromPlatform error:", e);
    return null;
  }
}

// Unlink user from platform
async function unlinkUserFromPlatform(platform: string, platformUserId: string): Promise<boolean> {
  try {
    const supabase = getSupabaseClient();
    const { error } = await supabase
      .from("user_integrations")
      .delete()
      .eq("platform", platform)
      .eq("platform_user_id", platformUserId);

    if (error) {
      console.error("Unlink error:", error);
      return false;
    }
    return true;
  } catch (e) {
    console.error("unlinkUserFromPlatform error:", e);
    return false;
  }
}

serve(async (req) => {
  try {
    const update = await req.json();
    console.log("Update:", JSON.stringify(update).substring(0, 200));

    // Handle callback queries (button clicks)
    const callbackQuery = update.callback_query;
    if (callbackQuery) {
      const chatId = callbackQuery.message.chat.id;
      const userId = callbackQuery.from.id;
      const data = callbackQuery.data || "";

      if (data.startsWith("unlink_confirm_")) {
        const success = await unlinkUserFromPlatform("telegram", String(userId));
        if (success) {
          await sendMessage(chatId, "✅ Your account has been unlinked successfully!\n\nYou can link again anytime using /link");
        } else {
          await sendMessage(chatId, "❌ Failed to unlink your account. Please try again later.");
        }
      } else if (data.startsWith("unlink_cancel_")) {
        await sendMessage(chatId, "✅ Unlink cancelled. Your account is still linked.");
      }

      return new Response("OK", { status: 200 });
    }

    const message = update.message;
    if (message) {
      const chatId = message.chat.id;
      const userId = message.from.id;
      const text = message.text || "";

      if (text === "/start") {
        await sendMessage(chatId, "👋 Welcome to Bexly AI Assistant!\n\nI can help you track expenses and income by simply chatting with me.\n\nLink your Bexly account first using /link to start tracking!");
      }
      else if (text === "/link") {
        const bexlyUserId = await getUserIdFromPlatform("telegram", String(userId));
        if (bexlyUserId) {
          await sendMessage(chatId, "✅ Your account is already linked!");
          return new Response("OK");
        }
        const linkToken = await generateLinkToken(String(userId));
        const deepLinkUrl = `bexly://telegram/link?token=${linkToken}`;

        // Generate 6-digit code from last 6 chars of token (simple fallback)
        const code = linkToken.slice(-6).toUpperCase();

        await sendMessage(chatId, `🔗 Link your Bexly account\n\n📱 Mobile: Tap the button below\n⌨️ Manual: Code ${code}\n\n(Open Bexly → Settings → Bot Integration → Enter code)`, {
          reply_markup: {
            inline_keyboard: [[{ text: "🔗 Link Account", url: deepLinkUrl }]],
          },
        });
      }
      else if (text === "/unlink") {
        const bexlyUserId = await getUserIdFromPlatform("telegram", String(userId));
        if (!bexlyUserId) {
          await sendMessage(chatId, "❌ Your account is not linked yet.\n\nUse /link to link your account first.");
          return new Response("OK");
        }
        await sendMessage(chatId, "⚠️ Are you sure you want to unlink your Bexly account?\n\nYou will need to link again to use the bot.", {
          reply_markup: {
            inline_keyboard: [[
              { text: "✅ Yes, unlink", callback_data: `unlink_confirm_${userId}` },
              { text: "❌ Cancel", callback_data: `unlink_cancel_${userId}` },
            ]],
          },
        });
      }
    }

    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message, stack: error.stack }),
      { status: 500 }
    );
  }
});
