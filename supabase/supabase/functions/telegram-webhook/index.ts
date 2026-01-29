import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Bot, webhookCallback } from "https://deno.land/x/grammy@v1.27.0/mod.ts";
import { create } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { createTransaction, getUserCategories, getUserIdFromPlatform, getUserWallets, updateWalletBalance } from "../_shared/supabase-client.ts";
import { parseTransactionWithAI } from "../_shared/ai-providers.ts";
import { LOCALIZATIONS } from "../_shared/types.ts";
// In-memory cache for pending transactions
const pendingTransactions = new Map();
// Initialize bot
const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
if (!botToken) {
  throw new Error("TELEGRAM_BOT_TOKEN not set");
}
const bot = new Bot(botToken);
// Helper: Generate JWT for Telegram linking
async function generateLinkToken(telegramId) {
  const jwtSecret = Deno.env.get("TELEGRAM_JWT_SECRET");
  if (!jwtSecret) {
    throw new Error("TELEGRAM_JWT_SECRET not set");
  }
  const payload = {
    telegram_id: telegramId,
    app: "bexly",
    bot_username: "BexlyBot",
    api_url: "https://dos.supabase.co/functions/v1/link-telegram",
    exp: Math.floor(Date.now() / 1000) + 600
  };
  // Create key for HS256
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(jwtSecret), {
    name: "HMAC",
    hash: "SHA-256"
  }, false, [
    "sign"
  ]);
  return await create({
    alg: "HS256",
    typ: "JWT"
  }, payload, key);
}
// Setup bot handlers
bot.command("start", async (ctx)=>{
  const message = `👋 Welcome to Bexly AI Assistant!

I can help you track expenses and income by simply chatting with me.

Examples:
🇻🇳 Vietnamese:
• "50k ăn sáng" - Track breakfast expense
• "100 triệu lương tháng 1" - Record January salary

🇬🇧 English:
• "lunch $20" - Track lunch expense
• "$5000 salary" - Record salary income

Link your Bexly account first using the app to start tracking!`;
  await ctx.reply(message);
});
bot.command("help", async (ctx)=>{
  const message = `💡 How to use Bexly Bot:

1️⃣ Link your account:
Open Bexly app → Settings → Bot Integration → Link Telegram

2️⃣ Track transactions:
Just send me a message like:
• "50k cafe" (Vietnamese)
• "lunch $20" (English)

3️⃣ Check balance:
Use /balance command

That's it! I'll parse your messages and create transactions automatically.`;
  await ctx.reply(message);
});
bot.command("balance", async (ctx)=>{
  try {
    const telegramUserId = String(ctx.from?.id);
    const userId = await getUserIdFromPlatform("telegram", telegramUserId);
    if (!userId) {
      await ctx.reply("❌ Please link your Bexly account first in the app.");
      return;
    }
    const wallets = await getUserWallets(userId);
    if (wallets.length === 0) {
      await ctx.reply("❌ No wallets found. Create one in Bexly app first.");
      return;
    }
    const balanceText = wallets.map((w)=>`${w.name}: ${w.balance.toLocaleString()} ${w.currency}`).join("\n");
    await ctx.reply(`💰 Your Balances:\n\n${balanceText}`);
  } catch (error) {
    console.error("Error fetching balance:", error);
    await ctx.reply("❌ Error fetching balance. Please try again.");
  }
});
// Handle text messages (transaction parsing)
bot.on("message:text", async (ctx)=>{
  try {
    const text = ctx.message?.text;
    if (!text) return;
    // Skip commands
    if (text.startsWith("/")) return;
    const telegramUserId = String(ctx.from?.id);
    const userId = await getUserIdFromPlatform("telegram", telegramUserId);
    if (!userId) {
      // Generate JWT token for linking
      const linkToken = await generateLinkToken(telegramUserId);
      // Use login page with redirect to avoid creating new route
      const redirectUrl = encodeURIComponent("bexly://telegram/linked");
      const loginUrl = `https://id.dos.me/login?redirect=${redirectUrl}&tg_token=${linkToken}`;
      await ctx.reply("❌ Please link your Bexly account first.\n\nClick the button below to link your account:", {
        reply_markup: {
          inline_keyboard: [
            [
              {
                text: "🔗 Link Account",
                url: loginUrl
              }
            ]
          ]
        }
      });
      return;
    }
    // Get user's wallets and categories
    const wallets = await getUserWallets(userId);
    const categories = await getUserCategories(userId);
    if (wallets.length === 0) {
      await ctx.reply("❌ No wallets found. Create one in Bexly app first.");
      return;
    }
    if (categories.length === 0) {
      await ctx.reply("❌ No categories found. Create categories in Bexly app first.");
      return;
    }
    // Parse transaction with AI
    const defaultWallet = wallets.find((w)=>w.is_default) || wallets[0];
    const parsed = await parseTransactionWithAI(text, categories.map((c)=>({
        id: c.cloud_id,
        title: c.title,
        transactionType: c.transaction_type,
        localizedTitles: c.localized_titles
      })), defaultWallet.currency);
    if (!parsed) {
      await ctx.reply("👋 Hi! Send me expense/income messages to track.");
      return;
    }
    // Find matching category
    const category = categories.find((c)=>c.title === parsed.category);
    if (!category) {
      await ctx.reply(`❌ Category "${parsed.category}" not found in your account.`);
      return;
    }
    // Save pending transaction and ask for confirmation
    const pendingId = `${telegramUserId}_${Date.now()}`;
    pendingTransactions.set(pendingId, parsed);
    const loc = LOCALIZATIONS[parsed.language] || LOCALIZATIONS.en;
    const confirmText = `${parsed.type === "expense" ? "💸" : "💰"} ${parsed.type === "expense" ? loc.expenseDetected : loc.incomeDetected}

Amount: ${parsed.amount.toLocaleString()} ${parsed.currency || defaultWallet.currency}
Category: ${parsed.category}
Description: ${parsed.description}

${loc.confirm}?`;
    await ctx.reply(confirmText, {
      reply_markup: {
        inline_keyboard: [
          [
            {
              text: "✅ " + loc.confirm,
              callback_data: `confirm_${pendingId}`
            },
            {
              text: "❌ " + loc.cancel,
              callback_data: `cancel_${pendingId}`
            }
          ]
        ]
      }
    });
  } catch (error) {
    console.error("Error processing message:", error);
    await ctx.reply("❌ Error processing message. Please try again.");
  }
});
// Handle callback queries (confirmations)
bot.on("callback_query:data", async (ctx)=>{
  try {
    const data = ctx.callbackQuery?.data;
    if (!data) return;
    const [action, pendingId] = data.split("_", 2);
    const parsed = pendingTransactions.get(pendingId);
    if (!parsed) {
      await ctx.answerCallbackQuery({
        text: "❌ Transaction expired"
      });
      return;
    }
    if (action === "cancel") {
      pendingTransactions.delete(pendingId);
      const loc = LOCALIZATIONS[parsed.language] || LOCALIZATIONS.en;
      await ctx.editMessageText(loc.cancelled);
      await ctx.answerCallbackQuery();
      return;
    }
    if (action === "confirm") {
      const telegramUserId = String(ctx.from?.id);
      const userId = await getUserIdFromPlatform("telegram", telegramUserId);
      if (!userId) {
        await ctx.answerCallbackQuery({
          text: "❌ Account not linked"
        });
        return;
      }
      // Get user data
      const wallets = await getUserWallets(userId);
      const categories = await getUserCategories(userId);
      const defaultWallet = wallets.find((w)=>w.is_default) || wallets[0];
      const category = categories.find((c)=>c.title === parsed.category);
      if (!category) {
        await ctx.answerCallbackQuery({
          text: "❌ Category not found"
        });
        return;
      }
      // Create transaction
      const amount = parsed.amount;
      const finalAmount = parsed.type === "expense" ? -amount : amount;
      await createTransaction(userId, defaultWallet.cloud_id, category.cloud_id, amount, parsed.type, parsed.description, new Date().toISOString());
      // Update wallet balance
      await updateWalletBalance(defaultWallet.cloud_id, finalAmount);
      // Clean up and confirm
      pendingTransactions.delete(pendingId);
      const loc = LOCALIZATIONS[parsed.language] || LOCALIZATIONS.en;
      const successText = `✅ ${loc.recorded} ${parsed.type}!

${amount.toLocaleString()} ${parsed.currency || defaultWallet.currency} - ${parsed.category}
${parsed.description ? `"${parsed.description}"` : ""}`;
      await ctx.editMessageText(successText);
      await ctx.answerCallbackQuery();
    }
  } catch (error) {
    console.error("Error handling callback:", error);
    await ctx.answerCallbackQuery({
      text: "❌ Error occurred"
    });
  }
});
// Handle webhook
const handleUpdate = webhookCallback(bot, "std/http");
serve(async (req)=>{
  try {
    // Handle webhook
    return await handleUpdate(req);
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response("Error", {
      status: 500
    });
  }
});
