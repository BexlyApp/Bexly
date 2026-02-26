import type { Supabase } from '../supabase.js';

// ── add_transaction ──────────────────────────────────────────────────────────

export interface AddTransactionParams {
  wallet_id: string;    // cloud_id UUID of the wallet
  amount: number;
  type: 'income' | 'expense';
  category_id: string;  // cloud_id UUID of the category
  note?: string;
  date?: string;
}

export async function addTransaction(supabase: Supabase, userId: string, params: AddTransactionParams) {
  const date = params.date ?? new Date().toISOString().slice(0, 10);
  const { data, error } = await supabase
    .from('transactions')
    .insert({
      user_id: userId,
      wallet_id: params.wallet_id,
      category_id: params.category_id,
      amount: params.amount,
      transaction_type: params.type,
      title: params.note ?? '',
      transaction_date: date,
      is_deleted: false,
      updated_at: new Date().toISOString(),
    })
    .select('cloud_id, amount, transaction_type, title, transaction_date')
    .single();
  if (error) throw new Error(error.message);
  return {
    success: true,
    transaction: {
      id: data.cloud_id,
      amount: data.amount,
      type: data.transaction_type,
      title: data.title,
      date: data.transaction_date?.slice(0, 10),
    },
  };
}

// ── update_transaction ───────────────────────────────────────────────────────

export interface UpdateTransactionParams {
  id: string;           // cloud_id UUID
  amount?: number;
  type?: 'income' | 'expense';
  category_id?: string;
  note?: string;
  date?: string;
}

export async function updateTransaction(supabase: Supabase, userId: string, params: UpdateTransactionParams) {
  const { id, type, note, date, category_id, ...rest } = params;

  // Verify ownership
  const { data: existing } = await supabase
    .from('transactions')
    .select('cloud_id')
    .eq('cloud_id', id)
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .single();
  if (!existing) throw new Error('Transaction not found or access denied.');

  const updates: Record<string, any> = { ...rest, updated_at: new Date().toISOString() };
  if (type) updates.transaction_type = type;
  if (note !== undefined) updates.title = note;
  if (date) updates.transaction_date = date;
  if (category_id) updates.category_id = category_id;

  const { data, error } = await supabase
    .from('transactions')
    .update(updates)
    .eq('cloud_id', id)
    .select('cloud_id, amount, transaction_type, title, transaction_date')
    .single();
  if (error) throw new Error(error.message);
  return {
    success: true,
    transaction: {
      id: data.cloud_id,
      amount: data.amount,
      type: data.transaction_type,
      title: data.title,
      date: data.transaction_date?.slice(0, 10),
    },
  };
}

// ── delete_transaction ───────────────────────────────────────────────────────

export async function deleteTransaction(supabase: Supabase, userId: string, id: string) {
  const { data: existing } = await supabase
    .from('transactions')
    .select('cloud_id, amount, transaction_type, title, transaction_date')
    .eq('cloud_id', id)
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .single();
  if (!existing) throw new Error('Transaction not found or access denied.');

  const { error } = await supabase
    .from('transactions')
    .update({ is_deleted: true, updated_at: new Date().toISOString() })
    .eq('cloud_id', id);
  if (error) throw new Error(error.message);

  return {
    success: true,
    deleted: {
      id: existing.cloud_id,
      amount: existing.amount,
      type: existing.transaction_type,
      title: existing.title,
      date: existing.transaction_date?.slice(0, 10),
    },
  };
}
