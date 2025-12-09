import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { Bot, webhookCallback, InlineKeyboard } from "grammy";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { v7 as uuidv7 } from "uuid";

// Define secrets
const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// AI Provider configuration - can be changed here
type AIProvider = "gemini" | "openai";
const AI_PROVIDER: AIProvider = "gemini";
const GEMINI_MODEL = "gemini-2.5-flash";
const OPENAI_MODEL = "gpt-4o-mini";

// Set global options for all functions
setGlobalOptions({
  region: "asia-southeast1",
});

// Initialize Firebase Admin
admin.initializeApp();

// Get reference to non-default database "bexly"
const bexlyDb = new admin.firestore.Firestore({
  projectId: "bexly-app",
  databaseId: "bexly",
});

// Bot instance cache
let bot: Bot | null = null;
let lastToken: string = "";

function getBot(): Bot {
  const token = telegramBotToken.value();

  // Reinitialize if token changed or bot not initialized
  if (!bot || token !== lastToken) {
    if (!token) {
      throw new Error("Bot not initialized - missing token");
    }
    bot = new Bot(token);
    lastToken = token;
    setupBotHandlers(bot);
  }
  return bot;
}

// AI-parsed transaction interface
interface ParsedTransaction {
  type: "expense" | "income";
  amount: number;
  currency: string | null; // null means use wallet's default currency
  category: string;
  description: string;
  responseText: string;
  language: string; // ISO language code detected from user input (vi, en, ja, ko, zh, th, etc.)
}

// User category from Firestore
interface UserCategory {
  id: string; // cloudId (document ID)
  title: string;
  transactionType: string; // "expense" or "income"
  localizedTitles?: Record<string, string>; // {"en": "Food & Drinks", "vi": "Ăn uống", ...}
}

// Localization for bot messages
interface Localization {
  expense: string;
  income: string;
  recorded: string;
  from: string;
  to: string;
  categories: Record<string, string>;
}

const LOCALIZATIONS: Record<string, Localization> = {
  en: {
    expense: "expense",
    income: "income",
    recorded: "Recorded",
    from: "from",
    to: "to",
    categories: {
      "Food & Drinks": "Food & Drinks",
      "Transportation": "Transportation",
      "Housing": "Housing",
      "Entertainment": "Entertainment",
      "Health": "Health",
      "Shopping": "Shopping",
      "Education": "Education",
      "Travel": "Travel",
      "Finance": "Finance",
      "Utilities": "Utilities",
      "Other": "Other",
    },
  },
  vi: {
    expense: "chi tiêu",
    income: "thu nhập",
    recorded: "Đã ghi nhận",
    from: "từ",
    to: "vào",
    categories: {
      "Food & Drinks": "Ăn uống",
      "Transportation": "Di chuyển",
      "Housing": "Nhà ở",
      "Entertainment": "Giải trí",
      "Health": "Sức khỏe",
      "Shopping": "Mua sắm",
      "Education": "Giáo dục",
      "Travel": "Du lịch",
      "Finance": "Tài chính",
      "Utilities": "Tiện ích",
      "Other": "Khác",
    },
  },
  ja: {
    expense: "支出",
    income: "収入",
    recorded: "記録しました",
    from: "から",
    to: "へ",
    categories: {
      "Food & Drinks": "飲食",
      "Transportation": "交通",
      "Housing": "住居",
      "Entertainment": "娯楽",
      "Health": "健康",
      "Shopping": "買い物",
      "Education": "教育",
      "Travel": "旅行",
      "Finance": "金融",
      "Utilities": "光熱費",
      "Other": "その他",
    },
  },
  ko: {
    expense: "지출",
    income: "수입",
    recorded: "기록됨",
    from: "에서",
    to: "로",
    categories: {
      "Food & Drinks": "음식",
      "Transportation": "교통",
      "Housing": "주거",
      "Entertainment": "오락",
      "Health": "건강",
      "Shopping": "쇼핑",
      "Education": "교육",
      "Travel": "여행",
      "Finance": "금융",
      "Utilities": "공과금",
      "Other": "기타",
    },
  },
  zh: {
    expense: "支出",
    income: "收入",
    recorded: "已记录",
    from: "来自",
    to: "到",
    categories: {
      "Food & Drinks": "餐饮",
      "Transportation": "交通",
      "Housing": "住房",
      "Entertainment": "娱乐",
      "Health": "健康",
      "Shopping": "购物",
      "Education": "教育",
      "Travel": "旅游",
      "Finance": "金融",
      "Utilities": "水电费",
      "Other": "其他",
    },
  },
  th: {
    expense: "รายจ่าย",
    income: "รายรับ",
    recorded: "บันทึกแล้ว",
    from: "จาก",
    to: "ไปยัง",
    categories: {
      "Food & Drinks": "อาหาร",
      "Transportation": "การเดินทาง",
      "Housing": "ที่อยู่อาศัย",
      "Entertainment": "บันเทิง",
      "Health": "สุขภาพ",
      "Shopping": "ช้อปปิ้ง",
      "Education": "การศึกษา",
      "Travel": "ท่องเที่ยว",
      "Finance": "การเงิน",
      "Utilities": "ค่าสาธารณูปโภค",
      "Other": "อื่นๆ",
    },
  },
  id: {
    expense: "pengeluaran",
    income: "pemasukan",
    recorded: "Tercatat",
    from: "dari",
    to: "ke",
    categories: {
      "Food & Drinks": "Makanan & Minuman",
      "Transportation": "Transportasi",
      "Housing": "Perumahan",
      "Entertainment": "Hiburan",
      "Health": "Kesehatan",
      "Shopping": "Belanja",
      "Education": "Pendidikan",
      "Travel": "Perjalanan",
      "Finance": "Keuangan",
      "Utilities": "Utilitas",
      "Other": "Lainnya",
    },
  },
};

// Get localization for a language (fallback to English)
function getLocalization(lang: string): Localization {
  return LOCALIZATIONS[lang] || LOCALIZATIONS["en"];
}

// Fetch user's categories from Firestore
async function getUserCategories(bexlyUserId: string): Promise<UserCategory[]> {
  try {
    const categoriesSnapshot = await bexlyDb
      .collection("users")
      .doc(bexlyUserId)
      .collection("data")
      .doc("categories")
      .collection("items")
      .get();

    if (categoriesSnapshot.empty) {
      console.log("No categories found for user:", bexlyUserId);
      return [];
    }

    const categories: UserCategory[] = [];
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      // Parse localizedTitles - it's stored as JSON string in Firestore
      let localizedTitles: Record<string, string> | undefined;
      if (data.localizedTitles) {
        try {
          // localizedTitles might be a string (JSON) or already an object
          if (typeof data.localizedTitles === 'string') {
            localizedTitles = JSON.parse(data.localizedTitles);
          } else {
            localizedTitles = data.localizedTitles;
          }
        } catch (e) {
          console.warn(`Failed to parse localizedTitles for category ${doc.id}:`, e);
        }
      }
      categories.push({
        id: doc.id,
        title: data.title || "",
        transactionType: data.transactionType || "expense",
        localizedTitles,
      });
    });

    console.log(`Fetched ${categories.length} categories for user:`, bexlyUserId);
    return categories;
  } catch (error) {
    console.error("Error fetching user categories:", error);
    return [];
  }
}

// Build dynamic AI prompt with user's actual categories
function buildDynamicPrompt(userCategories: UserCategory[]): string {
  // Separate expense and income categories
  const expenseCategories = userCategories
    .filter(c => c.transactionType === "expense")
    .map(c => c.title);
  const incomeCategories = userCategories
    .filter(c => c.transactionType === "income")
    .map(c => c.title);

  // Build category list for prompt
  const expenseCatList = expenseCategories.length > 0
    ? expenseCategories.join(", ")
    : "Food & Drinks, Transportation, Shopping, Entertainment, Health, Other";
  const incomeCatList = incomeCategories.length > 0
    ? incomeCategories.join(", ")
    : "Work & Business, Investments, Other Income";

  return `You are Bexly AI - a multilingual finance assistant for Telegram.

TASK: Parse transaction from user message and return JSON.

RESPONSE FORMAT:
Return a SINGLE LINE JSON object only. No explanation, no markdown, just JSON.

JSON SCHEMA:
{"action":"create_expense"|"create_income"|"none","amount":<number>,"currency":"<ISO currency code>"|null,"language":"<ISO 639-1 code>","description":"<string>","category":"<EXACT category name from list below>","responseText":"<confirmation message in user's language>"}

LANGUAGE DETECTION (CRITICAL):
- Detect language from the user's INPUT TEXT
- Return ISO 639-1 code: "vi" (Vietnamese), "en" (English), "ja" (Japanese), "ko" (Korean), "zh" (Chinese), "th" (Thai), "id" (Indonesian), "fr" (French), "de" (German), "es" (Spanish), etc.
- ALWAYS respond in the SAME language as the user's input

CURRENCY DETECTION:
- "$" or "dollar" → "USD"
- "¥" or "円" or "yen" → "JPY"
- "₩" or "원" → "KRW"
- "€" or "euro" → "EUR"
- "£" or "pound" → "GBP"
- "฿" or "บาท" or "baht" → "THB"
- "k" (Vietnamese context) → multiply by 1000, currency "VND"
- "tr" or "triệu" (Vietnamese) → multiply by 1000000, currency "VND"
- If NO currency symbol/word is specified → currency: null (will use wallet's default)

CATEGORIES - YOU MUST USE EXACT NAMES FROM THIS LIST:

EXPENSE categories (use for spending/paying/buying):
${expenseCatList}

INCOME categories (use for receiving/earning/salary):
${incomeCatList}

IMPORTANT:
- Use the EXACT category name as shown above - do NOT translate or modify the category name
- Pick the most appropriate category from the list based on the transaction description
- If no category matches well, use a general category like "Other" or "Shopping"

TRANSACTION TYPE:
- Expense: spent, paid, bought, for, chi, mua, trả, 買った, 샀다, etc.
- Income: received, earned, got, income, salary, nhận, lương, 받았다, etc.

EXAMPLES:
Input: "$25 for lunch"
Output: {"action":"create_expense","amount":25,"currency":"USD","language":"en","description":"lunch","category":"Food & Drinks","responseText":"✅ Recorded $25.00 for lunch (Food & Drinks)"}

Input: "ăn sáng 50k"
Output: {"action":"create_expense","amount":50000,"currency":"VND","language":"vi","description":"ăn sáng","category":"Food & Drinks","responseText":"✅ Đã ghi nhận 50.000 ₫ cho ăn sáng (Food & Drinks)"}

Input: "hello"
Output: {"action":"none","amount":0,"currency":null,"language":"en","description":"","category":"","responseText":""}

If you cannot parse a transaction, return {"action":"none",...}`;
}

// Parse transaction using Gemini AI
async function parseWithGemini(text: string, dynamicPrompt: string): Promise<string | null> {
  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    console.error("Gemini API key not configured");
    return null;
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0.1,
      maxOutputTokens: 1024,
    }
  });

  const result = await model.generateContent([
    { text: dynamicPrompt },
    { text: `Parse this message: "${text}"` }
  ]);

  return result.response.text().trim();
}

// Parse transaction using OpenAI
async function parseWithOpenAI(text: string, dynamicPrompt: string): Promise<string | null> {
  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    console.error("OpenAI API key not configured");
    return null;
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [
        { role: "system", content: dynamicPrompt },
        { role: "user", content: `Parse this message: "${text}"` }
      ],
      temperature: 0.1,
      max_tokens: 500
    })
  });

  if (!response.ok) {
    console.error("OpenAI API error:", response.status, await response.text());
    return null;
  }

  const data = await response.json() as { choices: { message: { content: string } }[] };
  return data.choices[0]?.message?.content?.trim() || null;
}

// Main AI parsing function - supports multiple providers
async function parseTransactionWithAI(text: string, userCategories: UserCategory[]): Promise<ParsedTransaction | null> {
  try {
    let response: string | null = null;

    // Build dynamic prompt with user's actual categories
    const dynamicPrompt = buildDynamicPrompt(userCategories);
    console.log("Using dynamic prompt with user categories:", userCategories.map(c => c.title).slice(0, 10), "...");

    // Use configured AI provider
    switch (AI_PROVIDER) {
      case "gemini":
        response = await parseWithGemini(text, dynamicPrompt);
        break;
      case "openai":
        response = await parseWithOpenAI(text, dynamicPrompt);
        break;
      default:
        console.error("Unknown AI provider:", AI_PROVIDER);
        return null;
    }

    if (!response) {
      console.log("No response from AI, falling back to regex parser");
      return parseTransactionFallback(text);
    }

    console.log(`${AI_PROVIDER} response:`, response);

    // Parse JSON from response
    // Handle potential markdown code blocks
    let jsonStr = response;
    if (jsonStr.startsWith("```")) {
      jsonStr = jsonStr.replace(/```json?\n?/g, "").replace(/```/g, "").trim();
    }

    const parsed = JSON.parse(jsonStr);

    if (parsed.action === "none" || !parsed.action) {
      return null;
    }

    return {
      type: parsed.action === "create_income" ? "income" : "expense",
      amount: parsed.amount,
      currency: parsed.currency || null, // null means use wallet's default
      category: parsed.category || "Other",
      description: parsed.description || "",
      responseText: parsed.responseText || "",
      language: parsed.language || "en"
    };
  } catch (error) {
    console.error("AI parsing error:", error);
    // Fallback to regex parser if AI fails
    console.log("AI failed, falling back to regex parser");
    return parseTransactionFallback(text);
  }
}

// Legacy regex parser as fallback
function parseTransactionFallback(text: string): ParsedTransaction | null {
  const lowerText = text.toLowerCase();

  // Detect transaction type
  const isExpense = /spent|paid|bought|chi|mua|trả|for\s+\w+/.test(lowerText);
  const isIncome = /received|earned|got|income|salary|nhận|lương|thu/.test(lowerText);
  const hasAmountForPattern = /\$[\d,.]+\s*(for|on)|[\d,.]+k?\s*(for|on)/i.test(text);

  if (!isExpense && !isIncome && !hasAmountForPattern) return null;

  const transactionType = isIncome ? "income" : "expense";

  // Extract amount
  const amountPatterns = [
    /\$\s*([\d,]+(?:\.\d{2})?)/,
    /([\d,]+(?:\.\d{2})?)\s*(?:usd|dollars?)/i,
    /([\d,]+(?:\.\d{2})?)\s*(?:k|K|ngàn|nghìn)/,
    /([\d,]+(?:\.\d{2})?)\s*(?:tr|triệu)/,
    /([\d,.]+)/
  ];

  let amount = 0;
  let currency = "USD";

  for (const pattern of amountPatterns) {
    const match = text.match(pattern);
    if (match) {
      let rawAmount = match[1].replace(/,/g, "");
      amount = parseFloat(rawAmount);

      if (/k|K|ngàn|nghìn/.test(match[0])) {
        amount *= 1000;
        currency = "VND";
      } else if (/tr|triệu/.test(match[0])) {
        amount *= 1000000;
        currency = "VND";
      } else if (/vnd|đồng|đ/i.test(text)) {
        currency = "VND";
      }
      break;
    }
  }

  if (amount <= 0) return null;

  // Category detection
  const categoryMap: Record<string, string[]> = {
    "Food & Drinks": ["lunch", "dinner", "breakfast", "food", "eat", "restaurant", "coffee", "ăn", "cơm", "phở", "cafe"],
    "Transportation": ["taxi", "uber", "grab", "bus", "gas", "fuel", "parking", "xe", "xăng"],
    "Shopping": ["buy", "bought", "shopping", "amazon", "mua", "sắm"],
    "Entertainment": ["movie", "netflix", "game", "concert", "phim", "giải trí"],
    "Bills & Utilities": ["bill", "electricity", "water", "internet", "phone", "điện", "nước", "wifi"],
    "Health": ["doctor", "medicine", "pharmacy", "hospital", "thuốc", "bệnh viện"],
  };

  let category = "Other";
  for (const [cat, keywords] of Object.entries(categoryMap)) {
    if (keywords.some(kw => lowerText.includes(kw))) {
      category = cat;
      break;
    }
  }

  let description = text
    .replace(/\$[\d,.]+/g, "")
    .replace(/[\d,.]+\s*(k|K|tr|usd|vnd|đ|dollars?|ngàn|nghìn|triệu)?/gi, "")
    .replace(/spent|paid|bought|received|earned|got|on|for|chi|mua|trả|nhận|lương|thu/gi, "")
    .trim();

  // Detect language from text content
  const hasVietnamese = /[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]|ăn|mua|chi|tiền|đồng|cho|của|được|vào|trong|ngoài|không|có/i.test(text);
  const language = hasVietnamese ? "vi" : "en";

  // Only set currency if explicitly specified, otherwise null (use wallet default)
  const hasCurrencySymbol = /\$|usd|vnd|đ|¥|€|£|₩|฿/i.test(text);
  const finalCurrency = hasCurrencySymbol ? currency : null;

  return {
    type: transactionType,
    amount,
    currency: finalCurrency,
    category,
    description: description || category,
    responseText: "",
    language
  };
}

// Setup bot handlers
function setupBotHandlers(bot: Bot) {
  // /start command
  bot.command("start", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    // Check if user is already linked
    const userLink = await bexlyDb.collection("user_platform_links")
      .where("platform", "==", "telegram")
      .where("platformUserId", "==", telegramId)
      .get();

    if (!userLink.empty) {
      await ctx.reply(
        "👋 Welcome back to Bexly!\n\n" +
        "You can:\n" +
        "• Log expenses: \"Spent $50 on lunch\"\n" +
        "• Log income: \"Received $500 salary\"\n" +
        "• Check balance: /balance\n" +
        "• This week's spending: /week\n" +
        "• Help: /help"
      );
    } else {
      const keyboard = new InlineKeyboard()
        .url("🔗 Link Bexly Account", `https://bexly-app.web.app/link?platform=telegram&id=${telegramId}`);

      await ctx.reply(
        "👋 Welcome to Bexly Bot!\n\n" +
        "I help you track expenses and income directly from Telegram.\n\n" +
        "First, let's link your Bexly account:",
        { reply_markup: keyboard }
      );
    }
  });

  // /link command - show link button
  bot.command("link", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    // Check if already linked
    const existingLink = await bexlyDb.collection("user_platform_links")
      .where("platform", "==", "telegram")
      .where("platformUserId", "==", telegramId)
      .get();

    if (!existingLink.empty) {
      await ctx.reply("✅ Your Telegram is already linked to Bexly!\n\nUse /unlink to disconnect.");
      return;
    }

    const keyboard = new InlineKeyboard()
      .url("🔗 Link Bexly Account", `https://bexly-app.web.app/telegram-link.html?id=${telegramId}`);

    await ctx.reply(
      "🔗 *Link your Bexly Account*\n\n" +
      "Click the button below to sign in and connect your Telegram:",
      { parse_mode: "Markdown", reply_markup: keyboard }
    );
  });

  // /unlink command
  bot.command("unlink", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    const snapshot = await bexlyDb.collection("user_platform_links")
      .where("platform", "==", "telegram")
      .where("platformUserId", "==", telegramId)
      .get();

    if (snapshot.empty) {
      await ctx.reply("❌ Your Telegram is not linked to any Bexly account.");
      return;
    }

    await snapshot.docs[0].ref.delete();
    await ctx.reply("✅ Your Telegram has been unlinked from Bexly.\n\nUse /link to connect again.");
  });

  // /help command
  bot.command("help", async (ctx) => {
    await ctx.reply(
      "📖 *Bexly Bot Help*\n\n" +
      "*Log Transactions:*\n" +
      "• \"Spent $50 on lunch\"\n" +
      "• \"Paid 100k for taxi\" (Vietnamese)\n" +
      "• \"Received $500 salary\"\n\n" +
      "*Commands:*\n" +
      "• /balance - Check your balance\n" +
      "• /week - This week's spending\n" +
      "• /month - This month's summary\n" +
      "• /link - Link Bexly account\n" +
      "• /unlink - Unlink account\n\n" +
      "*Tips:*\n" +
      "• Include amount and what it's for\n" +
      "• I'll auto-detect category\n" +
      "• Supports USD and VND",
      { parse_mode: "Markdown" }
    );
  });

  // /balance command
  bot.command("balance", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    const user = await getUserByTelegramId(telegramId);
    if (!user) {
      await ctx.reply("❌ Please link your Bexly account first. Use /start");
      return;
    }

    // Get user's wallets (path: users/{userId}/data/wallets)
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .get();

    if (walletsSnapshot.empty) {
      await ctx.reply("You don't have any wallets yet. Create one in the Bexly app!");
      return;
    }

    let message = "💰 *Your Wallets*\n\n";
    walletsSnapshot.forEach(doc => {
      const wallet = doc.data();
      message += `• ${wallet.name}: ${formatCurrency(wallet.balance || 0, wallet.currency)}\n`;
    });

    await ctx.reply(message, { parse_mode: "Markdown" });
  });

  // /today command
  bot.command("today", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    const user = await getUserByTelegramId(telegramId);
    if (!user) {
      await ctx.reply("❌ Please link your Bexly account first. Use /start");
      return;
    }

    // Get today's transactions
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    const transactionsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("transactions")
      .collection("items")
      .where("date", ">=", startOfDay)
      .where("date", "<=", endOfDay)
      .get();

    // Get user's default currency from first wallet
    let defaultCurrency = "USD";
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .limit(1)
      .get();

    if (!walletsSnapshot.empty) {
      defaultCurrency = walletsSnapshot.docs[0].data().currency || "USD";
    }

    let totalExpense = 0;
    let totalIncome = 0;
    const transactions: { title: string; amount: number; type: number }[] = [];

    transactionsSnapshot.forEach(doc => {
      const tx = doc.data();
      // transactionType: 0 = income, 1 = expense
      if (tx.transactionType === 1) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
      transactions.push({
        title: tx.title || "Unknown",
        amount: tx.amount,
        type: tx.transactionType
      });
    });

    const dateStr = now.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" });
    let message = `📅 *Today - ${dateStr}*\n\n`;

    if (transactions.length === 0) {
      message += "No transactions recorded today.\n\nStart by sending a message like:\n• \"$25 for lunch\"\n• \"Received $100 payment\"";
    } else {
      message += `📈 Income: ${formatCurrency(totalIncome, defaultCurrency)}\n`;
      message += `📉 Expense: ${formatCurrency(totalExpense, defaultCurrency)}\n`;
      message += `💵 Net: ${formatCurrency(totalIncome - totalExpense, defaultCurrency)}\n\n`;

      message += "*Transactions:*\n";
      // Show last 10 transactions
      const recentTxs = transactions.slice(-10);
      for (const tx of recentTxs) {
        const emoji = tx.type === 1 ? "🔴" : "🟢";
        const sign = tx.type === 1 ? "-" : "+";
        message += `${emoji} ${tx.title}: ${sign}${formatCurrency(tx.amount, defaultCurrency)}\n`;
      }

      if (transactions.length > 10) {
        message += `\n_... and ${transactions.length - 10} more_`;
      }
    }

    await ctx.reply(message, { parse_mode: "Markdown" });
  });

  // /week command
  bot.command("week", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    const user = await getUserByTelegramId(telegramId);
    if (!user) {
      await ctx.reply("❌ Please link your Bexly account first. Use /start");
      return;
    }

    // Get this week's transactions (path: users/{userId}/data/transactions/items)
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);

    const transactionsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("transactions")
      .collection("items")
      .where("date", ">=", startOfWeek)
      .get();

    // Get user's default currency from first wallet
    let defaultCurrency = "USD";
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .limit(1)
      .get();

    if (!walletsSnapshot.empty) {
      defaultCurrency = walletsSnapshot.docs[0].data().currency || "USD";
    }

    let totalExpense = 0;
    let totalIncome = 0;
    const categoryTotals: Record<string, number> = {};

    transactionsSnapshot.forEach(doc => {
      const tx = doc.data();
      // transactionType: 0 = income, 1 = expense
      if (tx.transactionType === 1) {
        totalExpense += tx.amount;
        const category = tx.title || "Other";
        categoryTotals[category] = (categoryTotals[category] || 0) + tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    });

    let message = "📊 *This Week's Summary*\n\n";
    message += `📈 Income: ${formatCurrency(totalIncome, defaultCurrency)}\n`;
    message += `📉 Expense: ${formatCurrency(totalExpense, defaultCurrency)}\n`;
    message += `💵 Net: ${formatCurrency(totalIncome - totalExpense, defaultCurrency)}\n\n`;

    if (Object.keys(categoryTotals).length > 0) {
      message += "*Top Expenses:*\n";
      const sorted = Object.entries(categoryTotals).sort((a, b) => b[1] - a[1]);
      for (const [title, amount] of sorted.slice(0, 5)) {
        message += `• ${title}: ${formatCurrency(amount, defaultCurrency)}\n`;
      }
    }

    await ctx.reply(message, { parse_mode: "Markdown" });
  });

  // /month command
  bot.command("month", async (ctx) => {
    const telegramId = ctx.from?.id.toString();
    if (!telegramId) return;

    const user = await getUserByTelegramId(telegramId);
    if (!user) {
      await ctx.reply("❌ Please link your Bexly account first. Use /start");
      return;
    }

    // Get this month's transactions
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

    const transactionsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("transactions")
      .collection("items")
      .where("date", ">=", startOfMonth)
      .get();

    // Get user's default currency from first wallet
    let defaultCurrency = "USD";
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .limit(1)
      .get();

    if (!walletsSnapshot.empty) {
      defaultCurrency = walletsSnapshot.docs[0].data().currency || "USD";
    }

    let totalExpense = 0;
    let totalIncome = 0;
    const categoryTotals: Record<string, number> = {};
    const dailyExpenses: Record<number, number> = {};

    transactionsSnapshot.forEach(doc => {
      const tx = doc.data();
      const txDate = tx.date.toDate ? tx.date.toDate() : new Date(tx.date);
      const day = txDate.getDate();

      // transactionType: 0 = income, 1 = expense
      if (tx.transactionType === 1) {
        totalExpense += tx.amount;
        const category = tx.title || "Other";
        categoryTotals[category] = (categoryTotals[category] || 0) + tx.amount;
        dailyExpenses[day] = (dailyExpenses[day] || 0) + tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    });

    const monthName = now.toLocaleDateString("en-US", { month: "long", year: "numeric" });
    let message = `📅 *${monthName}*\n\n`;

    message += `📈 Total Income: ${formatCurrency(totalIncome, defaultCurrency)}\n`;
    message += `📉 Total Expense: ${formatCurrency(totalExpense, defaultCurrency)}\n`;
    message += `💵 Net: ${formatCurrency(totalIncome - totalExpense, defaultCurrency)}\n\n`;

    // Calculate daily average
    const daysElapsed = now.getDate();
    const dailyAvg = totalExpense / daysElapsed;
    message += `📊 Daily Avg Expense: ${formatCurrency(dailyAvg, defaultCurrency)}\n\n`;

    if (Object.keys(categoryTotals).length > 0) {
      message += "*Top Expenses:*\n";
      const sorted = Object.entries(categoryTotals).sort((a, b) => b[1] - a[1]);
      for (const [title, amount] of sorted.slice(0, 7)) {
        const percent = ((amount / totalExpense) * 100).toFixed(1);
        message += `• ${title}: ${formatCurrency(amount, defaultCurrency)} (${percent}%)\n`;
      }
    }

    await ctx.reply(message, { parse_mode: "Markdown" });
  });

  // Handle text messages (expense/income logging)
  bot.on("message:text", async (ctx) => {
    const text = ctx.message.text;
    const telegramId = ctx.from?.id.toString();

    if (!telegramId) return;

    // Ignore commands
    if (text.startsWith("/")) return;

    // Check if user is linked
    const user = await getUserByTelegramId(telegramId);
    if (!user) {
      await ctx.reply(
        "❌ Your account is not linked yet.\n" +
        "Use /start to link your Bexly account first."
      );
      return;
    }

    // Show "typing" indicator while AI processes
    await ctx.replyWithChatAction("typing");

    // Fetch user's categories from Firestore to pass to AI
    const userCategories = await getUserCategories(user.bexlyUserId);

    // Parse the message using AI with user's actual categories
    const parsed = await parseTransactionWithAI(text, userCategories);

    if (!parsed) {
      await ctx.reply(
        "🤔 I couldn't understand that.\n\n" +
        "Try something like:\n" +
        "• \"$50 for lunch\"\n" +
        "• \"ăn sáng 50k\"\n" +
        "• \"Received $500 salary\"\n\n" +
        "Or use /help for more examples."
      );
      return;
    }

    // If currency is null, get wallet's default currency
    let displayCurrency = parsed.currency;
    if (!displayCurrency) {
      const walletsSnapshot = await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("wallets")
        .collection("items")
        .limit(1)
        .get();

      if (!walletsSnapshot.empty) {
        const walletData = walletsSnapshot.docs[0].data();
        displayCurrency = walletData.currency || "USD";
      } else {
        displayCurrency = "USD"; // fallback
      }
    }

    // Show confirmation with AI-generated response
    const emoji = parsed.type === "expense" ? "💸" : "💰";
    const catEmoji = getCategoryEmoji(parsed.category);

    // Get localized category name for display
    const localizedCategory = getLocalizedCategoryName(
      parsed.category,
      parsed.language,
      userCategories
    );

    // Include language and description in callback data so we can use it after confirm
    // Use "WALLET" as placeholder when currency should use wallet default
    // Truncate description to fit in 64-byte limit (category|lang|desc takes ~30 bytes max)
    const currencyForCallback = parsed.currency || "WALLET";
    const truncatedDesc = parsed.description.substring(0, 20);
    const keyboard = new InlineKeyboard()
      .text("✅ Confirm", `confirm_${parsed.type}_${parsed.amount}_${currencyForCallback}_${parsed.category}|${parsed.language}|${truncatedDesc}`)
      .text("❌ Cancel", "cancel");

    // Use AI response text if available, otherwise build our own with localized category
    const responseMessage = parsed.responseText ||
      `${emoji} *${parsed.type === "expense" ? "Expense" : "Income"} Detected*\n\n` +
      `💵 Amount: ${formatCurrency(parsed.amount, displayCurrency!)}\n` +
      `${catEmoji} Category: ${localizedCategory}\n` +
      `📝 Note: ${parsed.description}`;

    await ctx.reply(
      `${responseMessage}\n\nConfirm?`,
      { parse_mode: "Markdown", reply_markup: keyboard }
    );
  });

  // Handle callback queries (button clicks)
  bot.on("callback_query:data", async (ctx) => {
    const data = ctx.callbackQuery.data;
    const telegramId = ctx.from?.id.toString();

    if (!telegramId) return;

    if (data === "cancel") {
      await ctx.editMessageText("❌ Cancelled");
      await ctx.answerCallbackQuery();
      return;
    }

    if (data.startsWith("confirm_")) {
      // Format: confirm_type_amount_currency_category|language|description
      const parts = data.split("_");
      const type = parts[1] as "expense" | "income";
      const originalAmount = parseFloat(parts[2]);
      const inputCurrencyRaw = parts[3]; // "WALLET" means use wallet default, otherwise currency code
      // parts[4] onwards contains: category|language|description (rejoin in case category has underscores)
      const lastPart = parts.slice(4).join("_");
      const [category, language = "en", description = ""] = lastPart.split("|");

      const user = await getUserByTelegramId(telegramId);
      if (!user) {
        await ctx.answerCallbackQuery({ text: "Account not linked!" });
        return;
      }

      // DEBUG: Log bexlyUserId to verify it matches Firestore
      console.log("=== DEBUG WALLET LOOKUP ===");
      console.log("telegramId:", telegramId);
      console.log("bexlyUserId from user_platform_links:", user.bexlyUserId);
      console.log("Full user object:", JSON.stringify(user));

      // Get user's default wallet from settings, or fallback to first wallet
      let wallet: FirebaseFirestore.QueryDocumentSnapshot | null = null;

      // First, try to get defaultWalletCloudId from user settings
      const settingsDoc = await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("settings")
        .get();

      const defaultWalletCloudId = settingsDoc.exists ? settingsDoc.data()?.defaultWalletCloudId : null;
      console.log("defaultWalletCloudId from settings:", defaultWalletCloudId);

      if (defaultWalletCloudId) {
        // Get wallet by cloudId
        const defaultWalletDoc = await bexlyDb
          .collection("users")
          .doc(user.bexlyUserId)
          .collection("data")
          .doc("wallets")
          .collection("items")
          .doc(defaultWalletCloudId)
          .get();

        if (defaultWalletDoc.exists) {
          // Convert DocumentSnapshot to QueryDocumentSnapshot-like object for consistency
          wallet = defaultWalletDoc as unknown as FirebaseFirestore.QueryDocumentSnapshot;
          console.log("Using default wallet from settings:", defaultWalletCloudId);
        }
      }

      // Fallback: get first wallet if no default set or default not found
      if (!wallet) {
        const walletsSnapshot = await bexlyDb
          .collection("users")
          .doc(user.bexlyUserId)
          .collection("data")
          .doc("wallets")
          .collection("items")
          .limit(1)
          .get();

        console.log("walletsSnapshot.empty:", walletsSnapshot.empty);
        console.log("walletsSnapshot.size:", walletsSnapshot.size);

        if (walletsSnapshot.empty) {
          // DEBUG: Try to list all users to see what IDs exist
          const usersSnapshot = await bexlyDb.collection("users").limit(5).get();
          console.log("Sample user IDs in Firestore:");
          usersSnapshot.docs.forEach(doc => console.log(" - ", doc.id));

          await ctx.editMessageText("❌ No wallet found. Create one in Bexly app first.");
          await ctx.answerCallbackQuery();
          return;
        }

        wallet = walletsSnapshot.docs[0];
        console.log("Using first wallet (no default set):", wallet.id);
      }

      // Find matching category from user's categories
      // AI now returns EXACT category title from user's Firestore list
      console.log(`Searching for category with exact title: "${category}"`);

      // Search for exact match on title
      const categoriesSnapshot = await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("categories")
        .collection("items")
        .where("title", "==", category)
        .limit(1)
        .get();

      // If no exact match, try "Other" category (may exist in different languages)
      let categoryDoc = categoriesSnapshot.docs[0];
      if (!categoryDoc) {
        console.log(`No exact match for "${category}", trying fallback categories...`);
        // Try common "Other" category names
        const otherNames = ["Other", "Other Income", "Other Expense", "Khác"];
        const otherCategorySnapshot = await bexlyDb
          .collection("users")
          .doc(user.bexlyUserId)
          .collection("data")
          .doc("categories")
          .collection("items")
          .where("title", "in", otherNames)
          .limit(1)
          .get();
        categoryDoc = otherCategorySnapshot.docs[0];
      }
      if (!categoryDoc) {
        // Last resort: use first expense category
        const anyCategorySnapshot = await bexlyDb
          .collection("users")
          .doc(user.bexlyUserId)
          .collection("data")
          .doc("categories")
          .collection("items")
          .where("transactionType", "==", type)
          .limit(1)
          .get();
        categoryDoc = anyCategorySnapshot.docs[0];
      }
      if (!categoryDoc) {
        // Really last resort: any category
        const anyCategorySnapshot = await bexlyDb
          .collection("users")
          .doc(user.bexlyUserId)
          .collection("data")
          .doc("categories")
          .collection("items")
          .limit(1)
          .get();
        categoryDoc = anyCategorySnapshot.docs[0];
      }

      if (!categoryDoc) {
        await ctx.editMessageText("❌ No category found. Create one in Bexly app first.");
        await ctx.answerCallbackQuery();
        return;
      }

      // Convert type string to integer (0: income, 1: expense)
      const transactionType = type === "income" ? 0 : 1;

      // Get wallet currency for the transaction
      const walletData = wallet.data();
      const walletCurrency = walletData.currency || "USD";

      // Determine input currency - "WALLET" means use wallet's currency (no conversion needed)
      const inputCurrency = inputCurrencyRaw === "WALLET" ? walletCurrency : inputCurrencyRaw;

      // Convert amount if currencies don't match
      let finalAmount = originalAmount;
      let conversionNote = "";
      let didConvert = false;

      if (inputCurrency !== walletCurrency) {
        try {
          console.log(`Converting ${originalAmount} ${inputCurrency} to ${walletCurrency}`);
          const { convertedAmount, rate } = await convertCurrency(
            originalAmount,
            inputCurrency,
            walletCurrency
          );
          finalAmount = convertedAmount;
          didConvert = true;
          // Format conversion note nicely - show reverse rate for VND→USD
          if (inputCurrency === "VND" && rate < 0.01) {
            // Show as "1 USD = X VND" for better readability
            const reverseRate = 1 / rate;
            conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)} @ 1 ${walletCurrency} = ${reverseRate.toFixed(0)} ${inputCurrency})`;
          } else {
            conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)})`;
          }
          console.log(`Converted: ${originalAmount} ${inputCurrency} = ${finalAmount} ${walletCurrency}`);
        } catch (convError) {
          console.error("Currency conversion failed:", convError);
          await ctx.editMessageText(
            `❌ Currency conversion failed.\n\n` +
            `Your wallet uses ${walletCurrency}, but you entered ${inputCurrency}.\n` +
            `Please try again or update your wallet currency in the app.`
          );
          await ctx.answerCallbackQuery();
          return;
        }
      }

      // Generate UUID v7 for document ID (same format as app)
      const transactionId = uuidv7();

      // Create transaction with correct format for app sync
      // Use UUID v7 as document ID and store walletCloudId/categoryCloudId
      // Title: use description from AI (e.g., "lunch", "Mua PC"), fallback to category name
      const transactionTitle = description || category;
      await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("transactions")
        .collection("items")
        .doc(transactionId)
        .set({
          walletCloudId: wallet.id,
          categoryCloudId: categoryDoc.id,
          transactionType,
          amount: finalAmount,
          title: transactionTitle,
          notes: conversionNote || "",
          date: admin.firestore.Timestamp.now(),
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
          source: "telegram_bot"
        });

      console.log("Transaction created successfully:", transactionId, "walletCloudId:", wallet.id, "categoryCloudId:", categoryDoc.id, "amount:", finalAmount, "walletCurrency:", walletCurrency);

      // Update wallet balance
      const balanceChange = type === "expense" ? -finalAmount : finalAmount;
      await wallet.ref.update({
        balance: admin.firestore.FieldValue.increment(balanceChange)
      });

      // Get localization for user's language
      const loc = getLocalization(language);
      const localizedType = type === "expense" ? loc.expense : loc.income;

      // Get localized category title based on user's language
      const categoryData = categoryDoc.data();
      let categoryTitle = categoryData.title || category;

      // Try to get localized title from localizedTitles field
      if (categoryData.localizedTitles) {
        try {
          const localizedTitles = typeof categoryData.localizedTitles === 'string'
            ? JSON.parse(categoryData.localizedTitles)
            : categoryData.localizedTitles;

          if (localizedTitles[language]) {
            categoryTitle = localizedTitles[language];
          } else if (localizedTitles['en']) {
            categoryTitle = localizedTitles['en'];
          }
        } catch (e) {
          console.warn('Failed to parse localizedTitles for confirmation message:', e);
        }
      }

      // Format message in user's language
      let loggedText: string;
      if (didConvert) {
        // With conversion: "✅ $3.22 支出 (¥500から) → My USD Wallet | 飲食"
        loggedText = `✅ *${formatCurrency(finalAmount, walletCurrency)}* ${localizedType} (${formatCurrency(originalAmount, inputCurrency)} ${loc.from}) → *${walletData.name}*\n📝 ${categoryTitle}`;
      } else {
        // Without conversion: "✅ ¥500 支出 → My Wallet | 飲食"
        loggedText = `✅ *${formatCurrency(finalAmount, walletCurrency)}* ${localizedType} → *${walletData.name}*\n📝 ${categoryTitle}`;
      }

      await ctx.editMessageText(loggedText, { parse_mode: "Markdown" });
      await ctx.answerCallbackQuery({ text: "✅" });
    }
  });
}

// Helper functions
async function getUserByTelegramId(telegramId: string) {
  const snapshot = await bexlyDb.collection("user_platform_links")
    .where("platform", "==", "telegram")
    .where("platformUserId", "==", telegramId)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  return snapshot.docs[0].data();
}

function formatCurrency(amount: number, currency: string): string {
  if (currency === "VND") {
    return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount);
  }
  return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(amount);
}

function getCategoryEmoji(category: string): string {
  const emojis: Record<string, string> = {
    food: "🍔",
    transport: "🚗",
    shopping: "🛒",
    entertainment: "🎬",
    bills: "📄",
    health: "💊",
    salary: "💼",
    other: "📦"
  };
  return emojis[category] || "📦";
}

// Get localized category name from user's categories
// Returns the localized name based on language, falls back to English title, then original title
function getLocalizedCategoryName(
  categoryTitle: string,
  language: string,
  userCategories: UserCategory[]
): string {
  // Find the category by English title (stored in 'title' field)
  const category = userCategories.find(
    c => c.title.toLowerCase() === categoryTitle.toLowerCase()
  );

  if (!category) {
    // Category not found, return original title
    return categoryTitle;
  }

  // Try to get localized title for the detected language
  if (category.localizedTitles) {
    const localizedName = category.localizedTitles[language];
    if (localizedName) {
      return localizedName;
    }
    // Fallback to English if available
    if (category.localizedTitles['en']) {
      return category.localizedTitles['en'];
    }
  }

  // Fallback to original title (English)
  return category.title;
}

// Exchange rate API (same as Flutter app)
const EXCHANGE_RATE_API = "https://api.exchangerate-api.com/v4/latest";

// Emergency fallback rates (when API fails)
const FALLBACK_RATES: Record<string, number> = {
  "USD_VND": 25500,
  "VND_USD": 0.0000392,
  "USD_EUR": 0.92,
  "EUR_USD": 1.09,
};

// Get exchange rate from API
async function getExchangeRate(fromCurrency: string, toCurrency: string): Promise<number> {
  // Same currency = 1.0
  if (fromCurrency === toCurrency) {
    return 1.0;
  }

  try {
    // Try free API first
    const response = await fetch(`${EXCHANGE_RATE_API}/${fromCurrency}`);
    if (!response.ok) {
      throw new Error(`API returned ${response.status}`);
    }

    const data = await response.json() as { rates: Record<string, number> };
    const rate = data.rates[toCurrency];

    if (!rate || rate <= 0) {
      throw new Error(`Rate not found for ${toCurrency}`);
    }

    console.log(`Exchange rate: 1 ${fromCurrency} = ${rate} ${toCurrency}`);
    return rate;
  } catch (error) {
    console.error("Exchange rate API failed:", error);

    // Fallback to hardcoded rates
    const key = `${fromCurrency}_${toCurrency}`;
    if (FALLBACK_RATES[key]) {
      console.log(`Using fallback rate: ${FALLBACK_RATES[key]}`);
      return FALLBACK_RATES[key];
    }

    // Try reverse
    const reverseKey = `${toCurrency}_${fromCurrency}`;
    if (FALLBACK_RATES[reverseKey]) {
      const rate = 1.0 / FALLBACK_RATES[reverseKey];
      console.log(`Using reverse fallback rate: ${rate}`);
      return rate;
    }

    throw new Error(`No exchange rate available for ${fromCurrency} to ${toCurrency}`);
  }
}

// Convert amount from one currency to another
async function convertCurrency(
  amount: number,
  fromCurrency: string,
  toCurrency: string
): Promise<{ convertedAmount: number; rate: number }> {
  if (fromCurrency === toCurrency) {
    return { convertedAmount: amount, rate: 1.0 };
  }

  const rate = await getExchangeRate(fromCurrency, toCurrency);
  const convertedAmount = amount * rate;

  return { convertedAmount, rate };
}

// Telegram webhook endpoint (2nd gen)
export const telegramWebhook = onRequest(
  {
    secrets: [telegramBotToken, geminiApiKey, openaiApiKey],
  },
  async (req, res) => {
    try {
      const bot = getBot();
      const handleUpdate = webhookCallback(bot, "express");
      await handleUpdate(req, res);
    } catch (error) {
      console.error("Webhook error:", error);
      res.status(500).send("Error");
    }
  }
);

// Link account endpoint (called from Bexly app after OAuth) - 2nd gen
export const linkTelegramAccount = onCall(
  {
    secrets: [telegramBotToken],
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { telegramId } = request.data;
    const bexlyUserId = request.auth.uid;
    const userEmail = request.auth.token.email || "Unknown";
    const userName = request.auth.token.name || userEmail.split("@")[0];

    // Check if telegram account is already linked
    const existing = await bexlyDb.collection("user_platform_links")
      .where("platform", "==", "telegram")
      .where("platformUserId", "==", telegramId)
      .get();

    if (!existing.empty) {
      throw new HttpsError("already-exists", "This Telegram account is already linked");
    }

    // Create link
    await bexlyDb.collection("user_platform_links").add({
      bexlyUserId,
      platform: "telegram",
      platformUserId: telegramId,
      linkedAt: admin.firestore.Timestamp.now(),
      lastActivity: admin.firestore.Timestamp.now()
    });

    // Get user's wallets to show in welcome message (path: users/{userId}/data/wallets/items)
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .get();

    let walletsInfo = "";
    let totalBalance = 0;

    if (!walletsSnapshot.empty) {
      walletsInfo = walletsSnapshot.docs.map(doc => {
        const data = doc.data();
        const balance = data.balance || 0;
        const currency = data.currency || "VND";
        totalBalance += balance;
        return `  • ${data.name}: ${formatCurrency(balance, currency)}`;
      }).join("\n");
    } else {
      walletsInfo = "  No wallets yet";
    }

    // Send welcome message to Telegram
    const botToken = telegramBotToken.value();
    const welcomeMessage =
      `✅ *Account Linked Successfully!*\n\n` +
      `👤 *Account:* ${userName}\n` +
      `📧 *Email:* ${userEmail}\n\n` +
      `💰 *Your Wallets:*\n${walletsInfo}\n\n` +
      `You can now log transactions directly from Telegram!\n` +
      `Try: "Spent 50k for lunch" or "Received 100k salary"`;

    try {
      await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: telegramId,
          text: welcomeMessage,
          parse_mode: "Markdown"
        })
      });
    } catch (error) {
      console.error("Failed to send Telegram welcome message:", error);
    }

    return { success: true };
  }
);

// Unlink account - 2nd gen
export const unlinkTelegramAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const bexlyUserId = request.auth.uid;

  const snapshot = await bexlyDb.collection("user_platform_links")
    .where("platform", "==", "telegram")
    .where("bexlyUserId", "==", bexlyUserId)
    .get();

  if (snapshot.empty) {
    throw new HttpsError("not-found", "No linked Telegram account found");
  }

  await snapshot.docs[0].ref.delete();

  return { success: true };
});
