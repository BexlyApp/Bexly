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

### 3. Set bot token in Firebase config
```bash
firebase functions:config:set telegram.bot_token="8038733197:AAHjX1c05dLS3ibivcnikkarxbpr29Jpq7Q"
```

### 4. Deploy to Firebase
```bash
firebase deploy --only functions
```

### 5. Set Telegram Webhook
After deploy, get the function URL (will be shown in output), then:
```bash
curl "https://api.telegram.org/bot8038733197:AAHjX1c05dLS3ibivcnikkarxbpr29Jpq7Q/setWebhook?url=https://asia-southeast1-bexly-app.cloudfunctions.net/telegramWebhook"
```

## Test the Bot

1. Open Telegram
2. Search for @BexlyBot
3. Send `/start`
4. Should see welcome message with link to connect Bexly account

## Troubleshooting

### Check webhook status
```bash
curl "https://api.telegram.org/bot8038733197:AAHjX1c05dLS3ibivcnikkarxbpr29Jpq7Q/getWebhookInfo"
```

### View function logs
```bash
firebase functions:log
```

### Delete webhook (for testing)
```bash
curl "https://api.telegram.org/bot8038733197:AAHjX1c05dLS3ibivcnikkarxbpr29Jpq7Q/deleteWebhook"
```
