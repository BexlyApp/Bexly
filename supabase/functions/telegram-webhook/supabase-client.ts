import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Create Supabase client from environment variables
export function createSupabaseClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  return createClient(supabaseUrl, supabaseKey, {
    db: { schema: "bexly" },
  });
}

// Get user ID from Telegram/Messenger platform ID
export async function getUserIdFromPlatform(
  platform: "telegram" | "messenger",
  platformUserId: string,
) {
  const supabase = createSupabaseClient();

  const { data, error } = await supabase
    .from("user_integrations")
    .select("user_id")
    .eq("platform", platform)
    .eq("platform_user_id", platformUserId)
    .single();

  if (error || !data) {
    return null;
  }

  return data.user_id;
}

// Get user's wallets
export async function getUserWallets(userId: string) {
  const supabase = createSupabaseClient();

  const { data, error } = await supabase
    .from("wallets")
    .select("*")
    .eq("user_id", userId)
    .order("is_default", { ascending: false });

  if (error) {
    console.error("Error fetching wallets:", error);
    return [];
  }

  return data || [];
}

// Get user's categories
export async function getUserCategories(userId: string) {
  const supabase = createSupabaseClient();

  const { data, error } = await supabase
    .from("categories")
    .select("*")
    .eq("user_id", userId);

  if (error) {
    console.error("Error fetching categories:", error);
    return [];
  }

  return data || [];
}

// Create transaction
export async function createTransaction(
  userId: string,
  walletId: string,
  categoryId: string,
  amount: number,
  type: "expense" | "income",
  description: string | null,
  transactionDate: string,
) {
  const supabase = createSupabaseClient();

  const { data, error } = await supabase
    .from("transactions")
    .insert({
      user_id: userId,
      wallet_id: walletId,
      category_id: categoryId,
      amount,
      type,
      description,
      transaction_date: transactionDate,
    })
    .select()
    .single();

  if (error) {
    console.error("Error creating transaction:", error);
    throw error;
  }

  return data;
}

// Update wallet balance
export async function updateWalletBalance(
  walletId: string,
  amountChange: number,
) {
  const supabase = createSupabaseClient();

  // Get current balance
  const { data: wallet, error: fetchError } = await supabase
    .from("wallets")
    .select("balance")
    .eq("cloud_id", walletId)
    .single();

  if (fetchError) {
    console.error("Error fetching wallet:", fetchError);
    throw fetchError;
  }

  const newBalance = wallet.balance + amountChange;

  // Update balance
  const { error: updateError } = await supabase
    .from("wallets")
    .update({ balance: newBalance })
    .eq("cloud_id", walletId);

  if (updateError) {
    console.error("Error updating wallet balance:", updateError);
    throw updateError;
  }

  return newBalance;
}
