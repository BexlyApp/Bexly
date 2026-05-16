// Telegram Webhook - Phase 3.2: routes to Bexly Agent when BEXLY_TELEGRAM_USE_AGENT=true,
// otherwise uses legacy AI Transaction Processing + Financial Coach path.
//
// Required env (Supabase secrets):
//   BEXLY_TELEGRAM_BOT_TOKEN  - Telegram bot token
//   BEXLY_TELEGRAM_USE_AGENT  - "true" to route to the Bexly Agent
//   BEXLY_AGENT_URL           - Bexly Agent base URL (default https://ai.bexly.app)
//   BEXLY_CHANNEL_SECRET      - shared secret proving this is a trusted backend
//                               caller into the agent (no forged user JWT);
//                               must match BEXLY_CHANNEL_SECRET on Vercel
//   SUPABASE_URL              - auto-injected
//   SUPABASE_SERVICE_ROLE_KEY - auto-injected
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { parseTransactionWithAI } from "../_shared/ai-providers.ts";
import type { UserCategory } from "../_shared/types.ts";
import { LOCALIZATIONS } from "../_shared/types.ts";
import { buildSpendingInsights, formatInsightsForTelegram, formatInsightsForAI } from "../_shared/spending-insights.ts";
import { buildCoachPrompt } from "../_shared/financial-coach-prompt.ts";

const TELEGRAM_BOT_TOKEN = Deno.env.get("BEXLY_TELEGRAM_BOT_TOKEN");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BEXLY_AGENT_URL = Deno.env.get("BEXLY_AGENT_URL") ?? "https://ai.bexly.app";
const BEXLY_TELEGRAM_USE_AGENT = Deno.env.get("BEXLY_TELEGRAM_USE_AGENT") === "true";
// Shared secret for trusted server-to-server calls into the Bexly Agent.
// The Supabase project signs user JWTs with asymmetric ES256 keys, so this
// webhook cannot mint a matching user token. Instead it proves it is a
// trusted backend caller with this secret and names the target user via the
// X-Bexly-User-Id header; the agent uses its service key, scoping every
// query by that userId.
const BEXLY_CHANNEL_SECRET = Deno.env.get("BEXLY_CHANNEL_SECRET");

function getSupabaseClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: "bexly" },
  });
}

// ── Bexly Agent helpers (Phase 3.2; channel-auth as of channel-auth refactor) ─

// POST a message to the Bexly Agent as a trusted channel caller and
// accumulate the streamed reply into a plain string. Authenticates with the
// shared channel secret + explicit user id (no forged JWT).
async function callBexlyAgent(userId: string, message: string, threadId?: string): Promise<string> {
  if (!BEXLY_CHANNEL_SECRET) throw new Error('BEXLY_CHANNEL_SECRET not configured');
  const res = await fetch(`${BEXLY_AGENT_URL}/api/agent/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Bexly-Channel-Secret': BEXLY_CHANNEL_SECRET,
      'X-Bexly-User-Id': userId,
    },
    body: JSON.stringify({
      message,
      ...(threadId ? { threadId } : {}),
      locale: 'vi',
    }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`agent ${res.status}: ${body.slice(0, 200)}`);
  }
  // Plain-text streaming: accumulate
  const decoder = new TextDecoder();
  const reader = res.body?.getReader();
  if (!reader) throw new Error('agent: no response body');
  let full = '';
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    full += decoder.decode(value, { stream: true });
  }
  return full.trim();
}

// ── Telegram API helpers ──────────────────────────────────────────────────────

// Convert Markdown-style `*bold*` / `_italic_` to Telegram HTML tags.
// Safer than legacy Markdown because HTML parser tolerates punctuation
// adjacent to markers (e.g. `*-1.500đ*` which Markdown rejects).
function mdToHtml(text: string): string {
  let out = text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  // **bold** first (rare but possible)
  out = out.replace(/\*\*([^\n*]+)\*\*/g, "<b>$1</b>");
  // *bold* — non-greedy, no newlines inside
  out = out.replace(/\*([^\n*]+)\*/g, "<b>$1</b>");
  // _italic_ — non-greedy, no newlines inside
  out = out.replace(/_([^\n_]+)_/g, "<i>$1</i>");
  return out;
}

async function sendMessage(chatId: number, text: string, extra?: object) {
  const basePayload = { chat_id: chatId, text, ...extra };
  // First try: Markdown parse mode (unless caller overrode)
  const firstPayload = { parse_mode: "Markdown", ...basePayload };
  const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(firstPayload),
  });
  if (res.ok) return;
  // Markdown likely has unpaired `*` / `_` → retry as plain text
  const errBody = await res.text().catch(() => "");
  console.warn(`[sendMessage] Markdown failed (${res.status}): ${errBody.slice(0, 200)} — retrying plain text`);
  const plainPayload = { ...basePayload };
  // remove parse_mode entirely
  delete (plainPayload as Record<string, unknown>).parse_mode;
  const retry = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(plainPayload),
  });
  if (!retry.ok) {
    const retryErr = await retry.text().catch(() => "");
    console.error(`[sendMessage] Plain-text retry also failed (${retry.status}): ${retryErr.slice(0, 200)}`);
  }
}

async function editMessageText(chatId: number, messageId: number, text: string, extra?: object) {
  const basePayload = { chat_id: chatId, message_id: messageId, text, ...extra };
  const firstPayload = { parse_mode: "Markdown", ...basePayload };
  const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/editMessageText`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(firstPayload),
  });
  if (res.ok) return;
  const errBody = await res.text().catch(() => "");
  console.warn(`[editMessageText] Markdown failed (${res.status}): ${errBody.slice(0, 200)} — retrying plain text`);
  const plainPayload = { ...basePayload };
  delete (plainPayload as Record<string, unknown>).parse_mode;
  const retry = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/editMessageText`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(plainPayload),
  });
  if (!retry.ok) {
    const retryErr = await retry.text().catch(() => "");
    console.error(`[editMessageText] Plain-text retry also failed (${retry.status}): ${retryErr.slice(0, 200)}`);
  }
}

async function answerCallbackQuery(id: string, text?: string) {
  await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/answerCallbackQuery`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ callback_query_id: id, text }),
  });
}

// ── Auth helpers ──────────────────────────────────────────────────────────────

// Look up the Bexly user linked to this Telegram chat (null if unlinked).
async function getUserId(telegramId: string): Promise<string | null> {
  const { data } = await getSupabaseClient()
    .from("user_integrations")
    .select("user_id")
    .eq("platform", "telegram")
    .eq("platform_user_id", telegramId)
    .maybeSingle();
  return data?.user_id ?? null;
}

// Consume an app-generated link code: validate (unexpired, telegram),
// link this Telegram chat to the code's Bexly user, delete the code.
// Returns the linked user_id, "ALREADY" if this chat is already linked,
// or null if the code is invalid/expired.
async function consumeLinkCode(
  rawCode: string,
  telegramId: string,
): Promise<string | "ALREADY" | null> {
  const code = rawCode.trim().toUpperCase();
  const sb = getSupabaseClient();

  const { data: row } = await sb
    .from("bot_link_codes")
    .select("user_id")
    .eq("code", code)
    .eq("platform", "telegram")
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();
  if (!row?.user_id) return null;

  const existing = await getUserId(telegramId);
  if (existing) {
    await sb.from("bot_link_codes").delete().eq("code", code);
    return "ALREADY";
  }

  const { error: insErr } = await sb.from("user_integrations").insert({
    user_id: row.user_id,
    platform: "telegram",
    platform_user_id: telegramId,
    linked_at: new Date().toISOString(),
    last_activity: new Date().toISOString(),
  });
  if (insErr) {
    console.error("[telegram-webhook] link insert failed:", JSON.stringify(insErr));
    return null;
  }
  await sb.from("bot_link_codes").delete().eq("code", code);
  return row.user_id;
}

async function unlinkUser(telegramId: string): Promise<boolean> {
  const { error } = await getSupabaseClient()
    .from("user_integrations")
    .delete()
    .eq("platform", "telegram")
    .eq("platform_user_id", telegramId);
  return !error;
}

// ── Pending transaction store ─────────────────────────────────────────────────

function generateShortId(): string {
  // 8-char alphanumeric ID — fits comfortably in callback_data with prefix
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}

async function savePendingTransaction(
  userId: string,
  chatId: number,
  data: {
    type: "expense" | "income";
    amount: number;
    categoryId: string;
    walletId: string;
    description: string | null;
    notes: string | null;
    transactionDate: string;
    language: string;
  },
): Promise<string> {
  const id = generateShortId();
  await getSupabaseClient()
    .from("bot_pending_transactions")
    .insert({
      id,
      user_id: userId,
      platform: "telegram",
      chat_id: chatId,
      type: data.type,
      amount: data.amount,
      category_id: data.categoryId,
      wallet_id: data.walletId,
      description: data.description,
      notes: data.notes,
      transaction_date: data.transactionDate,
      language: data.language,
    });
  return id;
}

async function getPendingTransaction(id: string) {
  const { data } = await getSupabaseClient()
    .from("bot_pending_transactions")
    .select("*")
    .eq("id", id)
    .gt("expires_at", new Date().toISOString())
    .single();
  return data ?? null;
}

async function deletePendingTransaction(id: string) {
  await getSupabaseClient()
    .from("bot_pending_transactions")
    .delete()
    .eq("id", id);
}

// ── User data helpers ─────────────────────────────────────────────────────────

async function getDefaultWallet(userId: string) {
  // Deterministic selection so INSERT and later queries pick the same wallet.
  // Otherwise Postgres may return a different wallet per call, breaking coach
  // context (transaction lands in one wallet, insights query a different one).
  const { data } = await getSupabaseClient()
    .from("wallets")
    .select("cloud_id, name, currency, balance")
    .eq("user_id", userId)
    .eq("is_active", true)
    .order("created_at", { ascending: true })
    .order("cloud_id", { ascending: true })
    .limit(1)
    .single();
  return data ?? null;
}

async function getCategories(userId: string): Promise<UserCategory[]> {
  const { data } = await getSupabaseClient()
    .from("categories")
    .select("cloud_id, name, category_type")
    .eq("user_id", userId)
    .eq("is_deleted", false);

  return (data ?? []).map((c: any) => ({
    id: c.cloud_id,
    title: c.name,
    transactionType: c.category_type,
  }));
}

async function findCategoryId(userId: string, title: string): Promise<string | null> {
  const { data } = await getSupabaseClient()
    .from("categories")
    .select("cloud_id, name")
    .eq("user_id", userId)
    .eq("is_deleted", false);

  if (!data?.length) return null;

  // Exact match
  const exact = data.find((c: any) => c.name.toLowerCase() === title.toLowerCase());
  if (exact) return exact.cloud_id;

  // Partial match
  const partial = data.find((c: any) =>
    c.name.toLowerCase().includes(title.toLowerCase()) ||
    title.toLowerCase().includes(c.name.toLowerCase())
  );
  return partial?.cloud_id ?? null;
}

// ── Time resolution ───────────────────────────────────────────────────────────

function resolveDate(timeHint: string | null): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  if (!timeHint) return now.toISOString();

  const hourMap: Record<string, number> = {
    morning: 7, noon: 12, afternoon: 15, evening: 19,
  };

  if (timeHint in hourMap) {
    today.setHours(hourMap[timeHint], 0, 0, 0);
    return today.toISOString();
  }

  const offsets: Record<string, () => Date> = {
    yesterday: () => { const d = new Date(today); d.setDate(d.getDate() - 1); return d; },
    yesterday_night: () => { const d = new Date(today); d.setDate(d.getDate() - 1); d.setHours(21); return d; },
    yesterday_evening: () => { const d = new Date(today); d.setDate(d.getDate() - 1); d.setHours(19); return d; },
    last_week: () => { const d = new Date(today); d.setDate(d.getDate() - 7); return d; },
    last_month: () => { const d = new Date(today); d.setMonth(d.getMonth() - 1); return d; },
  };

  if (timeHint in offsets) return offsets[timeHint]().toISOString();

  // HH:MM format
  if (/^\d{1,2}:\d{2}$/.test(timeHint)) {
    const [h, m] = timeHint.split(":").map(Number);
    today.setHours(h, m, 0, 0);
    return today.toISOString();
  }

  return now.toISOString();
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function formatAmount(amount: number, currency: string): string {
  if (currency === "VND") return `${amount.toLocaleString("vi-VN")}đ`;
  return new Intl.NumberFormat("en-US", { style: "currency", currency, minimumFractionDigits: 0 }).format(amount);
}

// ── Chat history (shared with Flutter app via chat_messages table) ───────────

const HISTORY_LIMIT = 6; // Last N messages passed to AI for context

async function getChatHistory(
  userId: string,
): Promise<Array<{ role: "user" | "assistant"; content: string }>> {
  const { data } = await getSupabaseClient()
    .from("chat_messages")
    .select("content, is_from_user, timestamp")
    .eq("user_id", userId)
    .order("timestamp", { ascending: false })
    .limit(HISTORY_LIMIT);

  if (!data?.length) return [];

  // Reverse so oldest comes first (chronological)
  return data.reverse().map((m: any) => ({
    role: m.is_from_user ? "user" : "assistant",
    content: m.content,
  }));
}

async function saveChatMessage(
  userId: string,
  content: string,
  isFromUser: boolean,
): Promise<void> {
  await getSupabaseClient()
    .from("chat_messages")
    .insert({
      message_id: crypto.randomUUID(),
      user_id: userId,
      content,
      is_from_user: isFromUser,
      timestamp: new Date().toISOString(),
    });
}

// ── Financial Coach handler ──────────────────────────────────────────────────

async function handleCoachMessage(
  chatId: number,
  userId: string,
  text: string,
  lang: string,
) {
  const wallet = await getDefaultWallet(userId);
  if (!wallet) return null; // Fall through to transaction parsing

  // Build spending context aggregated across ALL user wallets
  // (matches Flutter dashboard which shows cross-wallet totals)
  const insights = await buildSpendingInsights(userId);
  if (!insights) return null;

  const spendingContext = formatInsightsForAI(insights);
  const systemPrompt = buildCoachPrompt(spendingContext);

  // Strict language enforcement to prevent Chinese/other-language bleed from Qwen
  const languageRule = lang === "vi"
    ? "\n\nSTRICT LANGUAGE RULE: Respond ONLY in Vietnamese. Never use Chinese, Japanese, Korean, or any other language. Never mix scripts. If you are about to write a Chinese character, stop and rewrite in Vietnamese."
    : "\n\nSTRICT LANGUAGE RULE: Respond ONLY in English. Never use Chinese, Japanese, Korean, or any other non-English script. Never mix languages.";

  // Load recent conversation history (shared with Flutter app)
  const history = await getChatHistory(userId);

  // Call Qwen (DOS AI) with full coach prompt - OpenAI-compatible API
  const apiKey = Deno.env.get("BEXLY_DOS_AI_API_KEY");
  const baseUrl = Deno.env.get("DOS_AI_URL") || "https://api.dos.ai/v1";
  const model = Deno.env.get("DOS_AI_MODEL") || "dos-ai";
  if (!apiKey) return null;

  try {
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
        "User-Agent": "Bexly/1.0 (Deno; Supabase Edge Function)",
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: systemPrompt + languageRule },
          ...history,
          { role: "user", content: text },
        ],
        temperature: 0.4,
        max_tokens: 900,
        enable_thinking: false,
      }),
    });

    if (!response.ok) {
      console.error("Coach AI error:", response.status, await response.text());
      return null;
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content?.trim();
    if (!reply) return null;

    // Check if AI returned a transaction JSON (it detected a transaction)
    const jsonMatch = reply.match(/\{[^}]*"action"\s*:\s*"create_(expense|income)"[^}]*\}/);
    if (jsonMatch) {
      // It's a transaction - return null so we fall through to normal parsing
      return null;
    }

    // Strip any stray CJK characters that leaked through (belt-and-suspenders)
    const cleaned = reply.replace(/[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]/g, "").trim();

    // Persist conversation so both the app and future bot turns see it
    await saveChatMessage(userId, text, true);
    await saveChatMessage(userId, cleaned, false);

    return cleaned;
  } catch (e) {
    console.error("Coach AI error:", e);
    return null;
  }
}

async function handleInsightsCommand(chatId: number, userId: string, lang: string) {
  const wallet = await getDefaultWallet(userId);
  if (!wallet) {
    const loc = LOCALIZATIONS[lang] ?? LOCALIZATIONS.en;
    await sendMessage(chatId, loc.noWallet);
    return;
  }

  const insights = await buildSpendingInsights(userId);
  if (!insights) {
    await sendMessage(chatId, lang === "vi"
      ? "📊 Chưa có dữ liệu chi tiêu. Hãy ghi nhận giao dịch trước nhé!"
      : "📊 No spending data yet. Record some transactions first!");
    return;
  }

  const formatted = formatInsightsForTelegram(insights, lang);
  await sendMessage(chatId, formatted);
}

// ── Transaction handler ───────────────────────────────────────────────────────

async function handleTransactionMessage(
  chatId: number,
  userId: string,
  text: string,
  lang: string,
) {
  const loc = LOCALIZATIONS[lang] ?? LOCALIZATIONS.en;

  const wallet = await getDefaultWallet(userId);
  console.log("Wallet:", wallet ? `${wallet.name} (${wallet.currency})` : "null");
  if (!wallet) { await sendMessage(chatId, loc.noWallet); return; }

  const categories = await getCategories(userId);
  console.log("Categories count:", categories.length, "first 5:", categories.slice(0, 5).map(c => c.title));
  if (!categories.length) { await sendMessage(chatId, loc.noCategory); return; }

  // Parse transaction FIRST — only falls through to coach if message is not a transaction
  console.log("Parsing with AI:", text, "lang:", lang, "currency:", wallet.currency);
  const parsed = await parseTransactionWithAI(text, categories, wallet.currency);
  console.log("AI parsed result:", parsed);

  if (!parsed) {
    // Not a transaction — try financial coach (has history + spending context)
    const coachReply = await handleCoachMessage(chatId, userId, text, lang);
    if (coachReply) {
      await sendMessage(chatId, mdToHtml(coachReply), { parse_mode: "HTML" });
      return;
    }

    const hint = lang === "vi"
      ? "💬 Tôi chưa hiểu. Thử gõ ví dụ:\n• *ăn trưa 50k*\n• *cafe 30k*\n• *lương 10tr*\n\nHoặc hỏi: _Tình hình tài chính tháng này?_"
      : "💬 I didn't understand that. Try:\n• *lunch 50k*\n• *coffee $3*\n• *salary 1000*\n\nOr ask: _How am I doing this month?_";
    await sendMessage(chatId, hint);
    return;
  }

  const categoryId = await findCategoryId(userId, parsed.category);
  if (!categoryId) {
    await sendMessage(chatId, `${loc.noCategory}: *${parsed.category}*`);
    return;
  }

  const txDate = resolveDate(parsed.datetime);
  const fmt = formatAmount(parsed.amount, wallet.currency);
  const emoji = parsed.type === "expense" ? "💸" : "💰";
  const typeLabel = parsed.type === "expense" ? loc.expenseDetected : loc.incomeDetected;
  const dateStr = new Date(txDate).toLocaleString(lang === "vi" ? "vi-VN" : "en-US", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });

  const desc = capitalize(parsed.description || parsed.category);
  const note = parsed.note ? capitalize(parsed.note) : null;
  const noteLine = note
    ? (lang === "vi" ? `\n📋 Ghi chú: ${note}` : `\n📋 Note: ${note}`)
    : "";

  const confirmText = lang === "vi"
    ? `${emoji} *${typeLabel}*\n\n📝 Nội dung: ${desc}\n💵 Số tiền: ${fmt}\n🏷 Danh mục: ${parsed.category}\n🏦 Ví: ${wallet.name}\n🕐 Thời gian: ${dateStr}${noteLine}\n\nXác nhận ghi lại?`
    : `${emoji} *${typeLabel}*\n\n📝 Description: ${desc}\n💵 Amount: ${fmt}\n🏷 Category: ${parsed.category}\n🏦 Wallet: ${wallet.name}\n🕐 Time: ${dateStr}${noteLine}\n\nConfirm?`;

  // Save to DB, use short ID in callback
  const pendingId = await savePendingTransaction(userId, chatId, {
    type: parsed.type,
    amount: parsed.amount,
    categoryId,
    walletId: wallet.cloud_id,
    description: desc,
    notes: note,
    transactionDate: txDate,
    language: lang,
  });

  await sendMessage(chatId, confirmText, {
    reply_markup: {
      inline_keyboard: [[
        { text: `✅ ${loc.confirm}`, callback_data: `ctx_${pendingId}` },
        { text: `❌ ${loc.cancel}`, callback_data: `cxl_${pendingId}` },
      ]],
    },
  });
}

async function handleConfirm(
  chatId: number,
  messageId: number,
  originalText: string,
  userId: string,
  callbackId: string,
  pendingId: string,
) {
  await answerCallbackQuery(callbackId);

  const pending = await getPendingTransaction(pendingId);
  if (!pending) {
    await editMessageText(chatId, messageId, originalText + "\n\n⏰ Expired.");
    return;
  }

  const lang = pending.language ?? "en";
  const loc = LOCALIZATIONS[lang] ?? LOCALIZATIONS.en;

  try {
    // Get wallet currency
    const wallet = await getDefaultWallet(userId);
    const currency = wallet?.currency ?? "VND";

    const cloudId = crypto.randomUUID();
    const { error } = await getSupabaseClient()
      .from("transactions")
      .insert({
        cloud_id: cloudId,
        user_id: userId,
        wallet_id: pending.wallet_id,
        category_id: pending.category_id,
        amount: pending.amount,
        transaction_type: pending.type,
        currency,
        title: pending.description || pending.type,
        notes: pending.notes || null,
        transaction_date: pending.transaction_date,
        is_deleted: false,
        updated_at: new Date().toISOString(),
      });

    if (error) throw error;

    // Update wallet balance
    const { data: w } = await getSupabaseClient()
      .from("wallets")
      .select("balance")
      .eq("cloud_id", pending.wallet_id)
      .single();

    if (w) {
      const delta = pending.type === "expense" ? -pending.amount : pending.amount;
      await getSupabaseClient()
        .from("wallets")
        .update({ balance: w.balance + delta })
        .eq("cloud_id", pending.wallet_id);
    }

    await deletePendingTransaction(pendingId);

    // Keep original card, replace buttons with status line
    const statusLine = lang === "vi" ? `\n\n✅ ${loc.recorded}!` : `\n\n✅ ${loc.recorded}!`;
    await editMessageText(chatId, messageId, originalText + statusLine);
  } catch (e) {
    console.error("Error creating transaction:", e);
    const failLine = lang === "vi" ? "\n\n❌ Ghi lỗi. Thử lại nhé." : "\n\n❌ Failed. Try again.";
    await editMessageText(chatId, messageId, originalText + failLine);
  }
}

// ── Main serve ────────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    const update = await req.json();
    console.log("Update:", JSON.stringify(update).substring(0, 300));

    // Callback queries
    const cb = update.callback_query;
    if (cb) {
      const chatId: number = cb.message.chat.id;
      const messageId: number = cb.message.message_id;
      const telegramUserId = String(cb.from.id);
      const data: string = cb.data ?? "";
      const cbId: string = cb.id;

      // Get original message text to preserve it
      const originalText = cb.message?.text ?? "";

      if (data.startsWith("ctx_")) {
        const userId = await getUserId(telegramUserId);
        if (!userId) { await answerCallbackQuery(cbId, "Not linked!"); return new Response("OK"); }
        await handleConfirm(chatId, messageId, originalText, userId, cbId, data.slice(4));

      } else if (data.startsWith("cxl_")) {
        await answerCallbackQuery(cbId);
        await deletePendingTransaction(data.slice(4));
        await editMessageText(chatId, messageId, originalText + "\n\n❌ Cancelled.");

      } else if (data.startsWith("unlink_confirm_")) {
        const ok = await unlinkUser(telegramUserId);
        await answerCallbackQuery(cbId);
        await editMessageText(chatId, messageId,
          ok
            ? "✅ Unlinked! Use /link to reconnect anytime."
            : "❌ Failed to unlink. Try again."
        );

      } else if (data.startsWith("unlink_cancel_")) {
        await answerCallbackQuery(cbId);
        await editMessageText(chatId, messageId, "✅ Cancelled. Account still linked.");

      } else if (data.startsWith("demo_")) {
        const demoNum = parseInt(data.slice(5));
        const demo = DEMO_ACCOUNTS.find((d) => d.num === demoNum);
        if (!demo) { await answerCallbackQuery(cbId, "Invalid demo"); return new Response("OK"); }

        const ok = await linkToDemoAccount(telegramUserId, demoNum);
        await answerCallbackQuery(cbId);
        if (ok) {
          await editMessageText(chatId, messageId,
            `✅ *Switched to ${demo.name}'s account!*\n\n` +
            `${demo.desc}\n\n` +
            `Try these:\n` +
            `• /insights - View spending overview\n` +
            `• \`Tình hình tài chính?\` - Get coaching\n` +
            `• \`ăn trưa 50k\` - Record expense\n` +
            `• /demo - Switch account`
          );
        } else {
          await editMessageText(chatId, messageId, "❌ Failed to switch. Try again.");
        }
      }

      return new Response("OK", { status: 200 });
    }

    // Messages
    const msg = update.message;
    if (!msg) return new Response("OK", { status: 200 });

    const chatId: number = msg.chat.id;
    const telegramUserId = String(msg.from.id);
    const text = (msg.text ?? "").trim();

    // Detect Vietnamese from text content or Telegram language_code
    const hasVietnamese = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/i.test(text);
    const lang = hasVietnamese || msg.from.language_code === "vi" ? "vi" : "en";

    if (text === "/start") {
      await sendMessage(chatId,
        "👋 *Welcome to Bexly AI Financial Coach!*\n" +
        "_Powered by Qwen AI & Shinhan Bank_\n\n" +
        "I can:\n" +
        "📝 Track expenses & income\n" +
        "📊 Analyze your spending patterns\n" +
        "💡 Give personalized financial coaching\n" +
        "🏦 Recommend Shinhan banking products\n\n" +
        "👇 *Pick a demo account to get started:*"
      );
      await showDemoSelector(chatId);
      return new Response("OK");
    }

    if (text === "/demo") {
      const existing = await getUserId(telegramUserId);
      const currentDemo = existing ? DEMO_ACCOUNTS.find((d) => d.userId === existing) : null;
      const prefix = currentDemo
        ? `🔄 *Switch demo account*\n_Currently: ${currentDemo.name} (#${currentDemo.num})_`
        : "👤 *Choose a demo account to explore:*";
      await showDemoSelector(chatId, prefix);
      return new Response("OK");
    }

    if (text === "/help") {
      await sendMessage(chatId,
        "📖 *Bexly AI Coach Commands*\n\n" +
        "/demo - Choose/switch demo account\n" +
        "/insights - Spending overview & health score\n" +
        "/link - Link your real Bexly account\n" +
        "/unlink - Unlink your account\n" +
        "/help - Show this help\n\n" +
        "*Record transactions:*\n" +
        "`ăn sáng 25k` - breakfast expense\n" +
        "`lunch $10` - lunch expense\n" +
        "`lương 15 triệu` - salary income\n\n" +
        "*Ask for coaching:*\n" +
        "`Tình hình tài chính tháng này?`\n" +
        "`How can I save more?`\n" +
        "`Nên cắt giảm chi tiêu gì?`"
      );
      return new Response("OK");
    }

    if (text === "/insights") {
      const userId = await getUserId(telegramUserId);
      if (!userId) {
        await showDemoSelector(chatId, "📊 *Pick an account first to view insights:*");
        return new Response("OK");
      }
      await handleInsightsCommand(chatId, userId, lang);
      return new Response("OK");
    }

    if (text === "/link") {
      const existing = await getUserId(telegramUserId);
      if (existing) {
        await sendMessage(chatId, "✅ Already linked! Just send a message to record a transaction.");
        return new Response("OK");
      }
      const code = await generateLinkCode(telegramUserId);
      await sendMessage(chatId,
        `🔗 *Link your Bexly account*\n\n` +
        `⌨️ Enter this code in Bexly app:\n\n` +
        `\`${code}\`\n\n` +
        `_(Settings → Integrations → Telegram)_\n` +
        `⏰ Code expires in 10 minutes.`
      );
      return new Response("OK");
    }

    if (text === "/unlink") {
      const existing = await getUserId(telegramUserId);
      if (!existing) {
        await sendMessage(chatId, "❌ Not linked yet. Use /link first.");
        return new Response("OK");
      }
      await sendMessage(chatId, "⚠️ Unlink your Bexly account?", {
        reply_markup: {
          inline_keyboard: [[
            { text: "✅ Yes, unlink", callback_data: `unlink_confirm_${telegramUserId}` },
            { text: "❌ Cancel", callback_data: `unlink_cancel_${telegramUserId}` },
          ]],
        },
      });
      return new Response("OK");
    }

    // Demo account selection via reply keyboard (e.g. "5. Duc")
    const demoMatch = text.match(/^(\d)\.\s*(\w+)$/);
    if (demoMatch) {
      const demoNum = parseInt(demoMatch[1]);
      const demo = DEMO_ACCOUNTS.find((d) => d.num === demoNum);
      if (demo) {
        const ok = await linkToDemoAccount(telegramUserId, demoNum);
        if (ok) {
          await sendMessage(chatId,
            `✅ *Switched to ${demo.name}'s account!*\n\n` +
            `${demo.desc}\n\n` +
            `Try these:\n` +
            `• /insights - View spending overview\n` +
            `• \`Tình hình tài chính?\` - Get coaching\n` +
            `• \`ăn trưa 50k\` - Record expense\n` +
            `• /demo - Switch account`,
            { reply_markup: { remove_keyboard: true } },
          );
        } else {
          await sendMessage(chatId, "❌ Failed to switch. Try again.");
        }
        return new Response("OK");
      }
    }

    // Any other message → try to parse as transaction
    const userId = await getUserId(telegramUserId);
    if (!userId) {
      await showDemoSelector(chatId, "👋 *Welcome!* Pick a demo account to get started:");
      return new Response("OK");
    }

    // Phase 3.2: route to Bexly Agent when feature flag is on
    if (BEXLY_TELEGRAM_USE_AGENT) {
      try {
        const reply = await callBexlyAgent(userId, text, `telegram-${chatId}`);
        if (reply.length > 0) {
          await sendMessage(chatId, mdToHtml(reply), { parse_mode: 'HTML' });
          // Also save to chat_messages so Flutter app sees the conversation
          await saveChatMessage(userId, text, true);
          await saveChatMessage(userId, reply, false);
          return new Response("OK", { status: 200 }); // agent handled this turn
        }
      } catch (err) {
        console.error('[telegram-webhook] Bexly Agent call failed, falling through to legacy coach:', err);
        // Fall through to existing logic below
      }
    }

    await handleTransactionMessage(chatId, userId, text, lang);

    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("Webhook error:", error);
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500 });
  }
});
