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

## Facebook Messenger Bot - Detailed Implementation

### Overview

Facebook Messenger Platform enables building chatbots that interact with 2B+ users. This is the most popular platform for individual users, especially in Vietnam.

### Prerequisites

1. **Facebook Page** - Create a dedicated page for Bexly at [facebook.com/pages/create](https://facebook.com/pages/create)
2. **Meta Developer Account** - Register at [developers.facebook.com](https://developers.facebook.com)
3. **Business Manager Account** - Required for Advanced Access permissions
4. **Privacy Policy URL** - Required for app review
5. **Terms of Service URL** - Required for app review

### Setup Steps

#### Step 1: Create Meta App

```
1. Go to developers.facebook.com
2. Click "Create App" → Select "Business" type
3. Choose "Messenger" as use case
4. Fill in app details
5. Add "Messenger" product to your app
```

#### Step 2: Configure Webhook

Webhook URL must be HTTPS. Use Firebase Cloud Functions or ngrok for local testing.

```javascript
// Webhook verification (GET request)
app.get('/webhook', (req, res) => {
  const VERIFY_TOKEN = 'your_verify_token';

  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === VERIFY_TOKEN) {
    console.log('Webhook verified');
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

// Receive messages (POST request)
app.post('/webhook', (req, res) => {
  const body = req.body;

  if (body.object === 'page') {
    body.entry.forEach(entry => {
      const webhook_event = entry.messaging[0];
      const sender_psid = webhook_event.sender.id;

      if (webhook_event.message) {
        handleMessage(sender_psid, webhook_event.message);
      } else if (webhook_event.postback) {
        handlePostback(sender_psid, webhook_event.postback);
      }
    });

    // IMPORTANT: Return 200 immediately
    res.status(200).send('EVENT_RECEIVED');
  } else {
    res.sendStatus(404);
  }
});
```

#### Step 3: Subscribe to Webhook Events

In Meta Developer Dashboard:
- Navigate to Messenger → Webhooks
- Click "Edit Callback URL"
- Enter webhook URL and Verify Token
- Subscribe to events: `messages`, `messaging_postbacks`, `messaging_optins`

#### Step 4: Get Page Access Token

```
1. In App Dashboard → Messenger → Access Tokens
2. Select your Facebook Page
3. Generate token (long-lived recommended)
4. Store securely in environment variables
```

### Message Types

#### 1. Text Message
```javascript
async function sendTextMessage(recipientId, text) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/messages`,
    {
      recipient: { id: recipientId },
      message: { text: text }
    },
    {
      params: { access_token: PAGE_ACCESS_TOKEN }
    }
  );
}
```

#### 2. Quick Replies (up to 13 buttons)
```javascript
async function sendQuickReplies(recipientId, text, replies) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/messages`,
    {
      recipient: { id: recipientId },
      message: {
        text: text,
        quick_replies: replies.map(r => ({
          content_type: 'text',
          title: r.title,      // max 20 chars
          payload: r.payload
        }))
      }
    },
    {
      params: { access_token: PAGE_ACCESS_TOKEN }
    }
  );
}

// Usage for expense categories
sendQuickReplies(psid, 'Select category:', [
  { title: '🍔 Food', payload: 'CAT_FOOD' },
  { title: '🚗 Transport', payload: 'CAT_TRANSPORT' },
  { title: '🛒 Shopping', payload: 'CAT_SHOPPING' },
  { title: '🎬 Entertainment', payload: 'CAT_ENTERTAINMENT' }
]);
```

#### 3. Button Template (up to 3 buttons)
```javascript
async function sendButtonTemplate(recipientId, text, buttons) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/messages`,
    {
      recipient: { id: recipientId },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: text,  // max 640 chars
            buttons: buttons
          }
        }
      }
    },
    {
      params: { access_token: PAGE_ACCESS_TOKEN }
    }
  );
}

// Usage for confirmation
sendButtonTemplate(psid, '✅ Expense recorded:\n💰 $50.00 - Coffee', [
  { type: 'postback', title: '✏️ Edit', payload: 'EDIT_LAST' },
  { type: 'postback', title: '🗑️ Delete', payload: 'DELETE_LAST' },
  { type: 'postback', title: '📝 Add note', payload: 'ADD_NOTE' }
]);
```

#### 4. Generic Template (Carousel - up to 10 cards)
```javascript
async function sendCarousel(recipientId, elements) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/messages`,
    {
      recipient: { id: recipientId },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: elements.map(e => ({
              title: e.title,
              subtitle: e.subtitle,
              image_url: e.image,
              buttons: e.buttons
            }))
          }
        }
      }
    },
    {
      params: { access_token: PAGE_ACCESS_TOKEN }
    }
  );
}

// Usage for wallet selection
sendCarousel(psid, [
  {
    title: '💵 Cash',
    subtitle: 'Balance: $250.00',
    buttons: [{ type: 'postback', title: 'Select wallet', payload: 'SELECT_WALLET_1' }]
  },
  {
    title: '💳 Bank Account',
    subtitle: 'Balance: $1,500.00',
    buttons: [{ type: 'postback', title: 'Select wallet', payload: 'SELECT_WALLET_2' }]
  }
]);
```

#### 5. Persistent Menu
```javascript
async function setPersistentMenu() {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/messenger_profile`,
    {
      persistent_menu: [
        {
          locale: 'default',
          composer_input_disabled: false,
          call_to_actions: [
            { type: 'postback', title: '💰 Add expense', payload: 'ADD_EXPENSE' },
            { type: 'postback', title: '💵 Add income', payload: 'ADD_INCOME' },
            { type: 'postback', title: '📊 View report', payload: 'VIEW_REPORT' },
            { type: 'postback', title: '💼 Wallet balances', payload: 'VIEW_BALANCES' },
            { type: 'postback', title: '⚙️ Settings', payload: 'SETTINGS' }
          ]
        }
      ]
    },
    {
      params: { access_token: PAGE_ACCESS_TOKEN }
    }
  );
}
```

### Permissions Required

| Permission | Description | Access Level |
|------------|-------------|--------------|
| `pages_messaging` | Send/receive messages | Standard → Advanced |
| `pages_manage_metadata` | Subscribe to webhook events | Standard |
| `pages_read_engagement` | Read page info | Standard |
| `pages_show_list` | Show pages you manage | Standard |

**Important:**
- Standard Access: Only admin/tester can receive messages
- Advanced Access: Public users can message → Requires App Review

### App Review Process

#### Requirements for Advanced Access:

1. **Privacy Policy** - Hosted URL accessible
2. **Terms of Service** - Hosted URL accessible
3. **App Icon** (1024x1024)
4. **Detailed Use Case Description**
5. **Screencast Video** - Demo bot functionality (2-5 mins)
6. **Business Verification** (optional nhưng recommended)

#### Review Timeline:

| Step | Duration |
|------|----------|
| Submit for review | 1-2 days |
| Initial review | 3-5 business days |
| Revision (if needed) | 1-3 days |
| Business verification | Up to 4 weeks |
| **Total** | **1-6 weeks** |

#### Common Rejection Reasons:

1. Bot doesn't respond to non-tester profiles
2. Onboarding too complex
3. Use-case doesn't match description
4. Missing Privacy Policy / ToS
5. Poor UX or error handling

### 24-Hour Messaging Window

Facebook limits bots to only send messages within **24 hours** after user interaction.

**Exceptions with Message Tags:**

| Tag | Use Case | Window |
|-----|----------|--------|
| `CONFIRMED_EVENT_UPDATE` | Event reminders | Extended |
| `POST_PURCHASE_UPDATE` | Order updates | Extended |
| `ACCOUNT_UPDATE` | Account changes | Extended |
| `HUMAN_AGENT` | Customer service | 7 days |

```javascript
// Sending with message tag
await axios.post(
  `https://graph.facebook.com/v18.0/me/messages`,
  {
    recipient: { id: recipientId },
    message: { text: 'Reminder: Electricity bill due soon!' },
    messaging_type: 'MESSAGE_TAG',
    tag: 'CONFIRMED_EVENT_UPDATE'
  },
  {
    params: { access_token: PAGE_ACCESS_TOKEN }
  }
);
```

### Node.js Libraries

| Library | Stars | TypeScript | Notes |
|---------|-------|------------|-------|
| `messenger-node` | 200+ | ✅ | Official-style SDK |
| `messaging-api-messenger` | 1.8k+ | ✅ | Part of messaging-apis suite |
| `node-facebook-messenger-api` | 100+ | ❌ | Simple, lightweight |
| Manual (axios) | - | ✅ | Full control |

**Recommendation:** Use `messenger-node` or manual axios for full control.

### Example: Complete Expense Flow

```javascript
// Handle incoming message
async function handleMessage(senderPsid, receivedMessage) {
  const messageText = receivedMessage.text;

  // Check if user is linked
  const userLink = await getUserLink('messenger', senderPsid);
  if (!userLink) {
    return sendLinkAccountMessage(senderPsid);
  }

  // Parse with Gemini AI
  const parsed = await parseWithGemini(messageText);

  if (parsed.intent === 'log_expense') {
    // Show confirmation with quick replies for category
    await sendQuickReplies(senderPsid,
      `💰 Ghi nhận chi tiêu: ${formatCurrency(parsed.amount)}\n\nChọn danh mục:`,
      [
        { title: '🍔 Ăn uống', payload: `CONFIRM_EXPENSE_FOOD_${parsed.amount}` },
        { title: '🚗 Di chuyển', payload: `CONFIRM_EXPENSE_TRANSPORT_${parsed.amount}` },
        { title: '🛒 Mua sắm', payload: `CONFIRM_EXPENSE_SHOPPING_${parsed.amount}` },
        { title: '❌ Hủy', payload: 'CANCEL' }
      ]
    );
  } else if (parsed.intent === 'query_balance') {
    const balances = await getWalletBalances(userLink.bexlyUserId);
    await sendBalanceReport(senderPsid, balances);
  }
}

// Handle postback (button click)
async function handlePostback(senderPsid, postback) {
  const payload = postback.payload;

  if (payload.startsWith('CONFIRM_EXPENSE_')) {
    const [_, __, category, amount] = payload.split('_');

    // Save to Firestore
    await saveTransaction(senderPsid, {
      type: 'expense',
      amount: parseFloat(amount),
      category: category.toLowerCase(),
      date: new Date()
    });

    await sendButtonTemplate(senderPsid,
      `✅ Đã lưu chi tiêu!\n💰 ${formatCurrency(amount)}\n📂 ${category}`,
      [
        { type: 'postback', title: '➕ Thêm mới', payload: 'ADD_EXPENSE' },
        { type: 'postback', title: '📊 Xem báo cáo', payload: 'VIEW_REPORT' }
      ]
    );
  }
}
```

### Bot-to-Human Handover

Meta provides a **Handover Protocol** to seamlessly transfer conversations between bot and human agents.

#### Trigger Scenarios

1. **User request** - Explicit keywords like "talk to human", "support"
2. **Fallback** - After 3+ failed understanding attempts
3. **Menu option** - Persistent menu button "Talk to Support"
4. **Complex queries** - Billing issues, account problems

#### Implementation

```javascript
// Keywords that trigger human handover
const humanKeywords = [
  'talk to human', 'speak to agent', 'real person', 'support',
  'nói chuyện với người', 'gặp support', 'hỗ trợ'
];

// Check if user wants human support
function needsHumanSupport(message, failedAttempts) {
  const wantsHuman = humanKeywords.some(kw =>
    message.toLowerCase().includes(kw)
  );
  return wantsHuman || failedAttempts >= 3;
}

// Pass thread control to Page Inbox (human agents)
async function passToHuman(recipientId, reason) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/pass_thread_control`,
    {
      recipient: { id: recipientId },
      target_app_id: '263902037430900', // Page Inbox App ID
      metadata: reason
    },
    { params: { access_token: PAGE_ACCESS_TOKEN } }
  );

  // Notify user
  await sendTextMessage(recipientId,
    '👤 Connecting you to our support team. Please wait...'
  );
}

// Take back thread control (bot resumes)
async function takeBackFromHuman(recipientId) {
  await axios.post(
    `https://graph.facebook.com/v18.0/me/take_thread_control`,
    {
      recipient: { id: recipientId },
      metadata: 'Bot resuming conversation'
    },
    { params: { access_token: PAGE_ACCESS_TOKEN } }
  );
}
```

#### Persistent Menu with Support Option

```javascript
call_to_actions: [
  { type: 'postback', title: '💰 Add expense', payload: 'ADD_EXPENSE' },
  { type: 'postback', title: '📊 View report', payload: 'VIEW_REPORT' },
  { type: 'postback', title: '👤 Talk to Support', payload: 'HUMAN_SUPPORT' }
]
```

#### Required Setup

1. Enable **Handover Protocol** in App Dashboard → Messenger → Settings
2. Set your app as **Primary Receiver** (bot handles first)
3. Set **Page Inbox** as Secondary Receiver (human fallback)

### Security Considerations

1. **Verify Webhook Signature**
```javascript
function verifySignature(req, res, buf) {
  const signature = req.headers['x-hub-signature-256'];
  if (!signature) {
    throw new Error('Missing signature');
  }

  const expectedSignature = 'sha256=' +
    crypto.createHmac('sha256', APP_SECRET)
      .update(buf)
      .digest('hex');

  if (signature !== expectedSignature) {
    throw new Error('Invalid signature');
  }
}
```

2. **Store tokens securely** - Use Firebase Secret Manager hoặc environment variables
3. **Rate limiting** - Facebook có rate limit, implement retry với exponential backoff
4. **User data encryption** - Encrypt PSID và user data at rest

### Cost Estimate (Messenger-specific)

| Item | Cost |
|------|------|
| Meta Platform | **Free** |
| Firebase Functions | ~$5-20/month |
| Gemini API | ~$10-30/month |
| **Total** | **$15-50/month** |

---

## References

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [grammY Framework](https://grammy.dev/)
- [Discord.js Guide](https://discordjs.guide/)
- [Facebook Messenger Platform](https://developers.facebook.com/docs/messenger-platform/)
- [Messenger Webhook Guide](https://messengerbot.app/mastering-facebook-messenger-webhooks-a-complete-guide-to-setup-automation-and-chatbot-creation/)
- [messenger-node SDK](https://github.com/amuramoto/messenger-node)
- [messaging-api-messenger npm](https://www.npmjs.com/package/messaging-api-messenger)
- [Messenger Policy Compliance](https://chatimize.com/facebook-messenger-policy/)
- [App Review Skip Guide](https://respond.io/blog/skip-facebook-bot-verification)
- [RASA NLU](https://rasa.com/docs/rasa/)
