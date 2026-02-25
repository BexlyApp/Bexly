import { z } from 'zod';
import { supabase } from '../supabase.js';

// ── add_transaction ──────────────────────────────────────────────────────────

export const addTransactionSchema = z.object({
  wallet_id: z.number().describe('ID of the wallet'),
  amount: z.number().positive().describe('Amount (positive number)'),
  type: z.enum(['income', 'expense']).describe('Transaction type'),
  category_id: z.number().describe('ID of the category'),
  note: z.string().optional().describe('Optional note or description'),
  date: z
    .string()
    .optional()
    .describe('Date ISO8601 e.g. 2025-03-15, defaults to today'),
});

export async function addTransaction(
  userId: string,
  params: z.infer<typeof addTransactionSchema>,
) {
  const date = params.date ?? new Date().toISOString().slice(0, 10);

  const { data, error } = await supabase
    .from('transactions')
    .insert({
      user_id: userId,
      wallet_id: params.wallet_id,
      amount: params.amount,
      type: params.type,
      category_id: params.category_id,
      note: params.note ?? null,
      date,
      source: 'mcp',
    })
    .select('id, amount, type, note, date')
    .single();

  if (error) throw new Error(error.message);
  return { success: true, transaction: data };
}

// ── update_transaction ───────────────────────────────────────────────────────

export const updateTransactionSchema = z.object({
  id: z.number().describe('Transaction ID to update'),
  amount: z.number().positive().optional(),
  type: z.enum(['income', 'expense']).optional(),
  category_id: z.number().optional(),
  note: z.string().optional(),
  date: z.string().optional().describe('Date ISO8601'),
});

export async function updateTransaction(
  userId: string,
  params: z.infer<typeof updateTransactionSchema>,
) {
  const { id, ...updates } = params;

  // Verify ownership
  const { data: existing } = await supabase
    .from('transactions')
    .select('id')
    .eq('id', id)
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .single();

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

export const deleteTransactionSchema = z.object({
  id: z.number().describe('Transaction ID to delete'),
});

export async function deleteTransaction(
  userId: string,
  params: z.infer<typeof deleteTransactionSchema>,
) {
  // Verify ownership
  const { data: existing } = await supabase
    .from('transactions')
    .select('id, amount, type, note, date')
    .eq('id', params.id)
    .eq('user_id', userId)
    .eq('is_deleted', false)
    .single();

  if (!existing) throw new Error('Transaction not found or access denied.');

  const { error } = await supabase
    .from('transactions')
    .update({ is_deleted: true, updated_at: new Date().toISOString() })
    .eq('id', params.id);

  if (error) throw new Error(error.message);

  return {
    success: true,
    deleted: existing,
    message: `Deleted transaction: ${existing.type} ${existing.amount} on ${existing.date}`,
  };
}
