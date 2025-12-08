# Bexly Multi-Platform Chatbot Integration Plan

## Overview

Cho phép user tương tác với Bexly qua các chatbot platforms để:
- Nhập thu/chi bằng tin nhắn tự nhiên
- Truy vấn số dư, chi tiêu theo thời gian
- Nhận báo cáo và insights

## Supported Platforms

| Platform | Pros | Cons |
|----------|------|------|
| **Telegram** | Free, đơn giản, 900M+ users | User phải /start trước |
| **Discord** | Free, slash commands UX tốt | Thiên về gaming community |
| **Messenger** | 2B+ users, webhook-based | Setup phức tạp, compliance |

**Recommendation:** Bắt đầu với **Telegram** (đơn giản nhất), sau đó mở rộng.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Chat Platforms (Telegram/Discord/Messenger)     │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Webhook Handler Service                   │
│     • Verify signatures   • Normalize messages               │
│     • Return 200 OK immediately                              │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Chatbot Core Service                      │
│     • NLP Intent Recognition    • Session Management         │
│     • Entity Extraction         • Response Formatting        │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Bexly Backend API                         │
│     • Firebase Auth   • Firestore   • Cloud Functions        │
└─────────────────────────────────────────────────────────────┘
```

---

## User Flow

### 1. Account Linking (First-time)

```
User: /start
Bot: Welcome! Please link your Bexly account.
     [Link Account] button

User: Clicks button → Redirect to Bexly OAuth
User: Login with Bexly credentials
Bot: Account linked! You can now log expenses.
```

### 2. Log Expense

```
User: Spent $50 on lunch
Bot: ✅ Logged expense:
     💰 Amount: $50.00
     📂 Category: Food
     📅 Date: Today

     [Edit] [Undo]
```

### 3. Query Data

```
User: How much did I spend this week?
Bot: 📊 This Week's Spending:
     Total: $245.50

     🍔 Food: $120.00
     🚗 Transport: $65.50
     🎬 Entertainment: $60.00
```

---

## NLP Intents

| Intent | Examples | Entities |
|--------|----------|----------|
| `log_expense` | "Spent $50 on lunch", "Paid 100k for taxi" | amount, category, date |
| `log_income` | "Received $500 salary", "Got 200 freelance" | amount, source, date |
| `query_balance` | "What's my balance?", "How much do I have?" | wallet |
| `query_spending` | "How much did I spend this week?" | period, category |
| `query_category` | "Show food expenses" | category, period |

### Entity Extraction

```
"Spent $50.25 on lunch today"
→ {
    intent: "log_expense",
    amount: 50.25,
    currency: "USD",
    category: "food",
    date: "2025-12-07"
  }
```

---

## Tech Stack

### Backend
- **Runtime:** Node.js + TypeScript
- **Framework:** Express.js / Fastify
- **Bot Libraries:**
  - Telegram: `grammY` (modern, TypeScript-first)
  - Discord: `discord.js`
  - Messenger: `axios` + manual webhook

### NLP Options
1. **Phase 1 (MVP):** Regex + pattern matching
2. **Phase 2:** RASA NLU (self-hosted)
3. **Phase 3:** Claude API (natural conversation)

### Database
- **Firebase Firestore** (existing Bexly DB)
- **Redis** for session/token management

### Hosting
- **Phase 1:** Firebase Cloud Functions (serverless)
- **Phase 2:** Docker + Cloud Run (scalable)

---

## Database Schema

### user_platform_links (Firestore)
```javascript
{
  bexlyUserId: "abc123",
  platform: "telegram",
  platformUserId: "123456789",
  accessToken: "encrypted_token",
  refreshToken: "encrypted_refresh",
  linkedAt: Timestamp,
  lastActivity: Timestamp
}
```

### bot_conversations (for analytics)
```javascript
{
  userId: "abc123",
  platform: "telegram",
  messageText: "Spent $50 on lunch",
  intent: "log_expense",
  entities: { amount: 50, category: "food" },
  response: "✅ Logged expense...",
  createdAt: Timestamp
}
```

---

## Security

1. **Token Encryption:** AES-256 for stored tokens
2. **Webhook Verification:** HMAC signature check
3. **Rate Limiting:** 100 requests/min per user
4. **Short-lived Tokens:** 1 hour expiry + refresh
5. **Audit Logging:** All financial operations logged

---

## Implementation Phases

### Phase 1: Telegram MVP (4-6 weeks)

**Week 1-2: Setup & Auth**
- [ ] Create Telegram bot via @BotFather
- [ ] Setup webhook handler (Cloud Functions)
- [ ] Implement OAuth 2.0 account linking
- [ ] Store user-platform mapping in Firestore

**Week 3-4: Core Features**
- [ ] Implement pattern-based NLP for intents
- [ ] Log expense/income via chat
- [ ] Query balance and spending
- [ ] Confirmation flow with inline buttons

**Week 5-6: Polish & Testing**
- [ ] Error handling and edge cases
- [ ] Multi-language support (VI, EN)
- [ ] Beta testing with 20 users
- [ ] Security audit

### Phase 2: Expand Platforms (4 weeks)

- [ ] Discord bot with slash commands
- [ ] Facebook Messenger bot
- [ ] Cross-platform session management
- [ ] Unified analytics

### Phase 3: Advanced Features (ongoing)

- [ ] LLM-powered natural conversations (Claude)
- [ ] Voice message support
- [ ] Receipt photo parsing (OCR)
- [ ] Budget alerts via bot
- [ ] Multi-currency handling

---

## Cost Estimate

### Phase 1 (MVP)
| Item | Monthly Cost |
|------|-------------|
| Firebase (Functions + Firestore) | $25-50 |
| Redis (Cloud Memorystore) | $15-30 |
| **Total** | **$40-80/month** |

### Growth (1k users)
| Item | Monthly Cost |
|------|-------------|
| Firebase | $100-200 |
| Redis | $30-50 |
| Claude API (optional) | $50-200 |
| **Total** | **$180-450/month** |

---

## Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| Token management across platforms | Composite key `{platform}:{userId}` in Redis |
| Facebook 20s timeout | Return 200 immediately, queue async processing |
| NLP accuracy | Confirmation flow + user feedback loop |
| Multi-turn conversations | Store state in Redis with 15min TTL |

---

## Next Steps

1. **Approve plan** - Xác nhận architecture và tech stack
2. **Setup Telegram bot** - @BotFather, get token
3. **Create Cloud Function** - Webhook handler
4. **Implement OAuth** - Account linking flow
5. **Build NLP** - Pattern matching for MVP

---

## References

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [grammY Framework](https://grammy.dev/)
- [Discord.js Guide](https://discordjs.guide/)
- [Facebook Messenger Webhooks](https://developers.facebook.com/docs/messenger-platform/)
- [RASA NLU](https://rasa.com/docs/rasa/)
