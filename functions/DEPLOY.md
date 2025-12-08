# Telegram Bot Deployment Guide

## Prerequisites

1. Install Node.js 20 LTS from https://nodejs.org/
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login: `firebase login`

## Deploy Steps

### 1. Install dependencies
```bash
cd functions
npm install
```

### 2. Build TypeScript
```bash
npm run build
```

### 3. Set bot token using Google Cloud Secret Manager
```bash
# Use gcloud to set the secret (do NOT hardcode token in files!)
gcloud secrets versions add TELEGRAM_BOT_TOKEN --data-file=-
# Then paste your token and press Ctrl+D
```

### 4. Deploy to Firebase
```bash
firebase deploy --only functions
```

### 5. Set Telegram Webhook
After deploy, get the function URL (will be shown in output), then:
```bash
# Replace YOUR_BOT_TOKEN with your actual token (do NOT commit this!)
curl "https://api.telegram.org/botYOUR_BOT_TOKEN/setWebhook?url=https://asia-southeast1-bexly-app.cloudfunctions.net/telegramWebhook"
```

## Test the Bot

1. Open Telegram
2. Search for @BexlyBot
3. Send `/start`
4. Should see welcome message with link to connect Bexly account

## Troubleshooting

### Check webhook status
```bash
curl "https://api.telegram.org/botYOUR_BOT_TOKEN/getWebhookInfo"
```

### View function logs
```bash
firebase functions:log
```

### Delete webhook (for testing)
```bash
curl "https://api.telegram.org/botYOUR_BOT_TOKEN/deleteWebhook"
```

## Security Notes

- NEVER commit bot tokens to git
- Always use Secret Manager for sensitive credentials
- If token is exposed, immediately revoke it via @BotFather `/revoke` command
