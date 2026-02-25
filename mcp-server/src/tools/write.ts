import type { Supabase } from '../supabase.js';

// ── add_transaction ──────────────────────────────────────────────────────────

export interface AddTransactionParams {
  wallet_id: number;
  amount: number;
  type: 'income' | 'expense';
  category_id: number;
  note?: string;
  date?: string;
}

export async function addTransaction(supabase: Supabase, userId: string, params: AddTransactionParams) {
  const date = params.date ?? new Date().toISOString().slice(0, 10);
  const { data, error } = await supabase
    .from('transactions')
    .insert({ user_id: userId, wallet_id: params.wallet_id, amount: params.amount, type: params.type, category_id: params.category_id, note: params.note ?? null, date, source: 'mcp' })
    .select('id, amount, type, note, date')
    .single();
  if (error) throw new Error(error.message);
  return { success: true, transaction: data };
}

// ── update_transaction ───────────────────────────────────────────────────────

export interface UpdateTransactionParams {
  id: number;
  amount?: number;
  type?: 'income' | 'expense';
  category_id?: number;
  note?: string;
  date?: string;
}

export async function updateTransaction(supabase: Supabase, userId: string, params: UpdateTransactionParams) {
  const { id, ...updates } = params;
  const { data: existing } = await supabase.from('transactions').select('id').eq('id', id).eq('user_id', userId).eq('is_deleted', false).single();
  if (!existing) throw new Error('Transaction not found or access denied.');
  const { data, error } = await supabase
    .from('transactions')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select('id, amount, type, note, date')
    .single();
  if (error) throw new Error(error.message);
  return { success: true, transaction: data };
}

// ── delete_transaction ───────────────────────────────────────────────────────

export async function deleteTransaction(supabase: Supabase, userId: string, id: number) {
  const { data: existing } = await supabase.from('transactions').select('id, amount, type, note, date').eq('id', id).eq('user_id', userId).eq('is_deleted', false).single();
  if (!existing) throw new Error('Transaction not found or access denied.');
  const { error } = await supabase.from('transactions').update({ is_deleted: true, updated_at: new Date().toISOString() }).eq('id', id);
  if (error) throw new Error(error.message);
  return { success: true, deleted: existing, message: `Deleted: ${existing.type} ${existing.amount} on ${existing.date}` };
}
