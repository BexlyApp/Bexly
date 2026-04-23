# DOS-Me Bank API Specification

## Overview
Bexly needs API endpoints to manage bank account connections via Stripe Financial Connections. These endpoints handle creating connection sessions, storing linked accounts, syncing transactions, and disconnecting accounts.

**Base Path:** `/api/bexly/bank`

## Required Environment Variables
- `STRIPE_SECRET_KEY` - Stripe secret key with Financial Connections permissions

## Database Schema (PostgreSQL)

### Table: `stripe_customers`
Maps users to their Stripe customer IDs.

```sql
CREATE TABLE stripe_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(128) NOT NULL UNIQUE REFERENCES users(uid),
  stripe_customer_id VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stripe_customers_user_id ON stripe_customers(user_id);
```

### Table: `linked_bank_accounts`
Stores user's linked bank accounts from Stripe Financial Connections.

```sql
CREATE TABLE linked_bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(128) NOT NULL REFERENCES users(uid),
  stripe_account_id VARCHAR(255) NOT NULL UNIQUE,
  institution_name VARCHAR(255),
  display_name VARCHAR(255),
  last4 VARCHAR(4),
  category VARCHAR(50),        -- checking, savings, credit, etc.
  subcategory VARCHAR(50),
  status VARCHAR(50),          -- active, inactive, disconnected
  balance_amount INTEGER,      -- in cents
  balance_currency VARCHAR(3), -- USD, etc.
  balance_as_of TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_linked_bank_accounts_user_id ON linked_bank_accounts(user_id);
CREATE INDEX idx_linked_bank_accounts_status ON linked_bank_accounts(status);
```

### Table: `bank_transactions`
Stores raw transactions synced from Stripe.

```sql
CREATE TABLE bank_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(128) NOT NULL REFERENCES users(uid),
  stripe_transaction_id VARCHAR(255) NOT NULL UNIQUE,
  stripe_account_id VARCHAR(255) NOT NULL REFERENCES linked_bank_accounts(stripe_account_id),
  amount INTEGER NOT NULL,           -- in cents (negative for debits)
  currency VARCHAR(3) NOT NULL,
  description TEXT,
  status VARCHAR(50),                -- pending, posted
  category VARCHAR(100),             -- Stripe's category
  subcategory VARCHAR(100),
  transacted_at TIMESTAMPTZ NOT NULL,
  posted_at TIMESTAMPTZ,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  raw_data JSONB                     -- Full Stripe transaction object
);

CREATE INDEX idx_bank_transactions_user_id ON bank_transactions(user_id);
CREATE INDEX idx_bank_transactions_account_id ON bank_transactions(stripe_account_id);
CREATE INDEX idx_bank_transactions_transacted_at ON bank_transactions(transacted_at);
```

---

## API Endpoints

### 1. Create Financial Connection Session
Creates a Stripe Financial Connections session for linking bank accounts.

**Endpoint:** `POST /api/bexly/bank/session`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "returnUrl": "bexly://bank-connections/callback"  // optional, default provided
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "clientSecret": "fcsess_client_secret_xxx",
    "sessionId": "fcsess_xxx"
  }
}
```

**Logic:**
1. Verify Firebase ID token
2. Get or create Stripe customer for user
3. Create Stripe Financial Connections session with:
   - `account_holder.type`: "customer"
   - `account_holder.customer`: stripe_customer_id
   - `permissions`: ["balances", "transactions", "ownership"]
   - `filters.countries`: ["US"]
4. Return clientSecret and sessionId

---

### 2. Complete Financial Connection
Called after user completes the Financial Connections flow to save linked accounts.

**Endpoint:** `POST /api/bexly/bank/complete`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "sessionId": "fcsess_xxx"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accounts": [
      {
        "id": "fca_xxx",
        "institutionName": "Chase",
        "displayName": "Chase Checking",
        "last4": "1234",
        "category": "checking"
      }
    ]
  }
}
```

**Logic:**
1. Verify Firebase ID token
2. Retrieve session from Stripe
3. For each linked account:
   - Insert into `linked_bank_accounts` table
   - Store institution_name, display_name, last4, category, balance
4. Return simplified account list

---

### 3. Get Linked Accounts
Returns all linked bank accounts for the authenticated user.

**Endpoint:** `GET /api/bexly/bank/accounts`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accounts": [
      {
        "id": "fca_xxx",
        "institutionName": "Chase",
        "displayName": "Chase Checking",
        "last4": "1234",
        "category": "checking",
        "status": "active",
        "balance": {
          "amount": 150000,
          "currency": "USD",
          "asOf": "2026-01-02T10:00:00Z"
        }
      }
    ]
  }
}
```

---

### 4. Sync Transactions
Fetches transactions from Stripe and stores in database.

**Endpoint:** `POST /api/bexly/bank/sync`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "accountId": "fca_xxx",    // optional, sync all if not provided
  "startDate": "2025-12-01", // optional
  "endDate": "2026-01-02"    // optional
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transactionCount": 150
  }
}
```

**Logic:**
1. Verify Firebase ID token
2. Get user's linked accounts (or specific account if accountId provided)
3. For each account, fetch transactions from Stripe with pagination
4. Upsert transactions into `bank_transactions` table
5. Return total count

**Note:** This endpoint may take several minutes for large histories. Consider:
- Timeout: 5 minutes
- Background job for initial sync
- Webhook for real-time updates

---

### 5. Disconnect Account
Disconnects a linked bank account.

**Endpoint:** `DELETE /api/bexly/bank/accounts/:accountId`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200):**
```json
{
  "success": true
}
```

**Logic:**
1. Verify Firebase ID token
2. Verify account belongs to user
3. Call `stripe.financialConnections.accounts.disconnect(accountId)`
4. Update account status to "disconnected" in database
5. Optionally delete associated transactions

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "User must be authenticated"
  }
}
```

**Error Codes:**
- `UNAUTHENTICATED` (401) - Missing or invalid token
- `FORBIDDEN` (403) - User doesn't own the resource
- `NOT_FOUND` (404) - Account not found
- `INVALID_ARGUMENT` (400) - Missing required fields
- `STRIPE_ERROR` (500) - Stripe API error
- `INTERNAL_ERROR` (500) - Server error

---

## Stripe SDK Usage

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Create session
const session = await stripe.financialConnections.sessions.create({
  account_holder: { type: 'customer', customer: customerId },
  permissions: ['balances', 'transactions', 'ownership'],
  filters: { countries: ['US'] },
  return_url: returnUrl,
});

// List transactions
const transactions = await stripe.financialConnections.transactions.list({
  account: accountId,
  limit: 100,
  transacted_at: { gte: startTimestamp, lte: endTimestamp },
});

// Disconnect account
await stripe.financialConnections.accounts.disconnect(accountId);
```

---

## Flutter Client Changes

After dos-me implements these endpoints, update `BankConnectionService` to call HTTP APIs instead of Firebase Functions:

```dart
class BankConnectionService {
  static const String baseUrl = 'https://api-v2.dos.me/api/bexly/bank';

  static Future<Map<String, String>> createSession() async {
    final idToken = await getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl/session'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    // ...
  }
}
```
