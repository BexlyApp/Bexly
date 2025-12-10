import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { Bot, webhookCallback, InlineKeyboard } from "grammy";
// Using REST API directly instead of SDK for better control
// import { GoogleGenerativeAI } from "@google/generative-ai";
import { v7 as uuidv7 } from "uuid";
import * as crypto from "crypto";

// Define secrets
const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const openaiApiKey = defineSecret("OPENAI_API_KEY");
// const claudeApiKey = defineSecret("CLAUDE_API_KEY"); // Uncomment when CLAUDE_API_KEY secret is set
const messengerPageToken = defineSecret("MESSENGER_PAGE_TOKEN");
const messengerAppSecret = defineSecret("MESSENGER_APP_SECRET");
const messengerVerifyToken = defineSecret("MESSENGER_VERIFY_TOKEN");

// AI Provider configuration - can be changed here
type AIProvider = "gemini" | "openai" | "claude";
const AI_PROVIDER: AIProvider = "gemini";
const GEMINI_MODEL = "gemini-2.5-flash";
const OPENAI_MODEL = "gpt-4o-mini";
// const CLAUDE_MODEL = "claude-sonnet-4-20250514"; // Uncomment when Claude is enabled

// Set global options for all functions
setGlobalOptions({
  region: "asia-southeast1",
  // Keep at least 1 instance warm to avoid cold start (~6-8s delay)
  minInstances: 1,
});

// Initialize Firebase Admin
admin.initializeApp();

// Get reference to non-default database "bexly"
// Using Firestore constructor directly for named database
const bexlyDb = new admin.firestore.Firestore({
  projectId: "bexly-app",
  databaseId: "bexly",
});

// Bot instance cache
let bot: Bot | null = null;
let lastToken: string = "";

// In-memory dedup for Messenger messages (survives within same instance)
const processedMessageIds = new Set<string>();

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
  // Error/UI messages
  cancelled: string;
  linkFirst: string;
  noWallet: string;
  noCategory: string;
  conversionFailed: string;
  addMore: string;
  balance: string;
  // Preview messages
  expenseDetected: string;
  incomeDetected: string;
  confirm: string;
  cancel: string;
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
    cancelled: "Cancelled",
    linkFirst: "Please link your Bexly account first",
    noWallet: "No wallet found. Create one in Bexly app first.",
    noCategory: "No category found. Create one in Bexly app first.",
    conversionFailed: "Currency conversion failed",
    addMore: "Add more",
    balance: "Balance",
    expenseDetected: "Expense Detected",
    incomeDetected: "Income Detected",
    confirm: "Confirm",
    cancel: "Cancel",
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
    cancelled: "Đã hủy",
    linkFirst: "Vui lòng liên kết tài khoản Bexly trước",
    noWallet: "Không tìm thấy ví. Tạo ví trong ứng dụng Bexly.",
    noCategory: "Không tìm thấy danh mục. Tạo trong ứng dụng Bexly.",
    conversionFailed: "Chuyển đổi tiền tệ thất bại",
    addMore: "Thêm giao dịch",
    balance: "Số dư",
    expenseDetected: "Chi tiêu",
    incomeDetected: "Thu nhập",
    confirm: "Xác nhận",
    cancel: "Hủy",
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
    cancelled: "キャンセル",
    linkFirst: "まずBexlyアカウントをリンクしてください",
    noWallet: "ウォレットが見つかりません。Bexlyアプリで作成してください。",
    noCategory: "カテゴリが見つかりません。Bexlyアプリで作成してください。",
    conversionFailed: "通貨変換に失敗しました",
    addMore: "追加",
    balance: "残高",
    expenseDetected: "支出",
    incomeDetected: "収入",
    confirm: "確認",
    cancel: "キャンセル",
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
    cancelled: "취소됨",
    linkFirst: "먼저 Bexly 계정을 연결하세요",
    noWallet: "지갑을 찾을 수 없습니다. Bexly 앱에서 생성하세요.",
    noCategory: "카테고리를 찾을 수 없습니다. Bexly 앱에서 생성하세요.",
    conversionFailed: "환전 실패",
    addMore: "추가",
    balance: "잔액",
    expenseDetected: "지출",
    incomeDetected: "수입",
    confirm: "확인",
    cancel: "취소",
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
    cancelled: "已取消",
    linkFirst: "请先关联您的Bexly账户",
    noWallet: "未找到钱包，请在Bexly应用中创建。",
    noCategory: "未找到类别，请在Bexly应用中创建。",
    conversionFailed: "货币转换失败",
    addMore: "添加更多",
    balance: "余额",
    expenseDetected: "支出",
    incomeDetected: "收入",
    confirm: "确认",
    cancel: "取消",
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
    cancelled: "ยกเลิกแล้ว",
    linkFirst: "กรุณาเชื่อมต่อบัญชี Bexly ก่อน",
    noWallet: "ไม่พบกระเป๋าเงิน กรุณาสร้างในแอป Bexly",
    noCategory: "ไม่พบหมวดหมู่ กรุณาสร้างในแอป Bexly",
    conversionFailed: "แปลงสกุลเงินล้มเหลว",
    addMore: "เพิ่มอีก",
    balance: "ยอดเงิน",
    expenseDetected: "รายจ่าย",
    incomeDetected: "รายรับ",
    confirm: "ยืนยัน",
    cancel: "ยกเลิก",
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
    cancelled: "Dibatalkan",
    linkFirst: "Silakan hubungkan akun Bexly terlebih dahulu",
    noWallet: "Dompet tidak ditemukan. Buat di aplikasi Bexly.",
    noCategory: "Kategori tidak ditemukan. Buat di aplikasi Bexly.",
    conversionFailed: "Konversi mata uang gagal",
    addMore: "Tambah lagi",
    balance: "Saldo",
    expenseDetected: "Pengeluaran",
    incomeDetected: "Pemasukan",
    confirm: "Konfirmasi",
    cancel: "Batal",
  },
};

// Get localization for a language (fallback to English)
function getLocalization(lang: string): Localization {
  return LOCALIZATIONS[lang] || LOCALIZATIONS["en"];
}

// Fetch user's categories from Firestore
async function getUserCategories(bexlyUserId: string): Promise<UserCategory[]> {
  try {
    // Path: users/{userId}/data/categories/items
    const categoriesPath = `users/${bexlyUserId}/data/categories/items`;
    console.log("Fetching categories from path:", categoriesPath);

    const categoriesSnapshot = await bexlyDb
      .collection("users")
      .doc(bexlyUserId)
      .collection("data")
      .doc("categories")
      .collection("items")
      .get();

    console.log("Categories snapshot size:", categoriesSnapshot.size, "empty:", categoriesSnapshot.empty);

    if (categoriesSnapshot.empty) {
      console.log("No categories found in Firestore for user:", bexlyUserId, "- returning default categories");
      // Return default categories if user hasn't synced yet
      return [
        { id: "food", title: "Food & Drinks", transactionType: "expense" },
        { id: "transport", title: "Transportation", transactionType: "expense" },
        { id: "shopping", title: "Shopping", transactionType: "expense" },
        { id: "bills", title: "Bills & Utilities", transactionType: "expense" },
        { id: "entertainment", title: "Entertainment", transactionType: "expense" },
        { id: "health", title: "Health", transactionType: "expense" },
        { id: "education", title: "Education", transactionType: "expense" },
        { id: "other", title: "Other", transactionType: "expense" },
        { id: "salary", title: "Salary", transactionType: "income" },
        { id: "bonus", title: "Bonus", transactionType: "income" },
        { id: "investment", title: "Investment", transactionType: "income" },
        { id: "other_income", title: "Other Income", transactionType: "income" },
      ];
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
    // Log all category titles for debugging
    console.log("Category titles:", categories.map(c => c.title).join(", "));

    // Warning if very few categories (likely sync issue)
    if (categories.length < 5) {
      console.warn(`Warning: User ${bexlyUserId} has only ${categories.length} categories in Firestore. App may not have synced yet.`);
    }

    return categories;
  } catch (error) {
    console.error("Error fetching user categories:", error);
    return [];
  }
}

// Build dynamic AI prompt with user's actual categories and wallet info
// OPTIMIZED: Shorter prompt = faster response
function buildDynamicPrompt(userCategories: UserCategory[], walletCurrency?: string): string {
  // Separate expense and income categories - limit to 10 each to reduce prompt size
  const expenseCategories = userCategories
    .filter(c => c.transactionType === "expense")
    .map(c => c.title)
    .slice(0, 10);
  const incomeCategories = userCategories
    .filter(c => c.transactionType === "income")
    .map(c => c.title)
    .slice(0, 5);

  // Build category list for prompt
  const expenseCatList = expenseCategories.length > 0
    ? expenseCategories.join("|")
    : "Food & Drinks|Shopping|Other";
  const incomeCatList = incomeCategories.length > 0
    ? incomeCategories.join("|")
    : "Salary|Other Income";

  // Ultra-compact prompt for speed - MUST ALWAYS return valid category
  return `Parse→JSON.{"action":"create_expense"|"create_income"|"none","amount":num,"currency":"VND"|"USD"|null,"lang":"vi"|"en","desc":"str","cat":"CATEGORY"}
k=×1000,tr=×1000000→VND.$→USD.No symbol→null.
EXP:${expenseCatList}|INC:${incomeCatList}
⚠️cat MUST be from list above or "Other"!NEVER empty!
"50k lunch"→{"action":"create_expense","amount":50000,"currency":"VND","lang":"vi","desc":"lunch","cat":"Food & Drinks"}
"mua túi LV 50tr"→{"action":"create_expense","amount":50000000,"currency":"VND","lang":"vi","desc":"mua túi LV","cat":"Shopping"}
"hi"→{"action":"none","amount":0,"currency":null,"lang":"en","desc":"","cat":""}`;
}

// Parse transaction using Gemini AI
async function parseWithGemini(text: string, dynamicPrompt: string): Promise<string | null> {
  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    console.error("Gemini API key not configured");
    return null;
  }

  // Use REST API directly for more control
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

  // Use systemInstruction for better caching (Gemini 2.5 implicit caching)
  // System instruction is cached separately, user input changes each request
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: dynamicPrompt }]
      },
      contents: [{
        role: "user",
        parts: [{ text: text }]
      }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 300,
        candidateCount: 1,
      }
    })
  });

  if (!response.ok) {
    console.error("Gemini API error:", response.status, await response.text());
    return null;
  }

  const data = await response.json() as {
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
      finishReason?: string;
    }>;
  };

  const result = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  const finishReason = data.candidates?.[0]?.finishReason;

  if (finishReason && finishReason !== "STOP") {
    console.warn("Gemini finish reason:", finishReason);
  }

  return result || null;
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

// Parse transaction using Claude
// Uncomment when CLAUDE_API_KEY secret is configured
// async function parseWithClaude(text: string, dynamicPrompt: string): Promise<string | null> {
//   const apiKey = claudeApiKey.value();
//   if (!apiKey) {
//     console.error("Claude API key not configured");
//     return null;
//   }
//
//   const response = await fetch("https://api.anthropic.com/v1/messages", {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//       "x-api-key": apiKey,
//       "anthropic-version": "2023-06-01"
//     },
//     body: JSON.stringify({
//       model: CLAUDE_MODEL,
//       max_tokens: 300,
//       system: dynamicPrompt, // Claude uses "system" for system prompt (cached)
//       messages: [
//         { role: "user", content: text }
//       ]
//     })
//   });
//
//   if (!response.ok) {
//     console.error("Claude API error:", response.status, await response.text());
//     return null;
//   }
//
//   const data = await response.json() as { content: { type: string; text: string }[] };
//   return data.content[0]?.text?.trim() || null;
// }

// Main AI parsing function - supports multiple providers
async function parseTransactionWithAI(text: string, userCategories: UserCategory[], walletCurrency?: string): Promise<ParsedTransaction | null> {
  try {
    let response: string | null = null;

    // Build dynamic prompt with user's actual categories and wallet currency
    const dynamicPrompt = buildDynamicPrompt(userCategories, walletCurrency);
    console.log("Using dynamic prompt with user categories:", userCategories.map(c => c.title).slice(0, 10), "...", "wallet:", walletCurrency);

    // Use configured AI provider
    switch (AI_PROVIDER) {
      case "gemini":
        response = await parseWithGemini(text, dynamicPrompt);
        break;
      case "openai":
        response = await parseWithOpenAI(text, dynamicPrompt);
        break;
      // case "claude":
      //   response = await parseWithClaude(text, dynamicPrompt);
      //   break;
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
    // Handle potential markdown code blocks and multi-line JSON
    let jsonStr = response;

    // Remove markdown code blocks
    if (jsonStr.includes("```")) {
      jsonStr = jsonStr.replace(/```json?\s*/gi, "").replace(/```/g, "");
    }

    // Remove newlines and extra spaces (in case of pretty-printed JSON)
    jsonStr = jsonStr.replace(/\n\s*/g, "").trim();

    // Try to find JSON object in the response
    const jsonMatch = jsonStr.match(/\{[^}]+\}/);
    if (jsonMatch) {
      jsonStr = jsonMatch[0];
    }

    const parsed = JSON.parse(jsonStr);

    if (parsed.action === "none" || !parsed.action) {
      return null;
    }

    // Get category - AI may return empty string, fallback to "Other"
    let category = parsed.cat || parsed.category || "";
    if (!category || category.trim() === "") {
      // Determine fallback based on transaction type
      category = parsed.action === "create_income" ? "Other Income" : "Other";
      console.log(`AI returned empty category, using fallback: ${category}`);
    }

    return {
      type: parsed.action === "create_income" ? "income" : "expense",
      amount: parsed.amount,
      currency: parsed.currency || null, // null means use wallet's default
      category,
      description: parsed.desc || parsed.description || "",
      responseText: "", // We build this ourselves now
      language: parsed.lang || parsed.language || "en"
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

  // Set currency if explicitly specified
  const hasCurrencySymbol = /\$|usd|vnd|đ|¥|€|£|₩|฿/i.test(text);
  // "tr/triệu/ngàn/nghìn" are Vietnamese-only shortcuts → always VND
  // "k" is ambiguous (could be English "k" for thousand) - only VND if Vietnamese context
  const hasVietnameseAmountShortcut = /\d+\s*(tr|triệu|ngàn|nghìn)/i.test(text);
  const hasKwithVietnamese = /\d+\s*k/i.test(text) && hasVietnamese;
  const impliesVND = hasVietnameseAmountShortcut || hasKwithVietnamese;
  const finalCurrency = (hasCurrencySymbol || impliesVND) ? currency : null;

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
      .url("🔗 Link Bexly Account", `https://bexly-app.web.app/link-account.html?platform=telegram&id=${telegramId}`);

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

    // Fetch user's categories and wallet currency for AI context
    const userCategories = await getUserCategories(user.bexlyUserId);

    // Get wallet currency to pass to AI for currency confirmation logic
    let walletCurrency = "USD";
    const walletsSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .limit(1)
      .get();

    if (!walletsSnapshot.empty) {
      walletCurrency = walletsSnapshot.docs[0].data().currency || "USD";
    }

    // Parse the message using AI with user's actual categories and wallet currency
    const parsed = await parseTransactionWithAI(text, userCategories, walletCurrency);

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

    // Get localization for user's language
    const loc = getLocalization(parsed.language);

    // Use wallet currency we already fetched, or parsed currency
    const displayCurrency = parsed.currency || walletCurrency;

    // Show confirmation with AI-generated response
    const emoji = parsed.type === "expense" ? "💸" : "💰";
    const catEmoji = getCategoryEmoji(parsed.category);

    // Get localized category name for display
    const localizedCategory = getLocalizedCategoryName(
      parsed.category,
      parsed.language,
      userCategories
    );

    // Get localized type label
    const localizedTypeLabel = parsed.type === "expense" ? loc.expenseDetected : loc.incomeDetected;

    // Include language and description in callback data so we can use it after confirm
    // Use "WALLET" as placeholder when currency should use wallet default
    // Truncate description to fit in 64-byte limit (category|lang|desc takes ~30 bytes max)
    const currencyForCallback = parsed.currency || "WALLET";
    const truncatedDesc = parsed.description.substring(0, 20);
    const keyboard = new InlineKeyboard()
      .text(`✅ ${loc.confirm}`, `confirm_${parsed.type}_${parsed.amount}_${currencyForCallback}_${parsed.category}|${parsed.language}|${truncatedDesc}`)
      .text(`❌ ${loc.cancel}`, "cancel");

    // Use AI response text if available, otherwise build localized preview
    const responseMessage = parsed.responseText ||
      `${emoji} *${localizedTypeLabel}*\n\n` +
      `💵 ${formatCurrency(parsed.amount, displayCurrency)}\n` +
      `${catEmoji} ${localizedCategory}\n` +
      `📝 ${parsed.description}`;

    // Add localized confirm prompt
    const confirmPrompt = parsed.language === "vi" ? "Xác nhận?" :
                         parsed.language === "ja" ? "確認しますか?" :
                         parsed.language === "ko" ? "확인하시겠습니까?" :
                         parsed.language === "zh" ? "确认？" :
                         parsed.language === "th" ? "ยืนยัน?" :
                         parsed.language === "id" ? "Konfirmasi?" :
                         "Confirm?";

    await ctx.reply(
      `${responseMessage}\n\n${confirmPrompt}`,
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
    secrets: [telegramBotToken, geminiApiKey, openaiApiKey], // Add claudeApiKey when CLAUDE_API_KEY secret is set
    timeoutSeconds: 60, // Allow more time for AI processing
  },
  async (req, res) => {
    try {
      const bot = getBot();
      // Increase webhook timeout to 30s to avoid duplicate responses
      const handleUpdate = webhookCallback(bot, "express", { timeoutMilliseconds: 30000 });
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

// ============================================================
// FACEBOOK MESSENGER BOT
// ============================================================

// Messenger API helpers
async function sendMessengerMessage(recipientId: string, message: object): Promise<void> {
  const pageToken = messengerPageToken.value();

  const response = await fetch(
    `https://graph.facebook.com/v22.0/me/messages?access_token=${pageToken}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        recipient: { id: recipientId },
        message
      })
    }
  );

  if (!response.ok) {
    const error = await response.text();
    console.error("Messenger API error:", error);
    throw new Error(`Messenger API error: ${response.status}`);
  }
}

async function sendMessengerText(recipientId: string, text: string): Promise<void> {
  await sendMessengerMessage(recipientId, { text });
}

async function sendMessengerQuickReplies(
  recipientId: string,
  text: string,
  replies: { title: string; payload: string }[]
): Promise<void> {
  await sendMessengerMessage(recipientId, {
    text,
    quick_replies: replies.map(r => ({
      content_type: "text",
      title: r.title.substring(0, 20), // Max 20 chars
      payload: r.payload
    }))
  });
}

async function sendMessengerButtons(
  recipientId: string,
  text: string,
  buttons: { title: string; payload: string }[]
): Promise<void> {
  await sendMessengerMessage(recipientId, {
    attachment: {
      type: "template",
      payload: {
        template_type: "button",
        text: text.substring(0, 640), // Max 640 chars
        buttons: buttons.slice(0, 3).map(b => ({ // Max 3 buttons
          type: "postback",
          title: b.title.substring(0, 20),
          payload: b.payload
        }))
      }
    }
  });
}

// Verify Messenger webhook signature
function verifyMessengerSignature(rawBody: string, signature: string, appSecret: string): boolean {
  if (!signature || !signature.startsWith("sha256=")) {
    return false;
  }

  const expectedSignature = "sha256=" + crypto
    .createHmac("sha256", appSecret)
    .update(rawBody, "utf8")
    .digest("hex");

  try {
    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  } catch {
    return false;
  }
}

// Get user by Messenger PSID
async function getUserByMessengerPsid(psid: string) {
  const snapshot = await bexlyDb.collection("user_platform_links")
    .where("platform", "==", "messenger")
    .where("platformUserId", "==", psid)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  return snapshot.docs[0].data();
}

// Handle Messenger text message
async function handleMessengerMessage(senderPsid: string, messageText: string): Promise<void> {
  const startTime = Date.now();
  console.log(`Messenger message from ${senderPsid}: ${messageText}`);

  // Check if user is linked
  const user = await getUserByMessengerPsid(senderPsid);
  console.log(`User lookup took ${Date.now() - startTime}ms`);
  if (!user) {
    await sendMessengerButtons(
      senderPsid,
      "👋 Welcome to Bexly!\n\nI help you track expenses and income.\n\nPlease link your Bexly account first:",
      [{ title: "🔗 Link Account", payload: "LINK_ACCOUNT" }]
    );
    return;
  }

  // Fetch categories and wallet in PARALLEL for speed
  const fetchStart = Date.now();
  const [userCategories, walletsSnapshot] = await Promise.all([
    getUserCategories(user.bexlyUserId),
    bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("wallets")
      .collection("items")
      .limit(1)
      .get()
  ]);
  console.log(`Categories + Wallet fetch took ${Date.now() - fetchStart}ms (parallel)`);

  // Get wallet currency to pass to AI for currency confirmation logic
  let walletCurrency = "USD";
  if (!walletsSnapshot.empty) {
    walletCurrency = walletsSnapshot.docs[0].data().currency || "USD";
  }

  // Parse message with AI (includes wallet currency for confirmation rules)
  const aiStart = Date.now();
  const parsed = await parseTransactionWithAI(messageText, userCategories, walletCurrency);
  console.log(`AI parsing took ${Date.now() - aiStart}ms`);

  if (!parsed) {
    await sendMessengerQuickReplies(
      senderPsid,
      "🤔 I couldn't understand that.\n\nTry something like:\n• \"$50 for lunch\"\n• \"Received $500 salary\"",
      [
        { title: "💰 Add expense", payload: "HELP_EXPENSE" },
        { title: "💵 Add income", payload: "HELP_INCOME" },
        { title: "📊 View report", payload: "VIEW_REPORT" }
      ]
    );
    return;
  }

  // Get localization for user's language
  const loc = getLocalization(parsed.language);

  // Use wallet currency we already fetched, or parsed currency
  const displayCurrency = parsed.currency || walletCurrency;

  // Show confirmation
  const currencyForPayload = parsed.currency || "WALLET";
  const truncatedDesc = parsed.description.substring(0, 15);
  const confirmPayload = `CONFIRM_${parsed.type.toUpperCase()}_${parsed.amount}_${currencyForPayload}_${parsed.category}|${parsed.language}|${truncatedDesc}`;

  const emoji = parsed.type === "expense" ? "💸" : "💰";
  const catEmoji = getCategoryEmoji(parsed.category);
  const localizedCategory = getLocalizedCategoryName(parsed.category, parsed.language, userCategories);

  // Get localized type label
  const localizedTypeLabel = parsed.type === "expense" ? loc.expenseDetected : loc.incomeDetected;

  // Add localized confirm prompt
  const confirmPrompt = parsed.language === "vi" ? "Xác nhận?" :
                       parsed.language === "ja" ? "確認しますか?" :
                       parsed.language === "ko" ? "확인하시겠습니까?" :
                       parsed.language === "zh" ? "确认？" :
                       parsed.language === "th" ? "ยืนยัน?" :
                       parsed.language === "id" ? "Konfirmasi?" :
                       "Confirm?";

  await sendMessengerButtons(
    senderPsid,
    `${emoji} ${localizedTypeLabel}\n\n` +
    `💵 ${formatCurrency(parsed.amount, displayCurrency)}\n` +
    `${catEmoji} ${localizedCategory}\n` +
    `📝 ${parsed.description}\n\n${confirmPrompt}`,
    [
      { title: `✅ ${loc.confirm}`.substring(0, 20), payload: confirmPayload },
      { title: `❌ ${loc.cancel}`.substring(0, 20), payload: "CANCEL" }
    ]
  );
}

// Handle Messenger postback (button click)
async function handleMessengerPostback(senderPsid: string, payload: string): Promise<void> {
  console.log(`Messenger postback from ${senderPsid}: ${payload}`);

  if (payload === "CANCEL") {
    await sendMessengerText(senderPsid, "❌ Cancelled");
    return;
  }

  if (payload === "LINK_ACCOUNT") {
    // Generate login URL with PSID - same format as Telegram
    const loginUrl = `https://bexly-app.web.app/link-account.html?platform=messenger&id=${senderPsid}`;

    await sendMessengerMessage(senderPsid, {
      attachment: {
        type: "template",
        payload: {
          template_type: "button",
          text: "🔗 Click the button below to link your Bexly account:",
          buttons: [
            {
              type: "web_url",
              url: loginUrl,
              title: "🔐 Login & Link",
              webview_height_ratio: "tall"
            }
          ]
        }
      }
    });
    return;
  }

  if (payload === "HELP_EXPENSE") {
    await sendMessengerText(
      senderPsid,
      "💸 To log an expense, just type:\n\n" +
      "• \"$25 for lunch\"\n" +
      "• \"Paid $100 for electricity\"\n" +
      "• \"50k taxi\" (Vietnamese)\n\n" +
      "I'll auto-detect the category!"
    );
    return;
  }

  if (payload === "HELP_INCOME") {
    await sendMessengerText(
      senderPsid,
      "💰 To log income, just type:\n\n" +
      "• \"Received $500 salary\"\n" +
      "• \"Got $100 from freelance\"\n" +
      "• \"Lương 10tr\" (Vietnamese)\n\n" +
      "I'll auto-detect the source!"
    );
    return;
  }

  if (payload === "VIEW_REPORT") {
    const user = await getUserByMessengerPsid(senderPsid);
    if (!user) {
      await sendMessengerText(senderPsid, "❌ Please link your account first.");
      return;
    }

    // Get this week's transactions
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

    transactionsSnapshot.forEach(doc => {
      const tx = doc.data();
      if (tx.transactionType === 1) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    });

    await sendMessengerText(
      senderPsid,
      `📊 This Week's Summary\n\n` +
      `📈 Income: ${formatCurrency(totalIncome, defaultCurrency)}\n` +
      `📉 Expense: ${formatCurrency(totalExpense, defaultCurrency)}\n` +
      `💵 Net: ${formatCurrency(totalIncome - totalExpense, defaultCurrency)}`
    );
    return;
  }

  // Handle confirm transaction
  if (payload.startsWith("CONFIRM_")) {
    const user = await getUserByMessengerPsid(senderPsid);
    if (!user) {
      await sendMessengerText(senderPsid, "❌ Account not linked!");
      return;
    }

    // Parse payload: CONFIRM_EXPENSE_100_USD_Food & Drinks|en|lunch
    const parts = payload.split("_");
    const type = parts[1].toLowerCase() as "expense" | "income";
    const originalAmount = parseFloat(parts[2]);
    const inputCurrencyRaw = parts[3];
    const lastPart = parts.slice(4).join("_");
    const [category, language = "en", description = ""] = lastPart.split("|");

    // Get wallet
    let wallet: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    const settingsDoc = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("settings")
      .get();

    const defaultWalletCloudId = settingsDoc.exists ? settingsDoc.data()?.defaultWalletCloudId : null;

    if (defaultWalletCloudId) {
      const defaultWalletDoc = await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("wallets")
        .collection("items")
        .doc(defaultWalletCloudId)
        .get();

      if (defaultWalletDoc.exists) {
        wallet = defaultWalletDoc as unknown as FirebaseFirestore.QueryDocumentSnapshot;
      }
    }

    if (!wallet) {
      const walletsSnapshot = await bexlyDb
        .collection("users")
        .doc(user.bexlyUserId)
        .collection("data")
        .doc("wallets")
        .collection("items")
        .limit(1)
        .get();

      if (walletsSnapshot.empty) {
        const loc = getLocalization(language);
        await sendMessengerText(senderPsid, `❌ ${loc.noWallet}`);
        return;
      }
      wallet = walletsSnapshot.docs[0];
    }

    // Find category
    const categoriesSnapshot = await bexlyDb
      .collection("users")
      .doc(user.bexlyUserId)
      .collection("data")
      .doc("categories")
      .collection("items")
      .where("title", "==", category)
      .limit(1)
      .get();

    let categoryDoc = categoriesSnapshot.docs[0];
    if (!categoryDoc) {
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
      const loc = getLocalization(language);
      await sendMessengerText(senderPsid, `❌ ${loc.noCategory}`);
      return;
    }

    // Convert currency if needed
    const walletData = wallet.data();
    const walletCurrency = walletData.currency || "USD";
    const inputCurrency = inputCurrencyRaw === "WALLET" ? walletCurrency : inputCurrencyRaw;

    let finalAmount = originalAmount;
    let conversionNote = "";

    if (inputCurrency !== walletCurrency) {
      try {
        const { convertedAmount, rate } = await convertCurrency(originalAmount, inputCurrency, walletCurrency);
        finalAmount = convertedAmount;
        if (inputCurrency === "VND" && rate < 0.01) {
          const reverseRate = 1 / rate;
          conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)} @ 1 ${walletCurrency} = ${reverseRate.toFixed(0)} ${inputCurrency})`;
        } else {
          conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)})`;
        }
      } catch (convError) {
        console.error("Currency conversion failed:", convError);
        const loc = getLocalization(language);
        await sendMessengerText(
          senderPsid,
          `❌ ${loc.conversionFailed}\n${walletCurrency} ≠ ${inputCurrency}`
        );
        return;
      }
    }

    // Create transaction
    const transactionId = uuidv7();
    const transactionType = type === "income" ? 0 : 1;
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
        source: "messenger_bot"
      });

    // Update wallet balance
    const balanceChange = type === "expense" ? -finalAmount : finalAmount;
    await wallet.ref.update({
      balance: admin.firestore.FieldValue.increment(balanceChange)
    });

    // Send confirmation - same format as Telegram
    const loc = getLocalization(language);
    const localizedType = type === "expense" ? loc.expense : loc.income;

    // Get localized category title
    const categoryData = categoryDoc.data();
    let categoryTitle = categoryData?.title || category;
    if (categoryData?.localizedTitles) {
      try {
        const localizedTitles = typeof categoryData.localizedTitles === 'string'
          ? JSON.parse(categoryData.localizedTitles)
          : categoryData.localizedTitles;
        if (localizedTitles[language]) {
          categoryTitle = localizedTitles[language];
        }
      } catch (e) {
        // Use default title
      }
    }

    // Format time
    const now = new Date();
    const timeStr = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    const dateStr = now.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });

    // Build confirmation message (same format as Telegram)
    let confirmMsg: string;
    if (conversionNote) {
      confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}${conversionNote}\n` +
        `📂 ${categoryTitle}\n` +
        `💼 ${walletData.name}\n` +
        `🕐 ${timeStr} ${dateStr}`;
    } else {
      confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}\n` +
        `📂 ${categoryTitle}\n` +
        `💼 ${walletData.name}\n` +
        `🕐 ${timeStr} ${dateStr}`;
    }

    await sendMessengerQuickReplies(
      senderPsid,
      confirmMsg,
      [
        { title: `➕ ${loc.addMore}`, payload: "HELP_EXPENSE" },
        { title: `💰 ${loc.balance}`, payload: "VIEW_BALANCE" }
      ]
    );
  }
}

// Messenger webhook endpoint
export const messengerWebhook = onRequest(
  {
    secrets: [messengerPageToken, messengerAppSecret, messengerVerifyToken, geminiApiKey, openaiApiKey], // Add claudeApiKey when needed
    serviceAccount: "service@bexly-app.iam.gserviceaccount.com",
  },
  async (req, res) => {
    // Webhook verification (GET request from Facebook)
    if (req.method === "GET") {
      const mode = req.query["hub.mode"];
      const token = req.query["hub.verify_token"];
      const challenge = req.query["hub.challenge"];

      const verifyToken = messengerVerifyToken.value();

      console.log("Webhook verification attempt:", { mode, token, challenge, expectedToken: verifyToken?.substring(0, 10) + "..." });

      if (mode === "subscribe" && token === verifyToken) {
        console.log("Messenger webhook verified successfully");
        res.status(200).send(challenge);
      } else {
        console.error("Messenger webhook verification failed - token mismatch or wrong mode");
        res.sendStatus(403);
      }
      return;
    }

    // Message handling (POST request)
    if (req.method === "POST") {
      const body = req.body;
      const bodyString = JSON.stringify(body);
      console.log("Messenger POST received:", bodyString.substring(0, 500));

      // Verify signature
      const signature = req.headers["x-hub-signature-256"] as string;
      const appSecret = messengerAppSecret.value();

      if (signature && appSecret) {
        if (!verifyMessengerSignature(bodyString, signature, appSecret)) {
          console.error("Invalid Messenger signature - expected hash of body");
          // Don't block for now during development
          console.log("Continuing despite signature mismatch for debugging...");
        } else {
          console.log("Signature verified successfully");
        }
      }

      // Process events BEFORE responding (to avoid CPU throttling after response)
      if (body.object === "page") {
        for (const entry of body.entry || []) {
          for (const event of entry.messaging || []) {
            const senderPsid = event.sender?.id;
            if (!senderPsid) continue;

            // Simple in-memory dedup using message ID
            const messageId = event.message?.mid || event.postback?.mid;
            if (messageId && processedMessageIds.has(messageId)) {
              console.log(`Skipping duplicate message: ${messageId}`);
              continue;
            }
            if (messageId) {
              processedMessageIds.add(messageId);
              // Clean up old IDs after 5 minutes
              setTimeout(() => processedMessageIds.delete(messageId), 5 * 60 * 1000);
            }

            try {
              if (event.message?.text) {
                await handleMessengerMessage(senderPsid, event.message.text);
              } else if (event.postback?.payload) {
                await handleMessengerPostback(senderPsid, event.postback.payload);
              }
            } catch (error) {
              console.error("Error handling Messenger event:", error);
            }
          }
        }
      }

      // Respond to Facebook after processing
      res.status(200).send("EVENT_RECEIVED");
      return;
    }

    res.sendStatus(405);
  }
);

// Link Messenger account (called from Bexly app)
export const linkMessengerAccount = onCall(
  {
    secrets: [messengerPageToken],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { messengerPsid } = request.data;
    const bexlyUserId = request.auth.uid;
    const userEmail = request.auth.token.email || "Unknown";
    const userName = request.auth.token.name || userEmail.split("@")[0];

    // Check if messenger account is already linked
    const existing = await bexlyDb.collection("user_platform_links")
      .where("platform", "==", "messenger")
      .where("platformUserId", "==", messengerPsid)
      .get();

    if (!existing.empty) {
      throw new HttpsError("already-exists", "This Messenger account is already linked");
    }

    // Create link
    await bexlyDb.collection("user_platform_links").add({
      bexlyUserId,
      platform: "messenger",
      platformUserId: messengerPsid,
      linkedAt: admin.firestore.Timestamp.now(),
      lastActivity: admin.firestore.Timestamp.now()
    });

    // Get user's wallets for balance display
    let balanceText = "";
    try {
      const walletsSnapshot = await bexlyDb
        .collection("users")
        .doc(bexlyUserId)
        .collection("data")
        .doc("wallets")
        .collection("items")
        .get();

      if (!walletsSnapshot.empty) {
        balanceText = "\n💰 Your Wallets:\n";
        walletsSnapshot.forEach(doc => {
          const wallet = doc.data();
          balanceText += `• ${wallet.name}: ${formatCurrency(wallet.balance || 0, wallet.currency)}\n`;
        });
      }
    } catch (error) {
      console.error("Failed to fetch wallets:", error);
    }

    // Send welcome message to Messenger
    const pageToken = messengerPageToken.value();
    if (pageToken) {
      try {
        await sendMessengerText(
          messengerPsid,
          `✅ Account Linked Successfully!\n\n` +
          `👤 ${userName}\n` +
          `📧 ${userEmail}` +
          balanceText +
          `\nYou can now log transactions directly from Messenger!\n` +
          `Try: "50k coffee" or "Received 500k salary"`
        );
      } catch (error) {
        console.error("Failed to send Messenger welcome message:", error);
      }
    }

    return { success: true };
  }
);

// Unlink Messenger account
export const unlinkMessengerAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const bexlyUserId = request.auth.uid;

  const snapshot = await bexlyDb.collection("user_platform_links")
    .where("platform", "==", "messenger")
    .where("bexlyUserId", "==", bexlyUserId)
    .get();

  if (snapshot.empty) {
    throw new HttpsError("not-found", "No linked Messenger account found");
  }

  await snapshot.docs[0].ref.delete();

  return { success: true };
});
