// Force redeploy v2
import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import admin from "firebase-admin";
import { Bot, webhookCallback, InlineKeyboard } from "grammy";
// Using REST API directly instead of SDK for better control
// import { GoogleGenerativeAI } from "@google/generative-ai";
import { v7 as uuidv7 } from "uuid";
import * as crypto from "crypto";
import Stripe from "stripe";
// Define secrets
const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const openaiApiKey = defineSecret("OPENAI_API_KEY");
// const claudeApiKey = defineSecret("CLAUDE_API_KEY"); // Uncomment when CLAUDE_API_KEY secret is set
const messengerPageToken = defineSecret("MESSENGER_PAGE_TOKEN");
const messengerAppSecret = defineSecret("MESSENGER_APP_SECRET");
const messengerVerifyToken = defineSecret("MESSENGER_VERIFY_TOKEN");
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const AI_PROVIDER = "gemini";
const GEMINI_MODEL = "gemini-2.5-flash";
const OPENAI_MODEL = "gpt-4o-mini";
// const CLAUDE_MODEL = "claude-sonnet-4-20250514"; // Uncomment when Claude is enabled
// Set global options for all Gen 2 functions
setGlobalOptions({
    region: "asia-southeast1",
    minInstances: 1, // Keep warm for faster cold starts
});
// Initialize Firebase Admin
admin.initializeApp();
// Get reference to non-default database "bexly"
// Using Firestore constructor directly for named database
const bexlyDb = new admin.firestore.Firestore({
    projectId: "bexly-app",
    databaseId: "bexly",
});
// Get reference to US database for Financial Connections data (Stripe compliance)
const bexlyUsDb = new admin.firestore.Firestore({
    projectId: "bexly-app",
    databaseId: "bexly-us",
});
// Bot instance cache
let bot = null;
let lastToken = "";
// In-memory dedup for Messenger messages (survives within same instance)
const processedMessageIds = new Set();
const pendingTransactions = new Map();
// Track if bot commands have been set
let commandsSet = false;
function getBot() {
    const token = telegramBotToken.value();
    // Reinitialize if token changed or bot not initialized
    if (!bot || token !== lastToken) {
        if (!token) {
            throw new Error("Bot not initialized - missing token");
        }
        bot = new Bot(token);
        lastToken = token;
        setupBotHandlers(bot);
        // Set bot commands menu (only once)
        if (!commandsSet) {
            setBotCommands(bot).catch(err => console.error("Failed to set bot commands:", err));
            commandsSet = true;
        }
    }
    return bot;
}
// Set bot commands for Telegram menu
async function setBotCommands(bot) {
    const commands = [
        { command: "start", description: "Start the bot" },
        { command: "help", description: "Show help and examples" },
        { command: "balance", description: "Check your wallet balances" },
        { command: "today", description: "Today's transactions" },
        { command: "week", description: "This week's spending" },
        { command: "month", description: "This month's summary" },
        { command: "plan", description: "View your subscription plan" },
        { command: "model", description: "Change AI model (Plus+)" },
        { command: "language", description: "Change language" },
        { command: "link", description: "Link Bexly account" },
        { command: "unlink", description: "Unlink account" },
    ];
    await bot.api.setMyCommands(commands);
    console.log("Bot commands menu updated successfully");
}
const LOCALIZATIONS = {
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
function getLocalization(lang) {
    return LOCALIZATIONS[lang] || LOCALIZATIONS["en"];
}
// Fetch user's categories from Firestore
async function getUserCategories(bexlyUserId) {
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
        const categories = [];
        categoriesSnapshot.forEach(doc => {
            const data = doc.data();
            // Parse localizedTitles - it's stored as JSON string in Firestore
            let localizedTitles;
            if (data.localizedTitles) {
                try {
                    // localizedTitles might be a string (JSON) or already an object
                    if (typeof data.localizedTitles === 'string') {
                        localizedTitles = JSON.parse(data.localizedTitles);
                    }
                    else {
                        localizedTitles = data.localizedTitles;
                    }
                }
                catch (e) {
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
    }
    catch (error) {
        console.error("Error fetching user categories:", error);
        return [];
    }
}
// Build dynamic AI prompt with user's actual categories and wallet info
// CRITICAL: Only use user's ACTUAL categories from Firestore - NEVER use fallback/generic categories!
function buildDynamicPrompt(userCategories, walletCurrency) {
    // Log categories for debugging
    console.log(`buildDynamicPrompt - User has ${userCategories.length} categories:`);
    userCategories.forEach(c => console.log(`  - "${c.title}" (${c.transactionType})`));
    // Separate expense and income categories - use ALL user's categories (no limit)
    const expenseCategories = userCategories
        .filter(c => c.transactionType === "expense")
        .map(c => c.title);
    const incomeCategories = userCategories
        .filter(c => c.transactionType === "income")
        .map(c => c.title);
    // Build category list - ONLY from user's Firestore, NO fallback/generic categories!
    // If user has no categories, they need to sync app first
    const expenseCatList = expenseCategories.length > 0
        ? expenseCategories.join("|")
        : "Other"; // Minimal fallback - user should sync app
    const incomeCatList = incomeCategories.length > 0
        ? incomeCategories.join("|")
        : "Other Income"; // Minimal fallback
    console.log(`EXP categories for prompt: ${expenseCatList}`);
    console.log(`INC categories for prompt: ${incomeCatList}`);
    // Prompt with STRICT category matching - AI must use EXACT category names from list
    return `Parse→JSON.{"action":"create_expense"|"create_income"|"none","amount":num,"currency":"VND"|"USD"|null,"lang":"vi"|"en","desc":"str","cat":"EXACT_CATEGORY_NAME","time":"TIME_HINT"}
k=×1000,tr=×1000000→VND.$→USD.No symbol→null.

⚠️CRITICAL CATEGORY RULES:
1. EXPENSE categories: ${expenseCatList}
2. INCOME categories: ${incomeCatList}
3. cat MUST be EXACTLY one of the names above! Copy the name EXACTLY including case!
4. If no good match, use first expense category for expenses, first income category for income
5. NEVER use generic names like "Shopping", "Food" unless they're in the list above!
6. NEVER make up category names!

⏰TIME EXTRACTION (time field):
- "ăn sáng/breakfast/早餐"→"morning" (7:00)
- "ăn trưa/lunch/午餐"→"noon" (12:00)
- "ăn chiều/snack"→"afternoon" (15:00)
- "ăn tối/dinner/晚餐"→"evening" (19:00)
- "đêm qua/last night"→"yesterday_night"
- "hôm qua/yesterday"→"yesterday"
- "tuần trước/last week"→"last_week"
- "tháng trước/last month"→"last_month"
- "sáng nay/this morning"→"morning"
- "tối qua/yesterday evening"→"yesterday_evening"
- Explicit time "lúc 3h/at 3pm"→"15:00"
- No time hint→null

Examples:
"50k ăn sáng"→{"action":"create_expense","amount":50000,"currency":"VND","lang":"vi","desc":"ăn sáng","cat":"${expenseCategories[0] || 'Other'}","time":"morning"}
"lunch $20"→{"action":"create_expense","amount":20,"currency":"USD","lang":"en","desc":"lunch","cat":"${expenseCategories[0] || 'Other'}","time":"noon"}
"hôm qua mua sách 100k"→{"action":"create_expense","amount":100000,"currency":"VND","lang":"vi","desc":"mua sách","cat":"${expenseCategories[0] || 'Other'}","time":"yesterday"}
"50k cafe"→{"action":"create_expense","amount":50000,"currency":"VND","lang":"vi","desc":"cafe","cat":"${expenseCategories[0] || 'Other'}","time":null}
"hi"→{"action":"none","amount":0,"currency":null,"lang":"en","desc":"","cat":"","time":null}`;
}
// Parse transaction using Gemini AI
async function parseWithGemini(text, dynamicPrompt) {
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
    const data = await response.json();
    const result = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    const finishReason = data.candidates?.[0]?.finishReason;
    if (finishReason && finishReason !== "STOP") {
        console.warn("Gemini finish reason:", finishReason);
    }
    return result || null;
}
// Parse transaction using OpenAI
async function parseWithOpenAI(text, dynamicPrompt) {
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
    const data = await response.json();
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
async function parseTransactionWithAI(text, userCategories, walletCurrency) {
    try {
        let response = null;
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
            language: parsed.lang || parsed.language || "en",
            datetime: parsed.time || null // Time hint from AI
        };
    }
    catch (error) {
        console.error("AI parsing error:", error);
        // Fallback to regex parser if AI fails
        console.log("AI failed, falling back to regex parser");
        return parseTransactionFallback(text);
    }
}
// Convert time hint from AI to actual Date object
// Uses UTC+7 (Vietnam timezone) for calculation
// Handles late-night scenarios: if it's 2AM and user says "dinner", means yesterday's dinner
function resolveTimeHint(timeHint) {
    const now = new Date();
    if (!timeHint) {
        return now;
    }
    // Work with UTC+7 (Vietnam timezone) - add 7 hours to get local time
    const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
    const localNow = new Date(now.getTime() + VN_OFFSET_MS);
    const currentHourVN = localNow.getUTCHours(); // This is VN hour since we added offset
    // Create result date - start with today's date in VN timezone
    const result = new Date(Date.UTC(localNow.getUTCFullYear(), localNow.getUTCMonth(), localNow.getUTCDate(), 0, 0, 0, 0));
    // Map of time hints to their target hours (in VN time)
    const timeHintHours = {
        morning: 7,
        noon: 12,
        afternoon: 15,
        evening: 19,
        night: 21,
    };
    try {
        const hint = timeHint.toLowerCase();
        // Check if it's a yesterday_ prefix
        if (hint.startsWith("yesterday")) {
            result.setUTCDate(result.getUTCDate() - 1);
            const subHint = hint.replace("yesterday_", "").replace("yesterday", "noon");
            const targetHour = timeHintHours[subHint] || 12;
            result.setUTCHours(targetHour - 7, subHint === "morning" ? 30 : 0, 0, 0);
            return result;
        }
        // Check if it's a last_week or last_month
        if (hint === "last_week") {
            result.setUTCDate(result.getUTCDate() - 7);
            result.setUTCHours(12 - 7, 0, 0, 0);
            return result;
        }
        if (hint === "last_month") {
            result.setUTCMonth(result.getUTCMonth() - 1);
            result.setUTCHours(12 - 7, 0, 0, 0);
            return result;
        }
        // Handle regular time hints (morning, noon, etc.)
        const targetHour = timeHintHours[hint];
        if (targetHour !== undefined) {
            result.setUTCHours(targetHour - 7, hint === "morning" ? 30 : 0, 0, 0);
            // KEY FIX: If target time is in the future (e.g., it's 2AM and user says "dinner" at 19:00),
            // then they likely mean yesterday's dinner, not today's (which hasn't happened yet)
            // Only apply this logic for late-night hours (0-6 AM)
            if (currentHourVN < 6 && targetHour > currentHourVN) {
                result.setUTCDate(result.getUTCDate() - 1);
                console.log(`Late-night adjustment: ${hint} at ${currentHourVN}:00 VN → moved to yesterday`);
            }
            return result;
        }
        // Try to parse explicit time like "15:00"
        const timeMatch = hint.match(/^(\d{1,2}):?(\d{2})?$/);
        if (timeMatch) {
            const hours = parseInt(timeMatch[1], 10);
            const minutes = parseInt(timeMatch[2] || "0", 10);
            result.setUTCHours(hours - 7, minutes, 0, 0);
            // Apply same late-night logic for explicit times
            if (currentHourVN < 6 && hours > currentHourVN) {
                result.setUTCDate(result.getUTCDate() - 1);
                console.log(`Late-night adjustment: ${hours}:${minutes} at ${currentHourVN}:00 VN → moved to yesterday`);
            }
            return result;
        }
        // Can't parse, return current time
        return now;
    }
    catch (e) {
        console.error("Error resolving time hint:", e);
        return now;
    }
}
// Legacy regex parser as fallback
function parseTransactionFallback(text) {
    const lowerText = text.toLowerCase();
    // Detect transaction type
    const isExpense = /spent|paid|bought|chi|mua|trả|for\s+\w+/.test(lowerText);
    const isIncome = /received|earned|got|income|salary|nhận|lương|thu/.test(lowerText);
    const hasAmountForPattern = /\$[\d,.]+\s*(for|on)|[\d,.]+k?\s*(for|on)/i.test(text);
    if (!isExpense && !isIncome && !hasAmountForPattern)
        return null;
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
            }
            else if (/tr|triệu/.test(match[0])) {
                amount *= 1000000;
                currency = "VND";
            }
            else if (/vnd|đồng|đ/i.test(text)) {
                currency = "VND";
            }
            break;
        }
    }
    if (amount <= 0)
        return null;
    // Category detection
    const categoryMap = {
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
    // Simple time detection for fallback parser
    let datetime = null;
    if (/ăn sáng|breakfast|早餐|朝食/i.test(text))
        datetime = "morning";
    else if (/ăn trưa|lunch|午餐|昼食/i.test(text))
        datetime = "noon";
    else if (/ăn tối|dinner|晚餐|夕食/i.test(text))
        datetime = "evening";
    else if (/hôm qua|yesterday|昨天/i.test(text))
        datetime = "yesterday";
    return {
        type: transactionType,
        amount,
        currency: finalCurrency,
        category,
        description: description || category,
        responseText: "",
        language,
        datetime
    };
}
// Setup bot handlers
function setupBotHandlers(bot) {
    // /start command
    bot.command("start", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
        // Check if user is already linked
        const userLink = await bexlyDb.collection("user_platform_links")
            .where("platform", "==", "telegram")
            .where("platformUserId", "==", telegramId)
            .get();
        if (!userLink.empty) {
            await ctx.reply("👋 Welcome back to Bexly!\n\n" +
                "You can:\n" +
                "• Log expenses: \"Spent $50 on lunch\"\n" +
                "• Log income: \"Received $500 salary\"\n" +
                "• Check balance: /balance\n" +
                "• This week's spending: /week\n" +
                "• Help: /help");
        }
        else {
            const keyboard = new InlineKeyboard()
                .url("🔗 Link Bexly Account", `https://bexly-app.web.app/link?platform=telegram&id=${telegramId}`);
            await ctx.reply("👋 Welcome to Bexly Bot!\n\n" +
                "I help you track expenses and income directly from Telegram.\n\n" +
                "First, let's link your Bexly account:", { reply_markup: keyboard });
        }
    });
    // /link command - show link button
    bot.command("link", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
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
        await ctx.reply("🔗 *Link your Bexly Account*\n\n" +
            "Click the button below to sign in and connect your Telegram:", { parse_mode: "Markdown", reply_markup: keyboard });
    });
    // /unlink command
    bot.command("unlink", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
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
        await ctx.reply("📖 *Bexly Bot Help*\n\n" +
            "*Log Transactions:*\n" +
            "• \"Spent $50 on lunch\"\n" +
            "• \"Paid 100k for taxi\" (Vietnamese)\n" +
            "• \"Received $500 salary\"\n\n" +
            "*Commands:*\n" +
            "• /balance - Check your balance\n" +
            "• /today - Today's transactions\n" +
            "• /week - This week's spending\n" +
            "• /month - This month's summary\n" +
            "• /plan - View your subscription plan\n" +
            "• /model - Change AI model (Plus+)\n" +
            "• /language - Change language\n" +
            "• /link - Link Bexly account\n" +
            "• /unlink - Unlink account\n\n" +
            "*Tips:*\n" +
            "• Include amount and what it's for\n" +
            "• I'll auto-detect category\n" +
            "• Supports USD and VND", { parse_mode: "Markdown" });
    });
    // /model command - Change AI model based on subscription
    bot.command("model", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
        const user = await getUserByTelegramId(telegramId);
        if (!user) {
            await ctx.reply("❌ Please link your Bexly account first. Use /link");
            return;
        }
        // Get user subscription tier from Firestore
        const settingsDoc = await bexlyDb
            .collection("users")
            .doc(user.bexlyUserId)
            .collection("data")
            .doc("settings")
            .get();
        const settings = settingsDoc.data() || {};
        const subscription = settings.subscriptionTier || "free"; // free, plus, pro
        const currentModel = settings.aiModel || "auto";
        // Build keyboard based on subscription
        let keyboard;
        let message;
        if (subscription === "free") {
            // Free users can't choose - just show info
            await ctx.reply("🤖 *AI Model*\n\n" +
                "You're using *Standard* model (free).\n\n" +
                "Upgrade to *Plus* to choose between:\n" +
                "• Auto (Standard first, then Premium)\n" +
                "• Standard\n" +
                "• Premium\n\n" +
                "Upgrade to *Pro* for Flagship model access!", { parse_mode: "Markdown" });
            return;
        }
        if (subscription === "plus") {
            // Plus: Auto, Standard, Premium
            keyboard = new InlineKeyboard()
                .text(currentModel === "auto" ? "✅ Auto" : "Auto", "model_auto").row()
                .text(currentModel === "standard" ? "✅ Standard" : "Standard", "model_standard").row()
                .text(currentModel === "premium" ? "✅ Premium" : "Premium", "model_premium");
            message = "🤖 *Select AI Model*\n\n" +
                "*Auto*: Uses Standard first, switches to Premium when quota runs out\n" +
                "*Standard*: Free model (120/month)\n" +
                "*Premium*: Better accuracy (120/month)\n\n" +
                `Current: *${currentModel}*`;
        }
        else {
            // Pro: Auto, Standard, Premium, Flagship
            keyboard = new InlineKeyboard()
                .text(currentModel === "auto" ? "✅ Auto" : "Auto", "model_auto").row()
                .text(currentModel === "standard" ? "✅ Standard" : "Standard", "model_standard").row()
                .text(currentModel === "premium" ? "✅ Premium" : "Premium", "model_premium").row()
                .text(currentModel === "flagship" ? "✅ Flagship" : "Flagship", "model_flagship");
            message = "🤖 *Select AI Model*\n\n" +
                "*Auto*: Standard → Premium → Flagship based on quota\n" +
                "*Standard*: Free model (300/month)\n" +
                "*Premium*: Better accuracy (300/month)\n" +
                "*Flagship*: Best AI capabilities (100/month)\n\n" +
                `Current: *${currentModel}*`;
        }
        await ctx.reply(message, { parse_mode: "Markdown", reply_markup: keyboard });
    });
    // /plan command - Show subscription info and upgrade options
    bot.command("plan", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
        const user = await getUserByTelegramId(telegramId);
        if (!user) {
            await ctx.reply("❌ Please link your Bexly account first. Use /link");
            return;
        }
        // Get user subscription info from Firestore
        const settingsDoc = await bexlyDb
            .collection("users")
            .doc(user.bexlyUserId)
            .collection("data")
            .doc("settings")
            .get();
        const settings = settingsDoc.data() || {};
        const subscription = settings.subscriptionTier || "free"; // free, plus, pro
        // Get AI usage for this month
        const now = new Date();
        const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
        const usageDoc = await bexlyDb
            .collection("users")
            .doc(user.bexlyUserId)
            .collection("data")
            .doc("ai_usage")
            .get();
        const usageData = usageDoc.data() || {};
        const monthUsage = usageData[monthKey] || { standard: 0, premium: 0, flagship: 0 };
        let message = "";
        let keyboard;
        if (subscription === "free") {
            message = "📋 *Your Plan: Free*\n\n" +
                "*Features:*\n" +
                "• 3 wallets\n" +
                "• 2 budgets & 2 goals\n" +
                "• 5 recurring transactions\n" +
                "• 3 months analytics history\n" +
                "• Standard AI only\n\n" +
                `*AI Usage (this month):*\n` +
                `• Standard: ${monthUsage.standard || 0}/60\n\n` +
                "─────────────────\n" +
                "✨ *Upgrade to Plus ($2.99/mo)*\n" +
                "• Unlimited wallets, budgets & goals\n" +
                "• 6 months analytics history\n" +
                "• 120 Standard + 120 Premium AI/month\n" +
                "• No ads\n\n" +
                "🚀 *Upgrade to Pro ($5.99/mo)*\n" +
                "• Everything in Plus\n" +
                "• Unlimited analytics history\n" +
                "• 300 Standard + 300 Premium + 100 Flagship AI/month\n" +
                "• Priority support";
            keyboard = new InlineKeyboard()
                .url("⬆️ Upgrade in App", "https://bexly-app.web.app/upgrade");
        }
        else if (subscription === "plus") {
            message = "📋 *Your Plan: Plus*\n\n" +
                "*Features:*\n" +
                "• Unlimited wallets, budgets & goals\n" +
                "• 6 months analytics history\n" +
                "• Standard & Premium AI models\n" +
                "• No ads\n\n" +
                `*AI Usage (this month):*\n` +
                `• Standard: ${monthUsage.standard || 0}/120\n` +
                `• Premium: ${monthUsage.premium || 0}/120\n\n` +
                "─────────────────\n" +
                "🚀 *Upgrade to Pro ($5.99/mo)*\n" +
                "• Unlimited analytics history\n" +
                "• 300 Standard + 300 Premium + 100 Flagship AI/month\n" +
                "• Priority support";
            keyboard = new InlineKeyboard()
                .url("⬆️ Upgrade to Pro", "https://bexly-app.web.app/upgrade");
        }
        else {
            // Pro
            message = "📋 *Your Plan: Pro* 🚀\n\n" +
                "*Features:*\n" +
                "• Unlimited wallets, budgets & goals\n" +
                "• Unlimited analytics history\n" +
                "• All AI models (Standard, Premium, Flagship)\n" +
                "• Priority support\n" +
                "• No ads\n\n" +
                `*AI Usage (this month):*\n` +
                `• Standard: ${monthUsage.standard || 0}/300\n` +
                `• Premium: ${monthUsage.premium || 0}/300\n` +
                `• Flagship: ${monthUsage.flagship || 0}/100\n\n` +
                "Thank you for supporting Bexly! 💜";
        }
        await ctx.reply(message, { parse_mode: "Markdown", reply_markup: keyboard });
    });
    // /balance command
    bot.command("balance", async (ctx) => {
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
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
        if (!telegramId)
            return;
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
        const transactions = [];
        transactionsSnapshot.forEach(doc => {
            const tx = doc.data();
            // transactionType: 0 = income, 1 = expense
            if (tx.transactionType === 1) {
                totalExpense += tx.amount;
            }
            else {
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
        }
        else {
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
        if (!telegramId)
            return;
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
        const categoryTotals = {};
        transactionsSnapshot.forEach(doc => {
            const tx = doc.data();
            // transactionType: 0 = income, 1 = expense
            if (tx.transactionType === 1) {
                totalExpense += tx.amount;
                const category = tx.title || "Other";
                categoryTotals[category] = (categoryTotals[category] || 0) + tx.amount;
            }
            else {
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
        if (!telegramId)
            return;
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
        const categoryTotals = {};
        const dailyExpenses = {};
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
            }
            else {
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
        if (!telegramId)
            return;
        // Ignore commands
        if (text.startsWith("/"))
            return;
        // Check if user is linked
        const user = await getUserByTelegramId(telegramId);
        if (!user) {
            await ctx.reply("❌ Your account is not linked yet.\n" +
                "Use /start to link your Bexly account first.");
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
            await ctx.reply("🤔 I couldn't understand that.\n\n" +
                "Try something like:\n" +
                "• \"$50 for lunch\"\n" +
                "• \"ăn sáng 50k\"\n" +
                "• \"Received $500 salary\"\n\n" +
                "Or use /help for more examples.");
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
        const localizedCategory = getLocalizedCategoryName(parsed.category, parsed.language, userCategories);
        // Get localized type label
        const localizedTypeLabel = parsed.type === "expense" ? loc.expenseDetected : loc.incomeDetected;
        // Include language and description in callback data so we can use it after confirm
        // IMPORTANT: Telegram callback_data has 64-byte limit!
        // Store full data in memory cache, use short key in callback
        const pendingKey = `${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
        // Store pending transaction data in memory (will be cleared after 10 minutes)
        pendingTransactions.set(pendingKey, {
            type: parsed.type,
            amount: parsed.amount,
            currency: parsed.currency,
            category: parsed.category,
            language: parsed.language,
            description: parsed.description,
            timestamp: Date.now(),
            datetime: parsed.datetime, // Time hint from AI
        });
        // Clean up old pending transactions (older than 10 minutes)
        const tenMinutesAgo = Date.now() - 10 * 60 * 1000;
        for (const [key, value] of pendingTransactions.entries()) {
            if (value.timestamp < tenMinutesAgo) {
                pendingTransactions.delete(key);
            }
        }
        const keyboard = new InlineKeyboard()
            .text(`✅ ${loc.confirm}`, `c_${pendingKey}`)
            .text(`❌ ${loc.cancel}`, "x");
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
        await ctx.reply(`${responseMessage}\n\n${confirmPrompt}`, { parse_mode: "Markdown", reply_markup: keyboard });
    });
    // Handle callback queries (button clicks)
    bot.on("callback_query:data", async (ctx) => {
        const data = ctx.callbackQuery.data;
        const telegramId = ctx.from?.id.toString();
        if (!telegramId)
            return;
        // Handle noop callback (disabled buttons after confirm/cancel)
        if (data === "noop") {
            await ctx.answerCallbackQuery();
            return;
        }
        // Handle model selection callbacks
        if (data.startsWith("model_")) {
            const selectedModel = data.replace("model_", ""); // auto, standard, premium, flagship
            const user = await getUserByTelegramId(telegramId);
            if (!user) {
                await ctx.answerCallbackQuery({ text: "❌ Account not linked!" });
                return;
            }
            // Save to Firestore
            await bexlyDb
                .collection("users")
                .doc(user.bexlyUserId)
                .collection("data")
                .doc("settings")
                .set({ aiModel: selectedModel }, { merge: true });
            // Update message to show new selection
            const modelNames = {
                auto: "Auto",
                standard: "Standard",
                premium: "Premium",
                flagship: "Flagship",
            };
            await ctx.editMessageText(`✅ AI Model changed to *${modelNames[selectedModel] || selectedModel}*`, { parse_mode: "Markdown" });
            await ctx.answerCallbackQuery({ text: `✅ ${modelNames[selectedModel]}` });
            return;
        }
        if (data === "cancel" || data === "x") {
            // Get original message text and update with cancelled status
            const originalText = ctx.callbackQuery.message?.text || "";
            // Remove the confirm prompt line and add cancelled status
            const textWithoutPrompt = originalText.replace(/\n\n(Xác nhận\?|確認しますか\?|확인하시겠습니까\?|确认？|ยืนยัน\?|Konfirmasi\?|Confirm\?)$/, "");
            // Create disabled button showing cancelled status
            const cancelledKeyboard = new InlineKeyboard()
                .text("❌ Đã hủy", "noop");
            await ctx.editMessageText(`${textWithoutPrompt}`, { reply_markup: cancelledKeyboard });
            await ctx.answerCallbackQuery({ text: "❌ Đã hủy" });
            return;
        }
        if (data.startsWith("c_")) {
            // New format: c_{pendingKey} - lookup from in-memory cache
            const pendingKey = data.slice(2);
            const pending = pendingTransactions.get(pendingKey);
            if (!pending) {
                await ctx.answerCallbackQuery({ text: "❌ Session expired. Please try again." });
                return;
            }
            // Clean up used pending transaction
            pendingTransactions.delete(pendingKey);
            const type = pending.type;
            const originalAmount = pending.amount;
            const inputCurrencyRaw = pending.currency || "WALLET";
            const category = pending.category;
            const language = pending.language;
            const description = pending.description;
            const datetimeHint = pending.datetime;
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
            let wallet = null;
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
                    wallet = defaultWalletDoc;
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
            console.log(`=== CATEGORY LOOKUP DEBUG ===`);
            console.log(`Category from callback data: "${category}"`);
            console.log(`Transaction type: "${type}"`);
            // First, list ALL user categories for debugging
            const allCategoriesSnapshot = await bexlyDb
                .collection("users")
                .doc(user.bexlyUserId)
                .collection("data")
                .doc("categories")
                .collection("items")
                .get();
            console.log(`User has ${allCategoriesSnapshot.size} categories:`);
            allCategoriesSnapshot.docs.forEach(doc => {
                const cat = doc.data();
                console.log(`  - "${cat.title}" (${cat.transactionType})`);
            });
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
            if (categoryDoc) {
                console.log(`✅ Found exact match for category: "${category}"`);
            }
            else {
                console.log(`❌ No exact match for "${category}", trying fallback categories...`);
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
            // Log final selected category
            const finalCategoryData = categoryDoc.data();
            console.log(`=== FINAL CATEGORY SELECTED ===`);
            console.log(`Original requested: "${category}"`);
            console.log(`Final selected: "${finalCategoryData.title}" (cloudId: ${categoryDoc.id})`);
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
                    const { convertedAmount, rate } = await convertCurrency(originalAmount, inputCurrency, walletCurrency);
                    finalAmount = convertedAmount;
                    didConvert = true;
                    // Format conversion note nicely - show reverse rate for VND→USD
                    if (inputCurrency === "VND" && rate < 0.01) {
                        // Show as "1 USD = X VND" for better readability
                        const reverseRate = 1 / rate;
                        conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)} @ 1 ${walletCurrency} = ${reverseRate.toFixed(0)} ${inputCurrency})`;
                    }
                    else {
                        conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)})`;
                    }
                    console.log(`Converted: ${originalAmount} ${inputCurrency} = ${finalAmount} ${walletCurrency}`);
                }
                catch (convError) {
                    console.error("Currency conversion failed:", convError);
                    await ctx.editMessageText(`❌ Currency conversion failed.\n\n` +
                        `Your wallet uses ${walletCurrency}, but you entered ${inputCurrency}.\n` +
                        `Please try again or update your wallet currency in the app.`);
                    await ctx.answerCallbackQuery();
                    return;
                }
            }
            // Generate UUID v7 for document ID (same format as app)
            const transactionId = uuidv7();
            // Resolve datetime from AI hint (e.g., "morning" → 7:30 today, "yesterday" → noon yesterday)
            const transactionDate = resolveTimeHint(datetimeHint);
            const transactionTimestamp = admin.firestore.Timestamp.fromDate(transactionDate);
            console.log(`Datetime hint: "${datetimeHint}" → resolved to: ${transactionDate.toISOString()}`);
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
                date: transactionTimestamp,
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
                    }
                    else if (localizedTitles['en']) {
                        categoryTitle = localizedTitles['en'];
                    }
                }
                catch (e) {
                    console.warn('Failed to parse localizedTitles for confirmation message:', e);
                }
            }
            // Format message in user's language
            let loggedText;
            if (didConvert) {
                // With conversion: "✅ $3.22 chi tiêu (từ 100.000.000 đ) → My USD Wallet"
                // Fixed: "từ" now comes BEFORE the amount for proper Vietnamese grammar
                loggedText = `✅ *${formatCurrency(finalAmount, walletCurrency)}* ${localizedType} (${loc.from} ${formatCurrency(originalAmount, inputCurrency)}) → *${walletData.name}*\n📝 ${categoryTitle}`;
            }
            else {
                // Without conversion: "✅ ¥500 支出 → My Wallet | 飲食"
                loggedText = `✅ *${formatCurrency(finalAmount, walletCurrency)}* ${localizedType} → *${walletData.name}*\n📝 ${categoryTitle}`;
            }
            // Create confirmed button to keep the message box visible
            const confirmedKeyboard = new InlineKeyboard()
                .text("✅ Đã xác nhận", "noop");
            await ctx.editMessageText(loggedText, { parse_mode: "Markdown", reply_markup: confirmedKeyboard });
            await ctx.answerCallbackQuery({ text: "✅ Đã ghi nhận" });
        }
    });
}
// Helper functions
async function getUserByTelegramId(telegramId) {
    const snapshot = await bexlyDb.collection("user_platform_links")
        .where("platform", "==", "telegram")
        .where("platformUserId", "==", telegramId)
        .limit(1)
        .get();
    if (snapshot.empty)
        return null;
    return snapshot.docs[0].data();
}
function formatCurrency(amount, currency) {
    if (currency === "VND") {
        return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount);
    }
    return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(amount);
}
function getCategoryEmoji(category) {
    const emojis = {
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
function getLocalizedCategoryName(categoryTitle, language, userCategories) {
    // Find the category by English title (stored in 'title' field)
    const category = userCategories.find(c => c.title.toLowerCase() === categoryTitle.toLowerCase());
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
const FALLBACK_RATES = {
    "USD_VND": 25500,
    "VND_USD": 0.0000392,
    "USD_EUR": 0.92,
    "EUR_USD": 1.09,
};
// Get exchange rate from API
async function getExchangeRate(fromCurrency, toCurrency) {
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
        const data = await response.json();
        const rate = data.rates[toCurrency];
        if (!rate || rate <= 0) {
            throw new Error(`Rate not found for ${toCurrency}`);
        }
        console.log(`Exchange rate: 1 ${fromCurrency} = ${rate} ${toCurrency}`);
        return rate;
    }
    catch (error) {
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
async function convertCurrency(amount, fromCurrency, toCurrency) {
    if (fromCurrency === toCurrency) {
        return { convertedAmount: amount, rate: 1.0 };
    }
    const rate = await getExchangeRate(fromCurrency, toCurrency);
    const convertedAmount = amount * rate;
    return { convertedAmount, rate };
}
// Health check endpoint for AI service monitoring
// Used by Upptime to verify AI is responding
export const aiHealthCheck = onRequest({
    secrets: [geminiApiKey, openaiApiKey],
    timeoutSeconds: 30,
}, async (req, res) => {
    const startTime = Date.now();
    try {
        // Simple ping to AI
        const prompt = "Reply with exactly: OK";
        let response = null;
        let provider = AI_PROVIDER;
        if (provider === "gemini") {
            response = await parseWithGemini("ping", prompt);
        }
        else if (provider === "openai") {
            response = await parseWithOpenAI("ping", prompt);
        }
        const latency = Date.now() - startTime;
        if (response && response.toLowerCase().includes("ok")) {
            res.status(200).json({
                status: "healthy",
                provider: provider,
                latency: `${latency}ms`,
                timestamp: new Date().toISOString(),
            });
        }
        else {
            res.status(503).json({
                status: "unhealthy",
                provider: provider,
                error: "AI did not respond correctly",
                response: response,
                latency: `${latency}ms`,
                timestamp: new Date().toISOString(),
            });
        }
    }
    catch (error) {
        const latency = Date.now() - startTime;
        console.error("AI health check failed:", error);
        res.status(503).json({
            status: "unhealthy",
            error: error instanceof Error ? error.message : "Unknown error",
            latency: `${latency}ms`,
            timestamp: new Date().toISOString(),
        });
    }
});
// Telegram webhook endpoint (2nd gen)
export const telegramWebhook = onRequest({
    secrets: [telegramBotToken, geminiApiKey, openaiApiKey], // Add claudeApiKey when CLAUDE_API_KEY secret is set
    timeoutSeconds: 60, // Allow more time for AI processing
}, async (req, res) => {
    try {
        const bot = getBot();
        // Increase webhook timeout to 30s to avoid duplicate responses
        const handleUpdate = webhookCallback(bot, "express", { timeoutMilliseconds: 30000 });
        await handleUpdate(req, res);
    }
    catch (error) {
        console.error("Webhook error:", error);
        res.status(500).send("Error");
    }
});
// Admin endpoint to update bot commands menu
export const updateTelegramCommands = onRequest({
    secrets: [telegramBotToken],
}, async (req, res) => {
    try {
        const token = telegramBotToken.value();
        const commands = [
            { command: "start", description: "Start the bot" },
            { command: "help", description: "Show help and examples" },
            { command: "balance", description: "Check your wallet balances" },
            { command: "today", description: "Today's transactions" },
            { command: "week", description: "This week's spending" },
            { command: "month", description: "This month's summary" },
            { command: "plan", description: "View your subscription plan" },
            { command: "model", description: "Change AI model (Plus+)" },
            { command: "language", description: "Change language" },
            { command: "link", description: "Link Bexly account" },
            { command: "unlink", description: "Unlink account" },
        ];
        const response = await fetch(`https://api.telegram.org/bot${token}/setMyCommands`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ commands }),
        });
        const result = await response.json();
        console.log("setMyCommands result:", result);
        if (result.ok) {
            res.status(200).json({ success: true, message: "Bot commands updated successfully" });
        }
        else {
            res.status(400).json({ success: false, error: result.description });
        }
    }
    catch (error) {
        console.error("Error updating commands:", error);
        res.status(500).json({ success: false, error: String(error) });
    }
});
// Link account endpoint (called from Bexly app after OAuth) - 2nd gen
export const linkTelegramAccount = onCall({
    secrets: [telegramBotToken],
}, async (request) => {
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
    }
    else {
        walletsInfo = "  No wallets yet";
    }
    // Send welcome message to Telegram
    const botToken = telegramBotToken.value();
    const welcomeMessage = `✅ *Account Linked Successfully!*\n\n` +
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
    }
    catch (error) {
        console.error("Failed to send Telegram welcome message:", error);
    }
    return { success: true };
});
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
async function sendMessengerMessage(recipientId, message) {
    const pageToken = messengerPageToken.value();
    const response = await fetch(`https://graph.facebook.com/v22.0/me/messages?access_token=${pageToken}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            recipient: { id: recipientId },
            message
        })
    });
    if (!response.ok) {
        const error = await response.text();
        console.error("Messenger API error:", error);
        throw new Error(`Messenger API error: ${response.status}`);
    }
}
async function sendMessengerText(recipientId, text) {
    await sendMessengerMessage(recipientId, { text });
}
async function sendMessengerQuickReplies(recipientId, text, replies) {
    await sendMessengerMessage(recipientId, {
        text,
        quick_replies: replies.map(r => ({
            content_type: "text",
            title: r.title.substring(0, 20), // Max 20 chars
            payload: r.payload
        }))
    });
}
async function sendMessengerButtons(recipientId, text, buttons) {
    await sendMessengerMessage(recipientId, {
        attachment: {
            type: "template",
            payload: {
                template_type: "button",
                text: text.substring(0, 640), // Max 640 chars
                buttons: buttons.slice(0, 3).map(b => ({
                    type: "postback",
                    title: b.title.substring(0, 20),
                    payload: b.payload
                }))
            }
        }
    });
}
// Verify Messenger webhook signature
function verifyMessengerSignature(rawBody, signature, appSecret) {
    if (!signature || !signature.startsWith("sha256=")) {
        return false;
    }
    const expectedSignature = "sha256=" + crypto
        .createHmac("sha256", appSecret)
        .update(rawBody, "utf8")
        .digest("hex");
    try {
        return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
    }
    catch {
        return false;
    }
}
// Get user by Messenger PSID
async function getUserByMessengerPsid(psid) {
    const snapshot = await bexlyDb.collection("user_platform_links")
        .where("platform", "==", "messenger")
        .where("platformUserId", "==", psid)
        .limit(1)
        .get();
    if (snapshot.empty)
        return null;
    return snapshot.docs[0].data();
}
// Handle Messenger text message
async function handleMessengerMessage(senderPsid, messageText) {
    const startTime = Date.now();
    console.log(`Messenger message from ${senderPsid}: ${messageText}`);
    // Check if user is linked
    const user = await getUserByMessengerPsid(senderPsid);
    console.log(`User lookup took ${Date.now() - startTime}ms`);
    if (!user) {
        await sendMessengerButtons(senderPsid, "👋 Welcome to Bexly!\n\nI help you track expenses and income.\n\nPlease link your Bexly account first:", [{ title: "🔗 Link Account", payload: "LINK_ACCOUNT" }]);
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
        await sendMessengerQuickReplies(senderPsid, "🤔 I couldn't understand that.\n\nTry something like:\n• \"$50 for lunch\"\n• \"Received $500 salary\"", [
            { title: "💰 Add expense", payload: "HELP_EXPENSE" },
            { title: "💵 Add income", payload: "HELP_INCOME" },
            { title: "📊 View report", payload: "VIEW_REPORT" }
        ]);
        return;
    }
    // Get localization for user's language
    const loc = getLocalization(parsed.language);
    // Use wallet currency we already fetched, or parsed currency
    const displayCurrency = parsed.currency || walletCurrency;
    // Store pending transaction in memory (same approach as Telegram)
    // Use format: m_{senderPsid}_{timestamp} to avoid conflicts with Telegram
    const pendingKey = `m_${senderPsid}_${Date.now()}`;
    pendingTransactions.set(pendingKey, {
        type: parsed.type,
        amount: parsed.amount,
        currency: parsed.currency,
        category: parsed.category,
        language: parsed.language,
        description: parsed.description,
        timestamp: Date.now(),
        datetime: parsed.datetime || null,
    });
    // Clean up old pending transactions (older than 10 minutes)
    const tenMinutesAgo = Date.now() - 10 * 60 * 1000;
    for (const [key, value] of pendingTransactions.entries()) {
        if (value.timestamp < tenMinutesAgo) {
            pendingTransactions.delete(key);
        }
    }
    // Use short key for payload (Messenger has 1000 byte limit, but keep it short)
    const confirmPayload = `MC_${pendingKey}`;
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
    await sendMessengerButtons(senderPsid, `${emoji} ${localizedTypeLabel}\n\n` +
        `💵 ${formatCurrency(parsed.amount, displayCurrency)}\n` +
        `${catEmoji} ${localizedCategory}\n` +
        `📝 ${parsed.description}\n\n${confirmPrompt}`, [
        { title: `✅ ${loc.confirm}`.substring(0, 20), payload: confirmPayload },
        { title: `❌ ${loc.cancel}`.substring(0, 20), payload: "CANCEL" }
    ]);
}
// Handle Messenger postback (button click)
async function handleMessengerPostback(senderPsid, payload) {
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
        await sendMessengerText(senderPsid, "💸 To log an expense, just type:\n\n" +
            "• \"$25 for lunch\"\n" +
            "• \"Paid $100 for electricity\"\n" +
            "• \"50k taxi\" (Vietnamese)\n\n" +
            "I'll auto-detect the category!");
        return;
    }
    if (payload === "HELP_INCOME") {
        await sendMessengerText(senderPsid, "💰 To log income, just type:\n\n" +
            "• \"Received $500 salary\"\n" +
            "• \"Got $100 from freelance\"\n" +
            "• \"Lương 10tr\" (Vietnamese)\n\n" +
            "I'll auto-detect the source!");
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
            }
            else {
                totalIncome += tx.amount;
            }
        });
        await sendMessengerText(senderPsid, `📊 This Week's Summary\n\n` +
            `📈 Income: ${formatCurrency(totalIncome, defaultCurrency)}\n` +
            `📉 Expense: ${formatCurrency(totalExpense, defaultCurrency)}\n` +
            `💵 Net: ${formatCurrency(totalIncome - totalExpense, defaultCurrency)}`);
        return;
    }
    // Handle confirm transaction with new pending cache (MC_ prefix)
    if (payload.startsWith("MC_")) {
        const pendingKey = payload.slice(3); // Remove "MC_" prefix
        const pending = pendingTransactions.get(pendingKey);
        if (!pending) {
            await sendMessengerText(senderPsid, "❌ Session expired. Please try again.");
            return;
        }
        // Clean up used pending transaction
        pendingTransactions.delete(pendingKey);
        const user = await getUserByMessengerPsid(senderPsid);
        if (!user) {
            await sendMessengerText(senderPsid, "❌ Account not linked!");
            return;
        }
        const type = pending.type;
        const originalAmount = pending.amount;
        const inputCurrencyRaw = pending.currency || "WALLET";
        const category = pending.category;
        const language = pending.language;
        const description = pending.description;
        // Get wallet
        let wallet = null;
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
                wallet = defaultWalletDoc;
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
                }
                else {
                    conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)})`;
                }
            }
            catch (convError) {
                console.error("Currency conversion failed:", convError);
                const loc = getLocalization(language);
                await sendMessengerText(senderPsid, `❌ ${loc.conversionFailed}\n${walletCurrency} ≠ ${inputCurrency}`);
                return;
            }
        }
        // Resolve datetime from time hint (same as Telegram)
        const transactionDate = resolveTimeHint(pending.datetime);
        console.log(`Messenger transaction datetime: hint="${pending.datetime}" → ${transactionDate.toISOString()}`);
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
            date: admin.firestore.Timestamp.fromDate(transactionDate),
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
            }
            catch (e) {
                // Use default title
            }
        }
        // Format time from resolved date (UTC+7)
        const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
        const localDate = new Date(transactionDate.getTime() + VN_OFFSET_MS);
        const hours = localDate.getUTCHours().toString().padStart(2, '0');
        const minutes = localDate.getUTCMinutes().toString().padStart(2, '0');
        const day = localDate.getUTCDate().toString().padStart(2, '0');
        const month = (localDate.getUTCMonth() + 1).toString().padStart(2, '0');
        const timeStr = `${hours}:${minutes}`;
        const dateStr = `${day}/${month}`;
        // Build confirmation message (same format as Telegram)
        let confirmMsg;
        if (conversionNote) {
            confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}${conversionNote}\n` +
                `📂 ${categoryTitle}\n` +
                `💼 ${walletData.name}\n` +
                `🕐 ${timeStr} ${dateStr}`;
        }
        else {
            confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}\n` +
                `📂 ${categoryTitle}\n` +
                `💼 ${walletData.name}\n` +
                `🕐 ${timeStr} ${dateStr}`;
        }
        await sendMessengerQuickReplies(senderPsid, confirmMsg, [
            { title: `➕ ${loc.addMore}`, payload: "HELP_EXPENSE" },
            { title: `💰 ${loc.balance}`, payload: "VIEW_BALANCE" }
        ]);
        return;
    }
    // Handle confirm transaction (legacy format - keep for backwards compatibility)
    if (payload.startsWith("CONFIRM_")) {
        const user = await getUserByMessengerPsid(senderPsid);
        if (!user) {
            await sendMessengerText(senderPsid, "❌ Account not linked!");
            return;
        }
        // Parse payload: CONFIRM_EXPENSE_100_USD_Food & Drinks|en|lunch
        const parts = payload.split("_");
        const type = parts[1].toLowerCase();
        const originalAmount = parseFloat(parts[2]);
        const inputCurrencyRaw = parts[3];
        const lastPart = parts.slice(4).join("_");
        const [category, language = "en", description = ""] = lastPart.split("|");
        // Get wallet
        let wallet = null;
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
                wallet = defaultWalletDoc;
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
                }
                else {
                    conversionNote = ` (from ${formatCurrency(originalAmount, inputCurrency)})`;
                }
            }
            catch (convError) {
                console.error("Currency conversion failed:", convError);
                const loc = getLocalization(language);
                await sendMessengerText(senderPsid, `❌ ${loc.conversionFailed}\n${walletCurrency} ≠ ${inputCurrency}`);
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
            }
            catch (e) {
                // Use default title
            }
        }
        // Format time
        const now = new Date();
        const timeStr = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
        const dateStr = now.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });
        // Build confirmation message (same format as Telegram)
        let confirmMsg;
        if (conversionNote) {
            confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}${conversionNote}\n` +
                `📂 ${categoryTitle}\n` +
                `💼 ${walletData.name}\n` +
                `🕐 ${timeStr} ${dateStr}`;
        }
        else {
            confirmMsg = `✅ ${formatCurrency(finalAmount, walletCurrency)} ${localizedType}\n` +
                `📂 ${categoryTitle}\n` +
                `💼 ${walletData.name}\n` +
                `🕐 ${timeStr} ${dateStr}`;
        }
        await sendMessengerQuickReplies(senderPsid, confirmMsg, [
            { title: `➕ ${loc.addMore}`, payload: "HELP_EXPENSE" },
            { title: `💰 ${loc.balance}`, payload: "VIEW_BALANCE" }
        ]);
    }
}
// Messenger webhook endpoint
export const messengerWebhook = onRequest({
    secrets: [messengerPageToken, messengerAppSecret, messengerVerifyToken, geminiApiKey, openaiApiKey], // Add claudeApiKey when needed
    serviceAccount: "service@bexly-app.iam.gserviceaccount.com",
}, async (req, res) => {
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
        }
        else {
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
        const signature = req.headers["x-hub-signature-256"];
        const appSecret = messengerAppSecret.value();
        if (signature && appSecret) {
            if (!verifyMessengerSignature(bodyString, signature, appSecret)) {
                console.error("Invalid Messenger signature - expected hash of body");
                // Don't block for now during development
                console.log("Continuing despite signature mismatch for debugging...");
            }
            else {
                console.log("Signature verified successfully");
            }
        }
        // Process events BEFORE responding (to avoid CPU throttling after response)
        if (body.object === "page") {
            for (const entry of body.entry || []) {
                for (const event of entry.messaging || []) {
                    const senderPsid = event.sender?.id;
                    if (!senderPsid)
                        continue;
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
                        }
                        else if (event.postback?.payload) {
                            await handleMessengerPostback(senderPsid, event.postback.payload);
                        }
                    }
                    catch (error) {
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
});
// Link Messenger account (called from Bexly app)
export const linkMessengerAccount = onCall({
    secrets: [messengerPageToken],
}, async (request) => {
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
    }
    catch (error) {
        console.error("Failed to fetch wallets:", error);
    }
    // Send welcome message to Messenger
    const pageToken = messengerPageToken.value();
    if (pageToken) {
        try {
            await sendMessengerText(messengerPsid, `✅ Account Linked Successfully!\n\n` +
                `👤 ${userName}\n` +
                `📧 ${userEmail}` +
                balanceText +
                `\nYou can now log transactions directly from Messenger!\n` +
                `Try: "50k coffee" or "Received 500k salary"`);
        }
        catch (error) {
            console.error("Failed to send Messenger welcome message:", error);
        }
    }
    return { success: true };
});
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
// Default categories with multi-language support
// Matches app's category_repo.dart structure
const DEFAULT_CATEGORIES = [
    // ========== EXPENSE CATEGORIES ==========
    // Food & Drinks (1)
    { id: 1, title: "Food & Drinks", icon: "category-food-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Food & Drinks", vi: "Ăn uống", zh: "餐饮", fr: "Nourriture", th: "อาหารและเครื่องดื่ม", id: "Makanan & Minuman", es: "Comida", pt: "Alimentação", ja: "食費", ko: "식비", de: "Essen", hi: "खाना-पीना", ru: "Еда", ar: "طعام وشراب" } },
    { id: 101, title: "Groceries", icon: "category-food-2", iconType: "asset", transactionType: "expense", parentId: 1, localizedTitles: { en: "Groceries", vi: "Thực phẩm", zh: "杂货", fr: "Épicerie", th: "ของชำ", id: "Belanjaan", es: "Supermercado", pt: "Mercearia", ja: "食料品", ko: "식료품", de: "Lebensmittel", hi: "किराने का सामान", ru: "Продукты", ar: "بقالة" } },
    { id: 102, title: "Restaurants", icon: "category-food-3", iconType: "asset", transactionType: "expense", parentId: 1, localizedTitles: { en: "Restaurants", vi: "Nhà hàng", zh: "餐厅", fr: "Restaurants", th: "ร้านอาหาร", id: "Restoran", es: "Restaurantes", pt: "Restaurantes", ja: "レストラン", ko: "레스토랑", de: "Restaurants", hi: "रेस्तरां", ru: "Рестораны", ar: "مطاعم" } },
    { id: 103, title: "Coffee", icon: "category-food-4", iconType: "asset", transactionType: "expense", parentId: 1, localizedTitles: { en: "Coffee", vi: "Cà phê", zh: "咖啡", fr: "Café", th: "กาแฟ", id: "Kopi", es: "Café", pt: "Café", ja: "コーヒー", ko: "커피", de: "Kaffee", hi: "कॉफी", ru: "Кофе", ar: "قهوة" } },
    { id: 104, title: "Snacks", icon: "category-food-5", iconType: "asset", transactionType: "expense", parentId: 1, localizedTitles: { en: "Snacks", vi: "Ăn vặt", zh: "零食", fr: "Snacks", th: "ขนม", id: "Camilan", es: "Snacks", pt: "Lanches", ja: "お菓子", ko: "간식", de: "Snacks", hi: "नाश्ता", ru: "Закуски", ar: "وجبات خفيفة" } },
    { id: 105, title: "Takeout", icon: "category-food-6", iconType: "asset", transactionType: "expense", parentId: 1, localizedTitles: { en: "Takeout", vi: "Đồ ăn mang đi", zh: "外卖", fr: "À emporter", th: "อาหารสั่งกลับบ้าน", id: "Bawa pulang", es: "Para llevar", pt: "Delivery", ja: "テイクアウト", ko: "포장", de: "Zum Mitnehmen", hi: "पार्सल", ru: "Навынос", ar: "طعام جاهز" } },
    // Transportation (2)
    { id: 2, title: "Transportation", icon: "category-transportation-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Transportation", vi: "Di chuyển", zh: "交通", fr: "Transport", th: "การเดินทาง", id: "Transportasi", es: "Transporte", pt: "Transporte", ja: "交通費", ko: "교통비", de: "Transport", hi: "परिवहन", ru: "Транспорт", ar: "مواصلات" } },
    { id: 201, title: "Public Transport", icon: "category-transportation-2", iconType: "asset", transactionType: "expense", parentId: 2, localizedTitles: { en: "Public Transport", vi: "Xe buýt/Tàu", zh: "公共交通", fr: "Transport public", th: "ขนส่งสาธารณะ", id: "Transportasi Umum", es: "Transporte público", pt: "Transporte público", ja: "公共交通", ko: "대중교통", de: "ÖPNV", hi: "सार्वजनिक परिवहन", ru: "Общ. транспорт", ar: "مواصلات عامة" } },
    { id: 202, title: "Fuel/Gas", icon: "category-transportation-3", iconType: "asset", transactionType: "expense", parentId: 2, localizedTitles: { en: "Fuel/Gas", vi: "Xăng dầu", zh: "燃油", fr: "Carburant", th: "น้ำมัน", id: "Bahan Bakar", es: "Combustible", pt: "Combustível", ja: "燃料", ko: "연료", de: "Kraftstoff", hi: "ईंधन", ru: "Топливо", ar: "وقود" } },
    { id: 203, title: "Taxi & Rideshare", icon: "category-transportation-4", iconType: "asset", transactionType: "expense", parentId: 2, localizedTitles: { en: "Taxi & Rideshare", vi: "Taxi/Grab", zh: "出租车/网约车", fr: "Taxi/VTC", th: "แท็กซี่/Grab", id: "Taksi/Ojol", es: "Taxi/App", pt: "Táxi/App", ja: "タクシー", ko: "택시/카풀", de: "Taxi", hi: "टैक्सी", ru: "Такси", ar: "تاكسي" } },
    { id: 204, title: "Vehicle Maintenance", icon: "category-transportation-5", iconType: "asset", transactionType: "expense", parentId: 2, localizedTitles: { en: "Vehicle Maintenance", vi: "Bảo dưỡng xe", zh: "车辆保养", fr: "Entretien véhicule", th: "ซ่อมบำรุงรถ", id: "Perawatan Kendaraan", es: "Mantenimiento", pt: "Manutenção", ja: "車両整備", ko: "차량정비", de: "Wartung", hi: "वाहन रखरखाव", ru: "Ремонт авто", ar: "صيانة السيارة" } },
    { id: 205, title: "Parking", icon: "category-transportation-6", iconType: "asset", transactionType: "expense", parentId: 2, localizedTitles: { en: "Parking", vi: "Đậu xe", zh: "停车", fr: "Parking", th: "ที่จอดรถ", id: "Parkir", es: "Estacionamiento", pt: "Estacionamento", ja: "駐車場", ko: "주차", de: "Parken", hi: "पार्किंग", ru: "Парковка", ar: "مواقف" } },
    // Housing (3)
    { id: 3, title: "Housing", icon: "category-housing-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Housing", vi: "Nhà ở", zh: "住房", fr: "Logement", th: "ที่อยู่อาศัย", id: "Perumahan", es: "Vivienda", pt: "Moradia", ja: "住居", ko: "주거비", de: "Wohnen", hi: "आवास", ru: "Жильё", ar: "سكن" } },
    { id: 301, title: "Rent", icon: "category-housing-2", iconType: "asset", transactionType: "expense", parentId: 3, localizedTitles: { en: "Rent", vi: "Tiền thuê nhà", zh: "房租", fr: "Loyer", th: "ค่าเช่า", id: "Sewa", es: "Alquiler", pt: "Aluguel", ja: "家賃", ko: "월세", de: "Miete", hi: "किराया", ru: "Аренда", ar: "إيجار" } },
    { id: 302, title: "Mortgage", icon: "category-housing-3", iconType: "asset", transactionType: "expense", parentId: 3, localizedTitles: { en: "Mortgage", vi: "Trả góp nhà", zh: "房贷", fr: "Hypothèque", th: "ผ่อนบ้าน", id: "KPR", es: "Hipoteca", pt: "Financiamento", ja: "住宅ローン", ko: "주택담보대출", de: "Hypothek", hi: "गृह ऋण", ru: "Ипотека", ar: "قسط منزل" } },
    { id: 303, title: "Utilities", icon: "category-housing-4", iconType: "asset", transactionType: "expense", parentId: 3, localizedTitles: { en: "Utilities", vi: "Tiện ích", zh: "水电费", fr: "Services", th: "สาธารณูปโภค", id: "Utilitas", es: "Servicios", pt: "Utilidades", ja: "光熱費", ko: "공과금", de: "Nebenkosten", hi: "उपयोगिताएं", ru: "Коммунальные", ar: "مرافق" } },
    { id: 304, title: "Maintenance", icon: "category-housing-5", iconType: "asset", transactionType: "expense", parentId: 3, localizedTitles: { en: "Maintenance", vi: "Sửa chữa", zh: "维修", fr: "Entretien", th: "ซ่อมบำรุง", id: "Perbaikan", es: "Mantenimiento", pt: "Manutenção", ja: "メンテナンス", ko: "유지보수", de: "Instandhaltung", hi: "रखरखाव", ru: "Ремонт", ar: "صيانة" } },
    { id: 305, title: "Property Tax", icon: "category-housing-6", iconType: "asset", transactionType: "expense", parentId: 3, localizedTitles: { en: "Property Tax", vi: "Thuế nhà đất", zh: "房产税", fr: "Taxe foncière", th: "ภาษีที่ดิน", id: "Pajak Properti", es: "Impuesto", pt: "IPTU", ja: "固定資産税", ko: "재산세", de: "Grundsteuer", hi: "संपत्ति कर", ru: "Налог на недвижимость", ar: "ضريبة عقارية" } },
    // Entertainment (4)
    { id: 4, title: "Entertainment", icon: "category-entertainment-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Entertainment", vi: "Giải trí", zh: "娱乐", fr: "Divertissement", th: "บันเทิง", id: "Hiburan", es: "Entretenimiento", pt: "Entretenimento", ja: "娯楽", ko: "오락", de: "Unterhaltung", hi: "मनोरंजन", ru: "Развлечения", ar: "ترفيه" } },
    { id: 401, title: "Movies", icon: "category-entertainment-2", iconType: "asset", transactionType: "expense", parentId: 4, localizedTitles: { en: "Movies", vi: "Phim", zh: "电影", fr: "Cinéma", th: "ภาพยนตร์", id: "Film", es: "Cine", pt: "Cinema", ja: "映画", ko: "영화", de: "Kino", hi: "फिल्में", ru: "Кино", ar: "أفلام" } },
    { id: 402, title: "Streaming", icon: "category-entertainment-3", iconType: "asset", transactionType: "expense", parentId: 4, localizedTitles: { en: "Streaming", vi: "Streaming", zh: "流媒体", fr: "Streaming", th: "สตรีมมิ่ง", id: "Streaming", es: "Streaming", pt: "Streaming", ja: "配信サービス", ko: "스트리밍", de: "Streaming", hi: "स्ट्रीमिंग", ru: "Стриминг", ar: "بث" } },
    { id: 403, title: "Gaming", icon: "category-entertainment-4", iconType: "asset", transactionType: "expense", parentId: 4, localizedTitles: { en: "Gaming", vi: "Game", zh: "游戏", fr: "Jeux vidéo", th: "เกม", id: "Game", es: "Juegos", pt: "Jogos", ja: "ゲーム", ko: "게임", de: "Gaming", hi: "गेमिंग", ru: "Игры", ar: "ألعاب" } },
    { id: 404, title: "Events", icon: "category-entertainment-5", iconType: "asset", transactionType: "expense", parentId: 4, localizedTitles: { en: "Events", vi: "Sự kiện", zh: "活动", fr: "Événements", th: "กิจกรรม", id: "Acara", es: "Eventos", pt: "Eventos", ja: "イベント", ko: "이벤트", de: "Events", hi: "कार्यक्रम", ru: "Мероприятия", ar: "فعاليات" } },
    { id: 405, title: "Subscriptions", icon: "category-entertainment-6", iconType: "asset", transactionType: "expense", parentId: 4, localizedTitles: { en: "Subscriptions", vi: "Đăng ký", zh: "订阅", fr: "Abonnements", th: "สมาชิก", id: "Langganan", es: "Suscripciones", pt: "Assinaturas", ja: "サブスクリプション", ko: "구독", de: "Abos", hi: "सदस्यता", ru: "Подписки", ar: "اشتراكات" } },
    // Health (5)
    { id: 5, title: "Health", icon: "category-health-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Health", vi: "Sức khỏe", zh: "健康", fr: "Santé", th: "สุขภาพ", id: "Kesehatan", es: "Salud", pt: "Saúde", ja: "健康", ko: "건강", de: "Gesundheit", hi: "स्वास्थ्य", ru: "Здоровье", ar: "صحة" } },
    { id: 501, title: "Doctor Visits", icon: "category-health-2", iconType: "asset", transactionType: "expense", parentId: 5, localizedTitles: { en: "Doctor Visits", vi: "Khám bệnh", zh: "看医生", fr: "Médecin", th: "พบแพทย์", id: "Dokter", es: "Médico", pt: "Médico", ja: "通院", ko: "진료", de: "Arztbesuche", hi: "डॉक्टर", ru: "Врач", ar: "طبيب" } },
    { id: 502, title: "Pharmacy", icon: "category-health-3", iconType: "asset", transactionType: "expense", parentId: 5, localizedTitles: { en: "Pharmacy", vi: "Thuốc", zh: "药店", fr: "Pharmacie", th: "ร้านยา", id: "Apotek", es: "Farmacia", pt: "Farmácia", ja: "薬局", ko: "약국", de: "Apotheke", hi: "दवाखाना", ru: "Аптека", ar: "صيدلية" } },
    { id: 503, title: "Insurance", icon: "category-health-4", iconType: "asset", transactionType: "expense", parentId: 5, localizedTitles: { en: "Insurance", vi: "Bảo hiểm", zh: "保险", fr: "Assurance", th: "ประกัน", id: "Asuransi", es: "Seguro", pt: "Seguro", ja: "保険", ko: "보험", de: "Versicherung", hi: "बीमा", ru: "Страховка", ar: "تأمين" } },
    { id: 504, title: "Fitness", icon: "category-health-5", iconType: "asset", transactionType: "expense", parentId: 5, localizedTitles: { en: "Fitness", vi: "Thể dục", zh: "健身", fr: "Sport", th: "ฟิตเนส", id: "Fitness", es: "Gimnasio", pt: "Academia", ja: "フィットネス", ko: "피트니스", de: "Fitness", hi: "फिटनेस", ru: "Фитнес", ar: "لياقة" } },
    { id: 505, title: "Dental", icon: "category-health-5", iconType: "asset", transactionType: "expense", parentId: 5, localizedTitles: { en: "Dental", vi: "Nha khoa", zh: "牙科", fr: "Dentiste", th: "ทันตกรรม", id: "Gigi", es: "Dentista", pt: "Dentista", ja: "歯科", ko: "치과", de: "Zahnarzt", hi: "दंत चिकित्सा", ru: "Стоматология", ar: "أسنان" } },
    // Shopping (6)
    { id: 6, title: "Shopping", icon: "category-shopping-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Shopping", vi: "Mua sắm", zh: "购物", fr: "Shopping", th: "ช้อปปิ้ง", id: "Belanja", es: "Compras", pt: "Compras", ja: "ショッピング", ko: "쇼핑", de: "Einkaufen", hi: "खरीदारी", ru: "Покупки", ar: "تسوق" } },
    { id: 601, title: "Clothing", icon: "category-shopping-2", iconType: "asset", transactionType: "expense", parentId: 6, localizedTitles: { en: "Clothing", vi: "Quần áo", zh: "服装", fr: "Vêtements", th: "เสื้อผ้า", id: "Pakaian", es: "Ropa", pt: "Roupas", ja: "衣類", ko: "의류", de: "Kleidung", hi: "कपड़े", ru: "Одежда", ar: "ملابس" } },
    { id: 602, title: "Electronics", icon: "category-shopping-3", iconType: "asset", transactionType: "expense", parentId: 6, localizedTitles: { en: "Electronics", vi: "Điện tử", zh: "电子产品", fr: "Électronique", th: "อิเล็กทรอนิกส์", id: "Elektronik", es: "Electrónica", pt: "Eletrônicos", ja: "家電", ko: "전자기기", de: "Elektronik", hi: "इलेक्ट्रॉनिक्स", ru: "Электроника", ar: "إلكترونيات" } },
    { id: 603, title: "Shoes", icon: "category-shopping-4", iconType: "asset", transactionType: "expense", parentId: 6, localizedTitles: { en: "Shoes", vi: "Giày dép", zh: "鞋子", fr: "Chaussures", th: "รองเท้า", id: "Sepatu", es: "Zapatos", pt: "Calçados", ja: "靴", ko: "신발", de: "Schuhe", hi: "जूते", ru: "Обувь", ar: "أحذية" } },
    { id: 604, title: "Accessories", icon: "category-shopping-5", iconType: "asset", transactionType: "expense", parentId: 6, localizedTitles: { en: "Accessories", vi: "Phụ kiện", zh: "配件", fr: "Accessoires", th: "เครื่องประดับ", id: "Aksesoris", es: "Accesorios", pt: "Acessórios", ja: "アクセサリー", ko: "액세서리", de: "Accessoires", hi: "सहायक उपकरण", ru: "Аксессуары", ar: "إكسسوارات" } },
    { id: 605, title: "Online Shopping", icon: "category-shopping-6", iconType: "asset", transactionType: "expense", parentId: 6, localizedTitles: { en: "Online Shopping", vi: "Mua online", zh: "网购", fr: "Achats en ligne", th: "ช้อปออนไลน์", id: "Belanja Online", es: "Compras online", pt: "Compras online", ja: "オンラインショッピング", ko: "온라인쇼핑", de: "Online-Shopping", hi: "ऑनलाइन शॉपिंग", ru: "Онлайн-покупки", ar: "تسوق إلكتروني" } },
    // Education (7)
    { id: 7, title: "Education", icon: "category-education-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Education", vi: "Giáo dục", zh: "教育", fr: "Éducation", th: "การศึกษา", id: "Pendidikan", es: "Educación", pt: "Educação", ja: "教育", ko: "교육", de: "Bildung", hi: "शिक्षा", ru: "Образование", ar: "تعليم" } },
    { id: 701, title: "Tuition", icon: "category-education-2", iconType: "asset", transactionType: "expense", parentId: 7, localizedTitles: { en: "Tuition", vi: "Học phí", zh: "学费", fr: "Frais de scolarité", th: "ค่าเรียน", id: "Uang Sekolah", es: "Matrícula", pt: "Mensalidade", ja: "授業料", ko: "등록금", de: "Studiengebühren", hi: "ट्यूशन", ru: "Обучение", ar: "رسوم دراسية" } },
    { id: 702, title: "Books", icon: "category-education-3", iconType: "asset", transactionType: "expense", parentId: 7, localizedTitles: { en: "Books", vi: "Sách", zh: "书籍", fr: "Livres", th: "หนังสือ", id: "Buku", es: "Libros", pt: "Livros", ja: "書籍", ko: "책", de: "Bücher", hi: "किताबें", ru: "Книги", ar: "كتب" } },
    { id: 703, title: "Online Courses", icon: "category-education-4", iconType: "asset", transactionType: "expense", parentId: 7, localizedTitles: { en: "Online Courses", vi: "Khóa học online", zh: "在线课程", fr: "Cours en ligne", th: "คอร์สออนไลน์", id: "Kursus Online", es: "Cursos online", pt: "Cursos online", ja: "オンライン講座", ko: "온라인강좌", de: "Online-Kurse", hi: "ऑनलाइन कोर्स", ru: "Онлайн-курсы", ar: "دورات إلكترونية" } },
    { id: 704, title: "Workshops", icon: "category-education-5", iconType: "asset", transactionType: "expense", parentId: 7, localizedTitles: { en: "Workshops", vi: "Workshop", zh: "研讨会", fr: "Ateliers", th: "เวิร์คช็อป", id: "Pelatihan", es: "Talleres", pt: "Workshops", ja: "ワークショップ", ko: "워크숍", de: "Workshops", hi: "कार्यशाला", ru: "Семинары", ar: "ورش عمل" } },
    { id: 705, title: "School Supplies", icon: "category-education-6", iconType: "asset", transactionType: "expense", parentId: 7, localizedTitles: { en: "School Supplies", vi: "Dụng cụ học tập", zh: "学习用品", fr: "Fournitures", th: "อุปกรณ์การเรียน", id: "Alat Sekolah", es: "Material escolar", pt: "Material escolar", ja: "学用品", ko: "학용품", de: "Schulmaterial", hi: "स्कूल सामग्री", ru: "Канцтовары", ar: "مستلزمات مدرسية" } },
    // Travel (8)
    { id: 8, title: "Travel", icon: "category-travel-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Travel", vi: "Du lịch", zh: "旅行", fr: "Voyage", th: "ท่องเที่ยว", id: "Perjalanan", es: "Viajes", pt: "Viagem", ja: "旅行", ko: "여행", de: "Reisen", hi: "यात्रा", ru: "Путешествия", ar: "سفر" } },
    { id: 801, title: "Flights", icon: "category-travel-2", iconType: "asset", transactionType: "expense", parentId: 8, localizedTitles: { en: "Flights", vi: "Vé máy bay", zh: "机票", fr: "Vols", th: "ตั๋วเครื่องบิน", id: "Tiket Pesawat", es: "Vuelos", pt: "Passagens", ja: "航空券", ko: "항공권", de: "Flüge", hi: "उड़ान", ru: "Авиабилеты", ar: "طيران" } },
    { id: 802, title: "Hotels", icon: "category-travel-3", iconType: "asset", transactionType: "expense", parentId: 8, localizedTitles: { en: "Hotels", vi: "Khách sạn", zh: "酒店", fr: "Hôtels", th: "โรงแรม", id: "Hotel", es: "Hoteles", pt: "Hotéis", ja: "ホテル", ko: "호텔", de: "Hotels", hi: "होटल", ru: "Отели", ar: "فنادق" } },
    { id: 803, title: "Tours", icon: "category-travel-4", iconType: "asset", transactionType: "expense", parentId: 8, localizedTitles: { en: "Tours", vi: "Tour", zh: "旅游团", fr: "Excursions", th: "ทัวร์", id: "Tur", es: "Tours", pt: "Passeios", ja: "ツアー", ko: "투어", de: "Touren", hi: "टूर", ru: "Туры", ar: "جولات" } },
    { id: 804, title: "Transport", icon: "category-travel-5", iconType: "asset", transactionType: "expense", parentId: 8, localizedTitles: { en: "Transport", vi: "Phương tiện", zh: "交通", fr: "Transport", th: "การเดินทาง", id: "Transportasi", es: "Transporte", pt: "Transporte", ja: "交通", ko: "교통", de: "Transport", hi: "परिवहन", ru: "Транспорт", ar: "مواصلات" } },
    { id: 805, title: "Souvenirs", icon: "category-travel-6", iconType: "asset", transactionType: "expense", parentId: 8, localizedTitles: { en: "Souvenirs", vi: "Quà lưu niệm", zh: "纪念品", fr: "Souvenirs", th: "ของที่ระลึก", id: "Oleh-oleh", es: "Recuerdos", pt: "Lembranças", ja: "お土産", ko: "기념품", de: "Souvenirs", hi: "स्मृति चिन्ह", ru: "Сувениры", ar: "تذكارات" } },
    // Finance (9)
    { id: 9, title: "Finance", icon: "category-finance-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Finance", vi: "Tài chính", zh: "金融", fr: "Finance", th: "การเงิน", id: "Keuangan", es: "Finanzas", pt: "Finanças", ja: "金融", ko: "금융", de: "Finanzen", hi: "वित्त", ru: "Финансы", ar: "مالية" } },
    { id: 901, title: "Loan Payments", icon: "category-finance-2", iconType: "asset", transactionType: "expense", parentId: 9, localizedTitles: { en: "Loan Payments", vi: "Trả nợ", zh: "还贷", fr: "Remboursement", th: "ผ่อนชำระ", id: "Cicilan", es: "Préstamos", pt: "Empréstimos", ja: "ローン返済", ko: "대출상환", de: "Kreditzahlung", hi: "ऋण भुगतान", ru: "Платежи по кредиту", ar: "أقساط" } },
    { id: 902, title: "Savings", icon: "category-finance-3", iconType: "asset", transactionType: "expense", parentId: 9, localizedTitles: { en: "Savings", vi: "Tiết kiệm", zh: "储蓄", fr: "Épargne", th: "ออมเงิน", id: "Tabungan", es: "Ahorros", pt: "Poupança", ja: "貯金", ko: "저축", de: "Sparen", hi: "बचत", ru: "Сбережения", ar: "ادخار" } },
    { id: 903, title: "Investments", icon: "category-finance-4", iconType: "asset", transactionType: "expense", parentId: 9, localizedTitles: { en: "Investments", vi: "Đầu tư", zh: "投资", fr: "Investissements", th: "ลงทุน", id: "Investasi", es: "Inversiones", pt: "Investimentos", ja: "投資", ko: "투자", de: "Investitionen", hi: "निवेश", ru: "Инвестиции", ar: "استثمارات" } },
    { id: 904, title: "Credit Card", icon: "category-finance-5", iconType: "asset", transactionType: "expense", parentId: 9, localizedTitles: { en: "Credit Card", vi: "Thẻ tín dụng", zh: "信用卡", fr: "Carte de crédit", th: "บัตรเครดิต", id: "Kartu Kredit", es: "Tarjeta de crédito", pt: "Cartão de crédito", ja: "クレジットカード", ko: "신용카드", de: "Kreditkarte", hi: "क्रेडिट कार्ड", ru: "Кредитная карта", ar: "بطاقة ائتمان" } },
    { id: 905, title: "Bank Fees", icon: "category-finance-6", iconType: "asset", transactionType: "expense", parentId: 9, localizedTitles: { en: "Bank Fees", vi: "Phí ngân hàng", zh: "银行费用", fr: "Frais bancaires", th: "ค่าธรรมเนียม", id: "Biaya Bank", es: "Comisiones", pt: "Taxas bancárias", ja: "銀行手数料", ko: "은행수수료", de: "Bankgebühren", hi: "बैंक शुल्क", ru: "Комиссии банка", ar: "رسوم بنكية" } },
    // Utilities (10)
    { id: 10, title: "Utilities", icon: "category-utilities-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Utilities", vi: "Tiện ích", zh: "公用事业", fr: "Services publics", th: "สาธารณูปโภค", id: "Utilitas", es: "Servicios", pt: "Utilidades", ja: "光熱費", ko: "공과금", de: "Nebenkosten", hi: "उपयोगिताएं", ru: "Коммунальные услуги", ar: "خدمات" } },
    { id: 1001, title: "Electricity", icon: "category-utilities-2", iconType: "asset", transactionType: "expense", parentId: 10, localizedTitles: { en: "Electricity", vi: "Điện", zh: "电费", fr: "Électricité", th: "ค่าไฟ", id: "Listrik", es: "Electricidad", pt: "Eletricidade", ja: "電気代", ko: "전기", de: "Strom", hi: "बिजली", ru: "Электричество", ar: "كهرباء" } },
    { id: 1002, title: "Water", icon: "category-utilities-3", iconType: "asset", transactionType: "expense", parentId: 10, localizedTitles: { en: "Water", vi: "Nước", zh: "水费", fr: "Eau", th: "ค่าน้ำ", id: "Air", es: "Agua", pt: "Água", ja: "水道代", ko: "수도", de: "Wasser", hi: "पानी", ru: "Вода", ar: "مياه" } },
    { id: 1003, title: "Gas", icon: "category-utilities-4", iconType: "asset", transactionType: "expense", parentId: 10, localizedTitles: { en: "Gas", vi: "Gas", zh: "燃气费", fr: "Gaz", th: "ค่าแก๊ส", id: "Gas", es: "Gas", pt: "Gás", ja: "ガス代", ko: "가스", de: "Gas", hi: "गैस", ru: "Газ", ar: "غاز" } },
    { id: 1004, title: "Internet", icon: "category-utilities-5", iconType: "asset", transactionType: "expense", parentId: 10, localizedTitles: { en: "Internet", vi: "Internet", zh: "网费", fr: "Internet", th: "อินเทอร์เน็ต", id: "Internet", es: "Internet", pt: "Internet", ja: "インターネット", ko: "인터넷", de: "Internet", hi: "इंटरनेट", ru: "Интернет", ar: "إنترنت" } },
    { id: 1005, title: "Phone", icon: "category-utilities-6", iconType: "asset", transactionType: "expense", parentId: 10, localizedTitles: { en: "Phone", vi: "Điện thoại", zh: "电话费", fr: "Téléphone", th: "โทรศัพท์", id: "Telepon", es: "Teléfono", pt: "Telefone", ja: "電話代", ko: "전화", de: "Telefon", hi: "फोन", ru: "Телефон", ar: "هاتف" } },
    // Other Expense (14)
    { id: 14, title: "Other", icon: "category-finance-1", iconType: "asset", transactionType: "expense", localizedTitles: { en: "Other", vi: "Khác", zh: "其他", fr: "Autre", th: "อื่นๆ", id: "Lainnya", es: "Otro", pt: "Outro", ja: "その他", ko: "기타", de: "Sonstiges", hi: "अन्य", ru: "Другое", ar: "أخرى" } },
    // ========== INCOME CATEGORIES ==========
    // Work & Business (11)
    { id: 11, title: "Work & Business", icon: "category-finance-1", iconType: "asset", transactionType: "income", localizedTitles: { en: "Work & Business", vi: "Công việc", zh: "工作收入", fr: "Travail", th: "งาน", id: "Pekerjaan", es: "Trabajo", pt: "Trabalho", ja: "仕事", ko: "근로소득", de: "Arbeit", hi: "कार्य", ru: "Работа", ar: "عمل" } },
    { id: 1101, title: "Salary", icon: "category-finance-2", iconType: "asset", transactionType: "income", parentId: 11, localizedTitles: { en: "Salary", vi: "Lương", zh: "工资", fr: "Salaire", th: "เงินเดือน", id: "Gaji", es: "Salario", pt: "Salário", ja: "給料", ko: "급여", de: "Gehalt", hi: "वेतन", ru: "Зарплата", ar: "راتب" } },
    { id: 1102, title: "Bonus", icon: "category-finance-3", iconType: "asset", transactionType: "income", parentId: 11, localizedTitles: { en: "Bonus", vi: "Thưởng", zh: "奖金", fr: "Prime", th: "โบนัส", id: "Bonus", es: "Bonificación", pt: "Bônus", ja: "ボーナス", ko: "보너스", de: "Bonus", hi: "बोनस", ru: "Премия", ar: "مكافأة" } },
    { id: 1103, title: "Freelance", icon: "category-finance-4", iconType: "asset", transactionType: "income", parentId: 11, localizedTitles: { en: "Freelance", vi: "Làm thêm", zh: "自由职业", fr: "Freelance", th: "ฟรีแลนซ์", id: "Freelance", es: "Freelance", pt: "Freelance", ja: "フリーランス", ko: "프리랜서", de: "Freelance", hi: "फ्रीलांस", ru: "Фриланс", ar: "عمل حر" } },
    { id: 1104, title: "Business Income", icon: "category-finance-5", iconType: "asset", transactionType: "income", parentId: 11, localizedTitles: { en: "Business Income", vi: "Kinh doanh", zh: "经营收入", fr: "Revenus d'entreprise", th: "รายได้ธุรกิจ", id: "Pendapatan Usaha", es: "Ingresos negocio", pt: "Renda empresarial", ja: "事業収入", ko: "사업소득", de: "Geschäftseinnahmen", hi: "व्यापार आय", ru: "Доход от бизнеса", ar: "دخل تجاري" } },
    // Investments (12)
    { id: 12, title: "Investments", icon: "category-finance-1", iconType: "asset", transactionType: "income", localizedTitles: { en: "Investments", vi: "Đầu tư", zh: "投资收益", fr: "Investissements", th: "การลงทุน", id: "Investasi", es: "Inversiones", pt: "Investimentos", ja: "投資", ko: "투자수익", de: "Investitionen", hi: "निवेश", ru: "Инвестиции", ar: "استثمارات" } },
    { id: 1201, title: "Dividends", icon: "category-finance-2", iconType: "asset", transactionType: "income", parentId: 12, localizedTitles: { en: "Dividends", vi: "Cổ tức", zh: "股息", fr: "Dividendes", th: "เงินปันผล", id: "Dividen", es: "Dividendos", pt: "Dividendos", ja: "配当金", ko: "배당금", de: "Dividenden", hi: "लाभांश", ru: "Дивиденды", ar: "أرباح أسهم" } },
    { id: 1202, title: "Interest", icon: "category-finance-3", iconType: "asset", transactionType: "income", parentId: 12, localizedTitles: { en: "Interest", vi: "Lãi suất", zh: "利息", fr: "Intérêts", th: "ดอกเบี้ย", id: "Bunga", es: "Intereses", pt: "Juros", ja: "利息", ko: "이자", de: "Zinsen", hi: "ब्याज", ru: "Проценты", ar: "فوائد" } },
    { id: 1203, title: "Capital Gains", icon: "category-finance-4", iconType: "asset", transactionType: "income", parentId: 12, localizedTitles: { en: "Capital Gains", vi: "Lợi nhuận", zh: "资本收益", fr: "Plus-values", th: "กำไรจากการลงทุน", id: "Keuntungan Modal", es: "Ganancias", pt: "Ganhos de capital", ja: "キャピタルゲイン", ko: "자본이득", de: "Kapitalgewinne", hi: "पूंजीगत लाभ", ru: "Прирост капитала", ar: "أرباح رأسمالية" } },
    { id: 1204, title: "Rental Income", icon: "category-finance-5", iconType: "asset", transactionType: "income", parentId: 12, localizedTitles: { en: "Rental Income", vi: "Cho thuê", zh: "租金收入", fr: "Revenus locatifs", th: "รายได้ค่าเช่า", id: "Sewa", es: "Alquiler", pt: "Aluguel", ja: "賃貸収入", ko: "임대수입", de: "Mieteinnahmen", hi: "किराया आय", ru: "Аренда", ar: "إيجار" } },
    // Other Income (13)
    { id: 13, title: "Other Income", icon: "category-finance-1", iconType: "asset", transactionType: "income", localizedTitles: { en: "Other Income", vi: "Thu nhập khác", zh: "其他收入", fr: "Autres revenus", th: "รายได้อื่นๆ", id: "Pendapatan Lain", es: "Otros ingresos", pt: "Outras receitas", ja: "その他の収入", ko: "기타수입", de: "Sonstige Einnahmen", hi: "अन्य आय", ru: "Прочие доходы", ar: "دخل آخر" } },
    { id: 1301, title: "Gifts Received", icon: "category-finance-2", iconType: "asset", transactionType: "income", parentId: 13, localizedTitles: { en: "Gifts Received", vi: "Quà tặng", zh: "收到的礼物", fr: "Cadeaux reçus", th: "ของขวัญที่ได้รับ", id: "Hadiah", es: "Regalos", pt: "Presentes", ja: "贈り物", ko: "선물", de: "Geschenke", hi: "उपहार", ru: "Подарки", ar: "هدايا" } },
    { id: 1302, title: "Refunds", icon: "category-finance-3", iconType: "asset", transactionType: "income", parentId: 13, localizedTitles: { en: "Refunds", vi: "Hoàn tiền", zh: "退款", fr: "Remboursements", th: "เงินคืน", id: "Pengembalian", es: "Reembolsos", pt: "Reembolsos", ja: "払い戻し", ko: "환불", de: "Rückerstattungen", hi: "रिफंड", ru: "Возвраты", ar: "استرداد" } },
    { id: 1303, title: "Cashback", icon: "category-finance-4", iconType: "asset", transactionType: "income", parentId: 13, localizedTitles: { en: "Cashback", vi: "Cashback", zh: "返现", fr: "Cashback", th: "เงินคืน", id: "Cashback", es: "Cashback", pt: "Cashback", ja: "キャッシュバック", ko: "캐시백", de: "Cashback", hi: "कैशबैक", ru: "Кэшбэк", ar: "استرداد نقدي" } },
    { id: 1304, title: "Tax Refund", icon: "category-finance-5", iconType: "asset", transactionType: "income", parentId: 13, localizedTitles: { en: "Tax Refund", vi: "Hoàn thuế", zh: "退税", fr: "Remboursement d'impôts", th: "คืนภาษี", id: "Pengembalian Pajak", es: "Devolución de impuestos", pt: "Restituição de impostos", ja: "税金還付", ko: "세금환급", de: "Steuerrückerstattung", hi: "कर वापसी", ru: "Возврат налога", ar: "استرداد ضريبي" } },
    { id: 1305, title: "Other", icon: "category-finance-6", iconType: "asset", transactionType: "income", parentId: 13, localizedTitles: { en: "Other", vi: "Khác", zh: "其他", fr: "Autre", th: "อื่นๆ", id: "Lainnya", es: "Otro", pt: "Outro", ja: "その他", ko: "기타", de: "Sonstiges", hi: "अन्य", ru: "Другое", ar: "أخرى" } },
];
// ============================================================================
// BEFORE USER CREATED - Create default categories for new users (Gen 2 Blocking Function)
// ============================================================================
/**
 * Firebase Auth blocking trigger - runs BEFORE a new user is saved
 * Creates default categories in Firestore for users who register via bot/web
 * (Users who register via app will have categories synced from app)
 *
 * Requires: Firebase Auth upgraded to Identity Platform (one-click in Firebase Console)
 * Timeout: Must complete within 7 seconds
 */
export const onUserCreated = beforeUserCreated(async (event) => {
    const user = event.data;
    if (!user) {
        console.error("No user data in event");
        return; // Allow user creation to proceed
    }
    console.log(`New user being created: ${user.uid} (${user.email || "no email"})`);
    try {
        // Check if user already has categories (created by app sync)
        const existingCategories = await bexlyDb
            .collection(`users/${user.uid}/data/categories/items`)
            .limit(1)
            .get();
        if (!existingCategories.empty) {
            console.log(`User ${user.uid} already has categories, skipping...`);
            return; // Allow user creation to proceed
        }
        // Create default categories for new user
        console.log(`Creating ${DEFAULT_CATEGORIES.length} default categories for user ${user.uid}...`);
        const batch = bexlyDb.batch();
        const now = admin.firestore.Timestamp.now();
        for (const cat of DEFAULT_CATEGORIES) {
            // Use deterministic cloudId based on category id for dedup
            const cloudId = `default_cat_${cat.id}`;
            const ref = bexlyDb.collection(`users/${user.uid}/data/categories/items`).doc(cloudId);
            batch.set(ref, {
                localId: cat.id,
                title: cat.title,
                icon: cat.icon,
                iconBackground: "",
                iconType: cat.iconType,
                transactionType: cat.transactionType,
                parentId: cat.parentId || null,
                localizedTitles: cat.localizedTitles,
                isSystemDefault: true,
                createdAt: now,
                updatedAt: now,
            });
        }
        await batch.commit();
        console.log(`Successfully created ${DEFAULT_CATEGORIES.length} categories for user ${user.uid}`);
    }
    catch (error) {
        console.error(`Failed to create categories for user ${user.uid}:`, error);
        // Don't throw - we don't want to block user creation
    }
    // Return nothing to allow user creation to proceed
});
// ============================================================================
// STRIPE FINANCIAL CONNECTIONS
// ============================================================================
// Stripe instance cache
let stripeInstance = null;
let lastStripeKey = "";
function getStripe() {
    const key = stripeSecretKey.value();
    if (!key) {
        throw new Error("Stripe secret key not configured");
    }
    if (!stripeInstance || key !== lastStripeKey) {
        stripeInstance = new Stripe(key);
        lastStripeKey = key;
    }
    return stripeInstance;
}
/**
 * Create a Financial Connections session for linking bank accounts
 * This allows users to connect their bank accounts for transaction import
 */
export const createFinancialConnectionSession = onCall({
    secrets: [stripeSecretKey],
    region: "us-central1", // US region for Financial Connections compliance
}, async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = request.auth.uid;
    const { returnUrl } = request.data;
    console.log(`Creating Financial Connection session for user ${userId}`);
    try {
        const stripe = getStripe();
        // Check if user already has a Stripe customer ID
        const userDoc = await bexlyDb.collection("users").doc(userId).get();
        const userData = userDoc.data();
        let customerId = userData?.stripeCustomerId;
        // Create Stripe customer if not exists
        if (!customerId) {
            const customer = await stripe.customers.create({
                metadata: {
                    firebaseUserId: userId,
                },
            });
            customerId = customer.id;
            // Save customer ID to user document
            await bexlyDb.collection("users").doc(userId).update({
                stripeCustomerId: customerId,
            });
            console.log(`Created Stripe customer ${customerId} for user ${userId}`);
        }
        // Create Financial Connections session
        const session = await stripe.financialConnections.sessions.create({
            account_holder: {
                type: "customer",
                customer: customerId,
            },
            permissions: ["balances", "transactions", "ownership"],
            filters: {
                countries: ["US"],
            },
            return_url: returnUrl || "bexly://financial-connections/callback",
        });
        console.log(`Created Financial Connection session ${session.id} for user ${userId}`);
        return {
            clientSecret: session.client_secret,
            sessionId: session.id,
        };
    }
    catch (error) {
        console.error(`Failed to create Financial Connection session for user ${userId}:`, error);
        if (error instanceof Stripe.errors.StripeError) {
            throw new HttpsError("internal", `Stripe error: ${error.message}`);
        }
        throw new HttpsError("internal", "Failed to create Financial Connection session");
    }
});
/**
 * Complete Financial Connection and fetch linked accounts
 * Called after user completes the Financial Connections flow
 */
export const completeFinancialConnection = onCall({
    secrets: [stripeSecretKey],
    region: "us-central1",
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = request.auth.uid;
    const { sessionId } = request.data;
    if (!sessionId) {
        throw new HttpsError("invalid-argument", "Session ID is required");
    }
    console.log(`Completing Financial Connection session ${sessionId} for user ${userId}`);
    try {
        const stripe = getStripe();
        // Retrieve the session to get linked accounts
        const session = await stripe.financialConnections.sessions.retrieve(sessionId);
        if (!session.accounts || session.accounts.data.length === 0) {
            throw new HttpsError("failed-precondition", "No accounts were linked");
        }
        const accounts = session.accounts.data;
        console.log(`User ${userId} linked ${accounts.length} accounts`);
        // Store linked accounts in bexly-us database
        const batch = bexlyUsDb.batch();
        const now = admin.firestore.Timestamp.now();
        for (const account of accounts) {
            const accountRef = bexlyUsDb
                .collection(`stripe_connections/${userId}/accounts`)
                .doc(account.id);
            batch.set(accountRef, {
                accountId: account.id,
                institutionName: account.institution_name,
                displayName: account.display_name,
                last4: account.last4,
                category: account.category, // checking, savings, etc.
                subcategory: account.subcategory,
                status: account.status,
                balance: account.balance,
                balanceRefresh: account.balance_refresh,
                ownership: account.ownership,
                supportedPaymentMethodTypes: account.supported_payment_method_types,
                createdAt: now,
                updatedAt: now,
            });
        }
        await batch.commit();
        console.log(`Saved ${accounts.length} accounts to bexly-us for user ${userId}`);
        // Return simplified account info
        return {
            success: true,
            accounts: accounts.map((acc) => ({
                id: acc.id,
                institutionName: acc.institution_name,
                displayName: acc.display_name,
                last4: acc.last4,
                category: acc.category,
            })),
        };
    }
    catch (error) {
        console.error(`Failed to complete Financial Connection for user ${userId}:`, error);
        if (error instanceof HttpsError) {
            throw error;
        }
        if (error instanceof Stripe.errors.StripeError) {
            throw new HttpsError("internal", `Stripe error: ${error.message}`);
        }
        throw new HttpsError("internal", "Failed to complete Financial Connection");
    }
});
/**
 * Fetch transactions from linked Financial Connections accounts
 * Syncs transactions from Stripe to bexly-us database
 */
export const syncFinancialConnectionTransactions = onCall({
    secrets: [stripeSecretKey],
    region: "us-central1",
    timeoutSeconds: 300, // 5 minutes for large transaction fetches
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = request.auth.uid;
    const { accountId, startDate, endDate } = request.data;
    console.log(`Syncing Financial Connection transactions for user ${userId}`);
    try {
        const stripe = getStripe();
        // Get user's linked accounts
        const accountsSnapshot = await bexlyUsDb
            .collection(`stripe_connections/${userId}/accounts`)
            .get();
        if (accountsSnapshot.empty) {
            throw new HttpsError("failed-precondition", "No linked accounts found");
        }
        const accountIds = accountId
            ? [accountId]
            : accountsSnapshot.docs.map((doc) => doc.id);
        let totalTransactions = 0;
        for (const accId of accountIds) {
            // Fetch transactions from Stripe
            const params = {
                account: accId,
                limit: 100,
            };
            // Add date filters if provided
            if (startDate && endDate) {
                params.transacted_at = {
                    gte: Math.floor(new Date(startDate).getTime() / 1000),
                    lte: Math.floor(new Date(endDate).getTime() / 1000),
                };
            }
            else if (startDate) {
                params.transacted_at = { gte: Math.floor(new Date(startDate).getTime() / 1000) };
            }
            else if (endDate) {
                params.transacted_at = { lte: Math.floor(new Date(endDate).getTime() / 1000) };
            }
            let hasMore = true;
            let startingAfter;
            while (hasMore) {
                const transactions = await stripe.financialConnections.transactions.list({
                    ...params,
                    starting_after: startingAfter,
                });
                if (transactions.data.length > 0) {
                    const batch = bexlyUsDb.batch();
                    const now = admin.firestore.Timestamp.now();
                    for (const txn of transactions.data) {
                        const txnRef = bexlyUsDb
                            .collection(`stripe_connections/${userId}/raw_transactions`)
                            .doc(txn.id);
                        // Type assertion for additional properties that may exist
                        const txnAny = txn;
                        batch.set(txnRef, {
                            transactionId: txn.id,
                            accountId: accId,
                            amount: txn.amount,
                            currency: txn.currency,
                            description: txn.description,
                            status: txn.status,
                            transactedAt: admin.firestore.Timestamp.fromMillis(txn.transacted_at * 1000),
                            postedAt: txnAny.posted_at
                                ? admin.firestore.Timestamp.fromMillis(txnAny.posted_at * 1000)
                                : null,
                            category: txnAny.category || null,
                            subcategory: txnAny.subcategory || null,
                            rawData: JSON.stringify(txn), // Store full transaction for debugging
                            syncedAt: now,
                        });
                        totalTransactions++;
                    }
                    await batch.commit();
                    startingAfter = transactions.data[transactions.data.length - 1].id;
                }
                hasMore = transactions.has_more;
            }
        }
        console.log(`Synced ${totalTransactions} transactions for user ${userId}`);
        return {
            success: true,
            transactionCount: totalTransactions,
        };
    }
    catch (error) {
        console.error(`Failed to sync transactions for user ${userId}:`, error);
        if (error instanceof HttpsError) {
            throw error;
        }
        if (error instanceof Stripe.errors.StripeError) {
            throw new HttpsError("internal", `Stripe error: ${error.message}`);
        }
        throw new HttpsError("internal", "Failed to sync transactions");
    }
});
/**
 * Get user's linked Financial Connections accounts
 */
export const getLinkedAccounts = onCall({
    secrets: [stripeSecretKey],
    region: "us-central1",
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = request.auth.uid;
    try {
        const accountsSnapshot = await bexlyUsDb
            .collection(`stripe_connections/${userId}/accounts`)
            .get();
        const accounts = accountsSnapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                institutionName: data.institutionName,
                displayName: data.displayName,
                last4: data.last4,
                category: data.category,
                status: data.status,
                balance: data.balance,
            };
        });
        return { accounts };
    }
    catch (error) {
        console.error(`Failed to get linked accounts for user ${userId}:`, error);
        throw new HttpsError("internal", "Failed to get linked accounts");
    }
});
/**
 * Disconnect a linked Financial Connections account
 */
export const disconnectFinancialAccount = onCall({
    secrets: [stripeSecretKey],
    region: "us-central1",
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    const userId = request.auth.uid;
    const { accountId } = request.data;
    if (!accountId) {
        throw new HttpsError("invalid-argument", "Account ID is required");
    }
    console.log(`Disconnecting account ${accountId} for user ${userId}`);
    try {
        const stripe = getStripe();
        // Disconnect from Stripe
        await stripe.financialConnections.accounts.disconnect(accountId);
        // Delete from bexly-us database
        await bexlyUsDb
            .collection(`stripe_connections/${userId}/accounts`)
            .doc(accountId)
            .delete();
        // Optionally delete associated transactions
        const transactionsSnapshot = await bexlyUsDb
            .collection(`stripe_connections/${userId}/raw_transactions`)
            .where("accountId", "==", accountId)
            .get();
        if (!transactionsSnapshot.empty) {
            const batch = bexlyUsDb.batch();
            transactionsSnapshot.docs.forEach((doc) => {
                batch.delete(doc.ref);
            });
            await batch.commit();
            console.log(`Deleted ${transactionsSnapshot.size} transactions for account ${accountId}`);
        }
        return { success: true };
    }
    catch (error) {
        console.error(`Failed to disconnect account ${accountId} for user ${userId}:`, error);
        if (error instanceof Stripe.errors.StripeError) {
            throw new HttpsError("internal", `Stripe error: ${error.message}`);
        }
        throw new HttpsError("internal", "Failed to disconnect account");
    }
});
//# sourceMappingURL=index.js.map