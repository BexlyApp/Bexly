# Pockaw Premium Plan

## Overview
Pockaw operates on a freemium model with local-first approach. Free users get full functionality with local storage only. Premium users get cloud sync, backup, and advanced features.

## Tier Structure

### Free Tier (Default)
**Price:** $0 forever

**Features:**
- ✅ Unlimited wallets and transactions
- ✅ All basic expense tracking features
- ✅ Budget management
- ✅ Basic analytics and reports
- ✅ Categories and tags
- ✅ 100% offline - works without internet
- ✅ Manual export/import (JSON/CSV)
- ✅ No ads, no tracking

**Limitations:**
- ❌ No cloud backup
- ❌ No multi-device sync
- ❌ No receipt image storage
- ❌ Manual backup only
- ❌ Lost data if device fails

### Premium Tier
**Price:** $2.99/month or $29.99/year (2 months free)

**Everything in Free, plus:**
- ✅ Automatic cloud backup
- ✅ Real-time sync across devices
- ✅ Receipt photo storage (up to 5GB)
- ✅ Restore data from any device
- ✅ Web access (coming soon)
- ✅ Priority support
- ✅ Early access to new features

### Pro Tier (Future)
**Price:** $5.99/month or $59.99/year

**Everything in Premium, plus:**
- ✅ AI-powered insights
- ✅ Receipt OCR scanning
- ✅ Advanced analytics
- ✅ Custom categories with AI suggestions
- ✅ Spending predictions
- ✅ Financial health score
- ✅ Export to accounting software
- ✅ Family sharing (up to 5 accounts)

## Technical Implementation

### Authentication Flow
```
App Launch
    ↓
Check Auth State
    ↓
No Auth → Local Mode (SQLite only)
    ↓
Auth → Check Subscription
    ↓
Active → Enable Cloud Sync
```

### Data Storage Strategy

**Free Users:**
- SQLite local database only
- No Firebase usage = $0 cost
- Manual backup via file export

**Premium Users:**
- SQLite local (primary, instant)
- Firestore cloud (backup, sync)
- Firebase Storage (receipts)
- Bidirectional sync

### Subscription Management

**Payment Processing:**
- Google Play Billing (Android)
- StoreKit (iOS)
- Stripe (Web - future)

**Verification:**
- Server-side validation via Firebase Functions
- RevenueCat or native implementation
- Grace period for expired payments

### Firebase Cost Analysis

**Per Premium User/Month:**
```
Firestore:
- Reads: ~10K = $0.036
- Writes: ~5K = $0.018
- Storage: ~10MB = $0.0026

Firebase Storage:
- Storage: 100MB = $0.0026
- Bandwidth: 500MB = $0.012

Total: ~$0.07/user
Profit: $2.99 - $0.07 = $2.92/user
```

**Break-even Analysis:**
- Firebase free tier supports ~50 active premium users
- At 100 premium users: $299/month revenue, ~$7 Firebase cost
- Profit margin: ~97%

## Migration Strategy

### Free → Premium Upgrade
1. User subscribes in-app
2. Prompt to create account (Google/Email)
3. Automatic upload local data to cloud
4. Enable sync for future changes
5. Show success with cloud backup status

### Premium → Free Downgrade
1. Notify 7 days before expiration
2. On expiration: disable cloud sync
3. Keep local data intact
4. Offer one-time cloud export
5. Data remains in cloud for 30 days

## Marketing Strategy

### Value Proposition
**Free Users:**
- "Your finances, your device, your control"
- "No account required - start immediately"
- "Works 100% offline"
- "Privacy-first: data never leaves your device"

**Premium Users:**
- "Never lose your financial data"
- "Access from any device"
- "Automatic backup for peace of mind"
- "Secure cloud storage with encryption"

### Conversion Tactics
1. **Gentle Reminders:**
   - After 30 days of use
   - When switching devices
   - After creating 100+ transactions

2. **Fear of Loss:**
   - "Backup your 500 transactions to cloud"
   - "Device lost = data lost. Protect now"

3. **Convenience:**
   - "Access on phone, tablet, and web"
   - "Switching phones? Take your data with you"

4. **Trial Period:**
   - 14-day free trial for premium
   - No credit card required initially

## Development Priorities

### Phase 1 (Current)
- [x] Local SQLite implementation
- [x] Core expense tracking features
- [ ] Firebase integration structure
- [ ] Authentication system

### Phase 2 (Q1 2025)
- [ ] Payment integration
- [ ] Cloud sync implementation
- [ ] Subscription management UI
- [ ] Server-side validation

### Phase 3 (Q2 2025)
- [ ] Receipt photo storage
- [ ] Web app for premium users
- [ ] Advanced analytics
- [ ] Family sharing

### Phase 4 (Q3 2025)
- [ ] AI features for Pro tier
- [ ] OCR receipt scanning
- [ ] Predictive analytics
- [ ] Third-party integrations

## Success Metrics

### Target KPIs
- Free to Premium conversion: 3-5%
- Monthly churn rate: <5%
- LTV: $50+ per premium user
- CAC: <$10 per premium user

### Milestones
- 100 premium users: Cover development costs
- 500 premium users: Part-time income
- 2000 premium users: Full-time sustainable

## Privacy & Security

### Data Protection
- End-to-end encryption for cloud data
- GDPR/CCPA compliant
- User owns and controls their data
- Export/delete at any time
- No data selling or ads

### Trust Building
- Open source core functionality
- Transparent privacy policy
- Regular security audits
- SOC 2 compliance (future)