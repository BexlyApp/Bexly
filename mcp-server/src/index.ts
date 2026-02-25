import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { validateApiKey } from './supabase.js';
import {
  listWalletsSchema, listWallets,
  listTransactionsSchema, listTransactions,
  getSpendingSummarySchema, getSpendingSummary,
  listBudgetsSchema, listBudgets,
  listGoalsSchema, listGoals,
  listCategoriesSchema, listCategories,
  getBalanceSchema, getBalance,
} from './tools/read.js';
import {
  addTransactionSchema, addTransaction,
  updateTransactionSchema, updateTransaction,
  deleteTransactionSchema, deleteTransaction,
} from './tools/write.js';

const PORT = parseInt(process.env.PORT ?? '8080', 10);

// Extract API key from request headers or query string
function extractApiKey(req: IncomingMessage): string | null {
  // Authorization: Bearer bex_live_xxx
  const auth = req.headers['authorization'];
  if (auth?.startsWith('Bearer ')) return auth.slice(7);

  // X-API-Key: bex_live_xxx
  const header = req.headers['x-api-key'];
  if (typeof header === 'string') return header;

  // ?key=bex_live_xxx (for SSE URL pasting in Claude.ai web)
  const url = new URL(req.url ?? '/', `http://localhost`);
  const queryKey = url.searchParams.get('key');
  if (queryKey) return queryKey;

  return null;
}

function createBexlyMcpServer(userId: string): McpServer {
  const server = new McpServer({
    name: 'bexly',
    version: '1.0.0',
  });

  // ── Read Tools ─────────────────────────────────────────────────────────────

  server.tool(
    'list_wallets',
    'List all your Bexly wallets with balances and currencies',
    listWalletsSchema.shape,
    async () => {
      const data = await listWallets(userId);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'list_transactions',
    'Query your transactions with optional filters (wallet, date range, category, type)',
    listTransactionsSchema.shape,
    async (params) => {
      const data = await listTransactions(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'get_spending_summary',
    'Get income/expense summary and top spending categories for a time period',
    getSpendingSummarySchema.shape,
    async (params) => {
      const data = await getSpendingSummary(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'list_budgets',
    'Get budgets with current spending progress for a month',
    listBudgetsSchema.shape,
    async (params) => {
      const data = await listBudgets(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'list_goals',
    'List your savings goals with progress',
    listGoalsSchema.shape,
    async () => {
      const data = await listGoals(userId);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'list_categories',
    'List transaction categories (income or expense)',
    listCategoriesSchema.shape,
    async (params) => {
      const data = await listCategories(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'get_balance',
    'Get current balance of all wallets',
    getBalanceSchema.shape,
    async () => {
      const data = await getBalance(userId);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  // ── Write Tools ────────────────────────────────────────────────────────────

  server.tool(
    'add_transaction',
    'Add a new income or expense transaction to a wallet',
    addTransactionSchema.shape,
    async (params) => {
      const data = await addTransaction(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'update_transaction',
    'Update an existing transaction (amount, category, note, date)',
    updateTransactionSchema.shape,
    async (params) => {
      const data = await updateTransaction(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  server.tool(
    'delete_transaction',
    'Delete (soft-delete) a transaction by ID',
    deleteTransactionSchema.shape,
    async (params) => {
      const data = await deleteTransaction(userId, params as any);
      return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };
    },
  );

  return server;
}

// ── HTTP Server ───────────────────────────────────────────────────────────────

const httpServer = createServer(async (req: IncomingMessage, res: ServerResponse) => {
  const url = new URL(req.url ?? '/', `http://localhost`);

  // Health check
  if (url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'bexly-mcp' }));
    return;
  }

  // Only handle /mcp endpoint
  if (url.pathname !== '/mcp' && url.pathname !== '/') {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  // CORS headers (for Claude.ai web)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Auth
  const rawKey = extractApiKey(req);
  if (!rawKey) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Missing API key. Provide via Authorization: Bearer <key> or X-API-Key header.' }));
    return;
  }

  const userId = await validateApiKey(rawKey);
  if (!userId) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Invalid or inactive API key.' }));
    return;
  }

  // Create per-request MCP server scoped to this user
  const mcpServer = createBexlyMcpServer(userId);
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined, // stateless
  });

  res.on('close', () => {
    transport.close();
    mcpServer.close();
  });

  await mcpServer.connect(transport);
  await transport.handleRequest(req, res);
});

httpServer.listen(PORT, () => {
  console.log(`Bexly MCP Server running on port ${PORT}`);
  console.log(`Endpoint: http://localhost:${PORT}/mcp`);
});
