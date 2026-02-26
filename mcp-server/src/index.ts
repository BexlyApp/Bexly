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

// ── OAuth 2.0 auth page HTML ──────────────────────────────────────────────────

function buildAuthPage(redirectUri: string, state: string): string {
  const safeRedirect = redirectUri.replace(/'/g, '%27');
  const safeState = state.replace(/'/g, '%27');
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Connect to Bexly</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0f0f0f;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh}
    .card{background:#1a1a1a;border:1px solid #2a2a2a;border-radius:16px;padding:36px;width:380px}
    .logo{width:48px;height:48px;background:#009FA4;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:22px;font-weight:700;margin-bottom:20px}
    h1{font-size:20px;font-weight:600;margin-bottom:8px}
    p{color:#888;font-size:14px;line-height:1.5;margin-bottom:24px}
    label{display:block;font-size:13px;color:#aaa;margin-bottom:6px}
    input{width:100%;padding:12px 14px;background:#111;border:1px solid #333;border-radius:10px;color:#fff;font-size:14px;font-family:monospace;outline:none;transition:border .2s}
    input:focus{border-color:#009FA4}
    .hint{font-size:12px;color:#555;margin-top:6px;margin-bottom:20px}
    button{width:100%;padding:13px;background:#009FA4;border:none;border-radius:10px;color:#fff;font-size:15px;font-weight:600;cursor:pointer;transition:background .2s;margin-top:4px}
    button:hover{background:#00b5bb}
    .err{color:#ff6b6b;font-size:13px;margin-top:10px;display:none}
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">B</div>
    <h1>Connect to Bexly</h1>
    <p>Enter your Bexly API key to allow Claude to access your financial data.</p>
    <label for="key">API Key</label>
    <input id="key" type="password" placeholder="bex_..." autocomplete="off" spellcheck="false">
    <div class="hint">Generate a key in Bexly → Settings → AI Integrations</div>
    <button onclick="connect()">Connect</button>
    <div id="err" class="err"></div>
  </div>
  <script>
    function connect() {
      const key = document.getElementById('key').value.trim();
      const err = document.getElementById('err');
      if (!key.startsWith('bex_')) {
        err.style.display = 'block';
        err.textContent = 'API key must start with bex_';
        return;
      }
      err.style.display = 'none';
      try {
        const u = new URL('${safeRedirect}');
        u.searchParams.set('code', key);
        if ('${safeState}') u.searchParams.set('state', '${safeState}');
        window.location.href = u.toString();
      } catch(e) {
        err.style.display = 'block';
        err.textContent = 'Invalid redirect URL. Please try reconnecting from Claude.';
      }
    }
    document.getElementById('key').addEventListener('keydown', e => { if (e.key === 'Enter') connect(); });
  </script>
</body>
</html>`;
}

// ── Workers fetch export ──────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const origin = url.origin;

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── OAuth discovery endpoints ─────────────────────────────────────────────
    if (url.pathname === '/.well-known/oauth-protected-resource') {
      return Response.json({
        resource: origin,
        authorization_servers: [origin],
        bearer_methods_supported: ['header'],
      }, { headers: CORS_HEADERS });
    }

    if (url.pathname === '/.well-known/oauth-authorization-server') {
      return Response.json({
        issuer: origin,
        authorization_endpoint: `${origin}/authorize`,
        token_endpoint: `${origin}/token`,
        registration_endpoint: `${origin}/register`,
        response_types_supported: ['code'],
        grant_types_supported: ['authorization_code'],
        code_challenge_methods_supported: ['S256'],
        token_endpoint_auth_methods_supported: ['none'],
        scopes_supported: ['bexly'],
      }, { headers: CORS_HEADERS });
    }

    // ── OAuth Dynamic Client Registration (RFC 7591) ──────────────────────────
    if (url.pathname === '/register' && request.method === 'POST') {
      let body: any = {};
      try { body = await request.json(); } catch { /* ignore */ }

      // Generate a random client_id — we don't use it for validation,
      // our security is based on the bex_ API key entered by the user.
      const clientId = crypto.randomUUID();

      return Response.json({
        client_id: clientId,
        client_name: body.client_name ?? 'MCP Client',
        redirect_uris: body.redirect_uris ?? [],
        grant_types: ['authorization_code'],
        response_types: ['code'],
        token_endpoint_auth_method: 'none',
        scope: 'bexly',
      }, { status: 201, headers: CORS_HEADERS });
    }

    // ── OAuth authorize: show API key input page ──────────────────────────────
    if (url.pathname === '/authorize') {
      const redirectUri = url.searchParams.get('redirect_uri') ?? '';
      const state = url.searchParams.get('state') ?? '';
      return new Response(buildAuthPage(redirectUri, state), {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    // ── OAuth token: exchange code (= API key) for access_token ──────────────
    if (url.pathname === '/token' && request.method === 'POST') {
      let code = '';
      const ct = request.headers.get('content-type') ?? '';
      if (ct.includes('application/x-www-form-urlencoded')) {
        const params = new URLSearchParams(await request.text());
        code = params.get('code') ?? '';
      } else {
        const body: any = await request.json().catch(() => ({}));
        code = body.code ?? '';
      }
      if (!code) {
        return Response.json({ error: 'invalid_request', error_description: 'Missing code' }, { status: 400, headers: CORS_HEADERS });
      }
      return Response.json({
        access_token: code,
        token_type: 'bearer',
        scope: 'bexly',
      }, { headers: CORS_HEADERS });
    }

    // ── Health ────────────────────────────────────────────────────────────────
    if (url.pathname === '/health') {
      return Response.json({ status: 'ok', service: 'bexly-mcp' }, { headers: CORS_HEADERS });
    }

    if (url.pathname !== '/mcp') {
      return new Response('Not found', { status: 404 });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // ── Auth ──────────────────────────────────────────────────────────────────
    const rawKey = extractApiKey(request);
    if (!rawKey) {
      return Response.json(
        { error: 'unauthorized' },
        {
          status: 401,
          headers: {
            ...CORS_HEADERS,
            'WWW-Authenticate': `Bearer resource_metadata="${origin}/.well-known/oauth-protected-resource"`,
          },
        },
      );
    }

    const supabase = createSupabase(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY);
    const userId = await validateApiKey(supabase, rawKey);
    if (!userId) {
      return Response.json({ error: 'Invalid or inactive API key.' }, { status: 403, headers: CORS_HEADERS });
    }

    // ── Parse + handle MCP ────────────────────────────────────────────────────
    let body: any;
    try {
      body = await request.json();
    } catch {
      return Response.json({ error: 'Invalid JSON body' }, { status: 400, headers: CORS_HEADERS });
    }

    const result = await handleMcp(body, userId, supabase);

    if (result === null) {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    return Response.json(result, { headers: CORS_HEADERS });
  },
};
