// Simple test version
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");

async function sendMessage(chatId: number, text: string) {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text }),
  });
}

serve(async (req) => {
  try {
    const update = await req.json();
    console.log("Received update:", JSON.stringify(update));

    const message = update.message;
    if (message) {
      const chatId = message.chat.id;
      const text = message.text || "";

      if (text === "/start") {
        await sendMessage(chatId, "✅ Bot is working! This is a test version.");
      }
    }

    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
});
