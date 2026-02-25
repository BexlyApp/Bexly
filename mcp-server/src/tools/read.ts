import { z } from 'zod';
import { supabase } from '../supabase.js';

// ── list_wallets ─────────────────────────────────────────────────────────────

export const listWalletsSchema = z.object({});

export async function listWallets(userId: string) {
  const { data, error } = await supabase
    .from('wallets')
    .select('id, name, currency, balance, type, color, is_deleted')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('created_at');

  if (error) throw new Error(error.message);
  return data ?? [];
}

// ── list_transactions ────────────────────────────────────────────────────────

export const listTransactionsSchema = z.object({
  wallet_id: z.number().optional().describe('Filter by wallet ID'),
  start_date: z.string().optional().describe('Start date ISO8601 e.g. 2025-01-01'),
  end_date: z.string().optional().describe('End date ISO8601 e.g. 2025-01-31'),
  category: z.string().optional().describe('Filter by category name'),
  type: z.enum(['income', 'expense']).optional().describe('income or expense'),
  limit: z.number().min(1).max(200).default(50).describe('Max results, default 50'),
});

export async function listTransactions(
  userId: string,
  params: z.infer<typeof listTransactionsSchema>,
) {
  let query = supabase
    .from('transactions')
    .select(
      `id, amount, type, note, date,
       wallet:wallets(name, currency),
       category:categories(name, icon)`,
    )
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('date', { ascending: false })
    .limit(params.limit);

  if (params.wallet_id) query = query.eq('wallet_id', params.wallet_id);
  if (params.start_date) query = query.gte('date', params.start_date);
  if (params.end_date) query = query.lte('date', params.end_date);
  if (params.type) query = query.eq('type', params.type);

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  let results = data ?? [];

  // Filter by category name if provided (join filter)
  if (params.category) {
    const cat = params.category.toLowerCase();
    results = results.filter((t: any) =>
      t.category?.name?.toLowerCase().includes(cat),
    );
  }

  return results;
}

// ── get_spending_summary ─────────────────────────────────────────────────────

export const getSpendingSummarySchema = z.object({
  period: z
    .enum(['this_month', 'last_month', 'this_year', 'last_7_days', 'last_30_days'])
    .default('this_month')
    .describe('Time period for the summary'),
  wallet_id: z.number().optional().describe('Limit to specific wallet'),
});

export async function getSpendingSummary(
  userId: string,
  params: z.infer<typeof getSpendingSummarySchema>,
) {
  const { start, end } = periodToDates(params.period);

  let query = supabase
    .from('transactions')
    .select('amount, type, category:categories(name)')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .gte('date', start)
    .lte('date', end);

  if (params.wallet_id) query = query.eq('wallet_id', params.wallet_id);

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const rows = data ?? [];

  const totalIncome = rows
    .filter((r: any) => r.type === 'income')
    .reduce((sum: number, r: any) => sum + Number(r.amount), 0);

  const totalExpense = rows
    .filter((r: any) => r.type === 'expense')
    .reduce((sum: number, r: any) => sum + Number(r.amount), 0);

  // Group expenses by category
  const byCategory: Record<string, number> = {};
  for (const r of rows as any[]) {
    if (r.type !== 'expense') continue;
    const catName = r.category?.name ?? 'Uncategorized';
    byCategory[catName] = (byCategory[catName] ?? 0) + Number(r.amount);
  }

  const topCategories = Object.entries(byCategory)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, amount]) => ({ name, amount }));

  return {
    period: params.period,
    start_date: start,
    end_date: end,
    total_income: totalIncome,
    total_expense: totalExpense,
    net: totalIncome - totalExpense,
    top_expense_categories: topCategories,
    transaction_count: rows.length,
  };
}

// ── list_budgets ─────────────────────────────────────────────────────────────

export const listBudgetsSchema = z.object({
  month: z
    .string()
    .optional()
    .describe('Month in YYYY-MM format, defaults to current month'),
});

export async function listBudgets(
  userId: string,
  params: z.infer<typeof listBudgetsSchema>,
) {
  const month = params.month ?? new Date().toISOString().slice(0, 7);

  const { data, error } = await supabase
    .from('budgets')
    .select(`id, amount, spent, period, category:categories(name, icon)`)
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .like('period', `${month}%`);

  if (error) throw new Error(error.message);

  return (data ?? []).map((b: any) => ({
    id: b.id,
    category: b.category?.name ?? 'Unknown',
    icon: b.category?.icon,
    budget: Number(b.amount),
    spent: Number(b.spent ?? 0),
    remaining: Number(b.amount) - Number(b.spent ?? 0),
    percent_used: b.amount > 0 ? Math.round((Number(b.spent ?? 0) / Number(b.amount)) * 100) : 0,
  }));
}

// ── list_goals ───────────────────────────────────────────────────────────────

export const listGoalsSchema = z.object({});

export async function listGoals(userId: string) {
  const { data, error } = await supabase
    .from('goals')
    .select('id, name, target_amount, current_amount, deadline, wallet:wallets(name, currency)')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('created_at');

  if (error) throw new Error(error.message);

  return (data ?? []).map((g: any) => ({
    id: g.id,
    name: g.name,
    target: Number(g.target_amount),
    current: Number(g.current_amount ?? 0),
    remaining: Number(g.target_amount) - Number(g.current_amount ?? 0),
    percent: g.target_amount > 0
      ? Math.round((Number(g.current_amount ?? 0) / Number(g.target_amount)) * 100)
      : 0,
    deadline: g.deadline,
    wallet: g.wallet?.name,
    currency: g.wallet?.currency,
  }));
}

// ── list_categories ──────────────────────────────────────────────────────────

export const listCategoriesSchema = z.object({
  type: z.enum(['income', 'expense']).optional(),
});

export async function listCategories(
  userId: string,
  params: z.infer<typeof listCategoriesSchema>,
) {
  let query = supabase
    .from('categories')
    .select('id, name, icon, type')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('name');

  if (params.type) query = query.eq('type', params.type);

  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return data ?? [];
}

// ── get_balance ──────────────────────────────────────────────────────────────

export const getBalanceSchema = z.object({});

export async function getBalance(userId: string) {
  const { data, error } = await supabase
    .from('wallets')
    .select('name, balance, currency')
    .eq('user_id', userId)
    .eq('is_deleted', false);

  if (error) throw new Error(error.message);

  const wallets = data ?? [];
  return {
    wallets: wallets.map((w: any) => ({
      name: w.name,
      balance: Number(w.balance),
      currency: w.currency,
    })),
    total_wallets: wallets.length,
  };
}

// ── helpers ──────────────────────────────────────────────────────────────────

function periodToDates(period: string): { start: string; end: string } {
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth();

  switch (period) {
    case 'this_month':
      return {
        start: new Date(y, m, 1).toISOString().slice(0, 10),
        end: new Date(y, m + 1, 0).toISOString().slice(0, 10),
      };
    case 'last_month':
      return {
        start: new Date(y, m - 1, 1).toISOString().slice(0, 10),
        end: new Date(y, m, 0).toISOString().slice(0, 10),
      };
    case 'this_year':
      return {
        start: `${y}-01-01`,
        end: `${y}-12-31`,
      };
    case 'last_7_days': {
      const s = new Date(now);
      s.setDate(s.getDate() - 6);
      return {
        start: s.toISOString().slice(0, 10),
        end: now.toISOString().slice(0, 10),
      };
    }
    case 'last_30_days': {
      const s = new Date(now);
      s.setDate(s.getDate() - 29);
      return {
        start: s.toISOString().slice(0, 10),
        end: now.toISOString().slice(0, 10),
      };
    }
    default:
      return {
        start: new Date(y, m, 1).toISOString().slice(0, 10),
        end: new Date(y, m + 1, 0).toISOString().slice(0, 10),
      };
  }
}
