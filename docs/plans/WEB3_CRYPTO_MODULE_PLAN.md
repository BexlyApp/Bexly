# Web3 Crypto Tracking Module Plan

## Overview

Module Web3 cho phép user track tài sản crypto ngay trong Bexly, kết hợp với tài chính truyền thống để có toàn cảnh tài chính 1 nơi duy nhất. Module được thiết kế ẩn mặc định, user bật khi cần.

**Rationale**: Tích hợp vào Bexly (không tách app riêng) vì:
- App crypto riêng = red ocean (CoinStats, Zerion, DeBank đã có)
- Module crypto trong app tài chính = blue ocean (chưa app VN nào có)
- Giá trị core là sự kết hợp: crypto + ngân sách + mục tiêu + báo cáo tổng hợp

**Phases:**
- Phase 1 (MVP): Manual entry + CoinGecko price tracking
- Phase 2: Auto-sync wallet address (on-chain tracking)
- Phase 3: CEX integration (Binance, OKX, Bybit)

---

## Database Layer

### Local Drift Tables (schema version 24+)

**`lib/core/database/tables/crypto_asset_table.dart`**
```dart
// User's crypto holdings — manual entry in Phase 1, auto in Phase 2+
@DataClassName('CryptoAssetEntry')
class CryptoAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get tokenId => text()();              // CoinGecko token ID: "bitcoin", "ethereum"
  TextColumn get tokenSymbol => text()();          // "BTC", "ETH", "SOL"
  TextColumn get tokenName => text()();            // "Bitcoin", "Ethereum"
  RealColumn get amount => real()();               // How much user holds
  TextColumn get source => text()                  // "manual", "wallet", "cex"
      .withDefault(const Constant('manual'))();
  IntColumn get cryptoWalletId => integer()        // FK to CryptoWallets (Phase 2+)
      .nullable()();
  IntColumn get cexConnectionId => integer()       // FK to CexConnections (Phase 3)
      .nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

**`lib/core/database/tables/crypto_price_cache_table.dart`**
```dart
// Cached prices — NOT synced to Supabase, local only
@DataClassName('CryptoPriceCacheEntry')
class CryptoPriceCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tokenId => text().unique()();     // CoinGecko token ID
  TextColumn get tokenSymbol => text()();
  RealColumn get priceUsd => real()();
  RealColumn get priceVnd => real()();
  RealColumn get change24h => real().nullable()();
  RealColumn get change7d => real().nullable()();
  RealColumn get marketCap => real().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime()();
}
```

**`lib/core/database/tables/crypto_wallet_table.dart`** (Phase 2)
```dart
// On-chain wallet addresses for auto-tracking
@DataClassName('CryptoWalletEntry')
class CryptoWallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get label => text()();                // "My MetaMask", "Cold wallet"
  TextColumn get address => text()();              // 0x... or SOL address
  TextColumn get chainType => text()();            // "evm", "solana", "bitcoin"
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

**`lib/core/database/tables/cex_connection_table.dart`** (Phase 3)
```dart
// CEX API connections — API keys stored in flutter_secure_storage, NOT here
@DataClassName('CexConnectionEntry')
class CexConnections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get exchange => text()();             // "binance", "okx", "bybit"
  TextColumn get label => text()();                // "My Binance"
  TextColumn get apiKeyRef => text()();            // Reference key for secure storage
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

### Supabase Cloud Tables (schema `bexly`)

```sql
-- Phase 1: Only crypto_assets synced (manual holdings)
CREATE TABLE bexly.crypto_assets (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    token_id TEXT NOT NULL,
    token_symbol TEXT NOT NULL,
    token_name TEXT NOT NULL,
    amount NUMERIC(30, 10) NOT NULL,
    source TEXT NOT NULL DEFAULT 'manual',
    crypto_wallet_cloud_id UUID REFERENCES bexly.crypto_wallets(cloud_id),
    cex_connection_cloud_id UUID REFERENCES bexly.cex_connections(cloud_id),
    notes TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Phase 2
CREATE TABLE bexly.crypto_wallets (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    label TEXT NOT NULL,
    address TEXT NOT NULL,
    chain_type TEXT NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Phase 3 (metadata only — API keys NEVER on cloud)
CREATE TABLE bexly.cex_connections (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    exchange TEXT NOT NULL,
    label TEXT NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS policies
ALTER TABLE bexly.crypto_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.crypto_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.cex_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own crypto_assets"
    ON bexly.crypto_assets FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own crypto_wallets"
    ON bexly.crypto_wallets FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own cex_connections"
    ON bexly.cex_connections FOR ALL USING (auth.uid() = user_id);
```

### Migrations

**Local Drift** — add to `app_database.dart`:
```dart
// Schema version 24: Add crypto tables
if (from < 24) {
  await m.createTable(cryptoAssets);
  await m.createTable(cryptoPriceCache);
}
// Schema version 25: Phase 2 — wallet tracking
if (from < 25) {
  await m.createTable(cryptoWallets);
  await m.addColumn(cryptoAssets, cryptoAssets.cryptoWalletId);
}
// Schema version 26: Phase 3 — CEX
if (from < 26) {
  await m.createTable(cexConnections);
  await m.addColumn(cryptoAssets, cryptoAssets.cexConnectionId);
}
```

---

## API Layer

### CoinGecko Price Service (Phase 1)

```
Endpoints (free tier, 30 calls/min):
- GET /coins/markets?vs_currency=usd&ids=bitcoin,ethereum,...
  → Price, 24h change, market cap, image
- GET /search?query=doge
  → Token search autocomplete
- GET /coins/{id}/market_chart?days=30
  → Price history for charts
- GET /simple/price?ids=bitcoin&vs_currencies=usd,vnd
  → Quick price check

Rate limiting strategy:
- Cache prices in CryptoPriceCache table
- Refresh max every 60 seconds (dashboard pull-to-refresh)
- Background refresh every 5 minutes when app is foreground
- Batch requests: up to 250 token IDs per call
```

### Zerion API (Phase 2)

```
Endpoints:
- GET /v1/wallets/{address}/positions
  → All token balances + DeFi positions, 38+ chains
- GET /v1/wallets/{address}/transactions
  → Transaction history
```

### CEX APIs (Phase 3)

```
Binance: GET /api/v3/account (HMAC-SHA256 signed)
OKX:     GET /api/v5/account/balance (HMAC-SHA256 + passphrase)
Bybit:   GET /v5/account/wallet-balance (HMAC-SHA256)

Security: API keys in flutter_secure_storage, NEVER in DB or Supabase.
```

---

## Feature Module Structure

```
lib/features/crypto/
├── data/
│   ├── models/
│   │   ├── crypto_asset_model.dart        # @freezed — user's holding
│   │   ├── crypto_price_model.dart        # @freezed — cached price data
│   │   ├── crypto_wallet_model.dart       # @freezed — wallet address (Phase 2)
│   │   ├── cex_connection_model.dart      # @freezed — exchange connection (Phase 3)
│   │   └── token_search_result.dart       # CoinGecko search result
│   ├── repositories/
│   │   └── crypto_repository.dart         # Aggregates DAO + API data
│   └── sources/
│       ├── coingecko_api_source.dart      # Price API (Phase 1)
│       ├── zerion_api_source.dart         # On-chain API (Phase 2)
│       └── cex_api_source.dart            # CEX APIs (Phase 3)
├── presentation/
│   ├── screens/
│   │   ├── crypto_dashboard_screen.dart   # Main portfolio view
│   │   ├── add_crypto_asset_screen.dart   # Manual add token + amount
│   │   ├── token_search_screen.dart       # Search CoinGecko tokens
│   │   ├── crypto_asset_detail_screen.dart # Token detail + chart
│   │   ├── add_wallet_screen.dart         # Phase 2
│   │   └── add_cex_screen.dart            # Phase 3
│   ├── components/
│   │   ├── crypto_portfolio_card.dart     # Dashboard summary card
│   │   ├── crypto_asset_tile.dart         # Single token row
│   │   ├── token_price_chart.dart         # Price chart (fl_chart)
│   │   ├── portfolio_pie_chart.dart       # Allocation chart
│   │   └── crypto_total_balance.dart      # Total crypto in USD/VND
│   └── riverpod/
│       ├── crypto_assets_provider.dart    # StreamProvider — user holdings
│       ├── crypto_prices_provider.dart    # FutureProvider — prices
│       ├── crypto_portfolio_provider.dart # Computed — holdings × prices
│       ├── token_search_provider.dart     # FutureProvider.family — search
│       └── crypto_settings_provider.dart  # Feature toggle state
├── services/
│   ├── crypto_price_service.dart          # Fetch + cache prices
│   └── crypto_sync_service.dart           # Supabase sync
└── utils/
    ├── crypto_formatters.dart             # Format BTC amount, market cap
    └── chain_config.dart                  # Chain IDs, explorer URLs
```

---

## UI Integration

### Dashboard
```
┌─ Dashboard ──────────────────────────
│  ├─ Balance Card v2 (existing)
│  ├─ [NEW] Crypto Portfolio Card      ← Only if crypto enabled
│  │   ├─ Total crypto value (USD/VND)
│  │   ├─ 24h change %
│  │   └─ Top 3 holdings mini-list
│  ├─ Cash Flow Cards (existing)
│  └─ ... rest of dashboard
```

### Settings
```
├─ Settings Finance Group
│  ├─ Backup & Restore
│  ├─ [NEW] Crypto Portfolio ← Toggle on/off + manage holdings
│  ├─ Bank Connections
│  └─ ...
```

### Routes
```dart
static const String cryptoDashboard = '/crypto';
static const String addCryptoAsset = '/crypto/add';
static const String cryptoAssetDetail = '/crypto/detail';
static const String tokenSearch = '/crypto/search';
static const String addCryptoWallet = '/crypto/wallet/add';    // Phase 2
static const String addCexConnection = '/crypto/cex/add';      // Phase 3
```

---

## Sync Service

Add to `supabase_sync_service.dart`:
```dart
// In syncAllData():
if (userSettings.cryptoEnabled) {
  await syncCryptoAssetsToCloud();
  await pullCryptoAssetsFromCloud();
}
```

Follow existing pattern: UUID v7 cloudId, upsert on conflict, check is_deleted before upload.

---

## Dependencies

```yaml
# Phase 1
flutter_secure_storage: ^9.0.0   # Prep for Phase 3 CEX API keys

# Phase 2+ — no new deps, use dio (already in project)

# Phase 3 (optional)
web3dart: ^2.7.3                 # Direct Ethereum RPC if needed
```

---

## Phase Breakdown

### Phase 1 — MVP Manual Tracking (~3-4 weeks)
1. Drift tables: `crypto_assets`, `crypto_price_cache` + migration
2. `CryptoAssetModel`, `CryptoPriceModel` (@freezed)
3. `CoinGeckoApiSource` (price fetch + search)
4. `CryptoPriceService` (cache + refresh logic)
5. `CryptoAssetDao` (CRUD)
6. Riverpod providers
7. UI: crypto_dashboard, add_crypto_asset, token_search, asset_detail screens
8. UI: crypto_portfolio_card for Dashboard
9. Settings toggle
10. Supabase migration + sync service
11. Routes + navigation

### Phase 2 — Wallet Tracking (~4-6 weeks after Phase 1)
1. Drift table: `crypto_wallets` + migration
2. `ZerionApiSource`
3. Auto-fetch balances for wallet addresses
4. UI: add_wallet_screen, wallet management
5. Merge manual + wallet balances in portfolio
6. Supabase migration + sync

### Phase 3 — CEX Integration (~4-6 weeks after Phase 2)
1. Drift table: `cex_connections` + migration
2. `flutter_secure_storage` for API keys
3. `CexApiSource` (Binance, OKX, Bybit HMAC-SHA256)
4. UI: add_cex_screen, CEX management
5. Merge all sources in portfolio
6. Supabase migration (metadata only, no API keys)

---

## Security

- CEX API keys: `flutter_secure_storage` only, NEVER in Drift DB, NEVER in Supabase
- Wallet addresses: public data, safe to sync
- CoinGecko API: no auth needed for free tier
- Zerion API: key in `.env` (gitignored)
- Rate limiting: respect API limits, cache aggressively
