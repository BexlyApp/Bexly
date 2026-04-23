import type { Supabase } from '../supabase.js';

// ── list_wallets ─────────────────────────────────────────────────────────────

export async function listWallets(supabase: Supabase, userId: string) {
  const { data, error } = await supabase
    .from('wallets')
    .select('cloud_id, name, currency, balance, wallet_type')
    .eq('user_id', userId)
    .eq('is_active', true)
    .order('created_at');
  if (error) throw new Error(error.message);
  return (data ?? []).map((w: any) => ({
    id: w.cloud_id,
    name: w.name,
    currency: w.currency,
    balance: Number(w.balance),
    type: w.wallet_type,
  }));
}

// ── list_transactions ────────────────────────────────────────────────────────

export interface ListTransactionsParams {
  wallet_id?: string;
  start_date?: string;
  end_date?: string;
  category?: string;
  type?: 'income' | 'expense';
  limit?: number;
}

export async function listTransactions(
  supabase: Supabase,
  userId: string,
  params: ListTransactionsParams,
) {
  const limit = params.limit ?? 50;
  let query = supabase
    .from('transactions')
    .select('cloud_id, amount, transaction_type, title, notes, transaction_date, wallet:wallets(name, currency), category:categories(name, icon)')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('transaction_date', { ascending: false })
    .limit(limit);

  if (params.wallet_id) query = query.eq('wallet_id', params.wallet_id);
  if (params.start_date) query = query.gte('transaction_date', params.start_date);
  if (params.end_date) query = query.lte('transaction_date', params.end_date);
  if (params.type) query = query.eq('transaction_type', params.type);

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  let rows = (data ?? []).map((t: any) => ({
    id: t.cloud_id,
    amount: Number(t.amount),
    type: t.transaction_type,
    title: t.title,
    notes: t.notes,
    date: t.transaction_date?.slice(0, 10),
    wallet: t.wallet?.name,
    currency: t.wallet?.currency,
    category: t.category?.name,
    category_icon: t.category?.icon,
  }));

  if (params.category) {
    const cat = params.category.toLowerCase();
    rows = rows.filter((t: any) => t.category?.toLowerCase().includes(cat));
  }
  return rows;
}

// ── get_spending_summary ─────────────────────────────────────────────────────

export interface SpendingSummaryParams {
  period?: 'this_month' | 'last_month' | 'this_year' | 'last_7_days' | 'last_30_days';
  wallet_id?: string;
}

export async function getSpendingSummary(
  supabase: Supabase,
  userId: string,
  params: SpendingSummaryParams,
) {
  const { start, end } = periodToDates(params.period ?? 'this_month');
  let query = supabase
    .from('transactions')
    .select('amount, transaction_type, category:categories(name)')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .gte('transaction_date', start)
    .lte('transaction_date', end);

  if (params.wallet_id) query = query.eq('wallet_id', params.wallet_id);
  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const rows = data ?? [];
  const totalIncome = rows.filter((r: any) => r.transaction_type === 'income').reduce((s: number, r: any) => s + Number(r.amount), 0);
  const totalExpense = rows.filter((r: any) => r.transaction_type === 'expense').reduce((s: number, r: any) => s + Number(r.amount), 0);

  const byCategory: Record<string, number> = {};
  for (const r of rows as any[]) {
    if (r.transaction_type !== 'expense') continue;
    const name = r.category?.name ?? 'Uncategorized';
    byCategory[name] = (byCategory[name] ?? 0) + Number(r.amount);
  }
  const topCategories = Object.entries(byCategory)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, amount]) => ({ name, amount }));

  return {
    period: params.period ?? 'this_month',
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

export async function listBudgets(supabase: Supabase, userId: string, month?: string) {
  const m = month ?? new Date().toISOString().slice(0, 7);
  const monthStart = `${m}-01`;
  // Last day of the month
  const [y, mo] = m.split('-').map(Number);
  const monthEnd = new Date(y, mo, 0).toISOString().slice(0, 10);

  const { data, error } = await supabase
    .from('budgets')
    .select('cloud_id, amount, start_date, end_date, category:categories(name, icon)')
    .eq('user_id', userId)
    .lte('start_date', monthEnd)
    .gte('end_date', monthStart);
  if (error) throw new Error(error.message);
  return (data ?? []).map((b: any) => ({
    id: b.cloud_id,
    category: b.category?.name ?? 'Unknown',
    icon: b.category?.icon,
    budget: Number(b.amount),
    start_date: b.start_date?.slice(0, 10),
    end_date: b.end_date?.slice(0, 10),
  }));
}

// ── list_goals ───────────────────────────────────────────────────────────────

export async function listGoals(supabase: Supabase, userId: string) {
  const { data, error } = await supabase
    .from('goals')
    .select('cloud_id, name, target_amount, current_amount, deadline, wallet:wallets(name, currency)')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('created_at');
  if (error) throw new Error(error.message);
  return (data ?? []).map((g: any) => ({
    id: g.cloud_id,
    name: g.name,
    target: Number(g.target_amount),
    current: Number(g.current_amount ?? 0),
    remaining: Number(g.target_amount) - Number(g.current_amount ?? 0),
    percent: g.target_amount > 0 ? Math.round((Number(g.current_amount ?? 0) / Number(g.target_amount)) * 100) : 0,
    deadline: g.deadline,
    wallet: g.wallet?.name,
    currency: g.wallet?.currency,
  }));
}

// ── list_categories ──────────────────────────────────────────────────────────

export async function listCategories(supabase: Supabase, userId: string, type?: 'income' | 'expense') {
  let query = supabase
    .from('categories')
    .select('cloud_id, name, icon, category_type')
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .order('name');
  if (type) query = query.eq('category_type', type);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return (data ?? []).map((c: any) => ({
    id: c.cloud_id,
    name: c.name,
    icon: c.icon,
    type: c.category_type,
  }));
}

// ── get_balance ──────────────────────────────────────────────────────────────

export async function getBalance(supabase: Supabase, userId: string) {
  const { data, error } = await supabase
    .from('wallets')
    .select('name, balance, currency')
    .eq('user_id', userId)
    .eq('is_active', true);
  if (error) throw new Error(error.message);
  const wallets = (data ?? []).map((w: any) => ({ name: w.name, balance: Number(w.balance), currency: w.currency }));
  return { wallets, total_wallets: wallets.length };
}

// ── helpers ──────────────────────────────────────────────────────────────────

function periodToDates(period: string): { start: string; end: string } {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth();
  switch (period) {
    case 'this_month': return { start: new Date(y, m, 1).toISOString().slice(0, 10), end: new Date(y, m + 1, 0).toISOString().slice(0, 10) };
    case 'last_month': return { start: new Date(y, m - 1, 1).toISOString().slice(0, 10), end: new Date(y, m, 0).toISOString().slice(0, 10) };
    case 'this_year': return { start: `${y}-01-01`, end: `${y}-12-31` };
    case 'last_7_days': { const s = new Date(now); s.setDate(s.getDate() - 6); return { start: s.toISOString().slice(0, 10), end: now.toISOString().slice(0, 10) }; }
    case 'last_30_days': { const s = new Date(now); s.setDate(s.getDate() - 29); return { start: s.toISOString().slice(0, 10), end: now.toISOString().slice(0, 10) }; }
    default: return { start: new Date(y, m, 1).toISOString().slice(0, 10), end: new Date(y, m + 1, 0).toISOString().slice(0, 10) };
  }
}
