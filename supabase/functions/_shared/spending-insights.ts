// Server-side spending insights calculation for Telegram bot
// Mirrors the Flutter app's spending insights injection (chat_provider.dart)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function getDb() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: "bexly" },
  });
}

interface MonthlyData {
  income: number;
  expense: number;
  topCategories: { name: string; amount: number; count: number }[];
}

interface BudgetStatus {
  category: string;
  limit: number;
  spent: number;
  pct: number;
}

interface RecentTransaction {
  amount: number;
  type: "income" | "expense" | "transfer";
  title: string;
  category: string;
  wallet: string;
  currency: string;
  date: string;
  notes?: string | null;
}

interface RecurringItem {
  title: string;
  amount: number;
  frequency: string;
  currency: string;
  nextDueDate?: string | null;
}

interface SpendingInsights {
  thisMonth: MonthlyData;
  lastMonth: MonthlyData;
  budgets: BudgetStatus[];
  recurringTotal: number;
  recurringCount: number;
  recurringItems: RecurringItem[];
  recentTransactions: RecentTransaction[];
  healthScore: number;
  currency: string;
  walletName: string;
}

// Calculate financial health score (0-100)
function calcHealthScore(insights: SpendingInsights): number {
  let score = 50;

  const { thisMonth } = insights;
  if (thisMonth.income > 0) {
    const savingsRate = (thisMonth.income - thisMonth.expense) / thisMonth.income;
    if (savingsRate >= 0.2) score += 20;
    else if (savingsRate >= 0.1) score += 10;
    else if (savingsRate < 0) score -= 15;
  }

  // Budget adherence
  const overBudget = insights.budgets.filter((b) => b.pct > 100).length;
  const nearBudget = insights.budgets.filter((b) => b.pct > 80 && b.pct <= 100).length;
  if (overBudget === 0 && insights.budgets.length > 0) score += 15;
  else score -= overBudget * 5;
  if (nearBudget > 0) score -= nearBudget * 2;

  // Recurring ratio
  if (thisMonth.income > 0) {
    const recurRatio = insights.recurringTotal / thisMonth.income;
    if (recurRatio > 0.5) score -= 10;
    else if (recurRatio < 0.2) score += 5;
  }

  return Math.max(0, Math.min(100, score));
}

function fmt(amount: number, currency: string): string {
  if (currency === "VND") return `${amount.toLocaleString("vi-VN")}đ`;
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    minimumFractionDigits: 0,
  }).format(amount);
}

export async function buildSpendingInsights(
  userId: string,
  walletId?: string,
): Promise<SpendingInsights | null> {
  const db = getDb();
  const now = new Date();
  const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
  const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
  const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59).toISOString();

  // Resolve wallet scope. If walletId is omitted we aggregate across ALL
  // active wallets of the user — matches how the Flutter dashboard shows totals.
  const { data: allWallets } = await db
    .from("wallets")
    .select("cloud_id, name, currency, balance")
    .eq("user_id", userId)
    .eq("is_active", true)
    .order("created_at", { ascending: true });

  if (!allWallets?.length) return null;

  const scopedWallets = walletId
    ? allWallets.filter((w: any) => w.cloud_id === walletId)
    : allWallets;
  if (!scopedWallets.length) return null;

  const walletIds = scopedWallets.map((w: any) => w.cloud_id);
  // Pick a representative currency — first wallet's currency, or VND.
  const currency = scopedWallets[0].currency || "VND";
  const walletLabel = walletId
    ? scopedWallets[0].name
    : (scopedWallets.length === 1 ? scopedWallets[0].name : "All wallets");

  // This month transactions across scoped wallets
  const { data: thisMonthTx } = await db
    .from("transactions")
    .select("amount, transaction_type, category_id")
    .eq("user_id", userId)
    .in("wallet_id", walletIds)
    .eq("is_deleted", false)
    .gte("transaction_date", thisMonthStart);

  // Last month transactions
  const { data: lastMonthTx } = await db
    .from("transactions")
    .select("amount, transaction_type, category_id")
    .eq("user_id", userId)
    .in("wallet_id", walletIds)
    .eq("is_deleted", false)
    .gte("transaction_date", lastMonthStart)
    .lte("transaction_date", lastMonthEnd);

  // Categories lookup
  const { data: categories } = await db
    .from("categories")
    .select("cloud_id, name")
    .eq("user_id", userId)
    .eq("is_deleted", false);

  const catMap = new Map((categories ?? []).map((c: any) => [c.cloud_id, c.name]));

  // Aggregate this month
  const thisIncome = (thisMonthTx ?? [])
    .filter((t: any) => t.transaction_type === "income")
    .reduce((s: number, t: any) => s + t.amount, 0);
  const thisExpense = (thisMonthTx ?? [])
    .filter((t: any) => t.transaction_type === "expense")
    .reduce((s: number, t: any) => s + t.amount, 0);

  // Top categories this month
  const catSpend = new Map<string, { amount: number; count: number }>();
  for (const t of (thisMonthTx ?? []).filter((t: any) => t.transaction_type === "expense")) {
    const name = catMap.get(t.category_id) || "Other";
    const prev = catSpend.get(name) || { amount: 0, count: 0 };
    catSpend.set(name, { amount: prev.amount + t.amount, count: prev.count + 1 });
  }
  const topCats = [...catSpend.entries()]
    .map(([name, v]) => ({ name, ...v }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 5);

  // Last month aggregate
  const lastIncome = (lastMonthTx ?? [])
    .filter((t: any) => t.transaction_type === "income")
    .reduce((s: number, t: any) => s + t.amount, 0);
  const lastExpense = (lastMonthTx ?? [])
    .filter((t: any) => t.transaction_type === "expense")
    .reduce((s: number, t: any) => s + t.amount, 0);

  // Budgets (no is_deleted column on budgets table)
  const { data: budgetRows } = await db
    .from("budgets")
    .select("category_id, amount")
    .eq("user_id", userId)
    .in("wallet_id", walletIds)
    .gte("end_date", thisMonthStart);

  const budgets: BudgetStatus[] = (budgetRows ?? []).map((b: any) => {
    const spent = (thisMonthTx ?? [])
      .filter((t: any) => t.transaction_type === "expense" && t.category_id === b.category_id)
      .reduce((s: number, t: any) => s + t.amount, 0);
    return {
      category: catMap.get(b.category_id) || "Unknown",
      limit: b.amount,
      spent,
      pct: b.amount > 0 ? Math.round((spent / b.amount) * 100) : 0,
    };
  });

  // Recurring (table is recurring_transactions, uses is_active not is_deleted)
  const { data: recurrings } = await db
    .from("recurring_transactions")
    .select("title, amount, frequency, currency, next_due_date")
    .eq("user_id", userId)
    .eq("is_active", true)
    .eq("status", "active")
    .order("amount", { ascending: false });

  const recurringTotal = (recurrings ?? []).reduce((s: number, r: any) => s + Number(r.amount), 0);
  const recurringCount = (recurrings ?? []).length;
  const recurringItems: RecurringItem[] = (recurrings ?? []).map((r: any) => ({
    title: r.title,
    amount: Number(r.amount),
    frequency: r.frequency,
    currency: r.currency || currency,
    nextDueDate: r.next_due_date,
  }));

  // Recent 10 transactions across scoped wallets — needed so the LLM can answer
  // "list recent transactions / what did I spend on yesterday" without guessing.
  const { data: recentTxRows } = await db
    .from("transactions")
    .select("amount, transaction_type, title, category_id, wallet_id, currency, transaction_date, notes")
    .eq("user_id", userId)
    .in("wallet_id", walletIds)
    .eq("is_deleted", false)
    .order("transaction_date", { ascending: false })
    .limit(10);

  const walletNameMap = new Map(scopedWallets.map((w: any) => [w.cloud_id, w.name]));
  const recentTransactions: RecentTransaction[] = (recentTxRows ?? []).map((t: any) => ({
    amount: Number(t.amount),
    type: t.transaction_type,
    title: t.title || catMap.get(t.category_id) || "—",
    category: catMap.get(t.category_id) || "—",
    wallet: walletNameMap.get(t.wallet_id) || "—",
    currency: t.currency || currency,
    date: t.transaction_date,
    notes: t.notes,
  }));

  const insights: SpendingInsights = {
    thisMonth: { income: thisIncome, expense: thisExpense, topCategories: topCats },
    lastMonth: { income: lastIncome, expense: lastExpense, topCategories: [] },
    budgets,
    recurringTotal,
    recurringCount,
    recurringItems,
    recentTransactions,
    healthScore: 0,
    currency,
    walletName: walletLabel,
  };
  insights.healthScore = calcHealthScore(insights);

  return insights;
}

// Format insights as text for AI context or Telegram message
export function formatInsightsForAI(i: SpendingInsights): string {
  const c = i.currency;
  const lines: string[] = [];

  lines.push(`SPENDING INSIGHTS (${i.walletName}):`);
  lines.push(`This month: Income ${fmt(i.thisMonth.income, c)} | Expenses ${fmt(i.thisMonth.expense, c)} | Net ${fmt(i.thisMonth.income - i.thisMonth.expense, c)}`);

  if (i.lastMonth.income > 0 || i.lastMonth.expense > 0) {
    const expDiff = i.thisMonth.expense - i.lastMonth.expense;
    const pct = i.lastMonth.expense > 0 ? Math.round((expDiff / i.lastMonth.expense) * 100) : 0;
    lines.push(`vs Last month: Income ${fmt(i.lastMonth.income, c)} | Expenses ${fmt(i.lastMonth.expense, c)} (${pct >= 0 ? "+" : ""}${pct}%)`);
  }

  if (i.thisMonth.topCategories.length > 0) {
    lines.push(`Top spending: ${i.thisMonth.topCategories.map((t) => `${t.name} ${fmt(t.amount, c)} (${t.count}x)`).join(", ")}`);
  }

  if (i.budgets.length > 0) {
    lines.push(`Budgets: ${i.budgets.map((b) => `${b.category} ${b.pct}% used (${fmt(b.spent, c)}/${fmt(b.limit, c)})`).join(", ")}`);
  }

  if (i.recurringCount > 0) {
    lines.push(`Recurring: ${i.recurringCount} subscriptions totaling ${fmt(i.recurringTotal, c)}/month`);
    // Full list so the LLM can answer "what subscriptions do I have?" etc.
    lines.push("Subscriptions:");
    for (const r of i.recurringItems) {
      lines.push(`  - ${r.title}: ${fmt(r.amount, r.currency)}/${r.frequency}${r.nextDueDate ? ` (next ${r.nextDueDate.slice(0, 10)})` : ""}`);
    }
  }

  lines.push(`Financial Health Score: ${i.healthScore}/100`);

  if (i.thisMonth.income > 0) {
    const savingsRate = Math.round(((i.thisMonth.income - i.thisMonth.expense) / i.thisMonth.income) * 100);
    lines.push(`Savings rate: ${savingsRate}%`);
  }

  // Raw recent transactions so the LLM can answer "list my recent transactions",
  // "what did I spend on yesterday", "which wallet charged me most today", etc.
  if (i.recentTransactions.length > 0) {
    lines.push("");
    lines.push(`RECENT TRANSACTIONS (last ${i.recentTransactions.length}):`);
    for (const t of i.recentTransactions) {
      const sign = t.type === "income" ? "+" : "-";
      // Compact date: DD/MM HH:mm (no year, no seconds)
      const d = new Date(t.date);
      const dd = String(d.getUTCDate()).padStart(2, "0");
      const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
      const hh = String(d.getUTCHours()).padStart(2, "0");
      const mi = String(d.getUTCMinutes()).padStart(2, "0");
      const dateStr = `${dd}/${mm} ${hh}:${mi}`;
      const noteStr = t.notes ? ` | note: ${t.notes}` : "";
      lines.push(`  - ${dateStr} | ${sign}${fmt(t.amount, t.currency)} | ${t.title} | ${t.category} | ${t.wallet}${noteStr}`);
    }
  }

  return lines.join("\n");
}

// Format insights as a pretty Telegram message
export function formatInsightsForTelegram(i: SpendingInsights, lang: string): string {
  const c = i.currency;
  const isVi = lang === "vi";
  const lines: string[] = [];

  lines.push(isVi ? `📊 *Tổng quan tài chính - ${i.walletName}*` : `📊 *Financial Overview - ${i.walletName}*`);
  lines.push("");

  // This month
  lines.push(isVi ? "📅 *Tháng này:*" : "📅 *This Month:*");
  lines.push(isVi
    ? `  💰 Thu nhập: ${fmt(i.thisMonth.income, c)}`
    : `  💰 Income: ${fmt(i.thisMonth.income, c)}`);
  lines.push(isVi
    ? `  💸 Chi tiêu: ${fmt(i.thisMonth.expense, c)}`
    : `  💸 Expenses: ${fmt(i.thisMonth.expense, c)}`);
  const net = i.thisMonth.income - i.thisMonth.expense;
  lines.push(isVi
    ? `  ${net >= 0 ? "✅" : "⚠️"} Còn lại: ${fmt(net, c)}`
    : `  ${net >= 0 ? "✅" : "⚠️"} Net: ${fmt(net, c)}`);

  // MoM comparison
  if (i.lastMonth.expense > 0) {
    const diff = i.thisMonth.expense - i.lastMonth.expense;
    const pct = Math.round((diff / i.lastMonth.expense) * 100);
    lines.push("");
    lines.push(isVi
      ? `📈 So với tháng trước: ${pct >= 0 ? "+" : ""}${pct}% chi tiêu`
      : `📈 vs Last month: ${pct >= 0 ? "+" : ""}${pct}% spending`);
  }

  // Top categories
  if (i.thisMonth.topCategories.length > 0) {
    lines.push("");
    lines.push(isVi ? "🏷 *Top chi tiêu:*" : "🏷 *Top Spending:*");
    for (const t of i.thisMonth.topCategories.slice(0, 5)) {
      lines.push(`  • ${t.name}: ${fmt(t.amount, c)} (${t.count}x)`);
    }
  }

  // Budgets
  if (i.budgets.length > 0) {
    lines.push("");
    lines.push(isVi ? "📋 *Ngân sách:*" : "📋 *Budgets:*");
    for (const b of i.budgets) {
      const bar = b.pct > 100 ? "🔴" : b.pct > 80 ? "🟡" : "🟢";
      lines.push(`  ${bar} ${b.category}: ${b.pct}% (${fmt(b.spent, c)}/${fmt(b.limit, c)})`);
    }
  }

  // Health score
  lines.push("");
  const scoreEmoji = i.healthScore >= 70 ? "💪" : i.healthScore >= 50 ? "👍" : "⚠️";
  lines.push(isVi
    ? `${scoreEmoji} *Sức khỏe tài chính: ${i.healthScore}/100*`
    : `${scoreEmoji} *Financial Health: ${i.healthScore}/100*`);

  if (i.thisMonth.income > 0) {
    const savingsRate = Math.round(((i.thisMonth.income - i.thisMonth.expense) / i.thisMonth.income) * 100);
    lines.push(isVi
      ? `💾 Tỷ lệ tiết kiệm: ${savingsRate}%`
      : `💾 Savings rate: ${savingsRate}%`);
  }

  return lines.join("\n");
}
