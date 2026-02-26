import { createSupabase, validateApiKey } from './supabase.js';
import { listWallets, listTransactions, getSpendingSummary, listBudgets, listGoals, listCategories, getBalance } from './tools/read.js';
import { addTransaction, updateTransaction, deleteTransaction } from './tools/write.js';

export interface Env {
  SUPABASE_URL: string;
  SUPABASE_SECRET_KEY: string;
}

// ── Tool definitions (for tools/list response) ───────────────────────────────

const TOOLS = [
  {
    name: 'list_wallets',
    description: 'List all your Bexly wallets with balances and currencies',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'list_transactions',
    description: 'Query transactions with optional filters (wallet, date range, category, type)',
    inputSchema: {
      type: 'object',
      properties: {
        wallet_id: { type: 'string', description: 'Filter by wallet ID (UUID from list_wallets)' },
        start_date: { type: 'string', description: 'Start date YYYY-MM-DD' },
        end_date: { type: 'string', description: 'End date YYYY-MM-DD' },
        category: { type: 'string', description: 'Filter by category name (partial match)' },
        type: { type: 'string', enum: ['income', 'expense'], description: 'Transaction type' },
        limit: { type: 'number', description: 'Max results (default 50, max 200)' },
      },
    },
  },
  {
    name: 'get_spending_summary',
    description: 'Get income/expense summary and top spending categories for a time period',
    inputSchema: {
      type: 'object',
      properties: {
        period: { type: 'string', enum: ['this_month', 'last_month', 'this_year', 'last_7_days', 'last_30_days'], description: 'Time period (default: this_month)' },
        wallet_id: { type: 'number', description: 'Limit to a specific wallet' },
      },
    },
  },
  {
    name: 'list_budgets',
    description: 'Get budgets with spending progress for a month',
    inputSchema: {
      type: 'object',
      properties: {
        month: { type: 'string', description: 'Month YYYY-MM (default: current month)' },
      },
    },
  },
  {
    name: 'list_goals',
    description: 'List savings goals with progress',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'list_categories',
    description: 'List transaction categories',
    inputSchema: {
      type: 'object',
      properties: {
        type: { type: 'string', enum: ['income', 'expense'], description: 'Filter by type' },
      },
    },
  },
  {
    name: 'get_balance',
    description: 'Get current balance of all wallets',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'add_transaction',
    description: 'Add a new income or expense transaction',
    inputSchema: {
      type: 'object',
      required: ['wallet_id', 'amount', 'type', 'category_id'],
      properties: {
        wallet_id: { type: 'string', description: 'Wallet ID (UUID from list_wallets)' },
        amount: { type: 'number', description: 'Amount (positive)' },
        type: { type: 'string', enum: ['income', 'expense'] },
        category_id: { type: 'string', description: 'Category ID (UUID from list_categories)' },
        note: { type: 'string', description: 'Optional note/title' },
        date: { type: 'string', description: 'Date YYYY-MM-DD (default: today)' },
      },
    },
  },
  {
    name: 'update_transaction',
    description: 'Update an existing transaction',
    inputSchema: {
      type: 'object',
      required: ['id'],
      properties: {
        id: { type: 'string', description: 'Transaction ID (UUID from list_transactions)' },
        amount: { type: 'number' },
        type: { type: 'string', enum: ['income', 'expense'] },
        category_id: { type: 'string', description: 'Category ID (UUID)' },
        note: { type: 'string' },
        date: { type: 'string' },
      },
    },
  },
  {
    name: 'delete_transaction',
    description: 'Delete a transaction by ID',
    inputSchema: {
      type: 'object',
      required: ['id'],
      properties: {
        id: { type: 'string', description: 'Transaction ID (UUID from list_transactions)' },
      },
    },
  },
];

// ── Tool dispatcher ───────────────────────────────────────────────────────────

async function callTool(name: string, args: any, userId: string, supabase: any): Promise<any> {
  switch (name) {
    case 'list_wallets':         return listWallets(supabase, userId);
    case 'list_transactions':    return listTransactions(supabase, userId, args);
    case 'get_spending_summary': return getSpendingSummary(supabase, userId, args);
    case 'list_budgets':         return listBudgets(supabase, userId, args.month);
    case 'list_goals':           return listGoals(supabase, userId);
    case 'list_categories':      return listCategories(supabase, userId, args.type);
    case 'get_balance':          return getBalance(supabase, userId);
    case 'add_transaction':      return addTransaction(supabase, userId, args);
    case 'update_transaction':   return updateTransaction(supabase, userId, args);
    case 'delete_transaction':   return deleteTransaction(supabase, userId, args.id);
    default: throw new Error(`Unknown tool: ${name}`);
  }
}

// ── MCP JSON-RPC handler ──────────────────────────────────────────────────────

async function handleMcp(body: any, userId: string, supabase: any): Promise<any> {
  const { jsonrpc, id, method, params } = body;

  try {
    switch (method) {
      case 'initialize':
        return {
          jsonrpc: '2.0', id,
          result: {
            protocolVersion: '2024-11-05',
            serverInfo: { name: 'bexly', version: '1.0.0' },
            capabilities: { tools: {} },
          },
        };

      case 'tools/list':
        return { jsonrpc: '2.0', id, result: { tools: TOOLS } };

      case 'tools/call': {
        const result = await callTool(params.name, params.arguments ?? {}, userId, supabase);
        return {
          jsonrpc: '2.0', id,
          result: { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] },
        };
      }

      case 'ping':
        return { jsonrpc: '2.0', id, result: {} };

      case 'notifications/initialized':
      case 'notifications/cancelled':
        return null; // no response for notifications

      default:
        return { jsonrpc: '2.0', id, error: { code: -32601, message: `Method not found: ${method}` } };
    }
  } catch (err: any) {
    return { jsonrpc: '2.0', id, error: { code: -32000, message: err.message } };
  }
}

// ── Auth helper ───────────────────────────────────────────────────────────────

function extractApiKey(request: Request): string | null {
  const auth = request.headers.get('authorization');
  if (auth?.startsWith('Bearer ')) return auth.slice(7);
  const header = request.headers.get('x-api-key');
  if (header) return header;
  const url = new URL(request.url);
  return url.searchParams.get('key');
}

// ── CORS ──────────────────────────────────────────────────────────────────────

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
};

// ── Workers fetch export ──────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (url.pathname === '/health') {
      return Response.json({ status: 'ok', service: 'bexly-mcp' }, { headers: CORS_HEADERS });
    }

    if (url.pathname !== '/mcp') {
      return new Response('Not found', { status: 404 });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // Auth
    const rawKey = extractApiKey(request);
    if (!rawKey) {
      return Response.json({ error: 'Missing API key. Use Authorization: Bearer <key> or X-API-Key header.' }, { status: 401, headers: CORS_HEADERS });
    }

    const supabase = createSupabase(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY);
    const userId = await validateApiKey(supabase, rawKey);
    if (!userId) {
      return Response.json({ error: 'Invalid or inactive API key.' }, { status: 403, headers: CORS_HEADERS });
    }

    // Parse + handle MCP
    let body: any;
    try {
      body = await request.json();
    } catch {
      return Response.json({ error: 'Invalid JSON body' }, { status: 400, headers: CORS_HEADERS });
    }

    const result = await handleMcp(body, userId, supabase);

    // Notifications return null (no response)
    if (result === null) {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    return Response.json(result, { headers: CORS_HEADERS });
  },
};
